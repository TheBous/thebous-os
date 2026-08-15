---
name: review-pr-multiharness
description: Use when reviewing, inspecting, or analyzing a GitHub pull request with risk-proportional specialist coverage, up to eight subagents, and provider-neutral multi-harness validation
---

# PR Review Multiharness

Review the change, not the author. Optimize for a merge decision that can be
defended in production with the least unnecessary reviewer effort.

## Regole

- Stay report-only by default. Never edit, merge, push, open PRs, or create tickets unless explicitly authorized.
- Never approve from green CI alone. CI proves only what its checks cover.
- Do not invent requirements, conventions, or findings. Report evidence and coverage gaps.
- Automate deterministic checks; reserve human/subagent attention for intent, behavior, contracts, risk, and trade-offs.
- Never name a concrete model, vendor, or harness. Use capability tiers so the workflow works across Codex, OpenCode, and other environments.
- If subagents are unavailable, run the same lenses sequentially and disclose degraded coverage.

## Workflow

### 1. Identify the PR and Jira task

Use `gh pr view` to get the PR metadata:
```bash
gh pr view --json number,title,body,author,headRefName,baseRefName,additions,deletions,changedFiles,headRefOid
```

Follow [`references/jira-task-context.md`](../../references/jira-task-context.md) with:
- `<SOURCES>` = the PR head branch, then the PR title and body;
- `<REQUIRED>` = `optional`;
- `<DETAILS>` = `full`.

Store the resolved Jira context (key, summary, requirements, status, priority,
assignee, type, and linked issues) for the walkthrough and review. If no Jira
task is found or Jira is unavailable, continue and record the missing context
in `Coverage`; do not invent a key. If no PR is open on the current branch, ask
the user for the PR number or URL.

### 2. Explain the PR before reviewing it

Before danger scoring, dispatching reviewers, or writing findings, run the
project's `explain-change` skill against the PR.
Pass it the PR number/URL, title, description, head SHA, full diff, changed
files, tests, and the linked Jira key when available. Do not start danger
scoring, dispatch reviewers, or write findings before this walkthrough has
been generated.

The walkthrough must include the business goal, before/after behavior, entry
points, component and data-flow map, relevant implementation chain, examples,
edge cases, verification steps, and explicit `Evidenza`, `Inferenza`, and `Non
verificato` labels. It must be a self-contained HTML artifact using local
CSS/SVG only, not a wall of text.

If a Jira key is available, save every generated walkthrough artifact in the
same review Obsidian root used for PR walkthroughs:

```text
<OBSIDIAN_VAULT_PATH>/Dev/Review/DC-<TASK_ID>/explain-change/<slug>-<timestamp>/
```

Do not overwrite an existing explanation. If the vault is not configured or
the Jira key cannot be determined, keep the artifact in its temporary
directory, mark the persistence as skipped in the final report, and never
invent a key. Record the absolute artifact path in `Coverage` and in the final
confirmation.

Use the shared environment loader before writing and create the destination
only after validating both the vault and the key:

```bash
source "scripts/helpers.sh"
if [ -f "$ENV_FILE" ]; then load_env; fi

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ] && [ -n "${REVIEW_JIRA_KEY:-}" ]; then
  DEST_DIR="${OBSIDIAN_VAULT_PATH}/Dev/Review/DC-<TASK_ID>/explain-change/<slug>-<timestamp>"
  mkdir -p "$DEST_DIR"
  cp -R "<ARTIFACT_DIR>/." "$DEST_DIR/"
fi
```

### 3. Resolve scope and intent

Identify the PR URL/number, branch, or local base. Do not switch branches or
mix a remote PR diff with unrelated workspace files. Capture base/head refs,
changed and untracked paths, PR title/description/commits/prior comments,
applicable standards, generated files, and any plan or acceptance criteria.

Read the PR description before the diff. It should explain problem, solution,
non-goals, tests, configuration, migrations, rollout, risks, and follow-ups.
If intent is incomplete, infer it from available evidence and mark uncertainty;
do not block on a question.

### 4. Classify danger before selecting reviewers

