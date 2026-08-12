---
name: cook
description: Develop a feature or fix on the current branch, run tests, and update documentation
---

## Goal

Implement a feature or fix starting from the context of the current branch/ticket, ensuring tests pass and documentation is up to date.

## Steps

### 1. Gather context

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

### 2. Choose the development flow

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
- If they choose **3 or 4**: proceed to step 3

This choice only affects how requirements are refined beforehand — implementation proceeds with SDD, regardless of which option was picked.

### 3. Proceed with SDD

Always use Spec-Driven Development for the implementation. Follow the SDD workflow available in the current environment.

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
source "${CLAUDE_PLUGIN_DATA}/.env"
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
source "${CLAUDE_PLUGIN_DATA}/.env"
source "scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  TICKET_DIR=$(obsidian_ticket_dir "${OBSIDIAN_VAULT_PATH}" "<KEY>")
  mkdir -p "$TICKET_DIR/docs"
  cp <SDD documents> "$TICKET_DIR/docs/"

  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "<SDD_SUMMARY> — SDD docs in [[<KEY>/docs]]"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — implemented via SDD"
fi
```

### 8. Link a Granola call (optional)

Only if `OBSIDIAN_VAULT_PATH` is set and `<KEY>` is set:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "scripts/helpers.sh"
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ]; then
  obsidian_granola_candidates "${OBSIDIAN_VAULT_PATH}" 14
fi
```

If it lists anything, show up to 5 candidates (filename + `title:` frontmatter) and ask: "Link one of these calls to `<KEY>`? (number or 'no')". On a pick:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "scripts/helpers.sh"
CALLS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "calls.md")
echo "- [[Granola/<chosen-filename-without-.md>]] — linked $(date +%Y-%m-%d)" >> "$CALLS_FILE"
```

If the list is empty or the user declines, skip silently.

### 9. Final confirmation

Show the user:
- ✅ Feature/fix implemented via SDD
- ✅ Tests: full suite green (all scripts passed)
- ✅ Documentation updated: `<list of files/pages>` (if applicable)
- ✅ Obsidian: SDD docs logged under `<KEY>/docs` (or "skipped, no vault configured")
- ✅ Granola call linked: `<note>` (if applicable, otherwise omit this line)
- → Suggest the next step: `/thebous-os:serve-up` to try it in a browser, or `/thebous-os:create-pr` to open the PR
