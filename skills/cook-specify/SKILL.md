---
name: cook-specify
description: Use when a feature, bug fix, or behavior change needs a versioned specification before planning or implementation, especially when requirements are ambiguous, scope may grow, contracts matter, or AI-generated assumptions are risky
---

# Cook Specify

## Overview

This is the specification phase of spec-driven development. Convert a bounded
request into a short, testable, reviewable delta specification without writing
production or test code. **No planning or implementation starts until the
validator passes and the engineer explicitly approves the specification.**

## When to Use

Use this skill for a new feature, bug fix, API or event contract change,
security-sensitive behavior, or any change whose requirements are not already
captured by an approved specification.

## When NOT to Use

Do not use it for formatting-only edits, documentation-only edits, generated
files, or implementation work that already has an approved current specification.
Do not skip it merely because the behavior change is small or urgent.

## Context Boundary

Run this phase in a fresh context, preferably a sub-agent with `context: fork`.
The parent/orchestrator passes only the request, `CHG_ID`, repository root,
constitution path, and relevant stable-spec paths. Do not pass the full
transcript, raw prior tool results, or unrelated conversation history. Read
additional repository evidence just-in-time and keep only high-signal facts in
the working context.

At the end, use `proposal.md` as the durable handoff. The parent reads the
compact handoff and validator result, not the exploration transcript. Include
the phase status, artifact paths, decisions, assumptions, unknowns, blockers,
and `next phase`. The handoff rule is literal: do not pass the full transcript.
If the host cannot create a sub-agent, simulate the same
boundary by starting from the listed files only.

## Non-Negotiable Rules

- Do not invent product decisions, limits, identities, payloads, error codes, or security behavior.
- Ask targeted Socratic questions before drafting: 2-4 questions per round, only about blocking ambiguity.
- Record unresolved uncertainty as a `Decision Moment` or open question. It blocks drafting and implementation.
- Write requirements only in EARS notation and tag every criterion with `[ADDED]`, `[MODIFIED]`, or `[REMOVED]`.
- Include typed boundary contracts, valid and invalid examples, business invariants, and a non-empty `## 5. Out of Scope` section.
- Keep `delta-spec.md` within 1,500 whitespace tokens. Move large schemas to versioned files beside the change.
- Run the deterministic validator. A verbal review, manual inspection, or unavailable validator is not a pass.
- Stop at the human checkpoint. Proceed only after an explicit approval naming the reviewed artifact.

Violating the letter of these gates violates the purpose of SDD: preventing
silent assumptions from becoming implementation behavior.

## Workflow

### 1. Context Ingestion

Read the request, `.spec-framework/constitution.md`, and relevant stable files
under `specs/`. Inspect the existing flow when the change modifies a codebase.
Declare the bounded context and affected stable specifications. Do not create a
file, plan, test, or code in this step.

Classify findings as `Fact`, `Decision`, `Assumption`, or `Unknown`. Retrieve
facts from the repository first; ask the engineer only for decisions or facts
that cannot be discovered. A missing constitution or stable specification is an
explicit unknown, never permission to invent policy.

### 2. Socratic Clarification

Build a decision frontier covering goal, actors, permissions, states, inputs,
outputs, persistence, integrations, errors, retries, concurrency, security,
performance, rollout, and scope. Ask 2-4 precise questions per round, each with
a recommendation when useful. Continue until every blocking ambiguity is
resolved or explicitly accepted as a documented decision.

Do not respond to pressure with assumptions. If the engineer refuses questions,
write the unresolved items as blockers and stop.

### 3. Draft the Delta

After clarification, create only:

```text
changes/{CHG_ID}/proposal.md
changes/{CHG_ID}/delta-spec.md
```

`proposal.md` records intent, resolved decisions, assumptions, risks, and the
human approval status. `delta-spec.md` uses this exact structure:

```markdown
# Spec Delta: <change>
**Change ID:** CHG-YYYY-NNN
**Status:** In Review
**Target Domain:** specs/<stable-file>.md

## 1. Context & Business Intent
Why, goal, and measurable outcome.

## 2. Acceptance Criteria (EARS Notation)
- `AC-001 [ADDED] [Ubiquitous]: The system shall ...`
- `AC-002 [MODIFIED] [Event-driven]: WHEN ..., the system shall ...`
- `AC-003 [ADDED] [State-driven]: WHILE ..., the system shall ...`
- `AC-004 [ADDED] [Unwanted Event]: IF ..., THEN the system shall ...`
- `AC-005 [ADDED] [Optional Feature]: WHERE ..., the system shall ...`

## 3. Interface Contracts & Invariants
```json
{"request":{"type":"object"},"response":{"type":"object"}}
```
- Invariant: <business rule and associated error outcome>.

## 4. Examples
- Valid: `{...}`
- Invalid: `{...}` -> `<deterministic error>`

## 5. Out of Scope
- <excluded behavior, deferred optimization, or prohibited change>
```

