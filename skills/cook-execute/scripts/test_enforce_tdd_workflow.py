#!/usr/bin/env python3
import subprocess
import tempfile
import unittest
from pathlib import Path

from test_enforce_tdd_support import EnforceTddFixture


class EnforceTddWorkflowTests(EnforceTddFixture):
    def test_select_task_requires_approval(self):
        directory, _, worktree = self.make_worktree(approved=False)
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "select-task", "")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("approval", result.stderr.lower())

    def test_select_task_returns_first_ready_task(self):
        tasks = """# Implementation Tasks: test
- [x] **Task 0: Foundation**
  - **ID:** T-000 | **DAG Phase:** 0 | **Deps:** []
- [ ] **Task 1: Ready**
  - **ID:** T-001 | **DAG Phase:** 1 | **Deps:** [T-000]
- [ ] **Task 2: Blocked**
  - **ID:** T-002 | **DAG Phase:** 1 | **Deps:** [T-001]
"""
        directory, _, worktree = self.make_worktree(tasks=tasks)
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "select-task", "")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("T-001", result.stdout)

    def test_approve_plan_gate_accepts_exact_marker(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "approve-plan", "")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("approved", result.stdout.lower())

    def test_verify_red_requires_exact_assertion_marker(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(
            worktree,
            "verify-red",
            self.python_command("raise AssertionError('different')"),
            "AC-001: expected failure",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("evidence", result.stderr.lower())

    def test_verify_red_rejects_non_assertion_failure_with_printed_marker(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(
            worktree,
            "verify-red",
            self.python_command("print('AC-001: expected failure'); raise NameError('wrong')"),
            "AC-001: expected failure",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("evidence", result.stderr.lower())

    def test_verify_quality_requires_static_mutation_and_review(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        review = Path(directory.name) / "review.md"
        review.write_text("PASS\n", encoding="utf-8")
        result = self.run_gate(
            worktree,
            "verify-quality",
            self.python_command("pass"),
            self.python_command("pass"),
            self.review_command(),
            str(review),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        git_dir = subprocess.check_output(
            ["git", "-C", str(worktree), "rev-parse", "--git-dir"], text=True
        ).strip()
        evidence = Path(git_dir) / "cook-tdd-evidence" / "CHG-2026-089"
        for name in ("T-001.static.log", "T-001.mutation.log", "T-001.review.log", "T-001.json"):
            self.assertTrue((evidence / name).is_file(), name)

    def test_verify_quality_rejects_stale_review_receipt(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        review = Path(directory.name) / "review.json"
        review.write_text('{"status":"PASS","task":"T-001","independent":true}\n', encoding="utf-8")
        result = self.run_gate(
            worktree,
            "verify-quality",
            self.python_command("pass"),
            self.python_command("pass"),
            self.python_command("pass"),
            str(review),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("receipt", result.stderr.lower())

    def test_verify_quality_rejects_receipt_inside_worktree(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        review = worktree / "review.json"
        result = self.run_gate(
            worktree,
            "verify-quality",
            self.python_command("pass"),
            self.python_command("pass"),
            self.review_command(),
            str(review),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("outside", result.stderr.lower())

    def test_verify_quality_rejects_missing_mutation_command(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        review = Path(directory.name) / "review.md"
        review.write_text("PASS\n", encoding="utf-8")
        result = self.run_gate(
            worktree,
            "verify-quality",
            self.python_command("pass"),
            "",
            self.review_command(),
            str(review),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("mutation", result.stderr.lower())

    def test_init_locks_primary_tree_until_unlock(self):
        directory, repo, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "init")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((repo / "README.md").stat().st_mode & 0o200, 0)
        result = self.run_gate(worktree, "unlock", "")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual((repo / "README.md").stat().st_mode & 0o200, 0)

    def test_complete_updates_task_and_commits_atomically(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "init")
        self.assertEqual(result.returncode, 0, result.stderr)
        test_file = worktree / "tests" / "test_example.py"
        test_file.parent.mkdir()
        test_file.write_text("assert True\n", encoding="utf-8")
        result = self.run_gate(worktree, "verify-red", self.red_command(), "AC-001: expected failure")
        self.assertEqual(result.returncode, 0, result.stderr)
        (worktree / "src.py").write_text("implemented\n", encoding="utf-8")
        result = self.run_gate(worktree, "verify-green", self.python_command("pass"))
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_gate(worktree, "verify-global", self.python_command("pass"))
        self.assertEqual(result.returncode, 0, result.stderr)
        review_dir = tempfile.TemporaryDirectory()
        self.addCleanup(review_dir.cleanup)
        review = Path(review_dir.name) / "review.md"
        review.write_text("PASS\n", encoding="utf-8")
        result = self.run_gate(
            worktree,
            "verify-quality",
            self.python_command("pass"),
            self.python_command("pass"),
            self.review_command(),
            str(review),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_gate(worktree, "complete", "src.py,tests/test_example.py", "config.py")
        self.assertEqual(result.returncode, 0, result.stderr)
        tasks = (worktree / "changes" / "CHG-2026-089" / "tasks.md").read_text(encoding="utf-8")
        self.assertIn("- [x] **Task 1", tasks)
        commit = subprocess.run(
            ["git", "log", "-1", "--format=%s"], cwd=worktree, capture_output=True, text=True, check=True
        )
        self.assertIn("T-001", commit.stdout)


if __name__ == "__main__":
    unittest.main()
