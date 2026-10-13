---
name: address-review
description: Assess code review comments against code evidence, fix confirmed issues on your PR after user approval, reply to every comment on GitHub, and update documentation for a linked Jira or Notion task
---

## Goal

You received code review feedback on your PR. Assess each claim against the current code before presenting it to the user. Propose fixes for confirmed issues, apply them after approval, and reply on GitHub with the outcome for every item, including refuted or unverified claims. No code is changed without your explicit permission.

**Use the resolution definitions in [the shared evaluation rubric](../../references/evaluation-rubric.md)** to categorize each outcome: `fixed`, `partial`, `not-fixed`, `needs-look`, or `outdated`. This ensures consistent reply messaging and clear communication back to reviewers.

## Steps

### 1. Identify the PR

If the user passed a PR URL when invoking the command, use it.

Otherwise, detect the PR from the current branch:
```bash
gh pr view --json number,title,url,headRefName 2>/dev/null
```

**If the command fails with a TLS/certificate error**, use this fallback:
```bash
OWNER_REPO=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+)(\.git)?$#\1#')
BRANCH=$(git branch --show-current)
curl -sf -H "Authorization: Bearer $(gh auth token)" \
  "https://api.github.com/repos/$OWNER_REPO/pulls?head=$(echo $OWNER_REPO | cut -d/ -f1):$BRANCH&state=open" \
  | jq '.[0] | {number, title, url: .html_url, headRefName: .head.ref}'
```

If there's no open PR for the current branch, ask the user to pass the URL explicitly.

### 1a. Resolve the linked task (optional)

Use `references/task-context.md` and its provider-neutral task reference with the
PR branch, title and body:

```bash
source "scripts/helpers.sh"
if ! TASK_REF=$(resolve_work_item_ref "<headRefName, title, or body>" 2>/tmp/resolve.err); then
  if grep -q "ambiguous" /tmp/resolve.err; then
    # ask user whether Jira or Notion is the source of truth, then re-resolve with `jira:...` or `notion:...`
  else
    TASK_REF=""
  fi
fi
```

Store the resulting `TaskRef` if non-empty. Jira and Notion are independent
providers; if both references are present, ask which one is the source of truth.
If no task resolves, continue without task context and skip provider-aware
Obsidian logging.

### 2. Ask about worktree usage

Ask the user:
```
Would you like to work in an isolated worktree, or use the current branch?

• **Worktree** (isolated): Creates a fresh worktree for the review cycle; safer, no local state interference
• **Current branch** (default): Work on the current checked-out branch directly
```

Wait for the user's choice. Default to current branch if they don't specify.

### 3. Switch to isolated worktree (if chosen)

If the user chose worktree, create it with:
```bash
wt switch pr:${PR_NUMBER}
```

This creates a dedicated worktree for addressing the review. **Do not create another worktree inside ce-code-review if step 5 delegates to it** — pass context that the worktree was already created.

If the user chose current branch, skip to step 4.

### 4. Fetch the review comments

```bash
gh pr view <NUMBER> --json reviews,comments \
  --jq '.reviews[] | select(.state == "CHANGES_REQUESTED") | {author: .author.login, body: .body}'

gh api repos/:owner/:repo/pulls/<NUMBER>/comments \
  --jq '.[] | {path: .path, line: .line, body: .body, author: .user.login}'
```

**TLS fallback**:
```bash
curl -sf -H "Authorization: Bearer $(gh auth token)" \
  "https://api.github.com/repos/$OWNER_REPO/pulls/<NUMBER>/reviews" \
  | jq '.[] | select(.state == "CHANGES_REQUESTED") | {author: .user.login, body}'

curl -sf -H "Authorization: Bearer $(gh auth token)" \
  "https://api.github.com/repos/$OWNER_REPO/pulls/<NUMBER>/comments" \
  | jq '.[] | {path, line, body, author: .user.login}'
```

Collect both general comments and inline code comments. Sort inline comments by file, then by line number (order of appearance in the PR). General (review-level) comments should be addressed first, in chronological order.

### 5. Split multi-point comments into individual items

