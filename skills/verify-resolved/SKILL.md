---
name: verify-resolved
description: Verify that review comments you left on someone else's pull request were correctly addressed, revalidate each thread, and reply only when a fix is partial or missing
---

## Goal

Revalidate every review thread where you commented on someone else's PR after
the author pushed changes. Check the current code and the author's response,
classify each concern, and communicate unresolved problems one thread at a time.

**Do not use this workflow if:**
- You are fixing feedback on your own PR — use `address-review`.
- You are performing the first full review of a PR — use `review-pr` or
  `review-pr-multiharness`.

## Rules

- Review the latest PR head, not the old diff hunk.
- Read the full relevant function, interface, or caller chain before deciding.
- Trust a technically valid alternative implementation even when it differs
  from your original suggestion.
- Never reply when the concern is correctly fixed or genuinely outdated.
- Keep each verdict and public reply tied to one review thread.
- All public GitHub replies are in English; the report to the user uses their
  language.

## Workflow

### 1. Identify the PR and viewer

If the user provided a PR number or URL, use it. Otherwise detect the PR on the
current branch:

```bash
gh pr view --json number,url,title,author,headRefName,headRefOid,baseRefName
```

Resolve and store `<PR_NUMBER>`, `<PR_URL>`, `<OWNER/REPO>`, `<HEAD_SHA>`, and
the authenticated viewer login. If the PR author is the viewer, stop and route
to `skills/address-review/SKILL.md`.

If no PR is open on the current branch, ask the user for its number or URL.

### 2. Fetch only your review threads

Run the repository helper, which returns resolved and unresolved threads where
the viewer left a comment, plus the viewer's pending-review state:

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
PR_HOST=$(gh repo view --json url -q .url 2>/dev/null | sed -n 's#^https\?://\([^/]*\)/.*#\1#p')
GH_HOST="${PR_HOST:-github.com}" bash "$PROJECT_ROOT/scripts/get-viewer-threads" \
  "<PR_NUMBER>" "<OWNER/REPO>"
```

If `pending_review` is non-null, stop: submit or discard that pending review
before verifying its threads.

Keep `COMMENT_ID`, `THREAD_ID`, original comment, path, line, `isResolved`,
`isOutdated`, author's reply, and current PR head for every item.

### 3. Establish current-code context

Verify that the checkout or fetched ref corresponds to `<HEAD_SHA>`. If the PR
branch is not checked out, fetch it without mixing unrelated working-tree
changes and inspect files from the PR ref:

```bash
git fetch origin "pull/<PR_NUMBER>/head:refs/remotes/origin/pr/<PR_NUMBER>"
```

Read the PR description, latest commits, changed files, and relevant full files
before evaluating comments. Use the current line when the thread moved. For an
outdated thread, search the file for a symbol, identifier, or behavior anchor
from the original comment. If the anchor is absent, classify it as `outdated`.

### 4. Evaluate threads sequentially

Process one thread at a time. For each thread:

1. Show the original concern, file/line, resolution state, and author's reply.
2. Read the current implementation at that location and its surrounding
   function or callers as needed.
3. Compare the implementation to the actual invariant or behavior requested,
   not just to the exact code change you suggested.
4. Run the smallest relevant check when code execution is needed to decide.
5. Record one verdict and its evidence before moving to the next thread.

Use [`../../references/evaluation-rubric.md`](../../references/evaluation-rubric.md)
for the verdict definitions:

| Verdict | Meaning | Action |
|---------|---------|--------|
| ✅ `fixed` | The concern is correctly addressed | Report only |
| ⚠️ `partial` | Part of the concern is addressed, but a concrete gap remains | Reply with the gap |
| ❌ `not-fixed` | The concern remains or the fix is incorrect | Reply with what is needed |
| ❓ `needs-look` | Code alone cannot establish correctness | Report to user, no reply |
| 🔇 `outdated` | The old location and behavior anchor no longer exist | Report only |

Use this per-thread record internally:

```text
🔍 Thread <N> — <path>:<line> — <author>
Original concern: <specific concern>
Current evidence: <what the latest code does>
Verdict: <emoji> <verdict>
Action: <reported / replied / reopened and replied>
```

### 5. Reply to unresolved concerns

For `partial` or `not-fixed` threads:

- If unresolved, reply on the existing thread.
- If resolved but demonstrably wrong, reopen it first, then reply.
- Never reopen a thread merely because the implementation differs from your
  suggestion.

Reopen only when required:

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
GH_HOST="${PR_HOST:-github.com}" bash "$PROJECT_ROOT/scripts/reopen-pr-thread" "<THREAD_ID>"
```

Reply in English, quoting only the specific original concern:

```markdown
> [specific sentence from the original review comment]

Still needs attention: [what is missing or incorrect, with concrete evidence]
```

Post one reply per thread. Keep it concise, explain the impact, and state the
next correction or verification needed. Record the reply URL or failure.

### 6. Final verification report

After all threads are evaluated and eligible replies are posted, report in this
format:

```markdown
## Verification report

### Fixed correctly
- ✅ <path>:<line> — <why the concern is resolved>

### Actionable findings
- ⚠️ <path>:<line> — <partial gap> — confidence: <high|medium|low>
- ❌ <path>:<line> — <remaining defect> — confidence: <high|medium|low>

### Coverage
- PR: <PR_URL>
- Threads evaluated: <N>
- Checks run: <commands or "none">
- Replied: <N>
- Reopened: <N>
- Skipped: <needs-look/outdated items and reason>

### Verdict
<Ready to merge | Ready with fixes | Not ready>

### Residual risk
<What was not verified and why, or "None">.
```

Use `Not ready` when at least one high-confidence `not-fixed` or blocking
`partial` concern remains. Use `Ready with fixes` when only non-blocking gaps
remain. Use `Ready to merge` only when every actionable concern is fixed and
no material verification gap remains.

## Reference

Read [`../../references/evaluation-rubric.md`](../../references/evaluation-rubric.md)
before assigning verdicts. Use [`../../references/run-tests.md`](../../references/run-tests.md)
only when a test or check is needed to establish whether a fix works.
