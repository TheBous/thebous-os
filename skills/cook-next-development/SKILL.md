---
name: cook-next-development
description: "Implement an already-planned feature with atomic tasks, test-first development, coding standards, CI, peer review, quality gates, PR stacking, and post-release verification. Use after cook-next-planning when spec.html, plan.md, and task.md are present and approved."
---

# Cook Next Development

This skill implements the approved plan. Do not repeat discovery: if the spec,
plan, or task file is missing, stop and use `cook-next-planning`.

## 1. Verify the handoff

Read both destinations:

- `docs/<KEY>/spec.html`, `plan.md`, `task.md`;
- `<OBSIDIAN_VAULT_PATH>/Dev/Tickets/<KEY>/spec.html`, `plan.md`, `task.md`.

Verify that the copies are identical, the spec and plan are approved, and
`task.md` contains the ordered work. Before the first source-code change:

```bash
BASE_COMMIT=$(git rev-parse HEAD)
```

Use this baseline to measure the current feature PR.

## 2. Implementation standards

Before writing code, search the codebase for:

- existing constants, enums, maps, configuration, and strings;
- reusable helpers, services, components, and functions;
- existing naming, structure, formatting, and error-handling conventions.

Follow these rules:

- do not use hardcoded values or strings when a shared definition already exists;
- if a value is genuinely new, define it once and import it wherever needed;
- do not duplicate logic: reuse existing code when it represents the same behavior;
- introduce abstractions only when there is concrete reuse or a clear boundary;
- prefer simple logic, small functions, single responsibilities, narrow
  interfaces, explicit dependencies, early returns, and readable flows;
- avoid deep nesting, syntactic magic, magic numbers, and magic strings;
- use the type system to make invalid states impossible when practical;
- comment the why, workarounds, and external constraints, not obvious code;
- update docstrings, README files, or public contract documentation;
- never hardcode secrets; validate inputs and permissions; apply least privilege;
- do not hide errors with generic catches or silent fallbacks;
- add useful logs without secrets or sensitive data;
- prefer native primitives and already-installed dependencies before new code;
- do not optimize before measuring the problem.

## 3. Test-first, incremental implementation

For each task:

1. update `task.md` to mark it in progress;
2. write tests linked to a requirement, edge case, or acceptance criterion first;
3. cover the happy path, error path, null/empty/limits, regressions, scale, and
   unavailable dependencies when applicable;
4. separate pure logic, integrations, and side effects to keep code testable;
5. implement a small block, ideally 10–20 lines;
6. run relevant tests and fix failures immediately;
7. refactor when duplication or complexity appears;
8. mark the task `[x]` only after verification and synchronize the three
   artifacts in the project and Obsidian.

Keep commits small and branches short; integrate frequently. After each
macro-block, zoom out and compare the implementation with the spec, critical
path, and user value. If the direction changes, update the spec and plan first.

For AI-generated code: provide explicit context, inspect every assumption,
verify legacy contracts, units, formats, permissions, and security, and do not
consider compilation or tests generated with the code sufficient.

## 4. Verify before merge

Run the checks required by the plan and risk matrix:

- unit and integration tests;
- E2E/smoke, security, performance, and stress tests when applicable;
- formatter, lint, typecheck, and static analysis;
- green CI after every commit;
- manual testing of every spec edge case;
- a regression test for every bug fixed;
- self-review focused on what is missing;
- independent peer code review;
- design inspection for high-risk changes.

Also verify that every acceptance criterion has evidence, no critical assumption
is marked `Not verified`, and reuse, single source of truth, naming, simplicity,
documentation, security, and testability standards are satisfied.

## 5. PR size and PR stack

Measure the change against the baseline:

```bash
git diff --numstat "$BASE_COMMIT"
```

Count added plus removed source and test lines; exclude `spec.html`, `plan.md`,
`task.md`, generated files, lockfiles, vendor files, and images.

If one PR exceeds 400 changed code lines:

1. stop before merge;
2. use the decomposition defined in the plan;
3. split independent slices ordered by dependency;
4. give each slice its own code, tests, and verification criteria;
5. create the stacked PRs and record branches/order in plan and task;
6. verify each slice before starting the next.

## 6. Release and post-release verification

Before release, verify staging, compatibility, migrations, monitoring, logs,
alerts, rollback, and feature flags/canary when required by risk.

After release, during the window defined in `spec.html`, record:

- acceptance rate;
- defect rate per feature;
- rework percentage;
- lead time and deployment frequency;
- adoption, engagement, and user satisfaction;
- regressions, incidents, and unexpected alerts.

The feature is complete when acceptance criteria and quality gates pass, residual
risk is acceptable, and metrics show the expected value. Never claim “zero bugs”:
report the passed checks, evidence, metrics, and remaining risks in the spec,
plan, and task files.
