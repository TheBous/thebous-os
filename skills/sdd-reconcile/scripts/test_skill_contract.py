#!/usr/bin/env python3
import unittest
from pathlib import Path


SKILL = Path(__file__).parent.parent / "SKILL.md"


class SkillContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SKILL.read_text(encoding="utf-8")

    def test_has_portable_metadata(self):
        self.assertIn("name: sdd-reconcile", self.source)
        self.assertRegex(self.source, r"description: Use when")

    def test_requires_reconciliation_gates(self):
        required = (
            "verification-report.md",
            "verification-approval.json",
            "CRITICAL",
            "IMPORTANT",
            "3-way",
            "fingerprint",
            "[ADDED]",
            "[MODIFIED]",
            "[REMOVED]",
            "persist-adr",
            "changes/archives",
            "archive",
            "teardown",
            "approve-verification",
            "fail-closed",
            "git branch -d",
            "context: fork",
            "archive requires proposal.md, design.md, and tasks.md",
            "persisted under specs/adr",
        )
        for phrase in required:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.source)

    def test_rejects_unsafe_prototype_shortcuts(self):
        engine = SKILL.parent.parent.parent / ".spec-framework/bin/reconcile_engine.sh"
        if engine.exists():
            source = engine.read_text(encoding="utf-8")
            self.assertNotIn("git branch -D", source)
            self.assertNotIn("worktree remove --force", source)


if __name__ == "__main__":
    unittest.main()
