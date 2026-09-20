---
name: update-doc
description: Update an existing documentation page in Confluence linked to an optional Jira or Notion task
---

## Goal

Find and update a documentation page in Confluence, identified by URL or title.

## Steps

### 1. Load the credentials

```bash
source "scripts/helpers.sh"
load_env
```

If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-os:setup` first.

### 1a. Resolve a linked task (optional)

Use `references/task-context.md` with the current branch as an optional
provider-neutral task source:

```bash
source "scripts/helpers.sh"
if ! TASK_REF=$(resolve_work_item_ref "$(git branch --show-current)" 2>/tmp/resolve.err); then
  if grep -q "ambiguous" /tmp/resolve.err; then
    # ask user whether Jira or Notion is the source of truth, then re-resolve with `jira:...` or `notion:...`
  else
    TASK_REF=""
  fi
fi
```

Store the `TaskRef` if found. Jira and Notion remain independent providers;
if the resolver reports an ambiguous reference, ask which one is the source
of truth; if no task resolves, skip the task-linked Obsidian step.

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

Only if `TASK_REF` was found in step 1a. Follow `references/obsidian-log.md`
and use the provider-aware helper:

```bash
source "scripts/helpers.sh"
load_env
obsidian_log_task "${OBSIDIAN_VAULT_PATH:-}" "<TASK_REF>" "plan.md" \
  "Confluence page updated: [<title>](<page URL>)" \
  "<PROVIDER>:<EXTERNAL_ID> — Confluence page updated: <title>"
```

### 6. Confirmation

Show the user:
- Page updated: `<title>` → `<page URL>`
- Obsidian: logged (or "skipped, no vault configured / no linked task")