Always compute a danger score before dispatching subagents. Score every axis
from 0 to 5:

| Axis | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| Impact | cosmetic | isolated | user-visible | important workflow | business-critical | safety/financial/legal critical |
| Blast radius | isolated | one module | several callers | shared service | cross-system | platform-wide/public |
| Irreversibility | trivial revert | easy revert | deploy revert | data/config rollback | difficult migration | destructive/permanent |
| Boundary sensitivity | none | local state | internal API | external API/auth | secrets/permissions | money/PII/security |
| Behavioral uncertainty | obvious | low | some edge cases | complex state | concurrency/retry | unknown/underspecified |
| Verification gap | strong proof | minor gap | partial tests | missing case | weak gates | silent-pass risk |

`danger_score = sum(axis scores)`, from 0 to 30. Apply these overrides:

- Minimum 24 for auth/authorization bypass, payments, destructive data,
  secrets, cryptography, or incompatible public contracts.
- Minimum 24 for risky migrations/backfills, irreversible rollout,
  retry/idempotency changes, concurrency/order changes, or external side
  effects without rollback/failure plans.
- Minimum 24 for CI, deployment, test, coverage, or merge gates that could
  silently pass while production is broken.

Il punteggio non è il numero di subagent. Il numero è sempre compreso tra 0 e
8: nessun caso può generare più di otto subagent.

| Score | Classification | Subagents | Treatment |
|---:|---|---:|---|
| 0–4 | minimal | 1 | main reviewer + automated checks |
| 5–8 | low | 2 | correctness or standards |
| 9–12 | moderate | 3 | correctness + tests/risk lens |
| 13–16 | significant | 4 | relevant security/API/reliability/performance lens |
| 17–20 | high | 5 | specialist coverage + explicit residual risk |
| 21–23 | very high | 6 | domain, adversarial, rollout/rollback |
| 24–27 | critical | 7 | independent second-harness review when useful |
| 28–30 | extreme | 8 | multi-harness review + human walkthrough |

The count is a ceiling, not a reason to create irrelevant work. Keep one
subagent per distinct lens; merge overlapping lenses. A small diff with high
blast radius gets the high-risk roster.

### 5. Select specialist lenses

Always run `correctness`. Add only lenses justified by the diff:

- `standards`: repository instructions and conventions;
- `tests`: changed tests, behavior changes, mocks, fixtures, or test gaps;
- `maintainability`: large/structural diff, abstractions, coupling, moves, types;
- `security`: auth, permissions, input, secrets, privacy, crypto;
- `api-contract`: routes, serializers, schemas, public types, versioning;
- `performance`: queries, caching, transforms, async, bundle/runtime cost;
- `reliability`: retries, timeouts, queues, background work, partial failure;
- `data-migration`: migrations, schema artifacts, backfills, destructive changes;
- `deployment`: rollout, rollback, feature flags, observability;
- `adversarial`: abuse cases, false confidence, downstream breakage, hidden behavior;
- `agent-native`: changed skills, prompts, tools, agents, MCP, or harness behavior;
- `previous-feedback`: existing PR comments needing resolution/revalidation;
- stack-specific lens when changed runtime behavior warrants it.

Select the additional lenses below only when the diff exposes the named
surface. Rank candidates before dispatching: (1) irreversible, security,
legal, or data-loss risk; (2) direct coverage of changed code; (3) blast radius;
(4) verification gap. If candidates exceed the score ceiling, run the highest
ranked distinct lenses and record the skipped ones in `Coverage`.

