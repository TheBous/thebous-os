---
description: Update an existing documentation page in Confluence
---

## Goal

Find and update a documentation page in Confluence, identified by URL or title.

## Steps

### 1. Load the credentials

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
```

If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-jira-git-sync:setup` first.

### 2. Identify the page

Ask the user: "URL or title of the page to update?"

**If URL**: extract the page ID with `echo "<URL>" | grep -oP '(?<=pages/)[0-9]+'`

**If title**: use the MCP tool `searchConfluenceUsingCql` with:
```
title = "<title>" AND ancestor = <PARENT_PAGE_ID>
```
where `PARENT_PAGE_ID` is extracted from `CONFLUENCE_PARENT_URL`. If there are multiple results, show them and ask which one.

### 3. Fetch the current content

Use the MCP tool `getConfluencePage` with the page ID found. Show the user the current title and body.

### 4. Gather the changes

Ask the user what they want to change (title, body, adding/removing tags, reference files).

### 5. Apply the changes

Use the MCP tool `updateConfluencePage` with the page ID and the updated content (`contentFormat: "html"`).

For tag changes: update the Tags row directly in the metadata table in the HTML body.

### 6. Confirmation

Show the user:
- Page updated: `<title>` → `<page URL>`
