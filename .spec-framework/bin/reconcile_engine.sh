#!/usr/bin/env bash
set -euo pipefail

ACTION=${1:-}
CHANGE_ID=${2:-}

if [[ ! "$CHANGE_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf 'ERROR: invalid change id\n' >&2
  exit 2
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'ERROR: not inside a Git repository\n' >&2
  exit 2
}

export SDD_RECONCILE_ROOT="$ROOT"
export SDD_RECONCILE_ACTION="$ACTION"
export SDD_RECONCILE_CHANGE_ID="$CHANGE_ID"

exec python3 - <<'PY'
import datetime as dt
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


class ReconcileError(RuntimeError):
    def __init__(self, message, code=2):
        super().__init__(message)
        self.code = code


ROOT = Path(os.environ["SDD_RECONCILE_ROOT"]).resolve()
ACTION = os.environ["SDD_RECONCILE_ACTION"]
CHANGE_ID = os.environ["SDD_RECONCILE_CHANGE_ID"]
REQ_RE = re.compile(
    r"(?ms)^### Requirement: ([^\n]+)\n.*?(?=^### Requirement: |^## |\Z)"
)
SCENARIO_RE = re.compile(
    r"(?ms)^#### Scenario: ([^\n]+)\n.*?(?=^#### Scenario: |\Z)"
)
DECISION_RE = re.compile(
    r"(?ms)^### Decision (ADR-[^:]+):?\s*([^\n]*)\n(.*?)(?=^### Decision |\Z)"
)
SECTION_RE = re.compile(
    r"(?ms)^## (ADDED|MODIFIED|REMOVED) Requirements\s*$\n(.*?)(?=^## [^\n]+\s*$|\Z)"
)


def fail(message, code=2):
    raise ReconcileError(message, code)


def read_json(path):
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid JSON: {path}: {error}")
    if not isinstance(value, dict):
        fail(f"JSON object required: {path}")
    return value


def sha256_bytes(value):
    return hashlib.sha256(value).hexdigest()


def sha256_text(value):
    return sha256_bytes(value.encode("utf-8"))


def safe_path(raw, base=ROOT):
    candidate = Path(raw)
    if candidate.is_absolute() or ".." in candidate.parts:
        fail(f"unsafe path: {raw}")
    current = base
    for part in candidate.parts:
        current /= part
        if current.is_symlink():
            fail(f"symlink path is not allowed: {current}")
    resolved = current.resolve(strict=False)
    try:
        resolved.relative_to(base.resolve())
    except ValueError:
        fail(f"path escapes repository: {raw}")
    return resolved


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, raw_tmp = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temp = Path(raw_tmp)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, path)
    finally:
        temp.unlink(missing_ok=True)


def change_dir(archived=False):
    if not archived:
        path = safe_path(Path("changes") / CHANGE_ID)
        if path.is_dir():
            return path
        fail(f"change directory is missing: {path}")
    root = safe_path("changes/archives")
    candidates = sorted(
        path for path in root.glob(f"*-{CHANGE_ID}") if path.is_dir() and not path.is_symlink()
    )
    if not candidates:
        fail(f"archived change is missing for teardown: {CHANGE_ID}")
    return candidates[-1]


def report_paths(directory):
    report = directory / "verification-report.md"
    approval = directory / "verification-approval.json"
    if not report.is_file():
        fail(f"verification-report.md is required: {report}")
    if not approval.is_file():
        fail(f"verification-approval.json is required: {approval}")
    text = report.read_text(encoding="utf-8")
    if not re.search(r"(?im)^\s*\*\*Status:\*\*\s*(?:Ready for human approval|ready-for-approval|PASS)\s*$", text):
        fail(f"verification report is not approved for reconciliation: {report}")
    for line in text.splitlines():
        matches = list(re.finditer(r"\b(?:CRITICAL|IMPORTANT)\b", line, re.IGNORECASE))
        for index, match in enumerate(matches):
            severity = match.group(0).upper()
            next_start = matches[index + 1].start() if index + 1 < len(matches) else len(line)
            segment = line[match.end():next_start]
            clause_start = line.rfind(";", 0, match.start()) + 1
            prefix = line[clause_start:match.start()]
            if re.search(rf"\b(?:no|none|zero|0)\b.*$", prefix, re.IGNORECASE):
                continue
            if re.search(r"\b(?:open|unresolved|remains)\b", segment, re.IGNORECASE):
                fail(f"verification report contains an open {severity} finding")
            if re.search(r"\b(?:closed|resolved|none)\b", segment, re.IGNORECASE):
                continue
            fail(f"verification report contains an open {severity} finding")
    return report, approval


