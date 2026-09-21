#!/usr/bin/env python3
import unittest
from pathlib import Path


SKILL = Path(__file__).parent.parent / "SKILL.md"


class SkillContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SKILL.read_text(encoding="utf-8")

    def test_documents_usage_boundaries(self):
        self.assertIn("## When to Use", self.source)
        self.assertIn("## When NOT to Use", self.source)

    def test_documents_common_mistakes(self):
        self.assertIn("## Common Mistakes", self.source)

    def test_defines_explicit_approval_command(self):
        self.assertIn("approve-spec changes/{CHG_ID}/delta-spec.md", self.source)

    def test_defines_a_compact_fresh_context_handoff(self):
        required = (
            "fresh context",
            "context: fork",
            "handoff",
            "do not pass the full transcript",
            "validator result",
            "next phase",
        )
        for phrase in required:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.source)


if __name__ == "__main__":
    unittest.main()