- `observability`: logs, metrics, traces, dashboards, alerts, or SLO signals;
- `production-readiness`: health checks, deadlines, retries, startup/shutdown, or SLO-sensitive behavior;
- `resource-management`: memory, file descriptors, sockets, threads, pools, or cleanup paths;
- `data-integrity`: ACID boundaries, consistency, idempotent writes, invariants, or duplicate/out-of-order events;
- `database-schema`: DDL, indexes, constraints, schema migrations, or online/zero-downtime changes;
- `idempotency`: retry keys, deduplication, at-least-once delivery, or repeated side effects;
- `backwards-compatibility`: changed consumers, versions, deprecations, or old/new coexistence;
- `rollback-strategy`: feature flags, graceful degradation, rollback, roll-forward, or recovery gates;
- `accessibility`: UI interaction, semantics, keyboard flow, focus, contrast, or assistive technology;
- `compliance`: GDPR/PII, retention, consent, auditability, SOX-relevant control evidence, or regulated data;
- `dependency-supply-chain`: dependency manifests, lockfiles, build provenance, plugins, or third-party code;
- `secrets-vault`: credentials, tokens, keys, secret stores, rotation, or secret exposure in logs/config;
- `concurrency`: shared mutable state, parallel tasks, locks, atomics, ordering, races, or deadlocks;
- `distributed-systems`: network partitions, quorum/consensus, cross-service state, sagas, or message delivery;
- `regression-testing`: changed behavior, bug fixes, edge cases, state combinations, or both flag states;
- `integration-testing`: cross-module/service/database boundaries, adapters, or real dependency behavior;
- `chaos-engineering`: resilience behavior that needs fault injection, degraded dependencies, or recovery proof;
- `feature-flag`: flag evaluation, rollout targeting, lifecycle, cleanup, or enabled/disabled behavior;
- `api-contract-testing`: consumer/provider interactions, OpenAPI or message contracts, or compatibility gates;
- `schema-evolution`: serialized/event/database schema changes, versioning, or forward/backward compatibility;
- `caching-strategy`: cache keys, invalidation, freshness, TTL, eviction, or stampede risk;
- `latency`: P95/P99 paths, async boundaries, batching, N+1 queries, or tail-latency regressions;
- `energy-efficiency`: polling, compute intensity, algorithmic work, payloads, or device/server energy use;
- `resource-proportionality`: lazy loading, memoization, bounded work, allocation, or over-fetching;
- `disaster-recovery`: backups, restore, failover, replication, RTO/RPO, or recovery-region readiness;
- `incident-response`: runbooks, diagnostics, escalation, containment, or incident telemetry;
- `documentation`: API docs, runbooks, ADRs, operational notes, or user-visible behavior documentation.

Coalesce overlapping candidates instead of dispatching duplicates: migration
and schema lenses; reliability, production-readiness, and observability;
tests, regression, integration, and API-contract testing; deployment,
rollback, feature flags, disaster recovery, and incident response; security,
secrets, dependencies, and compliance; performance, latency, resource,
resource-proportionality, and energy; correctness, integrity, idempotency,
concurrency, and distributed systems. Keep the most specific lens and give it
the shared evidence needed to cover the overlap.

For a silent-pass mechanism, always include `adversarial` regardless of line
count. Do not run irrelevant specialists just to fill the quota.

Before dispatch, load the matching prompt from
[`references/reviewer-prompts/`](references/reviewer-prompts/). Every selected
subagent must receive exactly one lens prompt, plus the shared review scope,
intent, relevant paths, diff, standards, and the structured output contract.
Do not dispatch a generic “review the PR” prompt. If a stack-specific lens is
selected, specialize `stack-specific.md` with the runtime/framework evidence
from the diff and name the concrete concern being checked.

### 6. Assign capability tiers without naming models

- `fast`: small, low-risk, deterministic lens;
- `standard`: normal correctness, tests, standards, maintainability;
- `deep`: security, data, API, reliability, performance, migrations;
- `independent`: adversarial pass from a separate harness or context.

Treat observability, production readiness, resource management, accessibility,
testing, feature flags, and documentation as `standard` by default. Treat data
integrity, schema, idempotency, compatibility, supply chain, secrets,
concurrency, distributed systems, compliance, chaos, API contracts, disaster
recovery, and incident response as `deep` when their trigger is present.

For scores 0–8 use fast/standard. For 9–20 use standard plus relevant deep
lenses. For 21+ add an independent reviewer only when the risk justifies it.
For 24+ prefer an independent second-harness pass, but keep the total at seven
or fewer unless the score is 28–30. If no second harness is available, run
adversarial locally and disclose the fallback. Never let a closed loop of
agents approve itself.