def verify_approval(directory):
    report, approval = report_paths(directory)
    evidence_raw = Path(
        subprocess.check_output(["git", "rev-parse", "--git-path", "cook-verify-evidence"], cwd=ROOT, text=True).strip()
    )
    if not evidence_raw.is_absolute():
        evidence_raw = ROOT / evidence_raw
    evidence = evidence_raw.resolve() / CHANGE_ID
    helper = ROOT / "skills/cook-verify/scripts/cook_verify.py"
    if not helper.is_file():
        fail(f"cook-verify validator is required: {helper}")
    receipt = read_json(approval)
    verification_commit = receipt.get("verification_commit")
    report_hash = sha256_bytes(report.read_bytes())
    if not verification_commit or not isinstance(verification_commit, str):
        fail("approval receipt has no verification commit")
    command = [
        "python3",
        str(helper),
        "validate-approval",
        str(approval),
        CHANGE_ID,
        verification_commit,
        report_hash,
        str(evidence),
    ]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "approval validation failed"
        fail(detail)


def load_change(directory):
    meta_path = directory / "meta.json"
    delta_path = directory / "delta-spec.md"
    if not meta_path.is_file() or not delta_path.is_file():
        fail("meta.json and delta-spec.md are required")
    meta = read_json(meta_path)
    if meta.get("change_id") not in (None, CHANGE_ID):
        fail("meta.json targets a different change")
    target = meta.get("target")
    if not isinstance(target, str) or not target.startswith("specs/"):
        fail("meta.json target must be a repository path under specs/")
    target_path = safe_path(target)
    if not target_path.is_file():
        fail(f"living spec is missing: {target_path}")
    delta = delta_path.read_text(encoding="utf-8")
    declared = re.search(r"(?m)^Target Domain:\s*(\S+)\s*$", delta)
    if declared and declared.group(1) != target:
        fail("delta target does not match meta.json target")
    return meta, delta, target_path


def requirement_blocks(text):
    blocks = {}
    for match in REQ_RE.finditer(text):
        title = match.group(1).strip()
        if title in blocks:
            fail(f"duplicate requirement title: {title}", 3)
        blocks[title] = match.group(0).strip()
    return blocks


def sections(delta):
    result = {"ADDED": [], "MODIFIED": [], "REMOVED": []}
    for match in SECTION_RE.finditer(delta):
        result[match.group(1)] = list(requirement_blocks(match.group(2)).values())
    return result


def scenario_map(block):
    return {match.group(1).strip(): match.group(0).strip() for match in SCENARIO_RE.finditer(block)}


def semantic_merge(base, live, delta, title):
    if live == delta:
        return live
    base_scenarios = scenario_map(base)
    live_scenarios = scenario_map(live)
    delta_scenarios = scenario_map(delta)
    if not base_scenarios or not delta_scenarios:
        fail(f"semantic conflict for requirement: {title}", 3)
    live_changed = {
        name for name in set(base_scenarios) | set(live_scenarios)
        if base_scenarios.get(name) != live_scenarios.get(name)
    }
    delta_changed = {
        name for name in set(base_scenarios) | set(delta_scenarios)
        if base_scenarios.get(name) != delta_scenarios.get(name)
    }
    if live_changed & delta_changed:
        fail(f"semantic conflict for requirement: {title}", 3)
    base_prefix = base.split("#### Scenario:", 1)[0]
    live_prefix = live.split("#### Scenario:", 1)[0]
    delta_prefix = delta.split("#### Scenario:", 1)[0]
    if live_prefix != base_prefix and delta_prefix != base_prefix and live_prefix != delta_prefix:
        fail(f"semantic conflict for requirement: {title}", 3)
    prefix = live_prefix if live_prefix != base_prefix else delta_prefix
    merged = [prefix.rstrip()]
    seen = set()
    for name in list(live_scenarios) + list(delta_scenarios):
        if name in seen:
            continue
        seen.add(name)
        if name in delta_changed and name not in live_changed:
            if name in delta_scenarios:
                merged.append(delta_scenarios[name])
        else:
            merged.append(live_scenarios.get(name, delta_scenarios[name]))
    return "\n\n".join(part for part in merged if part) + "\n"


