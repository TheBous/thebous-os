# Jira task context (compatibility adapter)

This reference is intentionally Jira-only and remains for existing workflows
that still consume Jira aliases. Provider-aware workflows must use
`references/task-context.md`.

Follow `references/task-context.md` with:

- `<SOURCES>` — the existing branch, PR or user-provided input;
- `<REQUIRED>` — the workflow's existing required/optional setting;
- `<DETAILS>` — the workflow's existing basic/full setting;
- provider — Jira. Reject a Notion reference instead of silently switching providers.

Expose the normalized Jira result through these unchanged compatibility aliases:

- `<KEY>` — uppercase Jira key;
- `<TASK_SUMMARY>` — Jira summary;
- `<TASK_DESCRIPTION>` — Jira description;
- `<TASK_REQUIREMENTS>` — explicit acceptance criteria found in the description;
  otherwise the description itself;
- `<TASK_STATUS>`, `<TASK_PRIORITY>`, `<TASK_ASSIGNEE>`, `<TASK_TYPE>`,
  `<TASK_LINKS>` — available when `<DETAILS>=full`.

When validating or reviewing the implementation, compare the diff and tests
against `<TASK_REQUIREMENTS>`. Mark each item `✅ Met`,
`⚠️ Partially met / unverifiable`, or `❌ Not met`, with concise evidence.
