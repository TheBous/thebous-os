# Review Lenses

Use this file after the initial danger score. It is a selection aid, not a
second checklist to run blindly.

## Deep-review triggers

Escalate when any of these appears:

- a “refactor” changes execution order, timing, scope, or observable behavior;
- a utility, base class, middleware, validator, serializer, or shared type has high fan-out;
- money, auth, permissions, PII, deletion, migrations, backfills, rate limits, or secrets change;
- a small diff touches a critical path;
- behavior changes without corresponding tests, or tests become weaker;
- a PR description says one thing while the diff changes another;
- rollback, feature flag, migration compatibility, or observability is missing;
- retry, idempotency, queue, timeout, concurrency, or ordering semantics change;
- a CI/test/deployment guard can produce a false green result;
- the PR is too large to understand in one focused review session.

Use the additional conditional lenses when their concrete surface is present:
observability, production readiness, resource management, data integrity,
database schema, idempotency, backwards compatibility, rollback strategy,
accessibility, compliance, dependency supply chain, secrets vault,
concurrency, distributed systems, regression testing, integration testing,
chaos engineering, feature flags, API contract testing, schema evolution,
caching strategy, latency, energy efficiency, resource proportionality,
disaster recovery, incident response, and documentation.

Do not run every matching name. Rank by irreversible/security/legal/data-loss
impact, direct changed-surface coverage, blast radius, and verification gap;
coalesce overlapping lenses and keep the score-based subagent ceiling. Record
both selected and skipped candidates in the final `Coverage` section.

## Large PR protocol

Prefer, in order:

1. split schema/migration, refactor, wiring, behavior, UI, tests, and docs;
2. separate refactor from behavior changes;
3. use meaningful atomic commits as a reading path, not as a substitute for a coherent PR;
4. use a walkthrough or pair review for unavoidable large changes;
5. use feature/integration branches with green checks for incremental delivery;
6. reject or return a non-reviewable PR with concrete split points rather than issuing a casual approval.

Feature flags may hide incomplete-but-valid work; they must not hide broken
code. Plan their removal and test both disabled and enabled behavior.

## AI-assisted review protocol

Use an agent for narrow, verifiable tasks:

- summarize the diff and map changed behavior;
- find callers, consumers, migrations, and configuration that should change;
- enumerate edge cases and failure paths;
- check a specific API, database, deployment, or security invariant;
- propose a focused smoke/load test.

Do not ask one agent to “review everything” and treat the output as approval.
Use an independent harness/context for high-risk changes. Synthesize all
outputs in one human-owned report. Do not let code-generating and code-reviewing
agents form a closed approval loop.

For AI-generated code, inspect tests first: removed assertions, weakened
expectations, tautologies, copied patterns, invented APIs, missing config, and
unexplained complexity are priority signals.

## Comment grammar

- `BLOCKER`: must fix before merge; state the concrete failure and affected path.
- `IMPORTANT`: meaningful defect or risk; state the safer behavior or decision needed.
- `SUGGESTION`: optional improvement; never imply merge blocking.
- `QUESTION`: unresolved assumption or missing context.
- `PRAISE`: specific behavior worth preserving.

Avoid style debates already handled by tooling. Do not confuse “I would write
it differently” with a correctness or maintainability defect.

## Final report contract

```text
## Summary
<intent, scope, danger score/classification, verdict>

## Actionable Findings
| # | Severity | File:line | Finding | Suggested action | Confidence |

## Coverage
- Scope:
- Score/classification:
- Subagents actually run:
- Independent harness:
- Automated checks:
- Skipped lenses and reasons:

## Residual Risk
<what was not verified and why>
```

If no actionable issues exist, write `Actionable findings: none.` Do not add
speculative suggestions merely to make the review look substantial.