def replace_blocks(text, replacements, removals):
    matches = list(REQ_RE.finditer(text))
    output = []
    cursor = 0
    for match in matches:
        title = match.group(1).strip()
        output.append(text[cursor:match.start()])
        if title not in removals:
            output.append(replacements.get(title, match.group(0)).rstrip() + "\n")
        cursor = match.end()
    output.append(text[cursor:])
    return "".join(output).strip() + "\n"


def validate_living_spec(text):
    for title, block in requirement_blocks(text).items():
        if not scenario_map(block):
            fail(f"living spec requirement has no scenario: {title}")


def sync_spec(directory):
    verify_approval(directory)
    meta, delta, target_path = load_change(directory)
    current = target_path.read_text(encoding="utf-8")
    current_blocks = requirement_blocks(current)
    delta_sections = sections(delta)
    metadata = meta.get("requirements", {})
    if not isinstance(metadata, dict):
        fail("meta.json requirements must be an object")
    replacements = {}
    removals = set()
    additions = []
    for kind in ("ADDED", "MODIFIED", "REMOVED"):
        for block in delta_sections[kind]:
            title_match = re.match(r"### Requirement: ([^\n]+)", block)
            if not title_match:
                fail(f"invalid requirement block in {kind}")
            title = title_match.group(1).strip()
            entry = metadata.get(title, {})
            if not isinstance(entry, dict):
                fail(f"meta.json requirement entry is invalid: {title}")
            base_hash = entry.get("base_sha256")
            if kind != "ADDED" and (
                not isinstance(base_hash, str)
                or not re.fullmatch(r"[0-9a-f]{64}", base_hash)
            ):
                fail(f"base_sha256 fingerprint is required for {kind.lower()} requirement: {title}")
            if kind == "ADDED":
                if title in current_blocks:
                    if current_blocks[title] != block:
                        fail(f"semantic conflict for added requirement: {title}", 3)
                    continue
                additions.append(block)
                continue
            if title not in current_blocks:
                if kind == "REMOVED":
                    continue
                fail(f"requirement to modify is missing: {title}", 3)
            live = current_blocks[title]
            if not isinstance(base_hash, str) or sha256_text(live) != base_hash:
                if kind == "REMOVED":
                    fail(f"semantic conflict for removed requirement: {title}", 3)
                base = entry.get("base")
                if not isinstance(base, str):
                    fail(f"base text is required for 3-way merge: {title}", 3)
                if sha256_text(base.strip()) != base_hash:
                    fail(f"base text does not match base_sha256: {title}", 3)
                replacements[title] = semantic_merge(base.strip(), live, block, title)
            elif kind == "MODIFIED":
                replacements[title] = block
            else:
                removals.add(title)
    updated = replace_blocks(current, replacements, removals)
    if additions:
        updated = updated.rstrip() + "\n\n" + "\n\n".join(additions) + "\n"
    if removals:
        deprecations = "## Deprecations\n" + "\n".join(
            f"- `{title}` retired by `{CHANGE_ID}`" for title in sorted(removals)
        )
        if "## Deprecations" not in updated:
            updated = updated.rstrip() + "\n\n" + deprecations + "\n"
        else:
            for line in deprecations.splitlines()[1:]:
                if line not in updated:
                    updated = updated.rstrip() + "\n" + line + "\n"
    updated = re.sub(r"\n+(?=### Requirement:|## Deprecations)", "\n\n", updated)
    validate_living_spec(updated)
    atomic_write(target_path, updated)
    state = {
        "change_id": CHANGE_ID,
        "target": str(target_path.relative_to(ROOT)),
        "spec_sha256": sha256_bytes(target_path.read_bytes()),
    }
    atomic_write(directory / ".reconcile-state.json", json.dumps(state, indent=2) + "\n")
    print(f"Living spec synchronized: {state['target']}")


