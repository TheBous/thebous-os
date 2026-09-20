# Task provider contract

Canonical contract for workflows that can track a task in Jira or Notion.
Provider-specific API calls must stay inside the provider adapter. Workflow
skills consume only this contract.

## Decision

- The provider is selected per task.
- The selected provider is the source of truth for that task.
- Jira and Notion are not synchronized.
- Existing Jira inputs and branch names remain valid.
- A provider adapter normalizes external data before exposing it to a workflow.

## Task reference

Every workflow carries this reference instead of a Jira key:

```json
{
  "provider": "jira",
  "external_id": "T-200",
  "url": "https://company.atlassian.net/browse/T-200"
}
```

The Notion equivalent uses the canonical page ID:

```json
{
  "provider": "notion",
  "external_id": "6f3b2c1a-1234-4567-89ab-0123456789ab",
  "url": "https://www.notion.so/example/6f3b2c1a1234456789ab0123456789ab"
}
```

`external_id` is provider-specific and must never be interpreted by a
workflow. The URL is the user-facing link and must be returned whenever the
provider supplies one.

## Reference input and resolution

Accepted input forms:

```text
jira:T-200
jira:https://company.atlassian.net/browse/T-200
notion:<page-id>
notion:https://www.notion.so/<page>
```

For backward compatibility, a bare Jira key or Jira URL remains valid. A bare
Notion URL may be detected by its host; a bare Notion title is not accepted
because titles are not stable identifiers.

When resolving a task from workflow context, use this precedence:

1. Explicit provider-qualified input.
2. A provider-qualified reference already attached to the workflow context.
3. An existing Jira key in a branch or PR, preserving current behavior.
4. A Notion page ID in the `ntn-<page-id>-<slug>` branch format.

If more than one reference is found, stop and ask the user which task is the
source of truth. Never silently choose between Jira and Notion.

## Normalized task

Adapters return this shape. Missing optional values are `null`; provider raw
payloads are never passed to workflow skills.

```json
{
  "ref": {
    "provider": "jira",
    "external_id": "T-200",
    "url": "https://company.atlassian.net/browse/T-200"
  },
  "title": "Implement OAuth login",
  "description": "...",
  "status": "in_progress",
  "assignee": "marco@example.com",
  "due_at": null,
  "start_at": null,
  "updated_at": "2026-09-20T09:30:00Z"
}
```

The language-neutral type contract is:

```text
TaskRef {
  provider: "jira" | "notion"
  external_id: non-empty string
  url: absolute URL | null
}

Task {
  ref: TaskRef
  title: non-empty string
  description: string | null
  status: "todo" | "in_progress" | "in_review" | "in_staging" | "done" | "unknown"
  assignee: string | null
  due_at: RFC3339 timestamp | null
  start_at: RFC3339 timestamp | null
  updated_at: RFC3339 timestamp | null
}

CreateTaskInput {
  provider: "jira" | "notion"
  title: non-empty string
  description: string
  target: opaque provider target | null
}

CommentReceipt {
  ref: TaskRef
  external_id: string | null
  url: absolute URL | null
  created_at: RFC3339 timestamp
}

Page<T> {
  items: T[]
  next_cursor: string | null
}

ActivityEvent {
  kind: "created" | "updated" | "commented" | "status_changed" | "assigned"
  ref: TaskRef
  at: RFC3339 timestamp
  actor: string | null
  summary: string
  url: absolute URL | null
}
```

### Canonical status values

The workflow layer may use only these values:

```text
todo | in_progress | in_review | in_staging | done
```

Provider-specific status names and transition IDs remain adapter details. An
unmapped provider status is returned as `unknown` for read-only reports and
cannot be written until a mapping exists.

## Operations

Each provider adapter must expose these semantic operations:

| Operation | Input | Result | Semantics |
|---|---|---|---|
| `resolve` | user text, branch, PR URL/body | `TaskRef` | Resolves one unambiguous provider reference. |
| `get` | `TaskRef`, detail level | `Task` | Returns normalized task data. |
| `create` | `CreateTaskInput` | `Task` | Creates a task in the selected provider. |
| `set_status` | `TaskRef`, canonical status | `Task` | Idempotent when the task already has that status. |
| `add_comment` | `TaskRef`, body | `CommentReceipt` | Adds one provider comment. It is not automatically retried after an unknown timeout. |
| `list` | filters and cursor | page of `Task` | Used by current-status and briefing queries. |
| `list_activity` | time window, optional refs | page of activity | Used for comments, updates and status changes in briefings. |

Language-neutral signatures:

```text
resolve(input: ResolveInput) -> TaskRef
get(input: { ref: TaskRef, detail: "basic" | "full" }) -> Task
create(input: CreateTaskInput) -> Task
set_status(input: { ref: TaskRef, status: canonical status }) -> Task
add_comment(input: { ref: TaskRef, body: non-empty string }) -> CommentReceipt
list(input: TaskFilters) -> Page<Task>
list_activity(input: ActivityFilters) -> Page<ActivityEvent>

ResolveInput {
  text: non-empty string
  branch: string | null
  pull_request_url: absolute URL | null
  pull_request_body: string | null
}

ActivityFilters {
  from: RFC3339 timestamp
  to: RFC3339 timestamp
  refs: TaskRef[] | null
  cursor: string | null
  limit: integer between 1 and 100
}
```

`set_status` and `add_comment` are intentionally separate. A provider may
successfully change status and fail to add a comment; the workflow must report
that partial result instead of claiming both operations succeeded.

List operations use a bounded page size and return a cursor when more results
exist. A workflow may stop after the requested time window and must report
incomplete coverage when the provider cannot supply the required data.

