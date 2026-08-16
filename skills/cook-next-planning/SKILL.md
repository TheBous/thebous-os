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
- Keep the depth proportional to the feature: use the full model and contract
  sections only when the feature crosses multiple capabilities, boundaries, or
  meaningful risk areas.
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

If the request contains multiple independently testable capabilities, create a
small capability map before the spec:

```markdown
| Capability | Responsibility | Depends on |
|---|---|---|
| account-creation | Create an account | — |
| email-verification | Verify ownership | account-creation |
```

Give each capability a stable id and split it into client-valued feature slices
that can be implemented, tested, and demonstrated independently.

## 3. Run the structured discovery interview

Before writing `spec.html`, run a structured discovery interview to eliminate
ambiguity. This is a planning gate, not implementation: do not modify production
or test code.

### 3.1 Build the decision tree

Create a decision tree from the ticket and repository findings. Group open
decisions under:

- business goal, user value, scope, and out of scope;
- actors, roles, permissions, and tenant boundaries;
- main flows, states, and transitions;
- inputs, outputs, persistence, contracts, and integrations;
- errors, null/invalid data, retries, idempotency, timeouts, and concurrency;
- security, privacy, performance, availability, accessibility, and cost;
- rollout, feature flags, migration, rollback, and success metrics.

Only ask questions whose prerequisites are settled. When a decision unlocks new
questions, add them to the next round. Keep each round to at most five questions
so the user can answer accurately.

### 3.2 Separate facts from decisions

Classify every relevant statement as:

- **Fact** — verified in Jira, the repository, documentation, or the environment;
- **Decision** — a product or technical choice requiring user/stakeholder input;
- **Assumption** — plausible but not confirmed;
- **Unknown** — unavailable information that blocks a safe decision.

Retrieve facts yourself whenever the environment can provide them. Ask the user
only for decisions or facts that cannot be discovered. Record the classification
in the interview notes and later in `spec.html`.

### 3.3 Ask questions in rounds

For each round, number the frontier questions and include a recommendation:

```text
❓ Q1 — Scope: Should the first version support bulk operations?

➡️ Recommendation: No. Keep the first version limited to one record per request
to reduce concurrency and rollback complexity.
```

After each user response, update the decision tree and recompute the next
frontier. Do not silently choose a product decision. If a question depends on a
fact, retrieve the fact before asking it.

### 3.4 Stress-test with concrete scenarios

For every important flow, define expected behavior for the happy path and the
relevant failure paths. Include, when applicable:

- missing, null, invalid, duplicate, and out-of-range input;
- timeout, retry, double-submit, partial failure, and unavailable dependency;
- concurrent updates, stale data, race conditions, and idempotency;
- insufficient permissions, cross-user access, tenant isolation, and data privacy;
- existing records, migration states, rollback, and feature-flag changes.

Use concrete actors and outcomes. Do not accept "it should work" as a decision.

### 3.5 Resolve domain vocabulary

Identify important domain terms and compare them with Jira, documentation, and
the code. If one term has multiple meanings, propose a canonical term and ask
which meaning is intended. Record the final vocabulary in the spec. Create an ADR
only when the decision is difficult to reverse, surprising to future maintainers,
and based on a real trade-off; do not create ADRs for ordinary implementation
choices.

### 3.6 End the interview with shared understanding

The discovery interview is complete only when:

- no critical question remains unanswered;
- every required behavior has an expected outcome;
- actors, permissions, states, data, contracts, and edge cases are defined;
- assumptions are either verified or explicitly accepted;
- scope is bounded to one feature or a documented PR stack;
- `DONE` and measurable success criteria are clear.

Summarize the resolved scope, decisions, assumptions, scenarios, risks, and open
questions. Ask the user to confirm the shared understanding before writing the
spec. If the user does not confirm, continue the interview; do not create the
spec prematurely.

## 4. Create `spec.html`

After receiving the user's answers:

