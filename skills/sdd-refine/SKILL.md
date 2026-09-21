---
name: sdd-refine
description: Use when a feature, bug fix, or task request is ambiguous and implementation direction must be clarified before specification, planning, or code
allowed-tools: "Read,Write,Glob,Grep,Bash(git:*),Bash(mkdir:*)"
---

# SDD Intent Discovery and Scope Refinement

## Overview

This is the mandatory intent-discovery pre-phase for Spec-Driven Development.
It converts an incomplete request into a bounded set of user decisions before
`cook-specify` writes formal requirements. It never writes implementation code,
tests, plans, or a delta specification.

Use directly with `/sdd:refine` when the host exposes that command; `cook`
invokes the same phase automatically for feature and bug work.

## When to Use

Use this phase before developing a feature, fixing a bug, changing behavior, or
planning a task when the desired outcome, actors, scope, failure policy, or
implementation direction is not already explicit and approved.

Do not use it for formatting-only changes, documentation-only edits, or a
request whose approved specification already fixes the intended behavior.

## Non-Negotiable Rules

- Read the repository and task context before asking questions.
- Ask the user only for decisions or facts that cannot be established from the
  repository. Never ask the user to explain discoverable code structure.
- Do not invent product behavior, limits, permissions, identities, retries,
  error outcomes, security policy, persistence, or rollout behavior.
- Do not write code, tests, `plan.md`, `tasks.md`, `proposal.md`, or
  `delta-spec.md` before refinement is complete and the user approves the
  build spec.
- Resolve blocking uncertainty; do not hide it in an assumption. If the user
  refuses a blocking question, stop and report the blocker.
- Treat urgency, authority, sunk cost, an existing branch, or an existing test
  as no waiver for this phase.

## Procedure

### 1. Establish the factual boundary

Read the request, current branch, relevant files, tests, stable specifications,
and available task context. Keep the exploration read-only. Record findings in
four buckets:

| Bucket | Meaning |
|---|---|
| `Fact` | Directly evidenced by the repository or supplied task context |
| `Decision` | A product or engineering choice requiring the user's authority |
| `Assumption` | A temporary interpretation that must be confirmed or removed |
| `Unknown` | Missing information that blocks a safe choice |

For a bug, identify the observed symptom, expected behavior, affected actors,
reproduction evidence, and compatibility boundary. Do not call a suspected
cause the root cause before evidence supports it.

### 2. Interview the current decision frontier

Build the smallest frontier of blocking choices in this order:

1. Goal, actors, success outcome, and priority.
2. Scope, supported states, permissions, inputs, outputs, and compatibility.
3. Errors, retries, security, persistence, integrations, rollout, and explicit
   exclusions.

Ask one round at a time. Each round contains at most 3-5 questions from the
same frontier. Every question has mutually exclusive options, a short impact
statement, and an explicitly marked recommendation. If repository evidence
cannot support one, write `No recommendation: user decision required` instead of
hiding the choice. Present
the options using the host's question UI when available; otherwise use `A`,
`B`, and `C` labels. Stop after each round and wait for the user's answers.

Use at most three rounds. If a blocking ambiguity remains after the third
round, stop and report it as a blocker; never continue asking for non-blocking
preferences after the contract is bounded.

After each answer, record the decision and advance the frontier. If an answer
conflicts with repository facts or an existing invariant, show the conflict and
ask a focused replacement question instead of silently choosing a compromise.

### 3. Produce the bounded build spec

Only after all blocking decisions are resolved, and only when `CHG_ID` is known,
create the change directory if needed and write:

```text
changes/{CHG_ID}/build-spec.md
```

Use this structure:

```markdown
# Build Spec: <short change name>
**Change ID:** CHG-YYYY-NNN
**Status:** Ready for Approval
**Source:** <task, bug, or user request>

## 1. Intent and Outcome
<problem, users, desired observable result>

## 2. Facts and Existing Context
- Fact: <repository evidence>

## 3. Decisions
- Decision: <choice> — <reason and consequence>

## 4. Assumptions and Unknowns
- Assumption: <confirmed interpretation or `none`>
- Unknown: <remaining non-blocking unknown or `none`>

## 5. In Scope
- <bounded behavior or component>

## 6. Out of Scope
- <explicit exclusion>

## 7. Risks and Verification Direction
- Risk: <risk> — verify with <evidence>

## 8. Agent Handoff
- **Next phase:** cook-specify
- **Status:** ready-for-approval
- **Approval:** `approve-build-spec changes/{CHG_ID}/build-spec.md`
```

`Out of Scope` must contain at least one explicit exclusion. The handoff must
list remaining non-blocking unknowns; an empty list is valid. Do not draft a
formal EARS criterion here; that belongs to `cook-specify`.

### 4. Human checkpoint

Show the user the path, decision summary, exclusions, risks, and unresolved
non-blocking unknowns. Wait for this exact approval:

```text
approve-build-spec changes/{CHG_ID}/build-spec.md
```

Record the exact approval in the build spec, change its status to `Approved`,
and only then hand it to `cook-specify`. Accept no substitute such as "looks
good". If the user asks for changes, update the build spec, return it to `Ready
for Approval`, and ask again. Without the approval, do not invoke planning, TDD,
or implementation.

## Quick Reference

| Gate | Evidence | Failure action |
|---|---|---|
| Context | Read-only repository facts | Inspect before asking |
| Classification | Fact/Decision/Assumption/Unknown | Resolve or record |
| Interview | Up to 3-5 questions per frontier round | Wait for answers |
| Scope | In Scope plus non-empty Out of Scope | Narrow the contract |
| Artifact | `changes/{CHG_ID}/build-spec.md` | Do not create formal spec |
| Approval | Exact `approve-build-spec ...` command | Stop before `cook-specify` |

## Common Mistakes

- Asking about file names or existing conventions that `Glob`, `Grep`, or
  `Read` can answer.
- Asking a large unstructured questionnaire instead of one decision frontier.
- Treating "fast", "secure", or "for everyone" as measurable requirements
  without asking for observable boundaries.
- Letting a product manager's unrecorded preference bypass the user's approval.
- Writing `delta-spec.md` while calling it a build spec.
- Continuing after a user declines a blocking question.

## Red Flags - Stop

- Code, tests, plans, or formal specs exist before build-spec approval.
- A question has no options, impact, or recommendation.
- More than 3-5 questions are presented in one round.
- A silent assumption fills a missing product decision.
- "Urgent", "obvious", "the PM decided", or sunk effort is used as a waiver.

**Violating the letter of these gates violates the purpose of SDD.**