The current Notion adapter supports status/date/cursor filters and resolves an
`assignee` email through the paginated workspace-user list before applying the
Notion people filter. The integration needs user-information capability for this
lookup. `list_activity` traverses configured task pages for page updates and
comments, including comment pagination; without explicit refs it discovers pages
updated in the requested window. Notion does not expose historical status or
assignment transitions through this path, so those categories remain a
documented coverage gap.

The shared list filters are:

```text
TaskFilters {
  status: canonical status[] | null
  assignee: string | null
  due_from: RFC3339 timestamp | null
  due_to: RFC3339 timestamp | null
  updated_from: RFC3339 timestamp | null
  updated_to: RFC3339 timestamp | null
  cursor: string | null
  limit: integer between 1 and 100
}
```

### Create input

```json
{
  "provider": "notion",
  "title": "Implement OAuth login",
  "description": "## Descrizione\n\n...\n\n## Acceptance Criteria\n\n[ ] ...",
  "target": null
}
```

`target` is optional when the provider has one configured default. Jira project
and issue type, or a Notion database, are configuration concerns and must not
leak into unrelated workflows.

## Error semantics

Every adapter must preserve these semantic error codes:

| Code | Meaning | Workflow behavior |
|---|---|---|
| `INVALID_REFERENCE` | Input is malformed or ambiguous. | Ask for a corrected reference. |
| `AUTH_REQUIRED` | Credentials are missing or rejected. | Stop the provider path and explain setup. |
| `NOT_FOUND` | The reference does not exist or is inaccessible. | Stop when required; otherwise report unavailable context. |
| `VALIDATION_ERROR` | Required task data or provider fields are invalid. | Stop before a write. |
| `UNSUPPORTED_OPERATION` | Provider cannot perform the requested operation. | Report the exact skipped operation. |
| `PROVIDER_UNAVAILABLE` | Timeout, rate limit or transient provider failure. | Do not invent completion; retry only when safe. |
| `CONFLICT` | Provider rejected the write because state changed. | Re-read and ask before overwriting. |

Error messages may contain safe provider context, but never tokens, headers,
cookies, credential-bearing URLs or raw untrusted payloads.

## Provider mappings

### Jira

- Existing Jira REST/MCP calls remain behind the Jira adapter.
- Existing transition IDs remain adapter configuration.
- Bare Jira keys and current branch formats remain supported.
- `summary`, `description`, `status`, `assignee`, `duedate` and `updated` map to
  the normalized task fields.

### Notion

The MVP uses one configured database with these fixed property names:

| Property | Required | Normalized field |
|---|---:|---|
| `Name` | yes | `title` |
| `Description` | yes | `description` |
| `Status` | yes | `status` |
| `Assignee` | no | `assignee` |
| `Due date` | no | `due_at` |
| `Start date` | no | `start_at` |

The adapter validates the property types and values at the boundary. Arbitrary
property-name mapping is out of scope for the MVP.

The adapter maps canonical status writes to supported Notion status values,
creates pages with the existing `Descrizione` / `Acceptance Criteria` text in
`Description`, and adds comments as separate operations. A status update that
already has the requested canonical state is idempotent.

## Git and Obsidian identity

Existing Jira branches stay unchanged:

```text
feat/t-200-implement-oauth-login
```

Notion branches use the stable page ID instead of the title alone:

```text
feat/ntn-6f3b2c1a1234456789ab0123456789ab-implement-oauth-login
```

The page ID is normalized by removing hyphens and lowercasing it. The slug is
only for readability; the provider and external ID are the identity.

Obsidian paths for existing Jira tasks remain compatible. New provider-aware
logs use a collision-safe storage key:

```text
jira:T-200   → Dev/Tickets/T-200/
notion:<id>  → Dev/Tickets/notion-<id>/
```

Provider-aware frontmatter adds `provider`, `external_id` and `url`. The
existing Jira `ticket` field remains for old notes and Jira compatibility.

## Workflow integration

| Workflow | Provider contract used |
|---|---|
| Create task | `create` |
| New branch | `resolve` → `get` → `set_status(in_progress)` → `add_comment` |
| Cook | `resolve` → `get` |
| Create PR | `resolve` → `get` → `add_comment` → `set_status(in_review)` |
| Merge PR | `resolve` → `set_status(in_staging)` → `add_comment` |
| Tag release | resolve all refs → `set_status(done)` → `add_comment` |
| Current status | `list` and `list_activity` per configured provider |
| Morning briefing | `list` and `list_activity` per configured provider |
| Obsidian logging | `TaskRef`, never a Jira key-only assumption |

Provider-specific actions must not be reimplemented in individual workflow
skills. Commands remain thin adapters and the canonical skills consume this
contract.

## Migration order

1. Add reference resolution and normalized task data while keeping all Jira
   behavior unchanged.
2. Extract Jira operations behind the contract and retain compatibility
   wrappers for `extract_jira_key`, `jira_comment` and existing Obsidian paths.
3. Add the Notion adapter and validate the fixed database schema.
4. Migrate `new-branch`, `create-pr` and `merge-pr` first; these exercise the
   smallest complete lifecycle.
5. Migrate task creation, `current-status`, `morning-briefing`, `cook` and tag
   workflows.

The first implementation milestone should stop after the lifecycle in step 4;
briefing and reporting parity can follow once task identity is proven.

## Explicitly out of scope

- Jira ↔ Notion synchronization.
- Searching Notion by title as a task identity mechanism.
- Arbitrary Notion database schemas.
- Provider-specific fields exposed to every workflow.
- Automatic retries for non-idempotent comments or task creation.
