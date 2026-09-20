# Provider-neutral task context

Use this reference whenever a workflow needs details for a task. The selected
provider is the source of truth; never merge Jira and Notion data for one task.
Provider-specific payloads must be normalized before they reach the workflow.

## Inputs

- `<SOURCES>` — branch, PR head branch/title/body, URL, key, or page ID to inspect.
- `<REQUIRED>` — `required` stops the workflow when no task resolves; `optional`
  continues without task context when the user declines or no reference exists.
- `<DETAILS>` — `basic` for title and description; `full` also includes status,
  priority, assignee, type and links when the provider supplies them.

## Resolve

Load the shared helper and resolve one unambiguous reference:

```bash
source "scripts/helpers.sh"
REF_JSON=$(resolve_work_item_ref "<SOURCES>")
```

If resolution fails, ask for a provider-qualified reference such as
`jira:T-200` or `notion:<page-id>`. A bare Jira key or URL remains valid for
backward compatibility. If a Jira and a Notion reference are both present, stop
and ask which one is the source of truth.

If no reference is available:

- `required`: stop before the workflow side effect and report that a task is required.
- `optional`: continue with an empty task context.

The resolved `REF_JSON` is the `TaskRef`:

```json
{"provider":"jira|notion","external_id":"...","url":"..."}
```

## Fetch and normalize

Route by `.provider` and return a normalized Task, never the raw provider response.

- **Jira** — use the existing `getJiraIssue` call. For `basic`, request
  `summary` and `description`; for `full`, also request `status`, `priority`,
  `assignee`, `issuetype` and `issuelinks`. Map the result to `title`,
  `description`, `status`, `assignee`, `updated_at` and the other contract fields.
  Preserve the existing Jira summary, description, requirements and full-context
  output for compatibility callers.
- **Notion** — source `scripts/notion.sh` and call:
  `notion_get_page "$(jq -r '.external_id' <<<"$REF_JSON")"`. The adapter
  validates the configured database schema and returns the normalized Task.
  Its supported writes are `notion_create_task`, `notion_set_status` and
  `notion_add_comment`; other writes must report `UNSUPPORTED_OPERATION`.

If fetching fails, map the provider result to the shared semantic errors:
`AUTH_REQUIRED`, `NOT_FOUND`, `VALIDATION_ERROR` or `PROVIDER_UNAVAILABLE`.
Do not expose tokens, headers, cookies or raw payloads.

## Output contract

The provider-aware caller receives:

- `TASK_REF` — the resolved `TaskRef`.
- `TASK_JSON` — the normalized `Task` from `references/task-provider.md`.
- `TASK_REQUIREMENTS` — explicit acceptance criteria in the description, or the
  description itself when no separate criteria are present.

The workflow may use only canonical statuses:
`todo`, `in_progress`, `in_review`, `in_staging`, `done` and `unknown`.

Status changes and comments remain separate provider operations. Use the selected
provider adapter for them; never call the Jira transition/comment reference for a
Notion task.
