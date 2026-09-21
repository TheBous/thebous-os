#!/usr/bin/env python3
import unittest
from pathlib import Path


SKILL = Path(__file__).parent.parent / "SKILL.md"


class SkillContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SKILL.read_text(encoding="utf-8")

    def test_has_planning_skill_metadata(self):
        self.assertIn("name: cook-plan", self.source)
        self.assertIn("Use when", self.source)

    def test_requires_all_planning_gates(self):
        required = (
            ".spec-framework/constitution.md",
            "File Modification Matrix",
            "Technology Guidance & Reuse Analysis",
            "worktree_manager.sh create",
            "Architecture Decision Records",
            "Context7",
            "architecture-first-development",
            "reuse existing",
            "DAG",
            "Allowed Paths",
            "Forbidden Paths",
            "validate_plan.py",
            ".spec-framework/bin/validate_plan.py",
            "100% branch coverage",
            "pre-commit",
            "context: fork",
            "fresh context",
            "handoff",
            "do not pass the full transcript",
            "single task",
            "next phase",
            "independent",
            "approve-plan",
        )
        for phrase in required:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.source)

    def test_defines_both_plan_artifacts(self):
        self.assertIn("changes/{CHG_ID}/design.md", self.source)
        self.assertIn("changes/{CHG_ID}/tasks.md", self.source)


if __name__ == "__main__":
    unittest.main()
