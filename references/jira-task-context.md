# Jira task context (shared interface)

Use this reference whenever a workflow needs details for a Jira task. Do not reimplement the key resolution or Jira fetch in the calling command.

## Inputs

- `<SOURCES>` — one or more texts to inspect, such as a branch name, PR head branch, PR title/body, or user-provided URL/key. Try them in the given order.
- `<REQUIRED>` — `required` stops the workflow if no task can be resolved; `optional` continues without Jira context when the user declines or no key is available.
- `<DETAILS>` — `basic` for summary and description; `full` also includes status, priority, assignee, issue type, and linked issues.

## Resolve and fetch

1. Load the helper and extract the first Jira key from each `<SOURCES>` value, using the first key found:
   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
   KEY=$(extract_jira_key "<SOURCE_1> <SOURCE_2> ...")
   ```
2. If `<KEY>` is empty, ask the user for a Jira key or ticket URL. Run `extract_jira_key` on the answer.
3. If the key is still empty:
   - `<REQUIRED>=required`: stop before the workflow's side effect and report that a Jira task is required.
   - `<REQUIRED>=optional`: continue with an empty Jira context.
4. Fetch the task with `getJiraIssue`:
   - `basic`: `fields: ["summary", "description"]`
   - `full`: `fields: ["summary", "description", "status", "priority", "assignee", "issuetype", "issuelinks"]`
5. If the fetch fails:
   - `<REQUIRED>=required`: stop before the workflow's side effect.
   - `<REQUIRED>=optional`: report that Jira context is unavailable and continue without it.

## Output contract

The caller receives:

- `<KEY>` — uppercase Jira key
- `<TASK_SUMMARY>` — Jira summary
- `<TASK_DESCRIPTION>` — Jira description
- `<TASK_REQUIREMENTS>` — explicit acceptance criteria found in the description; otherwise the description itself
- `<TASK_STATUS>`, `<TASK_PRIORITY>`, `<TASK_ASSIGNEE>`, `<TASK_TYPE>`, `<TASK_LINKS>` — available when `<DETAILS>=full`

When validating or reviewing the implementation, compare the diff and tests against `<TASK_REQUIREMENTS>`. Mark each item `✅ Met`, `⚠️ Partially met / unverifiable`, or `❌ Not met`, and include concise evidence.
