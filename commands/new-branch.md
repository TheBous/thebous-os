---
description: Create a new branch from a Jira task, move the task to In Progress, and notify Slack
---

## Goal

Create a git branch linked to a Jira ticket, transition the ticket to In Progress, notify Slack.

## Steps

### 1. Gather input

Ask the user: "Branch name or Jira ticket URL/ID?"

Accept:
- Full Jira URL (e.g. `https://company.atlassian.net/browse/DC-443`)
- Ticket key (e.g. `DC-443` or `dc-443`)
- Free-form branch name (e.g. `feat/my-thing`) — in this case skip the Jira steps

### 2. If input is a Jira ticket

Load the credentials:
```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
```
If the file doesn't exist, tell the user to run `/thebous-jira-git-sync:setup` first.

Extract the key (e.g. `DC-443`) from the URL or input. Then fetch the ticket title using the MCP tool `getJiraIssue` with `issueKey: "<KEY>"` and `fields: ["summary"]`.

Build the branch name: `feat/<key-lowercase>-<slugified-title>`.
- Slugify: lowercase, spaces and special characters → `-`, max 50 characters after the prefix.
- Example: `DC-443` + "Implement OAuth login" → `feat/dc-443-implement-oauth-login`

Show the proposed name and ask for confirmation. The user can edit it.

### 3. Search for relevant documentation (only if there's a Jira ticket)

If `CONFLUENCE_PARENT_URL` is configured in `.env`:

Extract 3-5 meaningful keywords from the ticket's title and description (exclude articles, common verbs, noise words). Extract `PARENT_PAGE_ID` from `CONFLUENCE_PARENT_URL` with:
```bash
echo "$CONFLUENCE_PARENT_URL" | grep -oP '(?<=pages/)[0-9]+'
```

Use the MCP tool `searchConfluenceUsingCql` with:
```
ancestor = <PARENT_PAGE_ID> AND (title ~ "<keyword1>" OR title ~ "<keyword2>" OR text ~ "<keyword1>")
```

If results are found, show the user the titles and URLs of the pages found as context before starting. If nothing is found, proceed silently.

### 4. Create and push the branch

```bash
git checkout -b <branch-name>
git push -u origin <branch-name>
```

If the branch already exists, warn the user and run `git checkout <branch-name>` followed by `git push -u origin <branch-name>`.

### 5. Jira transition (only if there's a ticket)

Follow `references/jira-transition.md` (in the plugin root) with:
- `<TRANSITION_ID>` = `$JIRA_IN_PROGRESS_ID`
- `<COMMENT_TEXT>` = `"🌿 Branch \`<branch-name>\` created."`

### 6. Slack notification

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
curl -sf -o /dev/null -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-type: application/json" \
  -d "{\"text\":\"🌿 New branch: \`<branch-name>\`\n🎫 <$JIRA_BASE_URL/browse/<KEY>|<KEY>> → *In Progress*\"}"
```

If there was no Jira ticket, the Slack message is just: `🌿 New branch: \`<branch-name>\``

### 7. Log to Obsidian (optional)

Only if a Jira ticket was found in step 2 (`<KEY>` is set). Follow `references/obsidian-log.md`; in short:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md" >/dev/null
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — branch \`<branch-name>\` created"
fi
```

### 8. Link a Granola call (optional)

Only if `OBSIDIAN_VAULT_PATH` is set and `<KEY>` is set. Follow `references/obsidian-log.md`'s Granola section:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ]; then
  obsidian_granola_candidates "${OBSIDIAN_VAULT_PATH}" 14
fi
```

If it lists anything, show up to 5 candidates (filename + `title:` frontmatter) and ask: "Vuoi collegare una di queste call a `<KEY>`? (numero o 'no')". On a pick:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
CALLS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "calls.md")
echo "- [[Granola/<chosen-filename-without-.md>]] — linked $(date +%Y-%m-%d)" >> "$CALLS_FILE"
```

If the list is empty or the user declines, skip silently.

### 9. Confirmation

Show the user:
- Branch created: `<branch-name>`
- Ticket transitioned: `<KEY>` → In Progress (if applicable)
- Slack: notified
- Obsidian: logged (or "skipped, no vault configured")
- Granola call linked: `<note>` (if applicable, otherwise omit this line)
