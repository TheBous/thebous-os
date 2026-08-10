---
description: Merge a PR to main, transition the Jira ticket to In Staging, and notify Slack
---

## Goal

Select and merge a PR into `main`, transition the linked Jira ticket to In Staging, notify Slack.

## Steps

### 1. Identify the PR to merge

If the user specified a PR number or URL when invoking the command, use that.

Otherwise, list the open PRs created by the current user:
```bash
gh pr list --author @me --state open --json number,title,headRefName,createdAt \
  --template '{{range .}}#{{.number}} | {{.headRefName}} | {{.title}}{{"\n"}}{{end}}'
```

**If the command fails with a TLS/certificate error**, use this fallback:
```bash
OWNER_REPO=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+)(\.git)?$#\1#')
ME=$(curl -sf -H "Authorization: Bearer $(gh auth token)" https://api.github.com/user | jq -r '.login')
curl -sf -H "Authorization: Bearer $(gh auth token)" \
  "https://api.github.com/repos/$OWNER_REPO/pulls?state=open" \
  | jq --arg me "$ME" '[.[] | select(.user.login == $me)] | .[] | {number, headRefName: .head.ref, title}'
```

Show the list to the user and ask which PR they want to merge. Wait for the reply.

### 2. Fetch PR details

```bash
gh pr view <NUMBER> --json number,title,headRefName,url,body
```

**TLS fallback**:
```bash
curl -sf -H "Authorization: Bearer $(gh auth token)" \
  "https://api.github.com/repos/$OWNER_REPO/pulls/<NUMBER>" \
  | jq '{number, title, headRefName: .head.ref, url: .html_url, body}'
```

Extract:
- `headRefName`: the PR's branch
- `url`: the PR URL
- Jira key from the branch name (pattern `[A-Za-z]+-[0-9]+`, case-insensitive — branch names use a lowercase key). Uppercase the match (e.g. `dc-443` → `DC-443`) before using it as `<KEY>`.

### 3. Merge the PR

Ask the user which merge type they prefer (default: squash):
- **Squash** (default): commits unified, clean history
- **Merge**: classic merge commit
- **Rebase**: linear commits

```bash
gh pr merge <NUMBER> --squash --auto
# or --merge or --rebase depending on the choice
```

**TLS fallback**:
```bash
curl -sf -X PUT -H "Authorization: Bearer $(gh auth token)" \
  "https://api.github.com/repos/$OWNER_REPO/pulls/<NUMBER>/merge" \
  -d '{"merge_method":"squash"}'
# merge_method: "squash" | "merge" | "rebase" depending on the choice
```

### 4. Jira transition and comment

If there's a linked Jira ticket, follow `references/jira-transition.md` (in the plugin root) with:
- `<TRANSITION_ID>` = `$JIRA_IN_STAGING_ID`
- `<COMMENT_TEXT>` = `"🔀 PR #<NUMBER> merged to main: <PR_URL>"`

### 5. Slack notification

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
MERGED_BY=$(git config user.name 2>/dev/null || echo "unknown")
curl -sf -o /dev/null -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-type: application/json" \
  -d "{\"text\":\"🔀 PR #<NUMBER> merged to main\n🎫 <$JIRA_BASE_URL/browse/<KEY>|<KEY>> → *In Staging*\n👤 $MERGED_BY\n🔗 <PR_URL>\"}"
```

If there's no Jira ticket, the Slack message is: `🔀 PR #<NUMBER> merged to main — <PR_TITLE>`

### 6. Confluence documentation update (if configured)

If `CONFLUENCE_PARENT_URL` is in `.env` and not empty:

Fetch the files changed in the merged branch:
```bash
git diff main...<BRANCH_NAME> --name-only
```

Extract `PARENT_PAGE_ID` from `CONFLUENCE_PARENT_URL`:
```bash
echo "$CONFLUENCE_PARENT_URL" | grep -oP '(?<=pages/)[0-9]+'
```

Use the MCP tool `searchConfluenceUsingCql` to search for pages mentioning the changed files:
```
ancestor = <PARENT_PAGE_ID> AND text ~ "<file1>" OR text ~ "<file2>"
```

If candidates are found, show the user:
```
📄 These Confluence pages might need updating:
- <title1>: <url1>
- <title2>: <url2>

Do you want to update any of these? (yes/no/list which ones)
```

For each confirmed page, ask the user what to update and use the MCP tool `updateConfluencePage` with the modified content.

If no candidates are found or the user declines, proceed silently.

### 7. Confirmation

Show the user:
- PR #`<NUMBER>` merged
- Ticket `<KEY>` → In Staging (if applicable)
- Slack: notified
- Documentation updated: `<list of updated pages>` (if applicable)
