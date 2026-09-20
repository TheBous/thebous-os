---
name: new-branch
description: Use when the user asks to create, start, or open a new git branch from a Jira or Notion task
---

## Goal

Create a git branch linked to a Jira or Notion task, move it to `in_progress`,
notify Slack, and log the activity when configured.

### 1. Gather input

Ask the user: "Branch name or Jira/Notion task URL or ID?"

Accept:
- Full Jira URL (e.g. `https://company.atlassian.net/browse/T-200`)
- Jira key (e.g. `T-200` or `t-200`)
- Notion page URL or explicit `notion:<page-id>`
- Explicit provider reference (`jira:T-200` or `notion:<page-id>`)
- Free-form branch name (e.g. `feat/my-thing`) — in this case skip task steps

### 2. If input is a task reference

Load the credentials:

```bash
source "scripts/helpers.sh"
load_env
```

If the file doesn't exist, tell the user to run `/thebous-os:setup` first.

Follow `references/task-context.md` with:
- `<SOURCES>` = the user's URL or task input
- `<REQUIRED>` = `required`
- `<DETAILS>` = `basic`

The context step resolves the single reference with:

```bash
REF_JSON=$(resolve_work_item_ref "<SOURCES>")
```

Set `TASK_REF`, `PROVIDER`, `EXTERNAL_ID`, `TASK_URL` and `TASK_SUMMARY` from
the normalized output.

Build the branch name from the selected provider:

- Jira: `feat/<key-lowercase>-<slugified-title>`.
- Notion: `feat/ntn-<page-id-without-hyphens>-<slugified-title>`.

Use the shared `slugify` helper; keep the slug at 50 characters after the
provider prefix. Examples:

- Jira: `T-200` + "Implement OAuth login" → `feat/t-200-implement-oauth-login`.
- Notion: `6f3b2c1a-1234-4567-89ab-0123456789ab` + "Implement OAuth login" → `feat/ntn-6f3b2c1a1234456789ab0123456789ab-implement-oauth-login`.

Show the proposed name and ask for confirmation. The user can edit it.

### 3. Search for relevant documentation (only for Jira)

If `PROVIDER=jira` and `CONFLUENCE_PARENT_URL` is configured in `.env`:

Extract 3-5 meaningful keywords from the task's title and description (exclude
articles, common verbs and noise words). Extract `PARENT_PAGE_ID` from
`CONFLUENCE_PARENT_URL` with:

```bash
source "scripts/helpers.sh"
PARENT_PAGE_ID=$(confluence_page_id "$CONFLUENCE_PARENT_URL")
```

Use the MCP tool `searchConfluenceUsingCql` with:
`ancestor = <PARENT_PAGE_ID> AND (title ~ "<keyword1>" OR title ~ "<keyword2>" OR text ~ "<keyword1>")`.
Show found titles and URLs before starting; if nothing is found, proceed silently.

### 4. Create and push the branch

```bash
git checkout -b <branch-name>
git push -u origin <branch-name>
```

If the branch already exists, warn the user and run `git checkout <branch-name>`
followed by `git push -u origin <branch-name>`.

### 5. Move the task to `in_progress` and comment

For `PROVIDER=jira`, follow `references/jira-transition.md` with:
- `<TRANSITION_ID>` = `$JIRA_IN_PROGRESS_ID`
- `<COMMENT_TEXT>` = `"🌿 Branch \`<branch-name>\` created."`

For `PROVIDER=notion`, source `scripts/notion.sh` and run both operations:

```bash
notion_set_status "<EXTERNAL_ID>" "in_progress"
notion_add_comment "<EXTERNAL_ID>" "🌿 Branch \`<branch-name>\` created."
```

Record each result separately. If one fails, report the semantic error and do
not claim that both operations succeeded.

### 6. Slack notification

For Jira, preserve the existing message format:

```bash
source "scripts/helpers.sh"
load_env
slack_notify "🌿 New branch: \`<branch-name>\`\n🎫 <$JIRA_BASE_URL/browse/<EXTERNAL_ID>|<EXTERNAL_ID>> → *In Progress*"
```

For Notion, use `TASK_URL` from the task reference:

```bash
slack_notify "🌿 New branch: \`<branch-name>\`\n🎫 <$TASK_URL|notion:<EXTERNAL_ID>> → *In Progress*"
```

If the task URL is unavailable, omit the task link and send only the branch
line plus the provider/external ID. A free-form branch sends only the branch line.

### 7. Log to Obsidian (optional)

If a task reference was found and Obsidian is configured, follow
`references/obsidian-log.md`; in short:

```bash
obsidian_log_task "${OBSIDIAN_VAULT_PATH:-}" "<TASK_REF>" "plan.md" "" \
  "<PROVIDER>:<EXTERNAL_ID> — branch \`<branch-name>\` created"
```

### 8. Link a Granola call (optional)

Only if `OBSIDIAN_VAULT_PATH` is set and a task reference was found. Follow
`references/obsidian-log.md`'s Granola section. On a user-selected call:

```bash
CALLS_FILE=$(obsidian_ensure_task_file "${OBSIDIAN_VAULT_PATH}" "<TASK_REF>" "calls.md")
echo "- [[Granola/<chosen-filename-without-.md>]] — linked $(date +%Y-%m-%d)" >> "$CALLS_FILE"
```

Never auto-pick a note. If the list is empty or the user declines, skip silently.

### 9. Confirmation

Show the user:
- Branch created: `<branch-name>`
- Task transitioned: `<PROVIDER>:<EXTERNAL_ID>` → `in_progress` (if applicable)
- Slack: notified (or the exact failure)
- Obsidian: logged (or "skipped, no vault configured")
- Granola call linked: `<note>` (if applicable)
