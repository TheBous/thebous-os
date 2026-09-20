---
name: create-task
description: Create a task in Jira or Notion with the shared Italian description and acceptance-criteria format
---

## Goal

Create one task in the provider chosen by the user. Jira and Notion coexist;
the selected provider is the source of truth and no synchronization is done.

`create-jira-task` remains the backward-compatible Jira-specific entry point.
Use this skill when the user wants to choose Jira or Notion per task.

### 1. Choose the provider and collect inputs

Ask for the provider first: Jira or Notion. Ask only for inputs missing for the
selected provider:

- Jira: project key, summary, requested behavior, acceptance criteria and issue
  type (use `Task` only when explicitly requested and supported).
- Notion: summary, requested behavior and acceptance criteria. Use the database
  configured by `NOTION_DATABASE_ID`.

Do not guess a project key, issue type, requirement or target database.

### 2. Write the shared description

Generate exactly this Markdown structure for both providers:

```text
## Descrizione

<work description>

## Acceptance Criteria

[ ] <verifiable criterion>

[ ] <verifiable criterion>
```

Keep the Italian headings unchanged. Use one blank line after headings and
between criteria. Criteria must be independent, testable and free of
placeholders. Include errors, permissions, required data and edge cases only
when relevant.

### 3. Preview and confirm

Show the provider, target, summary and complete description. Ask for explicit
confirmation before confirmation can be accepted. If the user edits any field,
regenerate the preview and ask again. Do not make a provider call before this
confirmation.

### 4. Create the task

For Jira, follow `skills/create-jira-task/SKILL.md` after confirmation. It owns
the Atlassian MCP path, REST fallback, Jira credentials and Jira-specific
result handling. Do not duplicate those calls here.

For Notion, load the shared credentials and adapter:

```bash
source "scripts/helpers.sh"
load_env
source "scripts/notion.sh"

TASK_JSON=$(notion_create_task "<SUMMARY>" "<DESCRIPTION>")
```

`notion_create_task` validates the configured fixed schema, writes `Name`,
`Description` and the initial `Status`, and returns only the normalized task
contract. If configuration or the provider fails, show the semantic error and
do not simulate creation.

### 5. Confirm the result

Show the normalized provider, external ID, URL when available and summary. Do
not automatically add comments, transition status, create a branch, open a PR,
write Obsidian notes or update Confluence.

If the user selected Notion but `NOTION_API_TOKEN` or `NOTION_DATABASE_ID` is
missing, stop and suggest `/thebous-os:setup`. Never echo the token or raw
provider response.
