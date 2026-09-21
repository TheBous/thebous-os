#!/usr/bin/env python3
import unittest
from pathlib import Path


SKILL = Path(__file__).parent.parent / "SKILL.md"


class SkillContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SKILL.read_text(encoding="utf-8") if SKILL.is_file() else ""

    def test_declares_execution_skill_metadata(self):
        self.assertIn("name: cook-execute", self.source)
        self.assertIn("Use when", self.source)

    def test_requires_tdd_and_workspace_gates(self):
        required = (
            "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST",
            "fresh context",
            "Allowed Paths",
            "Forbidden Paths",
            "enforce_tdd.sh init",
            "verify-red",
            "verify-green",
            "verify-global",
            "verify-paths",
            "select-task",
            "verify-quality",
            "complete",
            "unlock",
            "approval.md",
            "approve-plan",
            "assertion marker",
            "TDD_RED_EVIDENCE",
            "TDD_REVIEW_RECEIPT",
            "valid JSON",
            "independent review command",
            "mutation",
            "checkbox",
            "AssertionError",
            "independent",
            "atomic",
        )
        for phrase in required:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.source)

    def test_documents_safe_failure_handling(self):
        self.assertIn("never run eval", self.source)
        self.assertIn("never delete or reset", self.source)


if __name__ == "__main__":
    unittest.main()
