---
name: verify-resolved
description: Verify that PR review comments you left on someone else's PR were correctly addressed — checks each thread where you commented, reads the current code, and reports whether the fix is correct, partial, or missing
---

## Goal

You left review comments on someone else's PR and want to verify the fixes. This workflow checks each thread where you commented, reads the current code, and reports whether the fix addresses your concern, is partial, or is missing.

**Do not use this workflow if:**
- You are fixing PR feedback on *your own* PR (use `address-review` instead)
- You need a full initial code review (use `review-pr` instead)

## Steps

### 1. Resolve PR and Viewer

If you didn't provide a PR number, detect from the current branch:

```bash
PR_NUMBER=$(gh pr view --json number -q .number)
```

If you provided a PR URL (e.g., `https://github.com/OWNER/REPO/pull/123`), extract:
- `HOST` — `github.com` or your enterprise host
- `OWNER/REPO` — for fork→upstream support
- PR number

Detect the GitHub host:

```bash
PR_HOST=$(gh repo view --json url -q .url 2>/dev/null | sed -n 's#^https\?://\([^/]*\)/.*#\1#p')
echo "Verifying on PR #$PR_NUMBER (host: $PR_HOST)"
```

### 2. Fetch Your Threads

Run this to fetch all review threads where you have commented:

```bash
SKILL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
GH_HOST="${PR_HOST:-github.com}" bash "$SKILL_DIR/scripts/get-viewer-threads" "$PR_NUMBER"
```

This returns a JSON object with:
- `pending_review` — your unsubmitted (PENDING) review node ID, or null
- `viewer_threads` — array of threads where you commented
- `viewer_login` — your GitHub login

**STOP if `pending_review` is non-null.** You have an unsubmitted review that must be submitted or discarded first.

### 3. Evaluate Each Thread

For each thread, follow `references/evaluation-rubric.md` to determine the verdict:

| Verdict | Meaning | Action |
|---------|---------|--------|
| ✅ `fixed` | The code now correctly addresses your concern | Report as fixed |
| ⚠️ `partial` | Partially addressed — some aspects still missing | Reply with what remains |
| ❌ `not-fixed` | Your concern was not addressed | Reply explaining what's still needed |
| ❓ `needs-look` | Can't determine from code alone | Surface to user |
| 🔇 `outdated` | The code at this location no longer exists | Report as stale |

**Read the current code** at the thread's file and line before deciding. For outdated threads, search the file for an anchor (a symbol or identifier from your comment) to find the moved code.

**Recover the author's intent:** If the fix looks intentional but different from what you suggested, run:

```bash
git log -p -- <file> | grep -A5 -B5 <changed-line>
git blame <file> | grep <line>
```

The author may have chosen a different approach with good reason — read the commit message.

### 4. Act on Verdicts

For threads that are **not fixed** or **partially fixed**:

- **If unresolved on GitHub:** reply on the thread explaining what's still missing
- **If resolved but fix is wrong:** reply AND reopen the thread

For **fixed** and **outdated**: just report, do not reply.

**Reply format** (quote the specific concern):

```markdown
> [your original concern, specific sentence]

Still needs attention: [what's missing or wrong with the current fix]
```

**To reopen a thread that was resolved but the fix is wrong:**

```bash
SKILL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
GH_HOST="${PR_HOST:-github.com}" bash "$SKILL_DIR/scripts/reopen-pr-thread" "$THREAD_ID"
```

Then reply with the details (reopening alone doesn't tell the author what's missing).

### 5. Summary Report

Present a structured report of all threads evaluated:

```
✅ Fixed correctly (N threads): [per-thread summary]
❌ Not fixed (N threads): [per-thread summary — what's still missing]
⚠️ Partially fixed (N threads): [per-thread summary]
🔇 Outdated / N/A (N threads): [per-thread summary]

Replied on N threads.
Reopened N threads that were resolved but not fixed.
```

## Common Pitfalls to Avoid

- Don't reply on threads where the fix is already correct — only reply when something is still wrong or partial.
- Don't reopen threads unnecessarily. Only reopen when the fix demonstrably does not address your original concern.
- Don't assume the author didn't read your comment — they may have chosen a different approach. Check `git log` and commit messages first.
- Don't get stuck if a thread is outdated. Search the file for an anchor to find where the code moved, then evaluate the new location.
