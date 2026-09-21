---
name: cook
description: Use when the user decides to develop, implement, plan, design, or fix a feature, bug, task, or other change, including when they request an implementation plan before coding
---

## Goal

Implement a feature or fix starting from the context of the current branch/ticket, ensuring tests pass and documentation is up to date.

## Steps

### 1. Gather context

Before changing files, record the current commit as the implementation baseline:

```bash
BASE_COMMIT=$(git rev-parse HEAD)
```

Use this baseline only to measure the changes made for the current feature or fix;
do not count unrelated changes that were already present.

Follow `references/task-context.md` with:
- `<SOURCES>` = the current branch name
- `<REQUIRED>` = `optional`
- `<DETAILS>` = `full`

Set `TASK_REF` (the provider-neutral `TaskRef`), `PROVIDER`, `EXTERNAL_ID`, `TASK_SUMMARY`, `TASK_DESCRIPTION`,
and `TASK_REQUIREMENTS` from the normalized context. For Jira, also collect
direct relationships: linked issues, subtasks, parent story/task, epic or other
ancestor, and child tasks when available. For Notion, use only the normalized
page fields; related Jira links are not available and must not be invented.
Resolve Jira parent links upward until there is no parent or the hierarchy ends.
Use available related context to define scope, dependencies, acceptance
criteria and implementation order.

Do not show the user the ticket title or description. Ask only for confirmation
that the gathered scope is correct and incorporate any clarification:

```text
I collected the task context and available provider links. Shall I proceed with this scope? Would you like to add or correct anything?
```

Wait for a reply before creating the implementation artifacts.

### 2. Pull optional Granola context before development

Before choosing the development flow or writing any code, ask:

```text
Would you like me to retrieve Granola meetings for more development context? (yes/no)
```

If the user says **no**, continue to step 3 without pulling anything.

If the user says **yes**:

1. Require `TASK_REF` and a configured `OBSIDIAN_VAULT_PATH`. If either is
   missing, explain that the meeting cannot be imported into the task and
   ask whether to continue without Granola.
2. Prefer an available Granola MCP connection. Otherwise use the official
   Granola API with `GRANOLA_API_KEY`. On this machine, when the Obsidian
   Granola plugin is configured but the environment variable is absent, use
   the configured `apiKey` from
   `<OBSIDIAN_VAULT_PATH>/.obsidian/plugins/granola-sync-plus/data.json` or
   `granola-sync/data.json` without printing or persisting the key elsewhere.
3. Pull all accessible note summaries from `GET
   https://public-api.granola.ai/v1/notes`, following pagination with
   `cursor`. Show a numbered selection with title and creation date. If the
   list is large, let the user filter it by title/date before selecting.
4. Ask which meeting to use. Never select a meeting automatically, even when
   one title appears to match the task. If the user declines or no
   meeting is selected, continue without importing one.
5. For the selected note, pull its detail with `include=transcript`, then
   create a new Markdown page in the provider-aware Obsidian task folder using
   `obsidian_task_dir`. Name it
   `granola-<GRANOLA_ID>.md` so the same meeting cannot be imported twice.
6. Do not overwrite an existing page silently. If that file already exists,
   tell the user it is already imported and ask whether to use it or choose
   another meeting.
7. The new page must contain frontmatter for `provider`, `external_id`, `url`,
   `granola_id`, `title`, `created_at`, `updated_at`, `granola_url`, and
   `imported_at` (keep `ticket` for Jira compatibility), followed by
   the meeting title, summary, attendees, and full transcript when returned
   by Granola. Preserve the source content; do not invent or summarize it.
8. Confirm the imported page path to the user before proceeding with the
   development flow.

The Granola pull and Obsidian import are read-only with respect to the code
repository. If the API, MCP, or vault write fails, report the exact failure
and ask whether to continue without Granola; do not start implementation
silently after a failed requested import.

### 3. Initialize the SDD work package

Before invoking Wayfinder, Brainstorming, Grilling, Superpowers, or any other
preliminary skill, invoke `sdd-refine` as the mandatory intent-discovery
pre-phase. It must inspect the repository, ask only decision questions, create
`changes/{CHG_ID}/build-spec.md`, and stop for the exact approval
`approve-build-spec changes/{CHG_ID}/build-spec.md`. Do not continue when the
change ID is unknown; ask for it instead of inventing one.

Only after the build spec is approved may the SDD work package be created:

```text
<OBSIDIAN_VAULT_PATH>/Tickets/<TASK_STORAGE_KEY>/spec.md
<OBSIDIAN_VAULT_PATH>/Tickets/<TASK_STORAGE_KEY>/plan.md
<OBSIDIAN_VAULT_PATH>/Tickets/<TASK_STORAGE_KEY>/tasks.md
```

`OBSIDIAN_VAULT_PATH` is required for this workflow. If it is unset or the vault
does not exist, stop before invoking another skill or changing code and ask the
user to configure it.

If `TASK_REF` is empty, skip Granola import, provider relationships, provider
writes and task-scoped SDD artifacts; continue only with the user-confirmed
local scope and make no provider calls.

Derive `<TASK_STORAGE_KEY>` with `obsidian_task_storage_key "$TASK_REF"`.
This keeps existing Jira paths such as `Tickets/DC-123` and uses
`Tickets/notion-<page-id>` for Notion. Report the selected path.

Create these files before any code change. Their minimum responsibilities are:

- `spec.md`: problem, scope, related provider context, requirements, constraints,
  acceptance criteria, and decisions;
- `plan.md`: implementation approach, affected areas, dependencies, risks, and
  verification strategy;
- `tasks.md`: the ordered checklist of every implementation task and subtask.

