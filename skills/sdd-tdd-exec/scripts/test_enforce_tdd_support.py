#!/usr/bin/env python3
import shlex
import shutil
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


class EnforceTddFixture(unittest.TestCase):
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
        shutil.copy2(SOURCE_SCRIPT.parent / "sdd_tdd.py", destination.parent / "sdd_tdd.py")
        shutil.copy2(SOURCE_SCRIPT.parent / "sdd_tdd_lock.py", destination.parent / "sdd_tdd_lock.py")
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

    @classmethod
    def red_command(cls, marker="AC-001: expected failure"):
        code = (
            "import json, os; from pathlib import Path; "
            "Path(os.environ['TDD_RED_EVIDENCE']).write_text(json.dumps({"
            f"'status': 'FAIL', 'kind': 'assertion', 'task': '{TASK_ID}', 'marker': {marker!r}"
            "})); raise AssertionError('expected')"
        )
        return cls.python_command(code)

    @classmethod
    def review_command(cls):
        code = (
            "import json, os; from pathlib import Path; "
            "Path(os.environ['TDD_REVIEW_RECEIPT']).write_text(json.dumps({"
            f"'status': 'PASS', 'task': '{TASK_ID}', 'independent': True, 'findings': []"
            "}))"
        )
        return cls.python_command(code)
