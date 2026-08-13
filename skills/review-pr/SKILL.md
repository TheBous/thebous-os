---
name: review-pr
description: Use when the user asks to review, inspect, or analyze a GitHub pull request
---

## Goal

Act as the reviewer on a GitHub PR: identify the PR and linked Jira ticket, switch to an isolated worktree, delegate analysis to `ce-code-review` in report-only mode (no fixes applied), present findings by severity (P0–P3), ask the user which to post, and submit a structured review via `gh` with inline comments and committable suggestions.

## Steps

### 1. Identify the PR and Jira ticket

Use `gh pr view` to get PR metadata (same pattern as other jira-git-sync workflows):
```bash
gh pr view --json number,title,body,author,headRefName,baseRefName,additions,deletions,changedFiles
```

Follow `references/jira-task-context.md` with:
- `<SOURCES>` = the PR head branch, then the PR title and body
- `<REQUIRED>` = `optional`
- `<DETAILS>` = `full`

If a Jira task is resolved, check for **linked predecessor tasks** (blocking dependencies) using the `<TASK_LINKS>` output or by querying linked issues:
   ```jql
   key in issueFunction in linkedIssuesOf("DC-123", "is blocked by")
   ```

Store the resolved task context (key, summary, requirements, and predecessors) for display before review analysis. If no task is provided, continue without Jira context.

If no PR is open on the current branch, ask the user to pass the PR number or URL explicitly.

### 2. Gather full context

Get the diff and head commit SHA:
```bash
gh pr diff <NUMBER>
gh pr view <NUMBER> --json headRefOid --jq '.headRefOid'
```

Read full files (not just hunks) for lines touched by the diff. Always read the complete file when the diff doesn't show function bodies, type definitions, or imports.

### 2.5. Display task context (if available)

If a Jira task was identified in Step 1, display its context before the review:

```
## Task Context — <KEY>

**Summary**: <title>
**Status**: <status>
**Priority**: <priority>
**Type**: <type>
**Assignee**: <assignee>

**Description**: <first 200 chars of description>

**Predecessors** (blocking dependencies):
- <PRED-1>: <pred title> — <pred status>
- <PRED-2>: <pred title> — <pred status>
(or "None" if no predecessors)

**Key points to review**: <derived from task description and predecessors>
```

This context informs the depth and focus of the code review. Compare the implementation against `<TASK_REQUIREMENTS>` so the reviewer can connect code changes to the task and understand any upstream work that might affect this PR.

### 3. Ask about review depth

Ask the user whether they want a shallow or deep review:

```
Would you prefer a shallow or deep review?

• **Shallow** (default): Correctness + project standards only
• **Deep**: Full team review (correctness, testing, security, maintainability, adversarial, reliability, API-contract, data-migration, learnings, agent-native)
```

Wait for the user's choice. Default to shallow if they don't specify.

### 4. Switch to isolated worktree

Enter a fresh worktree isolated from the main branch, using the `worktrunk` pattern:
```bash
wt switch pr:${PR_NUMBER}
```

This creates a dedicated worktree for the review. **Do not create another worktree inside ce-code-review** — the next step will know one already exists.

Store the task context (from Step 2.5) in environment variables for reference during analysis:
```bash
export REVIEW_JIRA_KEY="<KEY>"
export REVIEW_TASK_SUMMARY="<summary>"
export REVIEW_PREDECESSORS="<predecessor list>"
```

### 5. Delegate analysis to ce-code-review

Invoke the `ce-code-review` skill in `mode:agent` (report-only JSON output):

**If shallow review was chosen:**
```
mode:agent <NUMBER>
```

**If deep review was chosen:**
```
mode:agent depth:full <NUMBER>
```

Pass the context that a worktree has already been created in step 4, so ce-code-review does NOT create a new one — it will use the existing isolated worktree.

ce-code-review returns structured findings:
- `title` — brief description
- `severity` — P0, P1, P2, P3 (internal codes)
- `file` and `line` — exact location
- `pre_existing` — whether the issue existed before this PR
- `suggested_fix` — optional code-level suggestion

**CRITICAL: Transform severity codes before presenting to the user or writing to GitHub:**
- `P0` → 🔴 "Must fix before merge"
- `P1` → 🟡 "Recommended"
- `P2` → 🟢 "Fix if straightforward"
- `P3` → ⚪ "Discretionary" (discard from public comments, mention only in verdict to user)

**Never write P0/P1/P2/P3 in any GitHub comment or presentation.** All public comments must use the human-readable labels.

**Scope discipline**: do not flag pre-existing issues as blocking this PR. Note them separately for the user's awareness.

### 6. Present the verdict to the user

Group findings by severity and present them in order (P0 → P3):

```
## Code Review: PR #N — <title>

**Jira**: <TICKET-123> — <ticket summary>
**Author**: @<author>
**+<additions> / -<deletions> lines**

---

### Findings by Severity

#### 🔴 P0 (Must fix before merge)
**Issue 1 — <short headline>**
`<file>`:<line>
<explanation + why it matters>
<suggested_fix if available>

#### 🟡 P1 (Recommended)
**Issue 2 — <short headline>**
...

#### 🟢 P2 (Fix if straightforward)
...

#### ⚪ P3 (Discretionary)
...

---

**Note**: <count> total findings. P0 issues require changes from the author before merge.

Which findings would you like me to post as a review? (e.g., "P0 and P1 only", "all", "none")
```

