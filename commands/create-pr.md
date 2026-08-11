---
description: Create a PR on GitHub against main, comment on Jira, and notify Slack
---

## Goal

Create a Pull Request for the current branch against `main`, automatically generating the title and description from the Jira ticket and the branch diff.

## Steps

### 1. Check status

```bash
git branch --show-current
git status --short
```

If there are uncommitted changes, warn the user and ask if they want to proceed anyway.

Verify the branch is pushed to origin:
```bash
git ls-remote --exit-code origin "$(git branch --show-current)" 2>/dev/null || echo "NOT_PUSHED"
```

If not pushed:
```bash
git push -u origin "$(git branch --show-current)"
```

### 2. Extract the Jira ticket and fetch details

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
KEY=$(extract_jira_key "$(git branch --show-current)")
```

If `<KEY>` is non-empty, fetch the ticket's title and description using the MCP tool `getJiraIssue` with `issueKey: "<KEY>"` and `fields: ["summary", "description"]`.

### 3. Analyze the diff against the base branch

Fetch the full diff against main:
```bash
git diff main...HEAD --stat
git log main..HEAD --pretty=format:"%s" --no-merges
git diff main...HEAD -- . ':(exclude)*.lock' ':(exclude)package-lock.json'
```

Analyze the diff to identify:
- Which files were added, modified, removed
- The type of change (bug fix, new feature, refactoring, etc.)
- Whether there are breaking changes
- Whether tests were added

**Don't trust the diff hunk alone** for this — when it doesn't show the full function body, type definitions, or imports needed to judge the change, read the full file locally (it's already checked out on this branch, no need for the GitHub API).

### 4. Auto-generate title and description

**Title**: `[<KEY>] <Jira ticket title>` — if there's no ticket, use the most recent commit title.

**Description**: fill in the following template based on the diff analysis and Jira ticket details. Don't leave sections with generic placeholders — each section must reflect the actual changes found in the diff.

```markdown
## Summary
[1-3 sentences explaining what this PR does and why, based on the Jira title/description and the diff]

## Changes
- [Bulleted list of specific changes found in the diff]
- [Group related changes together]
- [Specify what was added, modified, or removed]

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring (no functional changes)

## Testing
- [ ] [Describe the testing performed, detected from test files in the diff]
- [ ] [List any new tests added]
- [ ] [Notes on any manual testing steps]

## Breaking Changes
[If applicable, describe breaking changes and migration steps; otherwise write "None"]

## Related Issues
Fixes <JIRA_BASE_URL>/browse/<KEY>

## Screenshots
[If applicable, add screenshots; otherwise remove this section]

## Additional Context
[Any other context useful for reviewers, or remove this section if not needed]
```

Automatically check the correct checkbox in "Type of Change" based on the analyzed diff.

### 5. Ask for a screenshot (only if the change is visual)

Based on the diff analysis from step 3, decide whether this change is screenshot-worthy: new or modified UI (components, pages, styles, layouts) — yes; pure backend/core logic, refactoring, config, or non-visual bug fixes — no.

If it's screenshot-worthy, ask the user:
```
📸 This looks like a UI change — got a screenshot of the result? (paste an image URL, or say no to skip)
```

- If they give a URL, embed it in the `## Screenshots` section: `![screenshot](<URL>)`.
- If they say no or have none, leave the `## Screenshots` section as `_No screenshot provided._`.
- If they only have a local file path, note that `gh`/the API can't upload images — tell them to drag the file into the PR description on GitHub after it's created, then move on.

If the change isn't screenshot-worthy, skip this step silently and remove the `## Screenshots` section from the template.

### 6. Create the PR

```bash
gh pr create \
  --base main \
  --title "<generated title>" \
  --body "<generated description>"
```

Capture the PR URL from the output.

**If the command fails with a TLS/certificate error** (e.g. `tls: failed to verify certificate: x509: ...`), use this fallback:
```bash
OWNER_REPO=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+)(\.git)?$#\1#')
curl -sf \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  -X POST "https://api.github.com/repos/$OWNER_REPO/pulls" \
  -d "{\"title\":\"<generated title>\",\"body\":\"<generated description>\",\"head\":\"$(git branch --show-current)\",\"base\":\"main\"}" \
  | jq '{number, url: .html_url}'
```

### 6a. Log the PR link to Obsidian (optional)

Only if a Jira ticket was found in step 2 (`<KEY>` is set). Follow `references/obsidian-log.md`:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_set_pr "$PLAN_FILE" "<PR_URL>"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — PR opened: <PR_URL>"
fi
```

### 7. Jira comment (always)

If there's a ticket, **always** leave a comment on the Jira issue:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
```

Use the MCP tool `addCommentToJiraIssue` with `issueKey: "<KEY>"` and `comment: "🔍 PR opened: <PR_URL>"`.

**If the MCP call fails**, use the `jira_comment` helper as fallback:
```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
jira_comment "<KEY>" "🔍 PR opened: <PR_URL>"
```

### 8. Jira transition (optional)

If there's a ticket **and** `JIRA_IN_REVIEW_ID` is configured and not empty, also transition the ticket using `references/jira-transition.md` with:
- `<TRANSITION_ID>` = `$JIRA_IN_REVIEW_ID`
- `<COMMENT_TEXT>` = (empty/skip comment in jira-transition, we already left one in step 7)

If the transition fails or `JIRA_IN_REVIEW_ID` is not configured, **continue anyway** — the comment was already left in step 7.

### 9. Slack notification

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
slack_notify "🔍 PR opened: *<PR_TITLE>*\n🔗 <PR_URL>\n🎫 <$JIRA_BASE_URL/browse/<KEY>|<KEY>> → *In Review*"
```

If there's no Jira ticket: `🔍 PR opened: *<PR_TITLE>*\n🔗 <PR_URL>`

If Slack notification fails, **continue anyway** — the PR and Jira comment were already done.

### 11. Confirmation

Show the user:
- PR created: `<PR_URL>`
- Jira comment: left on `<KEY>` (if ticket found)
- Ticket `<KEY>` → In Review (if transition succeeded; otherwise note it was skipped)
- Slack: notified (or "notification failed, but PR and comment are done")
- Obsidian: PR link recorded (or "skipped, no vault configured / no linked ticket")
- → Suggest the next step: `/thebous-os:review-pr` to get it reviewed