Before building the work queue, check every comment (general or inline) for more than one distinct issue — a numbered/bulleted list, or several unrelated observations packed into one paragraph. If a comment raises multiple points, split it into separate items, one per point, each to be proposed, approved, and resolved on its own in step 5. Never bundle multiple points into a single proposal just because they arrived in the same comment.

Keep each split item tagged with the `COMMENT_ID` of the comment it came from — that's needed in step 5 to know where the reply goes.

The work queue for step 5 is built from these items, not from the raw comments: a comment with 3 points becomes 3 queue items in order; a comment with 1 point stays 1 item.

### 6. Set the approach with receiving-code-review

If the `superpowers:receiving-code-review` skill is available in the workspace, invoke it once via the Skill tool to set the approach: technical rigor, verify before implementing, no performative agreement. Apply these principles manually to each item in the loop in step 5 — don't re-invoke the skill on every iteration.

If it's not available, proceed anyway with the same principle: assess whether the item is technically sound before proposing a fix.

### 7. Resolve items one at a time

**Never change code without the user's explicit permission, and never batch multiple items into one fix.** Work through the queue built in step 5 strictly one item at a time:

1. Verify the reviewer's claim in the current code **before presenting an assessment or fix to the user**. Treat the comment as a hypothesis, not as evidence. Read the full surrounding implementation and follow the relevant callers, guards, types, configuration, and dependencies to establish whether the alleged failure is reachable. Actively look for code that contradicts the claim, including validation or guarantees outside the quoted lines.

   Record a verification result distinct from the resolution verdict below:
   - **Confirmed**: concrete code evidence establishes the triggering conditions, reachable execution path, and actual failure or violated contract. Cite file and line references and explain the causal chain. Use a focused reproduction or existing test when helpful; code evidence may suffice when the failure follows directly from the implementation.
   - **Refuted**: concrete code evidence contradicts the claim. Cite the guard, invariant, or behavior that prevents the alleged failure, and explain why it applies to this path.
   - **Unverified**: the evidence is incomplete or depends on unavailable code, runtime behavior, or assumptions. State exactly what is missing and how to verify it. Absence of proof is neither confirmation nor refutation.

   A reviewer's confidence, a plausible hypothetical input, a type assertion, or an assumed library guarantee does not establish runtime behavior. Keep investigating while relevant local evidence is available; if the missing evidence cannot be obtained, retain `unverified` instead of inventing certainty.

2. Present the item, verification result, and supporting evidence to the user. If the item came from a split multi-point comment, show only that point's text. For a **confirmed** issue, propose a concrete fix tied to the demonstrated failure. For a **refuted** issue, explain why no fix is warranted. For an **unverified** issue, explain the missing evidence and next verification step; defer a fix until the issue is confirmed.

   For every confirmed issue, include these three indicators in the response to the user:
   - **Criticality — 🟢 low, 🟡 medium, or 🔴 high**: assess the demonstrated impact and reachability. Use green for limited impact with a straightforward workaround, yellow for meaningful functional failures affecting a limited path or set of users, and red for serious security exposure, data loss/corruption, or blocked essential flows. Briefly justify the rating from the code evidence; severity is independent of fix effort.
   - **⏱️ Fix time**: give an approximate range for implementing and verifying the proposed fix, such as `15–30 min` or `1–2 hours`. Exclude waiting for approval or review. Base the estimate on the inspected scope and state any material uncertainty.
   - **🧩 Code scope**: estimate changed lines and affected files as ranges, including necessary tests or migrations when applicable, such as `~10–25 lines across 1–2 files`. Identify any wider change that makes the estimate uncertain. Prefer the smallest fix that fully addresses the confirmed failure.

   Keep estimates proportional to the available evidence. If time or code scope cannot yet be estimated, say what must be inspected first. For refuted claims, report criticality and fix estimates as not applicable; for unverified claims, report them as undetermined pending evidence. A missing proof must not look like a green, low-risk issue.

   ```
   📝 Comment on <file>:<line> (by <author>)
   "<item text>"
   🔎 Verification: <confirmed | refuted | unverified>
   Evidence: <file:line references, reachable behavior or counterevidence, and any remaining gaps>
   💡 Proposal / next step: <fix, reason to keep the code, or verification needed>
   <🟢 | 🟡 | 🔴> Criticality: <low | medium | high> — <brief impact-based reason>
   ⏱️ Fix time: <approximate implementation + verification range>
   🧩 Code scope: <approximate changed-line range and affected files>
   ```

   For a proposed fix, ask whether the user approves it. Any new or renamed identifier must follow `references/naming-conventions-code.md` (in the plugin root), plus `references/naming-conventions-db.md` for schema/migration changes or `references/naming-conventions-nextjs.md` for Next.js App Router files. Check library-mandated names and existing sibling patterns before treating a name as a violation.

