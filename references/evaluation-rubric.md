# Evaluation Rubric — ce-verify-resolved

Apply this to each thread where the viewer (you) left a comment. The goal is to determine whether the PR author's fix correctly addresses the concern you raised.

## What to Verify

For each thread, you have:
- **Your comment** — what you originally asked for
- **The thread's location** — file, line, and diff context
- **The current code** — what's now at that location (read it!)
- **The author's reply** (if any) — what the author said they did
- **`isOutdated`** — whether the diff hunk shifted since the thread was opened
- **`isResolved`** — whether someone marked the thread as resolved

## Default to trusting the fix

If the code at the thread location now addresses your concern — even if the approach differs from what you suggested — mark it as `fixed`. The author may have chosen a better approach than your suggestion. "Not what I said" is not a reason to flag it.

## How Deep to Read

- **Simple fix** (rename, null check, obvious guard, typo) → read the line, verify it's correct, move on.
- **Logic fix** (changed condition, added branch, different return) → read the surrounding function, check it handles the edge case you flagged.
- **Structural fix** (refactored method, extracted class, changed architecture) → read the full change if small; otherwise read the interface and the callers to verify contract is preserved.
- **Outdated thread** → search the same file for an anchor (symbol, identifier from your comment). If found, re-evaluate at that location. If not found → `outdated` verdict.

## Verdicts

### ✅ `fixed` — the concern is addressed

The code now handles the issue you raised. The approach may differ from what you suggested, but the concern is resolved.

Example: You asked for a null check on `user.address`. The code now wraps the access in an optional chain `user?.address?.city`. Different syntax, same intent → `fixed`.

### ⚠️ `partial` — some aspects addressed, some not

The author addressed part of your concern but left gaps. Be specific about what remains.

Example: You asked for two things: "validate email format AND return a 400 on invalid." The author added the validation but returns a 500 instead of 400. → `partial`.

Reply with exactly what's still missing. Quote your original concern and point to the unaddressed part.

### ❌ `not-fixed` — the concern was not addressed

The code at the thread location is unchanged, or the change doesn't actually address the concern.

Before marking `not-fixed`, make sure you're looking at the latest code on the PR branch. The author may have pushed new commits after your review. Use `git fetch` or check the PR's files tab.

Reply with what's still needed. Quote your original concern and show the code that still needs changing.

### ❓ `needs-look` — can't determine from code alone

The fix touches something you can't fully evaluate without running it, testing it, or knowing business context. Examples:
- The fix involves a complex payment calculation
- It depends on external API behavior
- It's in a domain you don't know well

Surface to the user in the summary report. Do NOT reply on the thread.

### 🔇 `outdated` — the code at this location no longer exists

The file or line referenced by the thread has changed or been removed. You searched the file for an anchor from your comment and didn't find it. The concern may or may not still apply — you can't tell from this thread alone.

Report as stale. Do not reply.

## Reply/Reopen Rules

| Verdict | Thread Status | Action |
|---------|---------------|--------|
| `fixed` | any | Nothing — report only |
| `partial` | unresolved | Reply with what's missing |
| `partial` | resolved | Reply + reopen, then reply |
| `not-fixed` | unresolved | Reply with what's needed |
| `not-fixed` | resolved | Reply + reopen |
| `needs-look` | any | Report to user, no PR action |
| `outdated` | any | Report only |

**Reply format** — always quote the specific part of your original concern, not the whole comment:

```markdown
> [specific sentence from your original review comment]

Still needs attention: [what's missing or wrong]
```

For `partial` verdicts, be precise about what was done vs. what remains:
```markdown
> We should validate the email format and return a 400 on invalid input.

The email format validation is there ✓, but it still returns a 500 instead of 400 (line 42: `throw new Error(...)` instead of `res.status(400).json(...)`).
```
