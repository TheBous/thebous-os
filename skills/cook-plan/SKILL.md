---
name: cook-plan
description: Use when an approved delta specification is ready for technical design, architecture decisions, and implementation task decomposition
allowed-tools: "Read,Write,Glob,Grep,Bash(git:*),Bash(python3:*),Bash(bash:*)"
version: 1.0.0
license: MIT
compatibility: "Universal Agent Skills (Claude Code, OpenAI Codex, OpenCode)"
metadata:
  workflow: spec-driven-development
  phase: technical-planning
---

# SDD Technical Planning and Task Decomposition Engine

## Overview

Compile one approved delta specification into two executable planning artifacts:
`design.md` and `tasks.md`. The plan maps requirements to real repository paths,
records irreversible decisions, isolates execution in a Git worktree, and breaks
implementation into a validated DAG of small tasks. This phase creates no
production or test implementation.

## When to Use

Use when `changes/{CHG_ID}/delta-spec.md` has been approved and the next step is
technical design or implementation planning. Use it for changes spanning
multiple modules, contracts, migrations, infrastructure boundaries, or parallel
work. Trigger with `/cook:plan` when the host exposes that command.

## When NOT to Use

Do not use it before specification approval, for formatting-only edits, or when
the existing approved plan already covers the requested work. Do not replace
this phase with an inline checklist because the change is urgent, familiar, or
small; use the existing plan only when it still matches the approved spec.

## Context Boundary

Run this phase in a fresh context, preferably a sub-agent with `context: fork`.
The parent/orchestrator passes only the approved `delta-spec.md`, the compact
`proposal.md` handoff, constitution and stable-spec paths, `CHG_ID`, repository
root, and the task-specific repository context needed for inspection. Do not
pass the full transcript or raw specification-phase tool results. Retrieve
repository and Context7 evidence just-in-time and retain only facts needed for
the current design decision.

The parent reads the compact plan handoff, validator result, and audit result;
it loads full `design.md` or `tasks.md` only when presenting or approving the
checkpoint. If the host cannot create a sub-agent, simulate the same boundary
by starting from the listed artifacts and files only. The handoff rule is
literal: do not pass the full transcript.

## Non-Negotiable Gates

- Missing constitution, approved delta, repository context, or worktree manager is a blocker. Do not invent a substitute.
- Do not write production code, test code, migrations, or implementation files.
- Every acceptance criterion must map to one or more task IDs; every task must map back to real acceptance criteria.
- Every task declares `Allowed Paths` and `Forbidden Paths`; allowed logic paths are limited to two per task.
- Every architectural fork becomes an ADR or a blocking `Decision Moment` for the engineer.
- Every task declares its DAG phase, dependencies, TDD protocol, and objective Definition of Done.
- Do not pass placeholders, vague instructions, orphan tasks, cyclic dependencies, or unverified generic paths to execution.
- The deterministic validator and independent plan audit must pass before the human checkpoint.
- Do not release tasks to TDD execution until the engineer sends the exact approval command:

```text
approve-plan changes/{CHG_ID}
```

## Procedure

### 1. Preconditions and Context Ingestion

Locate and read:

- `changes/{CHG_ID}/delta-spec.md`, with `Status: Approved`;
- `.spec-framework/constitution.md`;
- stable specifications under `specs/`;
- the repository README, structure, affected flow, contracts, persistence, and tests.

Run the existing specification validator before planning:

```bash
python3 skills/cook-specify/scripts/validate_spec.py \
  changes/{CHG_ID}/delta-spec.md
```

If any precondition or validation fails, stop and route the work back to
`cook-specify`. Classify discovered information as `Fact`, `Decision`,
`Assumption`, or `Unknown`. Do not create `design.md` or `tasks.md` until the
bounded context and approved requirements are known.

### 2. Topology and File Modification Matrix

Inspect the repository with `Glob`, `Grep`, and `Read`. Trace the real entry
point, domain logic, ports/adapters, persistence, routing, configuration, and
tests. Identify exactly what is created, modified, migrated, or deliberately
untouched.

Create `changes/{CHG_ID}/design.md` with this structure:

```markdown
# Technical Design: <change>
**Change ID:** CHG-YYYY-NNN
**Status:** Approved
**Related Specs:** specs/<stable-file>.md

## 1. Architectural Impact & Topology
<components, boundaries, data flow, and affected runtime path>

## 2. Invariants & Domain Contracts
<type signatures, DTOs, validation, error outcomes, and invariants>

## 3. Architecture Decision Records (ADR)
- **ADR-01:** <decision> — <rejected alternative and rationale>

## 4. File Modification Matrix
| File Path | Operation | Component Responsibility |
|---|---|---|
| `src/example.ts` | Create | <specific responsibility> |

## 5. Technology Guidance & Reuse Analysis
- **Technologies and versions:** <runtime, framework, libraries, persistence>
- **Context7 sources:** <library/topic/version queries and relevant guidance>
- **Architecture guidance:** `architecture-first-development` findings
- **Existing code search:** <helpers, ports, adapters, types, tests, and paths inspected>
- **Reuse decision:** <reuse/adapt/create, with evidence and rationale>
```

