#!/usr/bin/env python3
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).parents[3]
SOURCE_SCRIPT = ROOT / ".spec-framework" / "bin" / "enforce_tdd.sh"
CHANGE_ID = "CHG-2026-089"
TASK_ID = "T-001"
DEFAULT_TASKS = """# Implementation Tasks: test
**Change ID:** CHG-2026-089

- [ ] **Task 1: Implement the change**
  - **ID:** T-001 | **DAG Phase:** 1 (Core Logic) | **Deps:** []
  - **AC Coverage:** AC-001
  - **Allowed Paths:** `src.py`, `tests/test_example.py`
  - **Forbidden Paths:** `config.py`
  - **TDD Protocol:** Red, Green, Refactor.
  - **Definition of Done:** tests pass.
"""


class EnforceTddTests(unittest.TestCase):
    def run_gate(self, worktree, action, *args):
        if not SOURCE_SCRIPT.is_file():
            self.fail(f"missing enforcement script: {SOURCE_SCRIPT}")
        return subprocess.run(
            [str(SOURCE_SCRIPT), action, CHANGE_ID, TASK_ID, *args],
            cwd=worktree.parent.parent,
            capture_output=True,
            text=True,
            check=False,
        )

    def make_worktree(self, tasks=DEFAULT_TASKS, approved=True):
        if not SOURCE_SCRIPT.is_file():
            self.fail(f"missing enforcement script: {SOURCE_SCRIPT}")
        directory = tempfile.TemporaryDirectory()
        repo = Path(directory.name)
        subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=repo, check=True)
        subprocess.run(["git", "config", "user.name", "Test"], cwd=repo, check=True)
        (repo / "README.md").write_text("baseline\n", encoding="utf-8")
        change_dir = repo / "changes" / CHANGE_ID
        change_dir.mkdir(parents=True)
        (change_dir / "tasks.md").write_text(tasks, encoding="utf-8")
        if approved:
            (change_dir / "approval.md").write_text(
                f"approve-plan changes/{CHANGE_ID}\n", encoding="utf-8"
            )
        destination = repo / ".spec-framework" / "bin" / "enforce_tdd.sh"
        destination.parent.mkdir(parents=True)
        shutil.copy2(SOURCE_SCRIPT, destination)
        destination.chmod(0o755)
        helper = destination.parent / "sdd_tdd.py"
        shutil.copy2(SOURCE_SCRIPT.parent / "sdd_tdd.py", helper)
        subprocess.run(["git", "add", "README.md", "changes", ".spec-framework"], cwd=repo, check=True)
        subprocess.run(["git", "commit", "-qm", "baseline"], cwd=repo, check=True)

        worktree = repo / ".worktrees" / CHANGE_ID
        subprocess.run(
            ["git", "worktree", "add", "-q", "-b", f"feature/{CHANGE_ID}", str(worktree)],
            cwd=repo,
            check=True,
        )
        return directory, repo, worktree

    @staticmethod
    def python_command(code):
        return f"{shlex.quote(sys.executable)} -c {shlex.quote(code)}"

    def test_init_accepts_clean_worktree(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "init")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_init_rejects_dirty_worktree_without_deleting_changes(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        marker = worktree / "agent-notes.txt"
        marker.write_text("keep this evidence\n", encoding="utf-8")

        result = self.run_gate(worktree, "init")

        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(marker.exists())
        self.assertIn("dirty", result.stderr.lower())

    def test_verify_red_accepts_assertion_failure(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(
            worktree,
            "verify-red",
            self.python_command("print('AC-001: expected failure'); raise AssertionError('wrong')"),
            "AC-001: expected failure",
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_verify_red_rejects_passing_test(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(
            worktree, "verify-red", self.python_command("pass"), "AC-001: expected failure"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("passed", result.stderr.lower())

    def test_verify_red_rejects_structural_failure(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(
            worktree,
            "verify-red",
            self.python_command("raise SyntaxError('broken test')"),
            "AC-001: expected failure",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("structural", result.stderr.lower())

    def test_verify_red_rejects_production_changes_without_deleting_them(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "init")
        self.assertEqual(result.returncode, 0, result.stderr)
        source = worktree / "src.py"
        source.write_text("changed\n", encoding="utf-8")
        result = self.run_gate(
            worktree,
            "verify-red",
            self.python_command("print('AC-001: expected failure'); raise AssertionError('expected')"),
            "AC-001: expected failure",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(source.exists())
        self.assertIn("production", result.stderr.lower())

    def test_verify_green_requires_success(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "verify-green", self.python_command("raise SystemExit(1)"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("green", result.stderr.lower())

    def test_verify_green_accepts_success(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "verify-green", self.python_command("pass"))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_verify_global_requires_success(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "verify-global", self.python_command("raise SystemExit(1)"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("regression", result.stderr.lower())

    def test_verify_paths_accepts_allowed_test_file(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        test_file = worktree / "tests" / "test_example.py"
        test_file.parent.mkdir()
        test_file.write_text("assert True\n", encoding="utf-8")
        result = self.run_gate(worktree, "verify-paths", "tests/test_example.py", "src.py")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_verify_paths_rejects_outside_allowed_paths_without_deleting(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        source = worktree / "src.py"
        source.write_text("changed\n", encoding="utf-8")
        result = self.run_gate(worktree, "verify-paths", "tests/test_example.py", "none")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(source.exists())
        self.assertIn("outside allowed paths", result.stderr.lower())

    def test_verify_paths_rejects_explicitly_forbidden_file(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        source = worktree / "src.py"
        source.write_text("changed\n", encoding="utf-8")
        result = self.run_gate(worktree, "verify-paths", "src.py", "src.py")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(source.exists())
        self.assertIn("forbidden", result.stderr.lower())

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
        self.assertIn("marker", result.stderr.lower())

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
            str(review),
        )
        self.assertEqual(result.returncode, 0, result.stderr)

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
            str(review),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("mutation", result.stderr.lower())

    def test_init_locks_primary_tree_until_unlock(self):
        directory, repo, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "init")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(stat.S_IMODE((repo / "README.md").stat().st_mode) & stat.S_IWUSR, 0)
        result = self.run_gate(worktree, "unlock", "")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual(stat.S_IMODE((repo / "README.md").stat().st_mode) & stat.S_IWUSR, 0)

    def test_complete_updates_task_and_commits_atomically(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = self.run_gate(worktree, "init")
        self.assertEqual(result.returncode, 0, result.stderr)
        test_file = worktree / "tests" / "test_example.py"
        test_file.parent.mkdir()
        test_file.write_text("assert True\n", encoding="utf-8")
        result = self.run_gate(
            worktree,
            "verify-red",
            self.python_command("print('AC-001: expected failure'); raise AssertionError('red')"),
            "AC-001: expected failure",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        source = worktree / "src.py"
        source.write_text("implemented\n", encoding="utf-8")
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
            str(review),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_gate(worktree, "complete", "src.py,tests/test_example.py", "config.py")
        self.assertEqual(result.returncode, 0, result.stderr)
        tasks = (worktree / "changes" / CHANGE_ID / "tasks.md").read_text(encoding="utf-8")
        self.assertIn("- [x] **Task 1", tasks)
        commit = subprocess.run(
            ["git", "log", "-1", "--format=%s"], cwd=worktree, capture_output=True, text=True, check=True
        )
        self.assertIn("T-001", commit.stdout)

    def test_rejects_path_traversal_identifiers(self):
        directory, _, worktree = self.make_worktree()
        self.addCleanup(directory.cleanup)
        result = subprocess.run(
            [str(SOURCE_SCRIPT), "init", "../escape", TASK_ID],
            cwd=worktree.parent.parent,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("invalid", result.stderr.lower())


if __name__ == "__main__":
    unittest.main()