3. Wait for the user's reply. Depending on what they say:
   - **Approves**: apply the fix to the code
   - **Modifies the proposal**: adapt the fix per their instructions, then apply it
   - **Disagrees / wants something else**: discuss until you converge on an action (which may also be "don't change anything")

4. Determine the resolution verdict using the definitions in [the shared evaluation rubric](../../references/evaluation-rubric.md). That rubric also serves `verify-resolved`; for this skill, use the reply policy in step 7 below for every verdict, including `fixed`, `needs-look`, and `outdated`:

   | Verdict | Meaning | Reply content |
   |---------|---------|---------------|
   | ✅ `fixed` | The code now correctly addresses the concern | Say what changed and how it resolves the concern |
   | ⚠️ `partial` | Partially addressed — some aspects still missing | Explain what was addressed and what remains |
   | ❌ `not-fixed` | No fix was applied, or the concern remains | Explain why no change is warranted, or what is still needed |
   | ❓ `needs-look` | Can't determine from code alone | State what is unclear and what information or investigation is needed |
   | 🔇 `outdated` | The code at this location no longer exists | Explain why the comment no longer applies |

   Determine the resolution from the current code evidence, even when the implementation differs from the proposed fix. Mark `fixed` only when the confirmed failure is now addressed. Retain `needs-look` for an unverified claim. For a refuted claim, use `not-fixed` with an explanation that no change is warranted and cite the counterevidence; do not describe it as an outstanding bug.

5. Write and post a concise GitHub reply for **every queue item**, whatever its verdict. In particular, a `fixed` item must receive a reply that tells the reviewer what changed; recording the result only in the conversation with the user is not enough. If one original comment was split into multiple items, reply to its thread for each item so every analyzed concern has a clear outcome.

   Use the verdict-specific content from the table. For a refuted claim, reply with `🔎 Refuted — <counterevidence and why no change is warranted>`. For an unresolved `partial` or `not-fixed` issue, quote the relevant part of the original concern and explain what remains. For `needs-look`, be explicit about the missing information or next investigation. For `outdated`, briefly explain why the comment no longer applies.

   Example for a fixed item:
   ```text
   ✅ Fixed — Added a null check before accessing the field, so this path no longer throws when the value is absent.
   ```

   Post the reply in the comment's GitHub thread:
   ```bash
   SKILL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
   echo "[reply body]" | GH_HOST="${PR_HOST:-github.com}" bash "$SKILL_DIR/scripts/reply-to-pr-thread" "$THREAD_ID"
   ```

6. Record the verdict for this item against its `COMMENT_ID` and confirm that the GitHub reply was posted. If posting fails, report the failure and retry only after fixing the cause; do not mark the item fully handled until the reply succeeds.

7. For fixes applied (`fixed` verdict), also record the status line:
   ```
   ✅ Fixed — <brief description of what changed>
   ```

8. Move to the next item in the queue.

Continue through the queue until every item has a recorded verdict and a successful GitHub reply.

### 8. Shared Helpers

Before starting, note these shared references you'll use during the workflow:
- [Shared evaluation rubric](../../references/evaluation-rubric.md) — resolution definitions; step 7 defines this skill's verification and reply policy
- `references/run-tests.md` — how to find and run tests (step 9)
- `references/naming-conventions-{code,db,nextjs}.md` — naming rules for fixes

