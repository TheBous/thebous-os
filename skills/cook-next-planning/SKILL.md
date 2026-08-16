---
name: cook-next-planning
description: "Plan a feature or fix before development: retrieve the full Jira context, clarify requirements, build the mental model, and create synchronized spec.html, plan.md, and task.md files in the project and Obsidian. Use when scope, design, test strategy, risks, and PR stacking must be defined without writing code yet."
---

# Cook Next Planning

This skill prepares the work. Do not modify production or test code: produce
only analysis, decisions, and planning artifacts.

## Constraints

- Resolve the Jira task and retrieve its full context before proceeding.
- Require `OBSIDIAN_VAULT_PATH`; stop if the ticket or vault is unavailable.
- Create and synchronize:
  - project: `docs/<KEY>/spec.html`, `plan.md`, `task.md`;
  - Obsidian: `<OBSIDIAN_VAULT_PATH>/Dev/Tickets/<KEY>/spec.html`, `plan.md`,
    `task.md`.
- Use `task.md` as the single checklist, updating it before and after every
  activity.
- Do not start development until the artifacts are complete and approved.

## 1. Retrieve Jira context

Use `references/jira-task-context.md` with:

```text
<SOURCES> = current branch and user input
<REQUIRED> = required
<DETAILS> = full
```

Retrieve the summary, description, acceptance criteria, status, priority,
assignee, issue type, linked issues, subtasks, parent, epic/ancestor, and child
tasks. Walk up the parent hierarchy until it ends. Use this context to define
scope, dependencies, criteria, and work order; do not reimplement Jira key
resolution.

## 2. Understand deeply

- Read the requirement at least three times and read every linked reference.
- If the feature extends existing behavior, try the existing flow first.
- Ask about scope, use cases, personas, inputs/outputs, errors, null values,
  out-of-range values, timeouts, double-clicks, concurrency, permissions, rate
  limits, and race conditions.
- Involve the user, product owner, or domain expert when context is missing.
- Explore the README, structure, critical flow, data ingress and persistence,
  orchestrators, components, and dependencies.

Define what `DONE` means and work backward to identify dependencies and the
critical path. Always separate the required behavior (what) from the technical
solution (how).

## 3. Create `spec.html`

After receiving the user's answers:

```bash
source "scripts/helpers.sh"
load_env
test -n "${OBSIDIAN_VAULT_PATH:-}" && test -d "$OBSIDIAN_VAULT_PATH"
```

Use `obsidian_ticket_dir` for the Obsidian destination and create
`docs/<KEY>/` in the project. Write `spec.html` in both destinations with:

- problem, goal, user-visible value, stakeholder, scope, and out of scope;
- feature, priority, dependencies, and acceptance criteria;
- functional/non-functional requirements, use cases, and flows;
- inputs, outputs, error handling, and edge cases;
- data model at rest/in transit, contracts, and component responsibilities;
- requirement → criterion → test → evidence table;
- risks, assumptions, decisions, and open questions;
- success metrics and the post-release observation window;
- the 400-line PR limit and possible PR stack decomposition.

Mark unconfirmed assumptions as `Not verified`. For complex features, add
simple, self-contained diagrams for states, sequences, data flows, or
dependencies using inline SVG, Mermaid when supported, or readable text
diagrams. Verify that both copies exist and are non-empty.

## 4. Create `plan.md`

Only after creating the spec, write `plan.md` in both destinations. Include:

- backward path from `DONE` and the critical path;
- chosen technical approach and rejected alternatives;
- pseudocode/plain-English logic;
- components, files, data model, contracts, and interfaces;
- dependencies, order, and vertical feature slices;
- risk level and proportional controls;
- test matrix: unit, integration, E2E/smoke, security, performance, and stress;
- CI: tests, lint, formatter, typecheck, and static analysis;
- design inspection, peer review, rollout, monitoring, alerts, and rollback;
- acceptance, defect, rework, lead-time, and adoption metrics;
- any spike/proof of concept with timebox, expected result, and decision;
- any PR stack ordered by dependency.

For technical uncertainty, plan a time-boxed spike; do not turn it into
production code without an explicit decision, review, and tests.

## 5. Create `task.md`

After the spec and plan, create an ordered checklist in both destinations:

```markdown
- [ ] confirm scope, value, and the DONE result
- [ ] define the critical path, data, contracts, and interfaces
- [ ] add diagrams if the feature is complex
- [ ] define edge cases and the test matrix
- [ ] search for reusable constants, maps, helpers, and modules
- [ ] estimate size and PR stack
- [ ] complete any time-boxed spikes
- [ ] approve the spec and plan
- [ ] hand off to cook-next-development
```

Use `[x]` only after verification and `[blocked]` with a reason. Add the
development, testing, and release tasks that are already planned, but do not
execute them in this skill. Synchronize both copies after every update and
verify that they are identical.

## 6. Review and hand off

Before handoff, check:

- no `TODO`, placeholder, or ambiguous requirement remains;
- the scope is small enough for one feature or is split into slices;
- every requirement has a criterion, planned test, and expected evidence;
- every risk has a mitigation;
- spec, plan, and task are internally consistent;
- a forecast above 400 lines includes a PR stack;
- value, metrics, and stakeholder are explicit.

Ask the user to approve the spec and plan. After approval, switch to
`cook-next-development`; do not implement code during planning.
