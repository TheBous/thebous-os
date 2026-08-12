---
name: update-doc
description: Update an existing documentation page in Confluence
---

## Goal

Find and update a documentation page in Confluence, identified by URL or title.

## Steps

### 1. Load the credentials

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
```

If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-os:setup` first.

### 1a. Detect a linked Jira ticket (optional)

```bash
source "scripts/helpers.sh"
KEY=$(extract_jira_key "$(git branch --show-current)")
```

Store it as `<KEY>` if found — used later to link this doc into Obsidian. If no key is found, `<KEY>` stays empty and the Obsidian step at the end is skipped.

### 2. Identify the page

Ask the user: "URL or title of the page to update?"

**If URL**: `source "scripts/helpers.sh"; PAGE_ID=$(confluence_page_id "<URL>")`

**If title**: extract `PARENT_PAGE_ID` the same way from `CONFLUENCE_PARENT_URL`, then use the MCP tool `searchConfluenceUsingCql` with:
```
title = "<title>" AND ancestor = <PARENT_PAGE_ID>
```
If there are multiple results, show them and ask which one.

### 3. Fetch the current content

Use the MCP tool `getConfluencePage` with the page ID found. Show the user the current title and body.

### 4. Gather the changes

Ask the user what they want to change (title, body, adding/removing tags, reference files).

### 5. Apply the changes

Use the MCP tool `updateConfluencePage` with the page ID and the updated content (`contentFormat: "html"`).

For tag changes: update the Tags row directly in the metadata table in the HTML body.

### 5a. Log to Obsidian (optional)

Only if `<KEY>` was found in step 1a. Follow `references/obsidian-log.md`:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ] && [ -n "<KEY>" ]; then
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "Confluence page updated: [<title>](<page URL>)"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — Confluence page updated: <title>"
fi
```

### 6. Confirmation

Show the user:
- Page updated: `<title>` → `<page URL>`
- Obsidian: logged (or "skipped, no vault configured / no linked ticket")