### 9. Run the tests

If code changes were applied during the cycle, read `references/run-tests.md` (in the plugin root) and follow the instructions to find and run the project's tests/lint/checks.

If no comment required code changes, skip this step.

### 10. Analyze the overall diff and identify docs to update

After resolving all the comments in the cycle:
```bash
git diff HEAD --name-only
```

For each changed file, assess whether the change is logically significant (new signature, changed behavior, removed something public). If so, look for related documentation:

**Local docs** — check if a `docs/` folder exists in the repo:
```bash
ls docs/ 2>/dev/null && grep -rl "<changed-file-name>" docs/ 2>/dev/null
```

**Confluence** — load the credentials and check if `CONFLUENCE_PARENT_URL` is configured:
```bash
source "scripts/helpers.sh"
if [ -f "$ENV_FILE" ]; then load_env; fi
```

If `CONFLUENCE_PARENT_URL` is not empty, use the MCP tool `searchConfluenceUsingCql`:
```
ancestor = <PARENT_PAGE_ID> AND text ~ "<changed-file>"
```

### 11. Ask for confirmation before updating docs

If candidates were found (local or Confluence), show the user:
```
📄 These documents might need updating:
- [local] docs/auth.md
- [Confluence] Authentication flow → <url>

Do you want to update them? (yes/no/list which ones)
```

Wait for a reply before proceeding.

### 12. Update the documentation

**Local docs**: edit the `.md` files in the `docs/` folder directly with the updated information. Show the diff before saving.

**Confluence**: use the MCP tool `updateConfluencePage` for each confirmed page.

If no document was found or the user declines, skip this step silently.

### 13. Log to Obsidian (optional)

Only if `TASK_REF` was resolved in step 1a. Follow `references/obsidian-log.md`
and use the provider-aware helper. Summarize the resolved items
(`<RESOLUTION_SUMMARY>`, e.g. "3 comments addressed: 2 fixed, 1 outdated"):

```bash
source "scripts/helpers.sh"
load_env
obsidian_log_task "${OBSIDIAN_VAULT_PATH:-}" "<TASK_REF>" "address-review.md" \
  "<RESOLUTION_SUMMARY>" "<PROVIDER>:<EXTERNAL_ID> — addressed review comments"
```

### 14. Confirmation

Show the user:
- Fixes applied for the review comments
- Tests: `<list of scripts>` — all green (if run)
- Replies posted on the PR with their emoji statuses
- Documentation updated: `<list of files/pages>` (if applicable)
- Obsidian: logged (or "skipped, no vault configured / no linked task")
- Suggest pushing the branch with `git push`

### 15. Offer to request a new review

After all approved fixes, tests, documentation updates, and replies are
handled, identify the reviewer(s) who requested changes from the review data
collected in step 4. If there is exactly one reviewer, ask:

```
🔁 The requested changes are applied. Do you want me to request a new review from <REVIEWER>?
```

If there are multiple reviewers, show them and ask which reviewer(s) should be
notified. If there is no identifiable reviewer, ask the user to provide the
GitHub username or team; do not guess.

Wait for the user's answer. If they decline, finish without any GitHub action.
If they agree, verify that the current branch is pushed. If it is not pushed,
ask for confirmation before running:

```bash
git push
```

After the updated commits are available remotely, request the new review:

```bash
gh pr edit <NUMBER> --add-reviewer "<REVIEWER>"
```

For a team reviewer, pass the team slug supported by `gh`. Report whether the
new review request succeeded or failed. If GitHub reports that the reviewer is
already requested, report that no new request was sent and suggest using the
GitHub re-request-review action manually.

## Style for reply prose

**All public replies on GitHub must be in English** — regardless of the language used in your conversation with the user.

- **Step 7 (Reply to reviewer)** — **English only**. Status emoji + brief description + (if needed) why or how.
- **Conversation with the user** — present in the language they used.

For all GitHub replies: be concise, one line when possible (3 lines max). Format: `<emoji> <Status> — <brief reason or what changed>`