```bash
source "scripts/helpers.sh"
load_env
test -n "${OBSIDIAN_VAULT_PATH:-}" && test -d "$OBSIDIAN_VAULT_PATH"
```

Use `obsidian_ticket_dir` for the Obsidian destination and create
`docs/<KEY>/` in the project. Write `spec.html` in both destinations with:

- problem, goal, user-visible value, stakeholder, scope, and out of scope;
- capability map and client-valued feature list when the request is composite;
- resolved planning-interview decisions and shared understanding;
- domain vocabulary with canonical meanings and code representations;
- verified facts, accepted assumptions, unknowns, and open questions;
- feature, priority, dependencies, and acceptance criteria;
- functional/non-functional requirements, use cases, and flows;
- inputs, outputs, error handling, and edge cases;
- concrete happy-path and failure-path scenarios with expected outcomes;
- data model at rest/in transit, contracts, and component responsibilities;
- measurable targets for performance, availability, accessibility, privacy, or cost when applicable;
- API/event contract details (schemas, errors, auth, compatibility, examples) when a boundary changes;
- design package: component boundaries, sequence/state/data-flow diagrams, alternatives, and review outcome;
- requirement → criterion → test → evidence table;
- risks, assumptions, decisions, and open questions;
- success metrics and the post-release observation window;
- the 400-line PR limit and possible PR stack decomposition.

Mark unconfirmed assumptions as `Not verified`. For complex features, add
simple, self-contained diagrams for states, sequences, data flows, or
dependencies using inline SVG, Mermaid when supported, or readable text
diagrams. Verify that both copies exist and are non-empty.

## 5. Create `plan.md`

Only after creating the spec, write `plan.md` in both destinations. Include:

- one plan subsection per feature slice with value, owner, priority, size, risk,
  dependencies, touched areas, verification, PR, flag, and rollback;
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
- decisions from the planning interview, including alternatives and trade-offs;
- domain boundaries, terminology, and scenario coverage;
- milestone gates: domain/design review, contract validated, tests ready, code
  complete, inspection, integration, and acceptance;
- checkpoints after every two or three tasks, each leaving the feature slice
  buildable, testable, and demonstrable;
- safe parallel work, sequential dependencies, required owners/reviewers, and
  the contract that must be agreed before parallel work starts;
- traceability from Jira requirement → capability → feature slice → spec section
  → task → PR → test → evidence;
- any PR stack ordered by dependency.

For technical uncertainty, plan a time-boxed spike; do not turn it into
production code without an explicit decision, review, and tests.

## 6. Create `task.md`

After the spec and plan, create an ordered checklist in both destinations:

```markdown
- [ ] confirm scope, value, and the DONE result
- [ ] retrieve and verify environmental facts
- [ ] build the decision tree and complete the planning interview rounds
- [ ] resolve domain terminology and record canonical meanings
- [ ] validate happy-path and failure-path scenarios
- [ ] resolve security, permissions, concurrency, retry, and rollback decisions
- [ ] confirm shared understanding with the user
- [ ] review the capability/feature map and vertical-slice boundaries
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

## 7. Review and hand off

Before handoff, check:

- no `TODO`, placeholder, or ambiguous requirement remains;
- the structured interview reached shared understanding and its decisions are recorded;
- facts, decisions, assumptions, and unknowns are clearly separated;
- domain vocabulary has no unresolved conflicting meanings;
- every critical scenario has an expected result;
- the scope is small enough for one feature or is split into slices;
- every requirement has a criterion, planned test, and expected evidence;
- every feature slice has a value, owner, dependency order, verification,
  rollback, and PR/flag decision when applicable;
- measurable non-functional targets and boundary contracts are defined when relevant;
- checkpoints and parallelization rules are explicit;
- every risk has a mitigation;
- spec, plan, and task are internally consistent;
- a forecast above 400 lines includes a PR stack;
- value, metrics, and stakeholder are explicit.

Ask the user to approve the spec and plan. After approval, switch to
`cook-next-development`; do not implement code during planning.
