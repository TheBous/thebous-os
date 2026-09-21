#!/usr/bin/env python3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).parent
VALIDATOR = ROOT / "validate_plan.py"
PROJECT_VALIDATOR = ROOT.parents[2] / ".spec-framework" / "bin" / "validate_plan.py"

DELTA = """# Spec Delta: Two-Factor Authentication
**Change ID:** CHG-2026-089
**Status:** Approved
**Target Domain:** specs/auth/two-factor.md

## 2. Acceptance Criteria (EARS Notation)
- `AC-001 [ADDED] [Ubiquitous]: The system shall hash TOTP secrets at rest.`
- `AC-002 [ADDED] [Event-driven]: WHEN a valid code is submitted, the system shall create a session.`
- `AC-003 [ADDED] [Unwanted Event]: IF verification fails, THEN the system shall reject the request.`
"""

DESIGN = """# Technical Design: Two-Factor Authentication
**Change ID:** CHG-2026-089
**Status:** Approved
**Related Specs:** specs/auth/two-factor.md

## 1. Architectural Impact & Topology
- Add the TOTP service and guard.

## 2. Invariants & Domain Contracts
- Secrets are never persisted in plaintext.

## 3. Architecture Decision Records (ADR)
- **ADR-01:** Use the native crypto API.

## 4. File Modification Matrix
| File Path | Operation | Component Responsibility |
|---|---|---|
| `src/auth/totp.types.ts` | Create | DTO contracts |
| `src/auth/totp.service.ts` | Create | TOTP domain logic |
| `tests/unit/auth/totp.service.test.ts` | Create | Unit tests |

## 5. Technology Guidance & Reuse Analysis
- Context7 sources: Python standard library validation patterns.
- Required architecture guidance: architecture-first-development.
- Repository reuse search: existing validator tests and canonical scripts.
- Reuse decision: extend the canonical validator; do not duplicate helpers.
"""

TASKS = """# Implementation Tasks: Two-Factor Authentication
**Change ID:** CHG-2026-089
**Execution Topology:** Directed Acyclic Graph (DAG)
**Assigned Worktree:** .worktrees/CHG-2026-089

- [ ] **Task 1: Define typed contracts**
  - **ID:** T-001 | **DAG Phase:** 0 (Foundational) | **Deps:** []
  - **AC Coverage:** AC-001
  - **Allowed Paths:** `src/auth/totp.types.ts`
  - **Forbidden Paths:** `src/auth/totp.service.ts`
  - **TDD Protocol:** Not applicable for pure types; run the type checker.
  - **Definition of Done:** `npm run typecheck` passes.

- [ ] **Task 2: Implement the TOTP service**
  - **ID:** T-002 | **DAG Phase:** 1 (Core Logic) | **Deps:** [T-001]
  - **AC Coverage:** AC-001, AC-002, AC-003
  - **Allowed Paths:** `src/auth/totp.service.ts`, `tests/unit/auth/totp.service.test.ts`
  - **Forbidden Paths:** `src/auth/totp.types.ts`
  - **TDD Protocol:** Red, Green, Refactor with real assertions.
  - **Definition of Done:** Unit tests pass with failure paths covered.
"""


class ValidatePlanTests(unittest.TestCase):
    def run_validator(self, *, delta=DELTA, design=DESIGN, tasks=TASKS, validator=VALIDATOR):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "CHG-2026-089"
            path.mkdir()
            (path / "delta-spec.md").write_text(delta, encoding="utf-8")
            (path / "design.md").write_text(design, encoding="utf-8")
            (path / "tasks.md").write_text(tasks, encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(validator), str(path)],
                capture_output=True,
                text=True,
                check=False,
            )

    def test_accepts_a_complete_plan(self):
        result = self.run_validator()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_orphaned_acceptance_criteria(self):
        result = self.run_validator(tasks=TASKS.replace("AC-002, AC-003", "AC-002"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("AC-003", result.stderr)

    def test_rejects_allowed_and_forbidden_path_overlap(self):
        result = self.run_validator(
            tasks=TASKS.replace("src/auth/totp.types.ts`", "src/auth/totp.service.ts`")
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("both allowed and forbidden", result.stderr)

    def test_rejects_dependency_cycles(self):
        result = self.run_validator(
            tasks=TASKS.replace("Deps:** [T-001]", "Deps:** [T-002]")
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cycle", result.stderr)

    def test_rejects_placeholders(self):
        result = self.run_validator(
            design=DESIGN.replace("Add the TOTP service", "TODO: add the TOTP service")
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("placeholder", result.stderr)

    def test_rejects_missing_design_metadata(self):
        result = self.run_validator(
            design=DESIGN.replace("**Status:** Approved\n", "")
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Status", result.stderr)

    def test_rejects_missing_technology_guidance(self):
        result = self.run_validator(
            design=DESIGN.replace("\n## 5. Technology Guidance & Reuse Analysis\n", "")
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Technology Guidance", result.stderr)

    def test_rejects_missing_context7_evidence(self):
        result = self.run_validator(
            design=DESIGN.replace("Context7", "Documentation lookup")
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Context7", result.stderr)

    def test_rejects_missing_architecture_skill_evidence(self):
        result = self.run_validator(
            design=DESIGN.replace("architecture-first-development", "architecture review")
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("architecture-first-development", result.stderr)

    def test_rejects_missing_reuse_analysis(self):
        result = self.run_validator(
            design=DESIGN.replace("reuse search", "new implementation search").replace(
                "Reuse decision", "New implementation decision"
            )
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("reuse", result.stderr.lower())

    def test_rejects_unapproved_delta_spec(self):
        result = self.run_validator(delta=DELTA.replace("**Status:** Approved", "**Status:** In Review"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Approved", result.stderr)

    def test_rejects_dependency_on_a_later_dag_phase(self):
        tasks = TASKS.replace("DAG Phase:** 0", "DAG Phase:** 3", 1).replace(
            "DAG Phase:** 1", "DAG Phase:** 0", 1
        )
        result = self.run_validator(tasks=tasks)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("phase", result.stderr.lower())

    def test_rejects_task_without_acceptance_criteria(self):
        tasks = TASKS.replace("AC Coverage:** AC-001", "AC Coverage:** none", 1)
        result = self.run_validator(tasks=tasks)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("AC Coverage", result.stderr)

    def test_accepts_generic_type_syntax_in_design(self):
        design = DESIGN.replace(
            "- Secrets are never persisted in plaintext.",
            "- Secrets are never persisted in plaintext; the service returns Result<string>.",
        )
        result = self.run_validator(design=design)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_accepts_explicitly_empty_forbidden_paths(self):
        tasks = TASKS.replace(
            "**Forbidden Paths:** `src/auth/totp.service.ts`",
            "**Forbidden Paths:** None",
            1,
        )
        result = self.run_validator(tasks=tasks)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_project_validator_wrapper_uses_the_canonical_validator(self):
        result = self.run_validator(validator=PROJECT_VALIDATOR)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