Use only the EARS forms shown above. Replace vague adjectives with observable
outcomes, status codes, fields, limits, and error behavior. For existing
systems, describe only the delta; do not copy unchanged architecture.

### 4. Deterministic Validation

Run from the repository root:

```bash
python3 skills/cook-specify/scripts/validate_spec.py \
  changes/{CHG_ID}/delta-spec.md
```

The validator checks the required sections, unique `AC-NNN` criteria, valid
delta/EARS tags and clause shape, non-empty out-of-scope, invariant text,
valid/invalid examples, JSON or OpenAPI-JSON code blocks, and the 1,500
whitespace-token budget, plus `Change ID`, `Status`, and `Target Domain`
metadata. OpenAPI blocks must contain JSON; YAML is not parsed. Fix every
error and rerun it; do not bypass or substitute a prose claim that the
specification is complete.

### 5. Human Checkpoint

Before presenting the checkpoint, complete the handoff in `proposal.md`:

```markdown
## Agent Handoff
- **Phase:** cook-specify
- **Status:** ready-for-approval | blocked
- **Artifacts:** proposal.md, delta-spec.md
- **Validator result:** <command, exit status, and concise output>
- **Decisions:** <resolved decisions only>
- **Unknowns:** <remaining unknowns or `none`>
- **Blockers:** <blocking items or `none`>
- **Next phase:** cook-plan after explicit approval
```

Return only this compact handoff, the artifact paths, and the approval request.
Do not pass the full transcript to the next phase. Present the paths, validator
output, unresolved risks, and a short diff summary.
Wait for the exact approval command below:

```text
approve-spec changes/{CHG_ID}/delta-spec.md
```

Accept no substitute such as "looks good" or a verbal review. Verify that the
path matches the validated artifact, record the exact command and approver in
`proposal.md`, and then mark the proposal approved. Without this command, do
not invoke planning, TDD, or implementation workflows, even if the branch
already contains code or the request is urgent.

## Quick Reference

| Gate | Required evidence | Failure action |
|---|---|---|
| Context | Bounded context and classified facts | Retrieve or record an unknown |
| Clarification | 2-4 targeted questions per round | Keep unresolved items blocking |
| Requirements | EARS + delta tag on every `AC-NNN` | Rewrite the criterion |
| Contracts | JSON/OpenAPI JSON, examples, invariants | Add typed boundary behavior |
| Scope | Non-empty `Out of Scope` | Name exclusions explicitly |
| Size | At most 1,500 validator tokens | Move large schemas to files |
| Validation | `validate_spec.py` exits 0 | Fix errors; never waive |
| Approval | `approve-spec changes/{CHG_ID}/delta-spec.md` | Stop before planning/code |

## Common Mistakes

- Missing `Change ID`, `Status`, or `Target Domain` -> add the golden-template metadata before linting.
- Treating a passing JSON parse as a complete contract -> define fields, types, required values, examples, and invariants explicitly.
- Accepting "looks good" as approval -> require the exact `approve-spec <path>` command and record it.
- Using the skill for formatting-only work -> route directly to the relevant editing workflow.

## Baseline Rationalizations

| Excuse | Reality |
|---|---|
| "The requirements are obvious." | Rate limits, authentication, retries, and errors still contain decisions; ask and record them. |
| "A concise prose spec is enough." | Concision removes repetition, not EARS, contracts, examples, or scope boundaries. |
| "The branch already has a test, so continue." | A test based on invented behavior is implementation before specification. Stop and discard the assumption. |
| "Keep the implementation and write the spec afterward." | Existing code is read-only context, not product intent; freeze it and compare it against the approved spec later. |
| "The manager needs this in ten minutes." | Reduce question breadth, never remove validation or approval gates. |
| "The senior developer reviewed it verbally." | Verbal review is not an explicit approval of the versioned artifact. |
| "The validator is unavailable." | An unavailable deterministic gate is a blocker, not a passing result. |

## Red Flags - Stop

- Writing a test, plan, schema, or production code before clarification and approval
- Retrofitting a specification around existing code to make an unapproved implementation appear compliant
- Choosing a limit, header, token lifetime, identity, retry rule, or error code without a recorded decision
- Using free-form acceptance prose instead of EARS
- Omitting valid/invalid examples, invariants, or `Out of Scope`
- Replacing `validate_spec.py` with manual inspection
- Treating urgency, sunk cost, authority, or an existing branch as a waiver
- Proceeding after "looks good" without explicit approval tied to the artifact path

## Example

For a rate-limit change, do not invent "five requests per minute" and write a
test. Ask who is limited, which window applies, what happens when the counter
store is unavailable, and which endpoints are excluded. After answers, encode
the chosen behavior as EARS criteria, a JSON error contract, valid/invalid
payloads, an invariant, and explicit exclusions; lint it; then stop for approval.