def persist_adr(directory):
    verify_approval(directory)
    design = directory / "design.md"
    if not design.is_file():
        print("No design.md; no ADRs to persist.")
        return
    content = design.read_text(encoding="utf-8")
    adr_dir = safe_path("specs/adr")
    today = dt.datetime.now(dt.timezone.utc)
    date_stamp = today.strftime("%Y%m%d")
    date_text = today.strftime("%Y-%m-%d")
    for match in DECISION_RE.finditer(content):
        title = match.group(2).strip() or match.group(1)
        slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-") or "decision"
        prefix = f"ADR-{date_stamp}-{slug}"
        body = match.group(3).strip()
        rendered = (
            f"# ADR: {title}\n\n"
            f"Date: {date_text}\n"
            f"Change: {CHANGE_ID}\n\n{body}\n"
        )
        target = adr_dir / f"{prefix}.md"
        suffix = 2
        while target.exists() and target.read_text(encoding="utf-8") != rendered:
            target = adr_dir / f"{prefix}-{suffix}.md"
            suffix += 1
        if not target.exists():
            atomic_write(target, rendered)
            print(f"ADR persisted: {target.relative_to(ROOT)}")


def validate_archive_inputs(directory):
    for name in ("proposal.md", "design.md", "tasks.md"):
        if not (directory / name).is_file():
            fail(f"required audit artifact is missing: {directory / name}")
    content = (directory / "design.md").read_text(encoding="utf-8")
    adr_dir = safe_path("specs/adr")
    adr_files = list(adr_dir.glob("ADR-*.md")) if adr_dir.is_dir() else []
    for match in DECISION_RE.finditer(content):
        title = match.group(2).strip() or match.group(1)
        expected = f"# ADR: {title}\n"
        if not any(
            adr.is_file()
            and expected in adr.read_text(encoding="utf-8")
            and f"Change: {CHANGE_ID}\n" in adr.read_text(encoding="utf-8")
            for adr in adr_files
        ):
            fail(f"persist-adr is required before archive: {title}")


def archive(directory):
    verify_approval(directory)
    validate_archive_inputs(directory)
    state_path = directory / ".reconcile-state.json"
    if not state_path.is_file():
        fail("sync-spec must complete before archive")
    state = read_json(state_path)
    target = safe_path(state.get("target", ""))
    if not target.is_file() or sha256_bytes(target.read_bytes()) != state.get("spec_sha256"):
        fail("living spec changed after sync; rerun sync-spec")
    archive_root = safe_path("changes/archives")
    archive_root.mkdir(parents=True, exist_ok=True)
    destination = archive_root / f"{dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%d')}-{CHANGE_ID}"
    if destination.exists():
        fail(f"archive destination already exists: {destination}")
    subprocess.run(["git", "mv", str(directory), str(destination)], cwd=ROOT, check=True)
    print(f"Change archived: {destination.relative_to(ROOT)}")


def git_output(*args, cwd=ROOT):
    return subprocess.check_output(["git", *args], cwd=cwd, text=True).strip()


def teardown():
    directory = change_dir(archived=True)
    verify_approval(directory)
    worktree = safe_path(Path(".worktrees") / CHANGE_ID)
    if worktree.exists():
        if not worktree.is_dir():
            fail(f"worktree path is not a directory: {worktree}")
        status = git_output("-C", str(worktree), "status", "--porcelain", "--untracked-files=all")
        if status:
            fail(f"worktree is dirty; teardown refused: {worktree}", 4)
        branch = f"feature/{CHANGE_ID}"
        try:
            subprocess.run(
                ["git", "merge-base", "--is-ancestor", branch, git_output("rev-parse", "HEAD")],
                cwd=ROOT,
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError:
            fail(f"branch is not merged; teardown refused: {branch}", 4)
        subprocess.run(["git", "worktree", "remove", str(worktree)], cwd=ROOT, check=True)
    branch = f"feature/{CHANGE_ID}"
    if subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"], cwd=ROOT).returncode == 0:
        subprocess.run(["git", "branch", "-d", branch], cwd=ROOT, check=True)
    subprocess.run(["git", "worktree", "prune"], cwd=ROOT, check=True)
    print(f"Worktree torn down: {CHANGE_ID}")


def main():
    if ACTION == "sync-spec":
        sync_spec(change_dir())
    elif ACTION == "persist-adr":
        persist_adr(change_dir())
    elif ACTION == "archive":
        archive(change_dir())
    elif ACTION == "teardown":
        teardown()
    else:
        fail("valid actions: sync-spec, persist-adr, archive, teardown")


try:
    main()
except ReconcileError as error:
    print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(error.code)
except subprocess.CalledProcessError as error:
    detail = error.stderr.strip() if error.stderr else str(error)
    print(f"ERROR: command failed: {detail}", file=sys.stderr)
    raise SystemExit(2)
PY
