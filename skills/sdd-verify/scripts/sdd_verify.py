#!/usr/bin/env python3
import datetime as dt
import fnmatch
import hashlib
import hmac
import json
import math
import os
import re
import signal
import selectors
import subprocess
import sys
import time
from pathlib import Path


class VerificationError(ValueError):
    pass


SHA1 = re.compile(r"^[0-9a-f]{40}$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
MAX_LOG_BYTES = 10 * 1024 * 1024


def _reject_symlinks(path, boundary):
    candidate = Path(path)
    if not candidate.is_absolute():
        candidate = Path.cwd() / candidate
    boundary = Path(boundary).absolute()
    try:
        parts = candidate.relative_to(boundary).parts
    except ValueError as error:
        raise VerificationError(f"path escapes trusted boundary: {candidate}") from error
    current = boundary
    for part in parts:
        current /= part
        if current.is_symlink():
            raise VerificationError(f"symlink path is not allowed: {current}")


def _json(path):
    try:
        value = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise VerificationError(f"invalid JSON receipt: {path}") from error
    if not isinstance(value, dict):
        raise VerificationError(f"receipt must be a JSON object: {path}")
    return value


def _required(value, fields):
    missing = [field for field in fields if field not in value]
    if missing:
        raise VerificationError(f"receipt fields missing: {', '.join(missing)}")


def _sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _receipt_file(receipt_path, value):
    receipt_raw = Path(receipt_path)
    if not receipt_raw.is_absolute():
        receipt_raw = Path.cwd() / receipt_raw
    if receipt_raw.is_symlink():
        raise VerificationError("receipt cannot be a symlink")
    receipt_dir = receipt_raw.absolute().parent
    candidate = Path(value)
    candidate = receipt_dir / candidate if not candidate.is_absolute() else candidate
    _reject_symlinks(candidate, receipt_dir)
    candidate = candidate.resolve()
    receipt_dir = receipt_dir.resolve()
    try:
        candidate.relative_to(receipt_dir)
    except ValueError as error:
        raise VerificationError("receipt file must stay inside the evidence directory") from error
    if candidate.is_symlink():
        raise VerificationError("receipt file cannot be a symlink")
    return candidate


def _open_log(path):
    _reject_symlinks(path, Path(path).parent)
    if Path(path).exists() and not Path(path).is_file():
        raise VerificationError(f"evidence log is not a regular file: {path}")
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    return os.fdopen(os.open(path, flags, 0o600), "wb")


def _tree_snapshot(worktree):
    paths = subprocess.check_output(
        ["git", "-C", str(worktree), "ls-files", "-z"], text=False
    ).split(b"\0")
    snapshot = []
    for raw_path in paths:
        if not raw_path:
            continue
        path = worktree / os.fsdecode(raw_path)
        if path.is_symlink():
            value = os.readlink(path).encode()
        elif path.is_file():
            value = hashlib.sha256(path.read_bytes()).digest()
        else:
            value = b"<missing>"
        snapshot.append((raw_path, value))
    return tuple(snapshot)


def _strict_int(value):
    return isinstance(value, int) and not isinstance(value, bool)


def _verify_attestation(event, event_type):
    secret = os.environ.get("SDD_VERIFY_ATTESTATION_KEY")
    signature = event.get("signature")
    if not secret or not isinstance(signature, str) or not SHA256.fullmatch(signature):
        raise VerificationError("authenticated host attestation is required")
    unsigned = dict(event)
    del unsigned["signature"]
    payload = json.dumps(unsigned, sort_keys=True, separators=(",", ":")).encode()
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(signature, expected):
        raise VerificationError(f"invalid {event_type} host attestation signature")


def validate_mutation_receipt(
    path, base_sha, target_sha, minimum=80.0, git_root=None, target_worktree=None
):
    receipt = _json(path)
    _required(
        receipt,
        [
            "status",
            "base_sha",
            "target_sha",
            "tool",
            "tool_version",
            "killed",
            "total",
            "equivalent",
            "score",
        ],
    )
    if receipt["status"] != "PASS":
        raise VerificationError("mutation receipt is not PASS")
    if float(minimum) < 80.0:
        raise VerificationError("mutation threshold cannot be below 80%")
    if receipt["base_sha"] != base_sha or receipt["target_sha"] != target_sha:
        raise VerificationError("mutation receipt targets a different commit range")
    if not SHA1.fullmatch(base_sha) or not SHA1.fullmatch(target_sha):
        raise VerificationError("mutation receipt contains an invalid commit SHA")
    if not receipt["tool"] or not receipt["tool_version"]:
        raise VerificationError("mutation tool identity is required")
    if not all(_strict_int(receipt[field]) for field in ("killed", "total", "equivalent")):
        raise VerificationError("mutation counts must be integers")
    try:
        killed = receipt["killed"]
        total = receipt["total"]
        equivalent = receipt["equivalent"]
        score = float(receipt["score"])
    except (TypeError, ValueError) as error:
        raise VerificationError("mutation counts and score must be numeric") from error
    if not math.isfinite(score) or not math.isfinite(float(minimum)):
        raise VerificationError("mutation score and threshold must be finite")
    if git_root is not None:
        for sha in (base_sha, target_sha):
            try:
                subprocess.run(
                    ["git", "-C", str(git_root), "cat-file", "-e", f"{sha}^{{commit}}"],
                    check=True,
                    capture_output=True,
                )
            except (subprocess.CalledProcessError, OSError) as error:
                raise VerificationError("mutation receipt references an unknown commit") from error
    if target_worktree is not None:
        try:
            head = subprocess.check_output(
                ["git", "-C", str(target_worktree), "rev-parse", "HEAD"], text=True
            ).strip()
            if head != target_sha:
                raise VerificationError("mutation target is not the audited worktree HEAD")
            subprocess.run(
                ["git", "-C", str(target_worktree), "merge-base", "--is-ancestor", base_sha, target_sha],
                check=True,
                capture_output=True,
            )
        except (subprocess.CalledProcessError, OSError) as error:
            raise VerificationError("mutation target is outside the audited commit range") from error
    denominator = total - equivalent
    if total <= 0 or not 0 <= equivalent < total or denominator <= 0 or not 0 <= killed <= denominator:
        raise VerificationError("mutation counts are invalid")
    computed = killed / denominator * 100
    if not math.isclose(score, computed, rel_tol=0.0, abs_tol=1e-9):
        raise VerificationError("mutation score does not match raw counts")
    if computed < minimum:
        raise VerificationError(f"mutation score {computed:.4f} is below {minimum:.2f}")
    return computed


def validate_review_receipt(path, acceptance_criteria, input_sha256, evidence_root=None):
    if evidence_root is not None:
        evidence_root = Path(evidence_root).resolve()
        receipt_path = Path(path)
        if not receipt_path.is_absolute():
            receipt_path = Path.cwd() / receipt_path
        _reject_symlinks(receipt_path, evidence_root)
        try:
            receipt_path.resolve().relative_to(evidence_root)
        except ValueError as error:
            raise VerificationError("review receipt is outside evidence") from error
    receipt = _json(path)
    _required(
        receipt,
        [
            "status",
            "independent",
            "dispatch_id",
            "fork_id",
            "raw_receipt_path",
            "raw_receipt_sha256",
            "input_sha256",
            "host_attestation_path",
            "host_attestation_sha256",
            "findings",
            "ac_coverage",
        ],
    )
    if receipt["status"] != "PASS" or receipt["independent"] is not True:
        raise VerificationError("review receipt is not an independent PASS")
    if not receipt["dispatch_id"] or not receipt["fork_id"]:
        raise VerificationError("review dispatch and fork identity are required")
    if receipt["input_sha256"] != input_sha256 or not SHA256.fullmatch(input_sha256):
        raise VerificationError("review receipt input hash does not match")
    if not isinstance(receipt["findings"], list) or not isinstance(receipt["ac_coverage"], list):
        raise VerificationError("review findings and AC coverage must be arrays")
    if not all(isinstance(item, dict) for item in receipt["findings"] + receipt["ac_coverage"]):
        raise VerificationError("review findings and AC coverage entries must be objects")
    raw_path = _receipt_file(path, receipt["raw_receipt_path"])
    if not SHA256.fullmatch(receipt["raw_receipt_sha256"]):
        raise VerificationError("review raw receipt hash is invalid")
    try:
        raw_hash = _sha256(raw_path)
    except OSError as error:
        raise VerificationError("review raw receipt is unavailable") from error
    if raw_hash != receipt["raw_receipt_sha256"]:
        raise VerificationError("review raw receipt hash does not match")
    if not SHA256.fullmatch(receipt["host_attestation_sha256"]):
        raise VerificationError("review host attestation hash is invalid")
    attestation_path = _receipt_file(path, receipt["host_attestation_path"])
    try:
        if _sha256(attestation_path) != receipt["host_attestation_sha256"]:
            raise VerificationError("review host attestation hash does not match")
        attestation = _json(attestation_path)
    except OSError as error:
        raise VerificationError("review host attestation is unavailable") from error
    if attestation.get("event") != "review-dispatch":
        raise VerificationError("review host attestation is not a dispatch event")
    _verify_attestation(attestation, "review")
    for field in ("dispatch_id", "fork_id", "input_sha256", "raw_receipt_sha256"):
        if attestation.get(field) != receipt[field]:
            raise VerificationError("review host attestation does not match receipt")
    if any(
        str(finding.get("severity", "")).upper() in {"CRITICAL", "IMPORTANT"}
        for finding in receipt["findings"]
    ):
        raise VerificationError("review contains a blocking finding")
    covered = {item.get("id") for item in receipt["ac_coverage"] if isinstance(item, dict)}
    if covered != set(acceptance_criteria):
        raise VerificationError("review does not cover every acceptance criterion")
    if any(
        item.get("status") != "PASS" or not item.get("evidence")
        for item in receipt["ac_coverage"]
        if isinstance(item, dict)
    ):
        raise VerificationError("review acceptance evidence is incomplete")


def validate_approval(path, change_id, verification_commit, report_sha256, evidence_root=None):
    approval = _json(path)
    _required(
        approval,
        [
            "command",
            "approver",
            "approved_at",
            "verification_commit",
            "report_sha256",
            "host_attestation_path",
            "host_attestation_sha256",
        ],
    )
    if approval["command"] != f"approve-verification changes/{change_id}":
        raise VerificationError("approval command is not the exact change command")
    if not approval["approver"] or not isinstance(approval["approver"], str):
        raise VerificationError("approver identity is required")
    try:
        dt.datetime.fromisoformat(approval["approved_at"].replace("Z", "+00:00"))
    except (AttributeError, ValueError) as error:
        raise VerificationError("approval timestamp must be ISO-8601") from error
    if approval["verification_commit"] != verification_commit or not SHA1.fullmatch(verification_commit):
        raise VerificationError("approval targets a different verification commit")
    if approval["report_sha256"] != report_sha256 or not SHA256.fullmatch(report_sha256):
        raise VerificationError("approval targets a different report")
    if not SHA256.fullmatch(approval["host_attestation_sha256"]):
        raise VerificationError("approval host attestation hash is invalid")
    attestation_path = Path(approval["host_attestation_path"])
    if evidence_root is not None:
        evidence_root = Path(evidence_root).resolve()
        if not attestation_path.is_absolute():
            attestation_path = Path.cwd() / attestation_path
        _reject_symlinks(attestation_path, evidence_root)
        attestation_path = attestation_path.resolve()
        try:
            attestation_path.relative_to(evidence_root)
        except ValueError as error:
            raise VerificationError("approval attestation is outside evidence") from error
    try:
        if _sha256(attestation_path) != approval["host_attestation_sha256"]:
            raise VerificationError("approval host attestation hash does not match")
        event = _json(attestation_path)
        if event.get("event") != "human-checkpoint":
            raise VerificationError("approval host attestation is not a human checkpoint")
        _verify_attestation(event, "approval")
        for field in ("command", "approver", "verification_commit", "report_sha256"):
            if event.get(field) != approval[field]:
                raise VerificationError("approval host attestation does not match approval")
    except OSError as error:
        raise VerificationError("approval host attestation is unavailable") from error


def _paths(path):
    if " -> " in path:
        return path.split(" -> ", 1)
    return [path]


def _safe_path(path):
    candidate = Path(path)
    return not candidate.is_absolute() and ".." not in candidate.parts


def validate_scope(paths, allowed, forbidden, report_path):
    for changed in paths:
        for path in _paths(changed):
            if not _safe_path(path):
                raise VerificationError(f"unsafe changed path: {path}")
            if path == report_path:
                continue
            if any(fnmatch.fnmatchcase(path, pattern) for pattern in forbidden):
                raise VerificationError(f"forbidden changed path: {path}")
            if not any(fnmatch.fnmatchcase(path, pattern) for pattern in allowed):
                raise VerificationError(f"changed path outside plan: {path}")


def _plan_paths(path, label):
    patterns = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if label in line:
            patterns.extend(re.findall(r"`([^`]+)`", line))
    return patterns


def validate_git_scope(root, change_id, base_sha, target_sha):
    root = Path(root).absolute()
    raw_worktree = root / ".worktrees" / change_id
    _reject_symlinks(raw_worktree, root)
    worktree = raw_worktree.resolve()
    tasks = root / "changes" / change_id / "tasks.md"
    if not tasks.is_file():
        raise VerificationError("approved tasks.md is missing")
    allowed = _plan_paths(tasks, "Allowed Paths")
    forbidden = _plan_paths(tasks, "Forbidden Paths")
    if not allowed:
        raise VerificationError("approved Allowed Paths are missing")
    try:
        head = subprocess.check_output(
            ["git", "-C", str(worktree), "rev-parse", "HEAD"], text=True
        ).strip()
        if target_sha != head:
            raise VerificationError("scope target SHA is not the audited worktree HEAD")
        subprocess.run(
            ["git", "-C", str(worktree), "merge-base", "--is-ancestor", base_sha, target_sha],
            check=True,
            capture_output=True,
        )
        tracked = subprocess.check_output(
            ["git", "-C", str(worktree), "diff", "--name-only", "--no-renames", base_sha, target_sha],
            text=True,
        ).splitlines()
        untracked = subprocess.check_output(
            ["git", "-C", str(worktree), "status", "--porcelain", "--untracked-files=all"],
            text=True,
        )
    except (subprocess.CalledProcessError, OSError) as error:
        raise VerificationError("unable to derive changed paths from Git") from error
    paths = tracked + [line[3:] for line in untracked.splitlines() if len(line) >= 4]
    validate_scope(
        paths,
        allowed,
        forbidden,
        f"changes/{change_id}/verification-report.md",
    )


def _run_stage(command, worktree, log_path, timeout):
    process = subprocess.Popen(
        ["bash", "-c", "--", command],
        cwd=worktree,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    written = 0
    overflow = False
    timed_out = False
    deadline = time.monotonic() + timeout
    with _open_log(log_path) as log:
        while selector.get_map():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                timed_out = True
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
                selector.unregister(process.stdout)
                break
            for key, _ in selector.select(min(remaining, 0.1)):
                chunk = os.read(key.fd, 65536)
                if not chunk:
                    selector.unregister(key.fileobj)
                    continue
                available = MAX_LOG_BYTES - written
                if available > 0:
                    log.write(chunk[:available])
                    written += min(len(chunk), available)
                if len(chunk) > available:
                    overflow = True
    if not timed_out:
        process.wait()
    selector.close()
    process.stdout.close()
    if timed_out:
        return 124
    if overflow:
        return 125
    return process.returncode


def run_harness(root, change_id, base_sha, commands, evidence_path, command_manifest, timeout=600):
    root = Path(root).absolute()
    raw_worktree = root / ".worktrees" / change_id
    _reject_symlinks(raw_worktree, root)
    worktree = raw_worktree.resolve()
    evidence_input = Path(evidence_path)
    manifest_input = Path(command_manifest)
    raw_evidence = root / evidence_input if not evidence_input.is_absolute() else evidence_input
    raw_manifest = root / manifest_input if not manifest_input.is_absolute() else manifest_input
    _reject_symlinks(raw_evidence, root)
    _reject_symlinks(raw_manifest, root)
    evidence = raw_evidence.resolve()
    manifest = raw_manifest.resolve()
    if not worktree.is_dir():
        raise VerificationError(f"worktree not found: {worktree}")
    if not SHA1.fullmatch(base_sha):
        raise VerificationError("base commit must be a full SHA-1")
    try:
        subprocess.run(
            ["git", "-C", str(worktree), "cat-file", "-e", f"{base_sha}^{{commit}}"],
            check=True,
            capture_output=True,
        )
        target_sha = subprocess.check_output(
            ["git", "-C", str(worktree), "rev-parse", "HEAD"], text=True
        ).strip()
        subprocess.run(
            ["git", "-C", str(worktree), "merge-base", "--is-ancestor", base_sha, target_sha],
            check=True,
            capture_output=True,
        )
        worktree_root = Path(
            subprocess.check_output(
                ["git", "-C", str(worktree), "rev-parse", "--show-toplevel"], text=True
            ).strip()
        ).resolve()
        if worktree_root != worktree:
            raise VerificationError("audited path is not the trusted worktree root")
    except (subprocess.CalledProcessError, OSError) as error:
        raise VerificationError("base or target commit is invalid") from error
    dirty = subprocess.check_output(
        ["git", "-C", str(worktree), "status", "--porcelain", "--untracked-files=all"],
        text=True,
    )
    if dirty:
        raise VerificationError("audited worktree is dirty")
    git_dir = Path(
        subprocess.check_output(["git", "-C", str(root), "rev-parse", "--git-dir"], text=True).strip()
    )
    if not git_dir.is_absolute():
        git_dir = (root / git_dir).resolve()
    common_dir = Path(
        subprocess.check_output(
            ["git", "-C", str(worktree), "rev-parse", "--git-common-dir"], text=True
        ).strip()
    )
    if not common_dir.is_absolute():
        common_dir = (worktree / common_dir).resolve()
    if common_dir != git_dir:
        raise VerificationError("worktree belongs to a different Git repository")
    expected_evidence = (git_dir / "sdd-verify-evidence" / change_id).resolve()
    if evidence != expected_evidence:
        raise VerificationError("evidence path must be inside the Git evidence directory")
    expected_manifest = (root / "changes" / change_id / "verification-commands.json").resolve()
    if manifest != expected_manifest or manifest.is_symlink():
        raise VerificationError("command manifest must be the approved change artifact")
    command_spec = _json(manifest)
    if command_spec.get("change_id") != change_id or command_spec.get("base_sha") != base_sha:
        raise VerificationError("command manifest targets a different change or base commit")
    for candidate in (git_dir / "sdd-verify-evidence", expected_evidence):
        if candidate.is_symlink():
            raise VerificationError("evidence path cannot contain symlinks")
    if len(commands) != 4 or any(not command.strip() for command in commands):
        raise VerificationError("typecheck, static, architecture, and global commands are required")
    if len(set(commands)) != 4 or any(command.strip() in {"true", ":"} for command in commands):
        raise VerificationError("harness stage commands cannot be duplicate or no-op")
    stages_spec = command_spec.get("stages")
    if not isinstance(stages_spec, dict):
        raise VerificationError("command manifest stages are required")
    for name, command in zip(("typecheck", "static", "architecture", "global"), commands):
        expected_hash = stages_spec.get(name, {}).get("command_sha256")
        if expected_hash != hashlib.sha256(command.encode()).hexdigest():
            raise VerificationError(f"{name} command does not match the approved manifest")
    verifier_path = root / ".spec-framework/bin/run_harness.sh"
    helper_path = Path(__file__).resolve()
    verifier_hash = _sha256(verifier_path)
    helper_hash = _sha256(helper_path)
    manifest_hash = _sha256(manifest)
    evidence.mkdir(parents=True, exist_ok=True)
    evidence.chmod(0o700)
    stages = []
    names = ("typecheck", "static", "architecture", "global")
    for name, command in zip(names, commands):
        log_path = evidence / f"{name}.log"
        started = time.time()
        before_sha = subprocess.check_output(
            ["git", "-C", str(worktree), "rev-parse", "HEAD"], text=True
        ).strip()
        before_tree = _tree_snapshot(worktree)
        try:
            status = _run_stage(command, worktree, log_path, timeout)
        except OSError as error:
            raise VerificationError(f"unable to start {name} stage") from error
        after_sha = subprocess.check_output(
            ["git", "-C", str(worktree), "rev-parse", "HEAD"], text=True
        ).strip()
        after_dirty = subprocess.check_output(
            ["git", "-C", str(worktree), "status", "--porcelain", "--untracked-files=all"],
            text=True,
        )
        after_tree = _tree_snapshot(worktree)
        if status == 0 and (after_sha != before_sha or after_dirty or after_tree != before_tree):
            status = 126
        log_path.chmod(0o600)
        stages.append(
            {
                "name": name,
                "status": "PASS" if status == 0 else "FAIL",
                "exit_status": status,
                "log": str(log_path),
                "duration_seconds": round(time.time() - started, 3),
            }
        )
        if status != 0:
            break
    report = {
        "status": "PASS" if len(stages) == 4 and all(stage["status"] == "PASS" for stage in stages) else "FAIL",
        "change_id": change_id,
        "base_sha": base_sha,
        "target_sha": target_sha,
        "verifier_sha256": verifier_hash,
        "helper_sha256": helper_hash,
        "manifest_sha256": manifest_hash,
        "stages": stages,
    }
    if (
        _sha256(verifier_path) != verifier_hash
        or _sha256(helper_path) != helper_hash
        or _sha256(manifest) != manifest_hash
    ):
        report["status"] = "FAIL"
        report["integrity_error"] = "verifier or command manifest changed during harness"
    report_path = evidence / "harness.json"
    with _open_log(report_path) as report_file:
        report_file.write((json.dumps(report, indent=2) + "\n").encode())
    report_path.chmod(0o600)
    if report["status"] != "PASS":
        if report.get("integrity_error"):
            raise VerificationError(report["integrity_error"])
        if stages[-1]["exit_status"] == 126:
            raise VerificationError("harness stage changed the audited worktree")
        raise VerificationError(f"harness failed at {stages[-1]['name']}")
    return report


def main(argv):
    if len(argv) < 2:
        print(
            "usage: sdd_verify.py run-harness ROOT CHANGE_ID BASE_SHA EVIDENCE "
            "MANIFEST TYPECHECK STATIC ARCHITECTURE GLOBAL",
            file=sys.stderr,
        )
        return 2
    try:
        command = argv[1]
        if command == "run-harness" and len(argv) == 11:
            run_harness(argv[2], argv[3], argv[4], argv[7:11], argv[5], argv[6])
        elif command == "validate-mutation" and len(argv) in {5, 6, 7}:
            minimum = float(argv[5]) if len(argv) == 6 else 80.0
            if len(argv) == 7:
                minimum = float(argv[5])
            print(
                f"{validate_mutation_receipt(argv[2], argv[3], argv[4], minimum, Path.cwd(), argv[6] if len(argv) == 7 else None):.4f}"
            )
        elif command == "validate-review" and len(argv) in {5, 6}:
            validate_review_receipt(
                argv[2],
                [item for item in argv[3].split(",") if item],
                argv[4],
                argv[5] if len(argv) == 6 else None,
            )
        elif command == "validate-approval" and len(argv) in {6, 7}:
            validate_approval(argv[2], argv[3], argv[4], argv[5], argv[6] if len(argv) == 7 else None)
        elif command == "validate-scope" and len(argv) == 6:
            validate_scope(
                [item for item in argv[2].split(",") if item],
                [item for item in argv[3].split(",") if item],
                [item for item in argv[4].split(",") if item],
                argv[5],
            )
        elif command == "validate-scope-git" and len(argv) == 6:
            validate_git_scope(argv[2], argv[3], argv[4], argv[5])
        else:
            raise VerificationError("invalid command arguments")
    except VerificationError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