Wait for user confirmation. Do not submit without it.

### 7. Submit the top-level review

After the user confirms, post the main review comment on GitHub first. This is a **summary comment** that:
- Explains the focus and scope of the review
- Lists all findings grouped by severity
- Points to the detailed sub-comments (threads) for each issue

Structure of the main review comment:

```bash
gh pr review <NUMBER> --request-changes --body "$(cat <<'EOF'
## Review — <title>

<2-3 sentences explaining the focus and scope of the review>

For example:
"Focused on data integrity, concurrency invariants, and lifecycle constraints. Each thread proposes a correction direction and suggests a regression test. See detailed comments below grouped by severity."

---

### 🔴 Must fix before merge
- <headline> — see inline comment on `<path>:<line>`
- <headline> — see inline comment on `<path>:<line>`

### 🟡 Recommended
- <headline> — see inline comment on `<path>:<line>`

### 🟢 Fix if straightforward
- <headline> — see inline comment on `<path>:<line>`
EOF
)"
```

**When to use each flag:**
- If there are "Must fix before merge" findings → use `--request-changes`
- If only "Recommended" or "Fix if straightforward" → use `--comment`
- If P3 (Discretionary) only → omit from review, note them in the user conversation only

**Important structure rules**:
1. Main review body is **summary + index only** — no technical details
2. All technical details live in **sub-comments** (step 8)
3. Never write P0, P1, P2, P3 in GitHub; always use human-readable labels
4. Each main bullet in the review body links to its corresponding inline thread

### 8. Add detailed sub-comments for each finding

For each finding (grouped by severity in the main review), post a **detailed inline comment thread** on the affected code line.

**Structure of each sub-comment:**

```
<The problem — what's wrong, in technical detail>

<Why it matters — invariant violated, data loss, race condition, audit trail, atomicity broken, etc.>

Potremmo <direction of fix — concrete suggestion>?

<Test suggestion — how to verify the fix works>
```

**To post via gh:**

```bash
gh api repos/:owner/:repo/pulls/<NUMBER>/comments \
  --method POST \
  --field commit_id='<sha>' \
  --field path='<file>' \
  --field side='RIGHT' \
  --field line=<line> \
  --field body='<comment text>'
```

**Key principles**:
- **1 comment per finding** — each thread is independent
- **Problem first** — state what's wrong clearly and technically
- **"Potremmo..."** — always propose a concrete direction, never just "this is wrong"
- **Test suggestion** — always add how to test the fix
- **Invariant-focused language** — "violates atomicity", "audit trail missing", "data loss risk", "race condition", "state machine violation"
- **English content**: all comments on GitHub must be in English
- **No severity labels in comment body** — severity is only in the main review index

**Anchoring rules**:
- `commit_id` = PR's head commit SHA
- `side='RIGHT'` for added/modified lines, `side='LEFT'` for deleted lines
- `line` = actual file line number, not diff position
- Only comment on lines within the diff hunks

**Decision rules**:
- Trivial one-liner fix → committable `suggestion` block
- Fix needing coordinated changes → code snippet + explanation, no `suggestion`
- Fix needing new tests → code snippet with test code + explanation
- Generated artifacts (migrations, lockfiles) → suggest the *source*, note to regenerate

### 9. Optional Jira comment

If the branch matched a Jira key in step 1, ask:
```
Vuoi che lasci un commento su Jira con l'esito della review?
```

If yes, follow `references/jira-transition.md` for the comment call only — **do not transition the ticket**, just post:
```
🔍 Review PR #<NUMBER>: <Approved|Changes requested|Commented> — <PR_URL>
```

### 10. Log to Obsidian (optional)

Only if a Jira ticket was matched in step 1 (`<KEY>` is set). Follow `references/obsidian-log.md`:

```bash
source "scripts/helpers.sh"
load_env

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  REVIEW_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "review.md")
  obsidian_append_section "$REVIEW_FILE" "PR #<NUMBER> — <Approved|Changes requested|Commented>. <count> findings posted."
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — reviewed PR #<NUMBER>"
fi
```

### 11. Confirmation

Show the user:
- Review submitted: `<Approved|Changes requested|Commented>`
- Inline comments posted: `<count>`
- Jira comment: yes/no
- Obsidian: logged (or "skipped, no vault configured / no linked ticket")

## Style for review prose

**All public review content on GitHub must be in English** — regardless of the language used in your conversation with the user.

- **Step 6 (Verdict to user)** — present in the language the user used
- **Step 7 (Top-level review body)** — **English only**. Concise index grouped by severity, pointing to inline threads. No explanation duplication.
- **Step 8 (Inline comments)** — **English only**. Include the affected code snippet, explanation, and `suggested_fix` (if applicable).
- **Step 9 (Jira comment, if applicable)** — **English only**. Brief status update.

For all GitHub comments: be concise (issue, why it matters, affected code, fix — in that order), no emojis unless the team already uses them in code reviews.

## Common pitfalls to avoid

- Don't trust the diff for line numbers — use the actual file at the head SHA.
- Don't suggest a change without reading the full function/type definition.
- Don't post inline comments on lines outside the diff hunks.
- Don't flag "violations" before checking existing patterns in the same file.
- Don't duplicate explanation between the top-level body and inline comments — detail goes inline.
- Remember: P0 → PR blocks on author changes, P1/P2 → advice, P3 → omit entirely.
