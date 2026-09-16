---
name: verify-resolved
description: Use when revalidating review comments you left on someone else's pull request after new commits or author replies
---

## Goal

Revalidate every review thread where you commented on someone else's PR after
the author pushed changes. Check the current code and the author's response,
classify each concern, and communicate every verdict one thread at a time.

**Do not use this workflow if:**
- You are fixing feedback on your own PR — use `address-review`.
- You are performing the first full review of a PR — use `review-pr-multiharness`
  or `review-pr-multiharness-ponytail`.

## Rules

- Review the latest PR head, not the old diff hunk.
- Read the full relevant function, interface, or caller chain before deciding.
- Trust a technically valid alternative implementation even when it differs
  from your original suggestion.
- Treat the author's reply as context, not as evidence that the concern is fixed.
- Try to falsify the original concern before assigning `not-fixed` or `partial`.
- Reply to every thread regardless of verdict: `fixed`, `partial`, `not-fixed`,
  `needs-look`, and `outdated`.
- Never reopen a thread merely to reply to a `fixed`, `needs-look`, or `outdated`
  verdict.
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

Read [`../../references/review-evidence-contract.md`](../../references/review-evidence-contract.md)
before assigning a verdict. Apply its required record and evidence rules:

- `fixed` requires current-code evidence that the concern is satisfied.
- `partial` or `not-fixed` requires a concrete remaining gap tied to the original concern.
- Missing evidence, an unrun check, or unverified external behavior is `needs-look`, not a defect.
- The author's reply alone is not evidence.
- If the current anchor cannot be established, use `outdated` only when the original behavior anchor is gone; otherwise use `needs-look`.

Use [`../../references/evaluation-rubric.md`](../../references/evaluation-rubric.md)
for the verdict definitions:

| Verdict | Meaning | Action |
|---------|---------|--------|
| ✅ `fixed` | The concern is correctly addressed | Reply confirming the evidence |
| ⚠️ `partial` | Part of the concern is addressed, but a concrete gap remains | Reply with the gap |
| ❌ `not-fixed` | The concern remains or the fix is incorrect | Reply with what is needed |
| ❓ `needs-look` | Code alone cannot establish correctness | Reply with the missing evidence or check |
| 🔇 `outdated` | The old location and behavior anchor no longer exist | Reply explaining why the concern is outdated |

Use this per-thread record internally:

```text
🔍 Thread <N> — <path>:<line> — <author>
Original concern: <specific concern>
Current evidence: <what the latest code does>
Check: <command, test, trace, or "not run">
Verdict: <emoji> <verdict>
Confidence: <high|medium|low>
Action: <reported / replied / reopened and replied>
```

### 5. Reply to every thread

Reply once on the existing thread for every verdict, even when the concern is
fixed, outdated, or cannot be established from code alone.

- For `partial` or `not-fixed`, if the thread is resolved but demonstrably wrong,
  reopen it first, then reply.
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

fixed: Confirmed resolved because [concrete evidence].
partial: Still needs attention: [what is missing, with concrete evidence].
not-fixed: Still needs attention: [what remains incorrect, with concrete evidence].
needs-look: Unable to verify from the current evidence; [specific check or evidence needed].
outdated: This concern is outdated because [current code or behavior anchor].
```

Post exactly one reply per thread. Keep it concise, explain the evidence or
limitation, and state the next correction or verification needed when relevant.
Record the reply URL or failure.

### 6. Final verification report

After all threads are evaluated and replies are posted, report in this
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