The checklist is the single progress source of truth. Mark work as `[x]` only
after it is complete, leave pending work as `[ ]`, and use `[blocked]` with the
reason when necessary. Update it before and after every meaningful action,
including work delegated to Wayfinder, Superpowers, or another skill. No skill
may bypass this checklist.

### 4. Choose the development flow

Ask the user:
```
How do you want to approach this task?

1. 🧠 Brainstorming — explore options and approaches before writing code
2. 🔥 Grilling — a Q&A session to nail down requirements in detail
3. 🗺️ Wayfinder — chart the project as a map of decisions, resolve one ticket at a time
4. ⚡ Direct — implement right away with no preliminary flow
```

- If they choose **1**: invoke the `superpowers:brainstorming` skill before proceeding
- If they choose **2**: invoke the `grilling` skill before proceeding
- If they choose **3 or 4**: proceed to step 4

This choice is optional follow-up exploration after `sdd-refine`; it can never
bypass the build-spec interview or approval. Implementation still proceeds with
the SDD files and checklist from step 3, regardless of which option was picked.
Incorporate all decisions into `spec.md` and `plan.md`, and update `tasks.md` as
each preliminary skill completes.

### 5. Create the implementation direction HTML

Before changing source or test code, create a self-contained HTML document at:

```text
<OBSIDIAN_VAULT_PATH>/Tickets/<TASK_STORAGE_KEY>/implementation-direction.html
```

The document is written for a developer: it must sit between business and deep
implementation detail. Explain the intended behavior, the main flow, affected
components/files, key technical choices, alternatives rejected, risks, and how
the result will be verified. Use inline CSS/SVG or simple HTML only; do not use
remote assets. Mark assumptions and unchecked behavior as `Non verificato`.

The HTML is a planning artifact, not a report of completed work. Verify that it
exists and is non-empty before proceeding. If Obsidian is not configured, stop
before development and ask the user to configure it: this artifact is mandatory.

**REQUIRED SUB-SKILL:** Use `architecture-first-development` before changing
source or test code. It governs design and code structure; this skill continues
to govern provider context, SDD artifacts, verification, and documentation.

### 6. Proceed with SDD implementation

Always use Spec-Driven Development. Execute the tasks in `tasks.md` in order,
updating `spec.md`, `plan.md`, and `tasks.md` when requirements or decisions
change. The implementation may invoke other skills, but each delegated action
must be reflected in `tasks.md` before it starts and marked complete only after
its result is verified.

### 6a. Check the implementation size

Before treating the feature as complete, measure the code changes against
`$BASE_COMMIT`. Count added plus deleted lines only in source and test-code files;
exclude Markdown/docs, generated files, lockfiles, vendored files, images and other
non-code assets. Use `git diff --numstat "$BASE_COMMIT"` and classify the paths
manually when the extension is ambiguous.

If the total is greater than **300 lines of code**, always pause and ask the user:

```text
The changes exceed 300 lines of code. Would you like to split this feature into smaller, independent tasks organized as a PR stack?
```

Do not assume the answer. If the user says **yes**, propose a minimal decomposition
into independently reviewable tasks/PRs, ordered by dependency, and wait for approval
before continuing as a single feature. Do not create provider tasks, branches or PRs
automatically from this check. If the user says **no**, continue with the current
implementation and record that the user explicitly chose not to split it.

### 7. Run the full test suite

Run the **complete test suite** to ensure no regressions:

Read `references/run-tests.md` (in the plugin root) and follow the instructions to find and run the project's full tests/lint/checks.

### 8. Update documentation

Fetch the changed files:
```bash
git diff HEAD --name-only
```

**Local docs** — if `docs/` exists:
```bash
ls docs/ 2>/dev/null && grep -rl "<changed-file>" docs/ 2>/dev/null
```

**Confluence** — if `CONFLUENCE_PARENT_URL` is configured in `.env`:
```bash
source "scripts/helpers.sh"
load_env
```
Extract `PARENT_PAGE_ID` and use the MCP tool `searchConfluenceUsingCql`:
```
ancestor = <PARENT_PAGE_ID> AND (text ~ "<file1>" OR text ~ "<file2>")
```

If candidates are found (local or Confluence), show:
```
📄 Documentation to update:
- [local] docs/auth.md
- [Confluence] <title> → <url>

Do you want to update them? (yes/no/list which ones)
```

Wait for confirmation. For each confirmed doc, update the relevant content to reflect the implemented changes.

### 9. Finalize the SDD artifacts

Before the final response, ensure the three SDD files and the HTML direction
document are present in `<OBSIDIAN_VAULT_PATH>/Tickets/<TASK_STORAGE_KEY>/`. Mark every
completed item in `tasks.md`, record final decisions and verification results in
`plan.md`, and record the delivered behavior and acceptance-criteria status in
`spec.md`.

### 10. Log to Obsidian (optional)

If a task reference was found in step 1 (`TASK_REF` is set). Follow
`references/obsidian-log.md` for the daily note. Do not create a second
`plan.md` under the provider-aware task directory: the canonical SDD `plan.md` is already in
`Tickets/<TASK_STORAGE_KEY>` above.

```bash
source "scripts/helpers.sh"
load_env

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "<PROVIDER>:<EXTERNAL_ID> — implemented via SDD"
fi
```

### 11. Final confirmation

Show the user:
- ✅ Feature/fix implemented via SDD
- ✅ Tests: full suite green (all scripts passed)
- ✅ Documentation updated: `<list of files/pages>` (if applicable)
- ✅ SDD bundle: `Tickets/<TASK_STORAGE_KEY>/spec.md`, `plan.md`, `tasks.md`, and `implementation-direction.html`
- ✅ Obsidian log: updated (or "skipped, no vault configured")
- ✅ Granola context page: `<path>` (if imported, otherwise "skipped")
- → Suggest the next step: `/thebous-os:create-pr` to open the PR