The matrix is exhaustive for implementation paths. Do not include code bodies;
define boundaries, contracts, migration impact, and ownership instead.

During this same repository analysis, complete the technology and reuse section
before finalizing the matrix:

- Identify the actual technologies and versions in the repository; do not infer
  them from the requested feature alone.
- Use Context7 to inspect current documentation and best practices for each
  technology that materially affects the design. Record the library, version,
  topic, and relevant guidance. If Context7 is unavailable, record the missing
  evidence as a blocker or `Unknown`; never claim that best practices were
  verified.
- **REQUIRED SUB-SKILL:** Use `architecture-first-development` to trace the
  entrypoint, boundaries, domain rules, ports/adapters, I/O, invariants, error
  paths, complexity, and test implications.
- Search the repository before proposing new code. Check existing helpers,
  services, ports, adapters, DTOs, value objects, constants, validators, and
  tests with `Glob`, `Grep`, and `Read`.
- Prefer to reuse existing implementations when their model, ownership, and change
  cadence match. Adapt it only when the boundary remains coherent. Create new
  code only after recording what was searched and why no existing asset fits.
- Never copy an existing helper into a new file to avoid understanding or
  adapting it. A duplicated concept is a planning defect and must be resolved
  before the plan reaches audit.

### 3. Workspace Isolation

Before task execution, create the isolated workspace with the deterministic
manager:

```bash
bash .spec-framework/bin/worktree_manager.sh create {CHG_ID}
```

Verify that the worktree is mounted on `feature/{CHG_ID}` and run the baseline
test suite there. The primary working tree is not an execution workspace. If the
manager is unavailable or the branch/worktree cannot be verified, stop and
report the blocker.

### 4. ADRs and Decision Moments

Record every choice that affects architecture, contracts, persistence, security,
dependencies, concurrency, caching, or deployment as an ADR in `design.md`.
Each ADR states the decision, rejected alternative, rationale, and consequence.

If the choice depends on product intent or unresolved technical evidence, stop
and ask the engineer. Record it as a blocking `Decision Moment`; never silently
select a library, lock strategy, cache, migration behavior, or failure policy.

### 5. DAG Task Decomposition

Create `changes/{CHG_ID}/tasks.md` with this header:

```markdown
# Implementation Tasks: <change>
**Change ID:** CHG-YYYY-NNN
**Execution Topology:** Directed Acyclic Graph (DAG)
**Assigned Worktree:** .worktrees/CHG-YYYY-NNN
```

Each task is a 2-5 minute computational micro-step where practical and must
contain all fields below:

