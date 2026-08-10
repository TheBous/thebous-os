---
description: Resolve code review comments on your PR — implement fixes, apply only after user approval, reply on GitHub, then update documentation
---

## Goal

You received code review feedback on your PR. This workflow guides you through resolving each comment one at a time: read the comment, propose a fix, wait for approval, apply it, then reply on GitHub with a clear verdict. No code is changed without your explicit permission.

**Use the evaluation rubric** (`references/evaluation-rubric.md`) to categorize each fix: `fixed`, `partial`, `not-fixed`, `needs-look`, or `outdated`. This ensures consistent reply messaging and clear communication back to reviewers.

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

1. Show the item:
   ```
   📝 Comment on <file>:<line> (by <author>)
   "<item text>"
   ```
   If this item came from a split multi-point comment, say so and show only that point's text, not the whole original comment.

2. Analyze the item and propose a concrete fix. Read the full file locally around `<file>:<line>` — not just the snippet quoted in the comment — before proposing anything. The comment alone rarely shows the surrounding function body, type definitions, or imports needed to judge the fix correctly. Any new or renamed identifier in the fix must follow `references/naming-conventions-code.md` (in the plugin root) — plus `references/naming-conventions-db.md` for schema/migration changes or `references/naming-conventions-nextjs.md` for Next.js App Router files. Check for a library-mandated name or an existing sibling pattern before treating something as a violation.
   ```
   💡 Proposal: <description of the change you would make>

   Sound good? Do you want to change it or do you have a different opinion?
   ```

3. Wait for the user's reply. Depending on what they say:
   - **Approves**: apply the fix to the code
   - **Modifies the proposal**: adapt the fix per their instructions, then apply it
   - **Disagrees / wants something else**: discuss until you converge on an action (which may also be "don't change anything")

4. Determine the verdict using `references/evaluation-rubric.md`:

   | Verdict | Meaning | Reply? |
   |---------|---------|--------|
   | ✅ `fixed` | The code now correctly addresses the concern | No — report only |
   | ⚠️ `partial` | Partially addressed — some aspects still missing | Yes — quote original concern, explain what remains |
   | ❌ `not-fixed` | The concern was not addressed | Yes — explain what's still needed |
   | ❓ `needs-look` | Can't determine from code alone | No — surface to user |
   | 🔇 `outdated` | The code at this location no longer exists | No — report only |

   Default to trusting the fix: if the code now addresses your concern — even if the approach differs — mark it as `fixed`. The author may have chosen a better approach than your suggestion.

5. For fixes applied (`fixed` verdict), record the status line:
   ```
   ✅ Fixed — <brief description of what changed>
   ```
   
   For partial or not-fixed verdicts, use a reply following the ce-resolve-pr-feedback pattern:
   ```markdown
   > [quote the specific sentence from the original review comment]

   Still needs attention: [what's missing or wrong with the current fix]
   ```

   Post the reply:
   ```bash
   SKILL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
   echo "[reply body]" | GH_HOST="${PR_HOST:-github.com}" bash "$SKILL_DIR/scripts/reply-to-pr-thread" "$THREAD_ID"
   ```

6. Record the verdict for this item against its `COMMENT_ID`, then move to the next item in the queue.

Continue through the queue until every item has been resolved and replied to.

### 8. Shared Helpers

Before starting, note these shared references you'll use during the workflow:
- `references/evaluation-rubric.md` — how to judge each comment's fix (step 7)
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
source "${CLAUDE_PLUGIN_DATA}/.env" 2>/dev/null
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

Only if the PR's branch matched a Jira key in step 1 (`<KEY>` is set). Follow `references/obsidian-log.md`. Summarize the resolved items (`<RESOLUTION_SUMMARY>`, e.g. "3 comments addressed: 2 fixed, 1 outdated"):

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  ADDRESS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "address-review.md")
  obsidian_append_section "$ADDRESS_FILE" "<RESOLUTION_SUMMARY>"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — addressed review comments"
fi
```

### 14. Confirmation

Show the user:
- Fixes applied for the review comments
- Tests: `<list of scripts>` — all green (if run)
- Replies posted on the PR with their emoji statuses
- Documentation updated: `<list of files/pages>` (if applicable)
- Obsidian: logged (or "skipped, no vault configured / no linked ticket")
- Suggest pushing the branch with `git push`

## Style for reply prose

**All public replies on GitHub must be in English** — regardless of the language used in your conversation with the user.

- **Step 7 (Reply to reviewer)** — **English only**. Status emoji + brief description + (if needed) why or how.
- **Conversation with the user** — present in the language they used.

For all GitHub replies: be concise, one line when possible (3 lines max). Format: `<emoji> <Status> — <brief reason or what changed>`
