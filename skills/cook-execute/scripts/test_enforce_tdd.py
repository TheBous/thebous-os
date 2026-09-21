#!/usr/bin/env python3
import subprocess
import unittest

from test_enforce_tdd_support import SOURCE_SCRIPT, TASK_ID, EnforceTddFixture


class EnforceTddTests(EnforceTddFixture):

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
            self.red_command(),
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
            self.red_command(),
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
