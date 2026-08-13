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

Follow `references/jira-task-context.md` with:
- `<SOURCES>` = the current branch name
- `<REQUIRED>` = `optional`
- `<DETAILS>` = `basic`

Show the user:
```
🎫 Ticket: <KEY> — <title>
📋 <description truncated to 300 characters>

Is this what you want to implement? Do you want to add details or correct the direction?
```

Wait for a reply and incorporate any clarifications before proceeding.

### 2. Pull optional Granola context before development

Before choosing the development flow or writing any code, ask:

```text
Vuoi che recuperi i meeting di Granola per avere più contesto sullo sviluppo? (sì/no)
```

If the user says **no**, continue to step 3 without pulling anything.

If the user says **yes**:

1. Require `<KEY>` and a configured `OBSIDIAN_VAULT_PATH`. If either is
   missing, explain that the meeting cannot be imported into the ticket and
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
   one title appears to match the Jira ticket. If the user declines or no
   meeting is selected, continue without importing one.
5. For the selected note, pull its detail with `include=transcript`, then
   create a new Markdown page in the existing Obsidian ticket folder
   `Dev/Tickets/<KEY>` using `obsidian_ticket_dir`. Name it
   `granola-<GRANOLA_ID>.md` so the same meeting cannot be imported twice.
6. Do not overwrite an existing page silently. If that file already exists,
   tell the user it is already imported and ask whether to use it or choose
   another meeting.
7. The new page must contain frontmatter for `ticket`, `granola_id`, `title`,
   `created_at`, `updated_at`, `granola_url`, and `imported_at`, followed by
   the meeting title, summary, attendees, and full transcript when returned
   by Granola. Preserve the source content; do not invent or summarize it.
8. Confirm the imported page path to the user before proceeding with the
   development flow.

The Granola pull and Obsidian import are read-only with respect to the code
repository. If the API, MCP, or vault write fails, report the exact failure
and ask whether to continue without Granola; do not start implementation
silently after a failed requested import.

### 3. Choose the development flow

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

This choice only affects how requirements are refined beforehand — implementation proceeds with SDD, regardless of which option was picked.

### 4. Proceed with SDD

Always use Spec-Driven Development for the implementation. Follow the SDD workflow available in the current environment.

### 4a. Check the implementation size

Before treating the feature as complete, measure the code changes against
`$BASE_COMMIT`. Count added plus deleted lines only in source and test-code files;
exclude Markdown/docs, generated files, lockfiles, vendored files, images and other
non-code assets. Use `git diff --numstat "$BASE_COMMIT"` and classify the paths
manually when the extension is ambiguous.

If the total is greater than **300 lines of code**, always pause and ask the user:

```text
Le modifiche superano 300 righe di codice. Vuoi splittare questa feature in task più piccoli e indipendenti, organizzati in una PR stack?
```

Do not assume the answer. If the user says **yes**, propose a minimal decomposition
into independently reviewable tasks/PRs, ordered by dependency, and wait for approval
before continuing as a single feature. Do not create Jira tasks, branches or PRs
automatically from this check. If the user says **no**, continue with the current
implementation and record that the user explicitly chose not to split it.

### 5. Run the full test suite

Run the **complete test suite** to ensure no regressions:

Read `references/run-tests.md` (in the plugin root) and follow the instructions to find and run the project's full tests/lint/checks.

### 6. Update documentation

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

### 7. Log to Obsidian (optional)

Only if a Jira ticket was found in step 1 (`<KEY>` is set). Follow `references/obsidian-log.md`.

Copy any SDD documents produced during the implementation into the ticket's Obsidian folder:

```bash
source "scripts/helpers.sh"
load_env

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  DOCS_DIR=$(obsidian_copy_ticket_docs "${OBSIDIAN_VAULT_PATH}" "<KEY>" "sdd" <SDD_DOCUMENTS...>)

  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "<SDD_SUMMARY> — SDD docs in [docs](docs/sdd)"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — implemented via SDD"
fi
```

### 8. Final confirmation

Show the user:
- ✅ Feature/fix implemented via SDD
- ✅ Tests: full suite green (all scripts passed)
- ✅ Documentation updated: `<list of files/pages>` (if applicable)
- ✅ Obsidian: SDD docs logged under `<KEY>/docs` (or "skipped, no vault configured")
- ✅ Granola context page: `<path>` (if imported, otherwise "skipped")
- → Suggest the next step: `/thebous-os:serve-up` to try it in a browser, or `/thebous-os:create-pr` to open the PR
