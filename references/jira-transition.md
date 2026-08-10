# Jira transition + comment (standard pattern)

Whenever a step needs to transition a Jira ticket and leave a comment, follow this pattern exactly. Always do both — never merge/branch/PR without leaving the Jira comment, even on the fallback path.

Inputs needed from the calling step: `<KEY>` (the Jira ticket key), `<TRANSITION_ID>` (the `.env` variable to use, e.g. `$JIRA_IN_PROGRESS_ID`), `<COMMENT_TEXT>` (the comment body).

1. Load credentials:
```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
```

2. Try the MCP tools first:
- `transitionJiraIssue` with `issueKey: "<KEY>"` and `transitionId: "<TRANSITION_ID>"`
- `addCommentToJiraIssue` with `issueKey: "<KEY>"` and `comment: "<COMMENT_TEXT>"`

3. **If either MCP tool call fails**, fall back to curl:
```bash
source "${CLAUDE_PLUGIN_DATA}/.env"

curl -sf -o /dev/null \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE_URL/rest/api/2/issue/<KEY>/transitions" \
  -d "{\"transition\":{\"id\":\"<TRANSITION_ID>\"}}"

curl -sf -o /dev/null \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE_URL/rest/api/2/issue/<KEY>/comment" \
  -d "{\"body\":\"<COMMENT_TEXT>\"}"
```
