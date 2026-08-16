---
name: create-jira-task
description: Create a Jira task from a user request using the repository's fixed description format with the sections "Descrizione" and "Acceptance Criteria". Use when the user asks to create, open, or draft a new Jira task.
---

## Goal

Create a Jira task with this exact output structure. The Italian headings are a
functional repository convention and must remain unchanged:

```text
## Descrizione

<work description>

## Acceptance Criteria

[ ] <verifiable criterion>

[ ] <verifiable criterion>
```

The user's example is only a skeleton. Do not reuse its functional content.

## 1. Collect minimum inputs

Ask only for missing information:

- Jira project key;
- task summary;
- requested behavior or work;
- acceptance criteria, constraints, and known edge cases;
- issue type, using `Task` as the default only when explicitly requested and supported.

Do not guess the project key, issue type, or missing requirements. If the brief is
too vague for verifiable criteria, ask only for the missing information.

## 2. Write the description

Generate Markdown using exactly `## Descrizione` and `## Acceptance Criteria`.
Use one blank line after each heading and between criteria. Use one `[ ] ...`
line per criterion, without additional numbering or bullets. Make each criterion
independent, testable, and unambiguous. Include errors, permissions, required
data, and edge cases only when relevant. Do not invent copy, URLs, domain states,
entities, APIs, or technical details. Do not leave placeholders or generic
criteria such as `[ ] Il task funziona`.

Keep the summary short and outcome-oriented; do not add Jira prefixes or keys
unless requested.

## 3. Show a preview and request confirmation

Before writing to Jira, show project, issue type, summary, and the complete
description in a text block. Ask for explicit confirmation. If the user edits it,
regenerate the preview and ask again. Do not create a task with uncertain
requirements or placeholders.

## 4. Create the Jira task

Prefer the configured Atlassian MCP:

1. Resolve `cloudId` with `getAccessibleAtlassianResources`.
2. If multiple Jira sites exist, ask which one to use.
3. Create the issue with the available Jira creation tool, passing project, type, summary, and full description.
4. Use the exact parameters exposed by the available tool; do not invent custom fields.

If MCP is unavailable or fails, use the REST fallback only when
`JIRA_BASE_URL`, `JIRA_EMAIL`, and `JIRA_API_TOKEN` are configured in the shared
`.env` loaded through `scripts/helpers.sh`:

```bash
source "scripts/helpers.sh"
load_env

BODY=$(jq -n \
  --arg project_key "<PROJECT_KEY>" \
  --arg issue_type "<ISSUE_TYPE>" \
  --arg summary "<SUMMARY>" \
  --arg description "<DESCRIPTION>" \
  '{fields:{project:{key:$project_key},issuetype:{name:$issue_type},summary:$summary,description:$description}}')

curl -sf \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE_URL/rest/api/2/issue" \
  -d "$BODY"
```

Always use `jq --arg` for serialization. Never construct JSON by concatenating
the description. If credentials are missing, tell the user to run
`/thebous-os:setup`; do not make partial calls or simulate creation.

## 5. Confirm the result

After Jira succeeds, show the task key, `JIRA_BASE_URL/browse/<KEY>` when the base
URL is available, and the created summary. Do not automatically add Slack
comments, transitions, branches, PRs, Obsidian files, or Confluence pages.