```markdown
- [ ] **Task 1: <atomic outcome>**
  - **ID:** T-001 | **DAG Phase:** 0 (Foundational) | **Deps:** []
  - **AC Coverage:** AC-001, AC-002
  - **Allowed Paths:** `src/contracts/example.ts`, `tests/example.test.ts`
  - **Forbidden Paths:** `src/app.ts`, `src/infrastructure/**`
  - **TDD Protocol:** Red, Green, Refactor, or an explicit type-only/static reason.
  - **Definition of Done:** <observable command and expected evidence>.
```

Use only these DAG phases:

| Phase | Purpose | Typical deliverables |
|---|---|---|
| 0 | Foundational | Types, DTOs, contracts, migrations |
| 1 | Core Logic | Pure domain services and algorithms; require 100% branch coverage |
| 2 | Integration | Middleware, adapters, repositories, UI; mock infrastructure boundaries |
| 3 | Convergence | Router wiring, bootstrap, end-to-end tests; run the full suite |

Dependencies must point to earlier or independent tasks and form an acyclic
graph. A task may touch at most two logic paths in `Allowed Paths`. Its
`Forbidden Paths` prevent scope drift. Do not use `TODO`, `TBD`, generic
"implement this", guessed paths, or tasks without test/type evidence.

Record the exact path boundaries in every task. The execution phase must enforce
them with a deterministic pre-commit hook or execution wrapper that rejects any
diff outside `Allowed Paths` and changes to `Forbidden Paths`; this planning
skill validates the declarations but does not execute tasks.

### 6. Formal Validation and Independent Audit

Run the deterministic validator from the repository root:

```bash
python3 .spec-framework/bin/validate_plan.py changes/{CHG_ID}
```

The project entrypoint delegates to the canonical implementation at
`skills/cook-plan/scripts/validate_plan.py`. It validates the two planning
artifacts, metadata, required sections, technology guidance evidence, the file
matrix, AC-to-task traceability, allowed/forbidden paths, DAG dependencies and
cycles, TDD/Definition-of-Done fields, worktree metadata, and placeholders.
Zero errors is required.

Then start an independent plan reviewer with `context: fork`. Pass only:

- the approved `delta-spec.md`;
- `.spec-framework/constitution.md`;
- `design.md` and `tasks.md`;
- the validator result.

The reviewer checks requirement and error-path coverage, vague instructions,
placeholder text, terminology and type consistency, task boundaries, and missing
edge-case tests. The author must fix findings and rerun both validator and
independent audit until the reviewer reports no blocking gaps. The author must
not self-approve its own plan.

### 7. Context Handoff and Human Authorization Checkpoint

Before presenting the checkpoint, return a compact handoff rather than the
exploration transcript:

```markdown
## Agent Handoff
- **Phase:** cook-plan
- **Status:** ready-for-approval | blocked
- **Inputs:** delta-spec.md, proposal.md, constitution, repository commit
- **Artifacts:** design.md, tasks.md
- **Validator result:** <command, exit status, and concise output>
- **Audit result:** <reviewer status and blocking gaps>
- **DAG summary:** <task count, phases, and dependency roots>
- **Decisions:** <ADR IDs and unresolved Decision Moments>
- **Blockers:** <blocking items or `none`>
- **Next phase:** execution after `approve-plan changes/{CHG_ID}`
```

For the next phase, pass a single task card with its dependencies, allowed
paths, evidence, and Definition of Done. Do not pass the full transcript or the
entire plan when one task is sufficient.

Present a compact summary containing:

- the File Modification Matrix;
- the DAG and dependency order;
- task count and AC coverage;
- assigned worktree and baseline test result;
- validator output;
- independent audit result;
- unresolved risks and decisions.

Stop and wait for:

```text
approve-plan changes/{CHG_ID}
```

Record the exact approval in `changes/{CHG_ID}/approval.md`, including the
literal line `approve-plan changes/{CHG_ID}`. Only after this marker exists may
a separate execution skill release tasks to TDD implementation.

## Quick Reference

| Gate | Evidence | Blocker |
|---|---|---|
| Preconditions | Approved delta, constitution, stable specs | Route back to specification |
| Topology | Exhaustive file modification matrix | Inspect repository further |
| Technology and reuse | Context7, architecture-first-development, repository search and reuse decision | Record evidence or block |
| Isolation | `feature/{CHG_ID}` worktree and green baseline | Stop; do not use primary tree |
| Decisions | ADRs or explicit Decision Moments | Ask engineer; no invention |
| Tasks | DAG, IDs, deps, AC coverage, paths, TDD, DoD | Rewrite incomplete task |
| Validation | `validate_plan.py` exits 0 | Fix every error |
| Audit | Fresh-context independent reviewer passes | Correct and rerun |
| Authorization | `approve-plan changes/{CHG_ID}` | Do not start TDD |

## Common Mistakes

- Writing a generic plan before inspecting the repository -> replace guessed paths with verified matrix entries.
- Skipping Context7 because the framework is familiar -> record the missing evidence and stop rather than guessing.
- Adding a new helper before searching the repository -> locate and reuse the canonical implementation or document why it does not fit.
- Treating architecture guidance as optional -> run `architecture-first-development` before finalizing boundaries and tasks.
- Skipping worktree isolation because a branch already exists -> create and verify the dedicated worktree.
- Making a silent architecture choice -> record an ADR or block on a Decision Moment.
- Grouping an entire feature into one task -> split it by contract, core logic, integration, and convergence dependencies.
- Covering a requirement only in prose -> add its `AC-NNN` to a concrete task and test evidence.
- Allowing a task to touch whatever it needs -> declare exact Allowed and Forbidden Paths.
- Treating a passing validator as sufficient -> still run the independent fresh-context audit.
- Letting the author approve the plan -> require `approve-plan` only after independent review.

## Red Flags - Stop

- No approved `delta-spec.md` or missing constitution
- Worktree manager unavailable or baseline tests not run
- Generic file paths, orphan acceptance criteria, or cyclic dependencies
- `TODO`, `TBD`, placeholder text, or vague Definition of Done
- A task with more than two logic paths
- Design or tasks containing implementation code
- Self-review presented as independent audit
- Planning proceeds after "looks good" without `approve-plan changes/{CHG_ID}`

## Example

For a TOTP change, the design matrix names the pure DTOs, crypto service,
migration, guard, router, and tests. ADRs record native WebCrypto over a new
dependency and Redis over process-local rate limiting. Tasks then move through
phases 0-3, each with exact paths, AC coverage, dependencies, TDD evidence, and
an objective completion command. The validator and a clean-context reviewer run
before the engineer authorizes execution.
