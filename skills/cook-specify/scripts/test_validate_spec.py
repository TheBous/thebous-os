#!/usr/bin/env python3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).parent
VALIDATOR = ROOT / "validate_spec.py"

VALID_SPEC = """# Spec Delta: Rate Limiting

**Change ID:** CHG-2026-042
**Status:** In Review
**Target Domain:** specs/gateway/public-api.md

## 1. Context & Business Intent
Protect the public API from abuse.

## 2. Acceptance Criteria (EARS Notation)
- `AC-001 [ADDED] [Ubiquitous]: The system shall count requests per API key.`
- `AC-002 [ADDED] [Event-driven]: WHEN a request exceeds the limit, the system shall return HTTP 429.`
- `AC-003 [MODIFIED] [State-driven]: WHILE Redis is unavailable, the system shall use the instance bucket.`
- `AC-004 [ADDED] [Unwanted Event]: IF the API key is invalid, THEN the system shall reject the request.`
- `AC-005 [ADDED] [Optional Feature]: WHERE headers are enabled, the system shall include remaining capacity.`

## 3. Interface Contracts & Invariants
```json
{"error_response":{"type":"object","required":["error"]}}
```
- Invariant: protected endpoints cannot bypass the limiter.

## 4. Examples
- Valid: `{"api_key":"key-1"}`
- Invalid: `{"api_key":""}`

## 5. Out of Scope
- Dynamic limits from a database.
"""


class ValidateSpecTests(unittest.TestCase):
    def run_validator(self, content):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "delta-spec.md"
            path.write_text(content, encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(VALIDATOR), str(path)],
                capture_output=True,
                text=True,
                check=False,
            )

    def test_accepts_a_complete_ears_delta_spec(self):
        result = self.run_validator(VALID_SPEC)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_missing_out_of_scope(self):
        result = self.run_validator(VALID_SPEC.replace("## 5. Out of Scope", "## 5. Notes"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Out of Scope", result.stderr)

    def test_rejects_invalid_contract_json(self):
        result = self.run_validator(VALID_SPEC.replace(
            '{"error_response":{"type":"object","required":["error"]}}',
            '{"error_response":}',
        ))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("JSON", result.stderr)

    def test_accepts_openapi_json_contract(self):
        content = VALID_SPEC.replace("```json", "```openapi")
        result = self.run_validator(content)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_specs_over_the_token_budget(self):
        result = self.run_validator(VALID_SPEC + "\n" + ("extra " * 1501))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("token budget", result.stderr)

    def test_rejects_missing_golden_template_metadata(self):
        for field in ("Change ID", "Status", "Target Domain"):
            with self.subTest(field=field):
                result = self.run_validator(
                    "\n".join(line for line in VALID_SPEC.splitlines() if not line.startswith(f"**{field}:**"))
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(field, result.stderr)

    def test_rejects_acceptance_criteria_outside_acceptance_section(self):
        criteria = "\n".join(line for line in VALID_SPEC.splitlines() if "AC-" in line)
        content = VALID_SPEC.replace(criteria, "")
        content = content.replace("Protect the public API from abuse.", f"Protect the public API from abuse.\n{criteria}")
        result = self.run_validator(content)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Acceptance Criteria", result.stderr)

    def test_rejects_ears_text_that_only_contains_a_system_shall_fragment(self):
        content = VALID_SPEC.replace(
            "The system shall count requests per API key.",
            "This text is vague; the system shall eventually do something.",
        )
        result = self.run_validator(content)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Ubiquitous", result.stderr)


if __name__ == "__main__":
    unittest.main()
