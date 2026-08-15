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

### 1. Explain the PR before reviewing it

As the first operation, run the project's `explain-change` skill against the PR.
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

### 2. Resolve scope and intent

Identify the PR URL/number, branch, or local base. Do not switch branches or
mix a remote PR diff with unrelated workspace files. Capture base/head refs,
changed and untracked paths, PR title/description/commits/prior comments,
applicable standards, generated files, and any plan or acceptance criteria.

Read the PR description before the diff. It should explain problem, solution,
non-goals, tests, configuration, migrations, rollout, risks, and follow-ups.
If intent is incomplete, infer it from available evidence and mark uncertainty;
do not block on a question.

### 3. Classify danger before selecting reviewers

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
| 0–4 | minimal | 0 | main reviewer + automated checks |
| 5–8 | low | 1 | correctness or standards |
| 9–12 | moderate | 2 | correctness + tests/risk lens |
| 13–16 | significant | 3 | relevant security/API/reliability/performance lens |
| 17–20 | high | 4 | specialist coverage + explicit residual risk |
| 21–23 | very high | 5 | domain, adversarial, rollout/rollback |
| 24–27 | critical | 6 | independent second-harness review when useful |
| 28–30 | extreme | 8 | multi-harness review + human walkthrough |

The count is a ceiling, not a reason to create irrelevant work. Keep one
subagent per distinct lens; merge overlapping lenses. A small diff with high
blast radius gets the high-risk roster.

### 4. Select specialist lenses

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

For a silent-pass mechanism, always include `adversarial` regardless of line
count. Do not run irrelevant specialists just to fill the quota.

### 5. Assign capability tiers without naming models

- `fast`: small, low-risk, deterministic lens;
- `standard`: normal correctness, tests, standards, maintainability;
- `deep`: security, data, API, reliability, performance, migrations;
- `independent`: adversarial pass from a separate harness or context.

For scores 0–8 use fast/standard. For 9–20 use standard plus relevant deep
lenses. For 21+ add an independent reviewer only when the risk justifies it.
For 24+ prefer an independent second-harness pass, but keep the total at six
or fewer unless the score is 28–30. If no second harness is available, run
adversarial locally and disclose the fallback. Never let a closed loop of
agents approve itself.

### 6. Dispatch and collect

Give each subagent only the relevant scope, intent, paths, diff, and standards.
Dispatch independent lenses concurrently when supported; otherwise run
serially. Collect all results before synthesis.

Each reviewer returns structured findings with:

`severity`, `category`, `title`, `file`, `line`, `evidence`, `impact`,
`suggested_fix`, `confidence`, `requires_verification`.

Use `P0` for critical breakage/security/data loss, `P1` for high-impact defects
or broken contracts, `P2` for meaningful edge/performance/maintainability
issues, and `P3` for narrow advisory improvements.

### 7. Review in passes

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

### 8. Synthesize, validate, and report

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

### 9. Publish to GitHub only when explicitly authorized

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