### 7. Dispatch and collect

Give each subagent only the relevant scope, intent, paths, diff, standards, and
the selected lens prompt. Keep reviewers
independent: do not include another reviewer's findings in the initial prompt.
Dispatch independent lenses concurrently when supported; otherwise run
serially. Collect all results before synthesis.

Each reviewer returns structured findings with:

`severity`, `category`, `title`, `file`, `line`, `evidence`, `impact`,
`suggested_fix`, `confidence`, `requires_verification`.

Use `P0` for critical breakage/security/data loss, `P1` for high-impact defects
or broken contracts, `P2` for meaningful edge/performance/maintainability
issues, and `P3` for narrow advisory improvements.

### 8. Review in passes

1. **Story:** verify the requested problem, non-goals, and absence of unrelated work.
2. **Diff map:** locate semantic hotspots, high fan-out code, boundaries, and generated noise.
3. **Contracts:** inspect public APIs, call-sites, schemas, permissions, events, and compatibility.
4. **Behavior:** test happy path, invalid/empty/duplicate/out-of-order input, retries, timeouts, partial failure, concurrency, and downstream effects.
5. **Data and operations:** check transactions, idempotency, migrations, backfill, rollback, logging, PII, monitoring, and rollout.
6. **Tests as proof:** verify behavior-oriented names, negative paths, intact assertions, and a test that would fail for the claimed bug.
7. **Human judgment:** distinguish required fixes from preferences; do not rewrite a valid solution to match personal style.

For AI-assisted changes, inspect the test diff early. Look for removed or
weakened assertions, tautological tests, duplicated patterns, invented APIs,
missing configuration, and code the author cannot explain.

### 9. Synthesize, validate, and report

Deduplicate by root cause. Prefer one fix at the shared source over guards in
every caller. Validate high-confidence findings against source and run the
smallest relevant check. Never manufacture comments to appear thorough.

Write comments that state behavior, risk, and action. Prefix them with
`BLOCKER`, `IMPORTANT`, `SUGGESTION`, `QUESTION`, or `PRAISE`; mark suggestions
as non-blocking. Finish with:

- `Actionable Findings`: numbered P0–P2 findings with file:line and confidence;
- `Coverage`: scope, score, classification, subagents run, skipped lenses and reasons, checks;
- `Verdict`: `Not ready`, `Ready with fixes`, or `Ready to merge`;
- `Residual risk`: what was not verified and why.

Approve only when you can defend the change as if you owned its production
behavior. Applying fixes requires an explicit user instruction.

### 10. Publish to GitHub only when explicitly authorized

The default remains report-only. Never post to GitHub merely because the
review is complete. When publication is explicitly authorized, first verify
the PR number, repository, head SHA, and that every finding was introduced by
the PR. Re-read the complete affected file and anchor comments only to lines
inside the current diff hunk.

Use the posting format in
[github-posting.md](references/github-posting.md):

1. Post one top-level review first. It contains the review scope and a short
   index grouped by human-readable impact; it must not duplicate technical
   details.
2. Post one independent inline thread per actionable finding, linked to the
   affected changed line. Put the problem, why it matters, concrete correction
   direction, and a regression-test suggestion in that thread.
3. Use `request-changes` when at least one `Must fix before merge` finding is
   present; otherwise use a comment review. Omit discretionary P3 findings
   from GitHub and mention them only in the local verdict.
4. Write all public GitHub content in English. Never expose internal P0–P3
   codes in the review body or inline comments.
5. Use a committable `suggestion` block only for a small, self-contained change
   on the anchored lines. For coordinated changes or test additions, explain
   the direction without pretending the snippet is directly committable.

After posting, report the review state, number of inline comments, skipped P3
items, and any findings that could not be anchored to the diff. Do not merge,
push, or apply fixes unless separately authorized.

## Reference

Read [review-lenses.md](references/review-lenses.md) when selecting lenses,
scoring difficult changes, or checking the final report.
