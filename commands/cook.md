---
description: Develop a feature or fix on the current branch, run tests, and update documentation
---

## Goal

Implement a feature or fix starting from the context of the current branch/ticket, ensuring tests pass and documentation is up to date.

## Steps

### 1. Gather context

Extract the Jira key from the current branch (pattern `[A-Za-z]+-[0-9]+`, case-insensitive — branch names use a lowercase key):
```bash
git branch --show-current
```

Uppercase the extracted key (e.g. `dc-443` → `DC-443`) before using it in any Jira call.

If found, fetch the ticket's title and description with the MCP tool `getJiraIssue` using `issueKey: "<KEY>"` and `fields: ["summary", "description"]`.

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

This choice only affects how requirements are refined beforehand — implementation always follows SDD + TDD (Spec-Driven Development + Test-Driven Development), regardless of which option was picked.

### 3. Enter the SDD workflow

Always use Spec-Driven Development. Invoke the SDD skill chain in order:

1. **`sdd-explore`** — Investigate the codebase, understand current architecture, compare approaches
2. **`sdd-propose`** — Formalize the change into a proposal with intent, scope, and approach
3. **`sdd-spec`** — Write delta specifications with requirements and scenarios
4. **`sdd-design`** — Create technical design document with architecture decisions
5. **`sdd-tasks`** — Break down the change into actionable, ordered work items
6. **`sdd-apply`** — Implement code changes following the spec and tasks
7. **`sdd-verify`** — Validate that implementation matches specs, design, and tasks
8. **`sdd-archive`** — Archive the completed change and persist the final report

After SDD completes with successful verification, proceed to step 5.

### 5. Run the full test suite

SDD's `sdd-verify` already validates targeted tests. Now run the **complete test suite** to ensure no regressions:

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

Only if a Jira ticket was found in step 1 (`<KEY>` is set). Follow `references/obsidian-log.md`. Summarize what the SDD chain produced into a few sentences (`<SDD_SUMMARY>` — not the full spec/design docs) and append it to the ticket's plan:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "<SDD_SUMMARY>"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — implemented via SDD"
fi
```

### 8. Link a Granola call (optional)

Only if `OBSIDIAN_VAULT_PATH` is set and `<KEY>` is set:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ]; then
  obsidian_granola_candidates "${OBSIDIAN_VAULT_PATH}" 14
fi
```

If it lists anything, show up to 5 candidates (filename + `title:` frontmatter) and ask: "Link one of these calls to `<KEY>`? (number or 'no')". On a pick:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
CALLS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "calls.md")
echo "- [[Granola/<chosen-filename-without-.md>]] — linked $(date +%Y-%m-%d)" >> "$CALLS_FILE"
```

If the list is empty or the user declines, skip silently.

### 9. Final confirmation

Show the user:
- ✅ Feature/fix implemented via SDD
- ✅ Spec, design, and tasks completed and archived
- ✅ Tests: full suite green (all scripts passed)
- ✅ Documentation updated: `<list of files/pages>` (if applicable)
- ✅ Obsidian: logged (or "skipped, no vault configured")
- ✅ Granola call linked: `<note>` (if applicable, otherwise omit this line)
- → Suggest the next step: `/thebous-os:serve-up` to try it in a browser, or `/thebous-os:create-pr` to open the PR
