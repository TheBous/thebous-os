import hashlib
import hmac
import json
import os
import shutil
import subprocess
import sys
import time
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sdd_verify import (  # noqa: E402
    VerificationError,
    validate_approval,
    validate_mutation_receipt,
    validate_review_receipt,
    validate_scope,
    validate_git_scope,
    run_harness,
    MAX_LOG_BYTES,
)


class SddVerifyTests(unittest.TestCase):
    def setUp(self):
        os.environ["SDD_VERIFY_ATTESTATION_KEY"] = "test-key"

    def tearDown(self):
        os.environ.pop("SDD_VERIFY_ATTESTATION_KEY", None)

    def signed_attestation(self, value):
        payload = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
        value["signature"] = hmac.new(b"test-key", payload, hashlib.sha256).hexdigest()
        return value

    def write_json(self, directory, name, value):
        path = Path(directory) / name
        path.write_text(json.dumps(value), encoding="utf-8")
        return path

    def test_mutation_receipt_uses_raw_counts_and_target_sha(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = self.write_json(
                directory,
                "mutation.json",
                {
                    "status": "PASS",
                    "base_sha": "a" * 40,
                    "target_sha": "b" * 40,
                    "tool": "mutmut",
                    "tool_version": "3.2.1",
                    "killed": 8,
                    "total": 10,
                    "equivalent": 0,
                    "score": 80.0,
                },
            )
            self.assertEqual(
                validate_mutation_receipt(receipt, "a" * 40, "b" * 40),
                80.0,
            )

    def test_mutation_receipt_rejects_mismatched_score(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = self.write_json(
                directory,
                "mutation.json",
                {
                    "status": "PASS",
                    "base_sha": "a" * 40,
                    "target_sha": "b" * 40,
                    "tool": "mutmut",
                    "tool_version": "3.2.1",
                    "killed": 7,
                    "total": 10,
                    "equivalent": 0,
                    "score": 80.0,
                },
            )
            with self.assertRaises(VerificationError):
                validate_mutation_receipt(receipt, "a" * 40, "b" * 40)

    def test_mutation_receipt_rejects_fractional_counts(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = self.write_json(
                directory,
                "mutation.json",
                {
                    "status": "PASS",
                    "base_sha": "a" * 40,
                    "target_sha": "b" * 40,
                    "tool": "mutmut",
                    "tool_version": "3.2.1",
                    "killed": 8.5,
                    "total": 10,
                    "equivalent": 0,
                    "score": 85.0,
                },
            )
            with self.assertRaises(VerificationError):
                validate_mutation_receipt(receipt, "a" * 40, "b" * 40)

    def test_cli_validates_mutation_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
            receipt = self.write_json(
                directory,
                "mutation.json",
                {
                    "status": "PASS",
                    "base_sha": sha,
                    "target_sha": sha,
                    "tool": "mutmut",
                    "tool_version": "3.2.1",
                    "killed": 8,
                    "total": 10,
                    "equivalent": 0,
                    "score": 80.0,
                },
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(Path(__file__).with_name("sdd_verify.py")),
                    "validate-mutation",
                    str(receipt),
                    sha,
                    sha,
                ],
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_cli_rejects_a_mutation_threshold_below_eighty(self):
        with tempfile.TemporaryDirectory() as directory:
            sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
            receipt = self.write_json(
                directory,
                "mutation.json",
                {
                    "status": "PASS",
                    "base_sha": sha,
                    "target_sha": sha,
                    "tool": "mutmut",
                    "tool_version": "3.2.1",
                    "killed": 8,
                    "total": 10,
                    "equivalent": 0,
                    "score": 80.0,
                },
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(Path(__file__).with_name("sdd_verify.py")),
                    "validate-mutation",
                    str(receipt),
                    sha,
                    sha,
                    "70",
                ],
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("80", result.stderr)

    def test_review_receipt_requires_fork_provenance_and_all_acceptance_criteria(self):
        with tempfile.TemporaryDirectory() as directory:
            raw = Path(directory) / "review.raw.json"
            raw.write_text('{"status":"PASS"}\n', encoding="utf-8")
            attestation = Path(directory) / "review-attestation.json"
            attestation.write_text(
                json.dumps(self.signed_attestation(
                    {
                        "event": "review-dispatch",
                        "dispatch_id": "dispatch-1",
                        "fork_id": "fork-1",
                        "input_sha256": "c" * 64,
                        "raw_receipt_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                    }
                )),
                encoding="utf-8",
            )
            receipt = self.write_json(
                directory,
                "review.json",
                {
                    "status": "PASS",
                    "independent": True,
                    "dispatch_id": "dispatch-1",
                    "fork_id": "fork-1",
                    "raw_receipt_path": str(raw),
                    "raw_receipt_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                    "input_sha256": "c" * 64,
                    "host_attestation_path": str(attestation),
                    "host_attestation_sha256": hashlib.sha256(attestation.read_bytes()).hexdigest(),
                    "findings": [],
                    "ac_coverage": [
                        {"id": "AC-001", "status": "PASS", "evidence": "test"}
                    ],
                },
            )
            validate_review_receipt(receipt, ["AC-001"], "c" * 64)

    def test_review_receipt_rejects_important_finding(self):
        with tempfile.TemporaryDirectory() as directory:
            raw = Path(directory) / "review.raw.json"
            raw.write_text('{"status":"PASS"}\n', encoding="utf-8")
            attestation = Path(directory) / "review-attestation.json"
            attestation.write_text(
                json.dumps(self.signed_attestation(
                    {
                        "event": "review-dispatch",
                        "dispatch_id": "dispatch-1",
                        "fork_id": "fork-1",
                        "input_sha256": "c" * 64,
                        "raw_receipt_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                    }
                )),
                encoding="utf-8",
            )
            receipt = self.write_json(
                directory,
                "review.json",
                {
                    "status": "PASS",
                    "independent": True,
                    "dispatch_id": "dispatch-1",
                    "fork_id": "fork-1",
                    "raw_receipt_path": str(raw),
                    "raw_receipt_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                    "input_sha256": "c" * 64,
                    "host_attestation_path": str(attestation),
                    "host_attestation_sha256": hashlib.sha256(attestation.read_bytes()).hexdigest(),
                    "findings": [{"severity": "IMPORTANT", "summary": "gap"}],
                    "ac_coverage": [
                        {"id": "AC-001", "status": "PASS", "evidence": "test"}
                    ],
                },
            )
            with self.assertRaises(VerificationError):
                validate_review_receipt(receipt, ["AC-001"], "c" * 64)

    def test_review_receipt_rejects_malformed_findings(self):
        with tempfile.TemporaryDirectory() as directory:
            raw = Path(directory) / "review.raw.json"
            raw.write_text('{"status":"PASS"}\n', encoding="utf-8")
            attestation = Path(directory) / "review-attestation.json"
            attestation.write_text(
                json.dumps(self.signed_attestation(
                    {
                        "event": "review-dispatch",
                        "dispatch_id": "dispatch-1",
                        "fork_id": "fork-1",
                        "input_sha256": "c" * 64,
                        "raw_receipt_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                    }
                )),
                encoding="utf-8",
            )
            receipt = self.write_json(
                directory,
                "review.json",
                {
                    "status": "PASS",
                    "independent": True,
                    "dispatch_id": "dispatch-1",
                    "fork_id": "fork-1",
                    "raw_receipt_path": str(raw),
                    "raw_receipt_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                    "input_sha256": "c" * 64,
                    "host_attestation_path": str(attestation),
                    "host_attestation_sha256": hashlib.sha256(attestation.read_bytes()).hexdigest(),
                    "findings": ["none"],
                    "ac_coverage": [
                        {"id": "AC-001", "status": "PASS", "evidence": "test"}
                    ],
                },
            )
            with self.assertRaises(VerificationError):
                validate_review_receipt(receipt, ["AC-001"], "c" * 64)

    def test_cli_without_command_returns_usage_error(self):
        result = subprocess.run(
            [sys.executable, str(Path(__file__).with_name("sdd_verify.py"))],
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("usage:", result.stderr)

    def test_approval_receipt_binds_report_and_verification_commit(self):
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory) / "verification-report.md"
            report.write_text("report", encoding="utf-8")
            attestation = Path(directory) / "approval-event.json"
            attestation.write_text(
                json.dumps(self.signed_attestation(
                    {
                        "event": "human-checkpoint",
                        "id": "event-1",
                        "command": "approve-verification changes/CHG-2026-042",
                        "approver": "engineer@example.com",
                        "verification_commit": "d" * 40,
                        "report_sha256": hashlib.sha256(report.read_bytes()).hexdigest(),
                    }
                )),
                encoding="utf-8",
            )
            approval = self.write_json(
                directory,
                "approval.json",
                {
                    "command": "approve-verification changes/CHG-2026-042",
                    "approver": "engineer@example.com",
                    "approved_at": "2026-09-20T10:00:00Z",
                    "verification_commit": "d" * 40,
                    "report_sha256": hashlib.sha256(report.read_bytes()).hexdigest(),
                    "host_attestation_path": str(attestation),
                    "host_attestation_sha256": hashlib.sha256(attestation.read_bytes()).hexdigest(),
                },
            )
            validate_approval(
                approval,
                "CHG-2026-042",
                "d" * 40,
                hashlib.sha256(report.read_bytes()).hexdigest(),
            )
            event = json.loads(attestation.read_text(encoding="utf-8"))
            del event["signature"]
            attestation.write_text(json.dumps(event), encoding="utf-8")
            approval_data = json.loads(approval.read_text(encoding="utf-8"))
            approval_data["host_attestation_sha256"] = hashlib.sha256(attestation.read_bytes()).hexdigest()
            approval.write_text(json.dumps(approval_data), encoding="utf-8")
            with self.assertRaises(VerificationError):
                validate_approval(
                    approval,
                    "CHG-2026-042",
                    "d" * 40,
                    hashlib.sha256(report.read_bytes()).hexdigest(),
                )
            approval_data = json.loads(approval.read_text(encoding="utf-8"))
            del approval_data["host_attestation_path"]
            approval.write_text(json.dumps(approval_data), encoding="utf-8")
            with self.assertRaises(VerificationError):
                validate_approval(
                    approval,
                    "CHG-2026-042",
                    "d" * 40,
                    hashlib.sha256(report.read_bytes()).hexdigest(),
                )
            approval_data = json.loads(approval.read_text(encoding="utf-8"))
            approval_data["host_attestation_path"] = str(attestation)
            approval_data["host_attestation_sha256"] = hashlib.sha256(attestation.read_bytes()).hexdigest()
            approval_data["approver"] = "other@example.com"
            approval.write_text(json.dumps(approval_data), encoding="utf-8")
            with self.assertRaises(VerificationError):
                validate_approval(
                    approval,
                    "CHG-2026-042",
                    "d" * 40,
                    hashlib.sha256(report.read_bytes()).hexdigest(),
                )

    def test_scope_rejects_paths_outside_plan_but_allows_only_the_report_exception(self):
        with self.assertRaises(VerificationError):
            validate_scope(
                ["src/service.py", "docs/unplanned.md"],
                ["src/**"],
                [],
                "changes/CHG-2026-042/verification-report.md",
            )
        validate_scope(
            [
                "src/service.py",
                "changes/CHG-2026-042/verification-report.md",
            ],
            ["src/**"],
            [],
            "changes/CHG-2026-042/verification-report.md",
        )

    def test_git_scope_comes_from_the_worktree_and_approved_task_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            tasks = root / "changes/CHG-2026-042/tasks.md"
            tasks.parent.mkdir(parents=True, exist_ok=True)
            tasks.write_text(
                "- **Allowed Paths:** `src/**`\n- **Forbidden Paths:** `docs/**`\n",
                encoding="utf-8",
            )
            worktree = root / ".worktrees/CHG-2026-042"
            (worktree / "src/service.py").parent.mkdir(parents=True, exist_ok=True)
            (worktree / "src/service.py").write_text("pass\n", encoding="utf-8")
            subprocess.run(["git", "add", "src/service.py"], cwd=worktree, check=True)
            subprocess.run(["git", "commit", "-qm", "change"], cwd=worktree, check=True)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD~1"], cwd=worktree, text=True
            ).strip()
            target_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=worktree, text=True
            ).strip()
            with self.assertRaises(VerificationError):
                validate_git_scope(root, "CHG-2026-042", base_sha, base_sha)
            validate_git_scope(root, "CHG-2026-042", base_sha, target_sha)
            (worktree / "docs/unplanned.md").parent.mkdir(parents=True, exist_ok=True)
            (worktree / "docs/unplanned.md").write_text("nope\n", encoding="utf-8")
            with self.assertRaises(VerificationError):
                validate_git_scope(root, "CHG-2026-042", base_sha, target_sha)

    def test_harness_runs_all_required_layers_and_writes_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            evidence = root / ".git/sdd-verify-evidence/CHG-2026-042"
            command = self.harness_command(
                root,
                base_sha,
                ["python3 -c 'print(1)'", "python3 -c 'print(2)'", "python3 -c 'print(3)'", "python3 -c 'print(4)'"],
                evidence,
            )
            result = subprocess.run(command, cwd=root, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            report = json.loads((evidence / "harness.json").read_text(encoding="utf-8"))
            self.assertEqual(report["status"], "PASS")
            self.assertRegex(report["verifier_sha256"], r"^[0-9a-f]{64}$")
            self.assertRegex(report["helper_sha256"], r"^[0-9a-f]{64}$")
            self.assertRegex(report["manifest_sha256"], r"^[0-9a-f]{64}$")
            self.assertEqual([stage["name"] for stage in report["stages"]], [
                "typecheck", "static", "architecture", "global"
            ])

    def test_harness_rejects_a_dirty_worktree(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            (root / ".worktrees/CHG-2026-042/untracked.txt").write_text("dirty\n")
            command = self.harness_command(
                root,
                base_sha,
                ["python3 -c 'print(1)'", "python3 -c 'print(2)'", "python3 -c 'print(3)'", "python3 -c 'print(4)'"],
                root / ".git/sdd-verify-evidence/CHG-2026-042",
            )
            result = subprocess.run(command, cwd=root, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("dirty", result.stderr.lower())

    def test_harness_rejects_stage_mutations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            command = self.harness_command(
                root,
                base_sha,
                ["touch generated.txt", "python3 -c 'print(2)'", "python3 -c 'print(3)'", "python3 -c 'print(4)'"],
                root / ".git/sdd-verify-evidence/CHG-2026-042",
            )
            result = subprocess.run(command, cwd=root, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("changed", result.stderr.lower())

    def test_harness_detects_assume_unchanged_file_mutations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            worktree = root / ".worktrees/CHG-2026-042"
            subprocess.run(["git", "update-index", "--assume-unchanged", "README.md"], cwd=worktree, check=True)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            command = self.harness_command(
                root,
                base_sha,
                [
                    "python3 -c \"open('README.md','w').write('changed\\n')\"",
                    "python3 -c 'print(2)'",
                    "python3 -c 'print(3)'",
                    "python3 -c 'print(4)'",
                ],
                root / ".git/sdd-verify-evidence/CHG-2026-042",
            )
            result = subprocess.run(command, cwd=root, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("changed", result.stderr.lower())

    def test_harness_rejects_evidence_outside_git_evidence_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            command = self.harness_command(
                root,
                base_sha,
                ["python3 -c 'print(1)'", "python3 -c 'print(2)'", "python3 -c 'print(3)'", "python3 -c 'print(4)'"],
                root / "evidence",
            )
            result = subprocess.run(command, cwd=root, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("evidence", result.stderr.lower())

    def test_harness_rejects_a_symlinked_worktree(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            worktree = root / ".worktrees/CHG-2026-042"
            real_worktree = root / ".worktrees/real-worktree"
            worktree.rename(real_worktree)
            worktree.symlink_to(real_worktree, target_is_directory=True)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            command = self.harness_command(
                root,
                base_sha,
                ["python3 -c 'print(1)'", "python3 -c 'print(2)'", "python3 -c 'print(3)'", "python3 -c 'print(4)'"],
                root / ".git/sdd-verify-evidence/CHG-2026-042",
            )
            result = subprocess.run(command, cwd=root, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("worktree", result.stderr.lower())

    def test_harness_rejects_noop_stage_commands(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            command = self.harness_command(
                root,
                base_sha,
                ["true", "true", "true", "true"],
                root / ".git/sdd-verify-evidence/CHG-2026-042",
            )
            result = subprocess.run(command, cwd=root, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("no-op", result.stderr.lower())

    def test_harness_kills_timed_out_stage_process_group(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            child = root / ".worktrees/CHG-2026-042/timedout-child"
            commands = [
                "python3 -c \"import subprocess,time; subprocess.Popen(['bash','-c','sleep 0.3; touch timedout-child']); time.sleep(1)\"",
                "python3 -c 'print(2)'",
                "python3 -c 'print(3)'",
                "python3 -c 'print(4)'",
            ]
            command = self.harness_command(
                root,
                base_sha,
                commands,
                root / ".git/sdd-verify-evidence/CHG-2026-042",
            )
            with self.assertRaises(VerificationError):
                run_harness(root, "CHG-2026-042", base_sha, commands, command[-1], command[-2], timeout=0.05)
            time.sleep(0.4)
            self.assertFalse(child.exists())

    def test_harness_caps_stage_logs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.init_repo(root)
            base_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=root, text=True
            ).strip()
            commands = [
                "python3 -c \"print('x' * 11000000)\"",
                "python3 -c 'print(2)'",
                "python3 -c 'print(3)'",
                "python3 -c 'print(4)'",
            ]
            command = self.harness_command(
                root,
                base_sha,
                commands,
                root / ".git/sdd-verify-evidence/CHG-2026-042",
            )
            with self.assertRaises(VerificationError):
                run_harness(root, "CHG-2026-042", base_sha, commands, command[-1], command[-2])
            self.assertLessEqual(
                (root / ".git/sdd-verify-evidence/CHG-2026-042/typecheck.log").stat().st_size,
                MAX_LOG_BYTES,
            )

    def harness_command(self, root, base_sha, commands, evidence):
        manifest = root / "changes/CHG-2026-042/verification-commands.json"
        manifest.parent.mkdir(parents=True, exist_ok=True)
        stages = {}
        for name, command in zip(("typecheck", "static", "architecture", "global"), commands):
            stages[name] = {"command_sha256": hashlib.sha256(command.encode()).hexdigest()}
        manifest.write_text(
            json.dumps({"change_id": "CHG-2026-042", "base_sha": base_sha, "stages": stages}),
            encoding="utf-8",
        )
        return [
            "bash",
            str(Path(__file__).parent.parent.parent.parent / ".spec-framework/bin/run_harness.sh"),
            "CHG-2026-042",
            base_sha,
            *commands,
            str(manifest.relative_to(root) if manifest.is_absolute() else manifest),
            str(evidence.relative_to(root) if evidence.is_absolute() else evidence),
        ]

    def init_repo(self, root):
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        for key, value in (("user.email", "test@example.com"), ("user.name", "Test")):
            subprocess.run(["git", "config", key, value], cwd=root, check=True)
        (root / "README.md").write_text("test\n", encoding="utf-8")
        subprocess.run(["git", "add", "README.md"], cwd=root, check=True)
        subprocess.run(["git", "commit", "-qm", "init"], cwd=root, check=True)
        subprocess.run(["git", "branch", "-M", "main"], cwd=root, check=True)
        helper = root / "skills/sdd-verify/scripts"
        helper.mkdir(parents=True)
        shutil.copy(Path(__file__).with_name("sdd_verify.py"), helper / "sdd_verify.py")
        harness = root / ".spec-framework/bin"
        harness.mkdir(parents=True)
        shutil.copy(
            Path(__file__).parents[3] / ".spec-framework/bin/run_harness.sh",
            harness / "run_harness.sh",
        )
        (harness / "run_harness.sh").chmod(0o755)
        subprocess.run(
            ["git", "worktree", "add", "-q", ".worktrees/CHG-2026-042", "-b", "feature/CHG-2026-042"],
            cwd=root,
            check=True,
            env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"},
        )


if __name__ == "__main__":
    unittest.main()
