# Obsidian logging (standard pattern)

Whenever a step needs to log activity to the user's Obsidian vault or link a
Granola call, follow this pattern. It is always optional and non-blocking:
if `OBSIDIAN_VAULT_PATH` is unset, the directory doesn't exist, or there's no
Jira ticket in scope, **skip the step silently** — never fail or warn about it.

## Setup (every time)

```bash
source "scripts/helpers.sh"
if [ -f "$ENV_FILE" ]; then load_env; fi
```

Then guard every Obsidian write with:

```bash
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  ...
fi
```

## Vault structure

```
Dev/
  Tickets/
    <KEY>/
      plan.md            # from cook's SDD chain
      review.md          # from review-pr
      address-review.md  # from address-review
      calls.md           # wikilinks to related Granola notes
      docs/              # shared destination for generated documentation
  Daily/
    <YYYY-MM-DD>.md      # index for the day
```

Every ticket file starts with frontmatter (`ticket`, `pr`, `status`, `date`).
Writes are additive: append a dated section or bullet, never truncate.

## Helper functions (`scripts/helpers.sh`)

| Function | Signature | Does |
|---|---|---|
| `obsidian_ticket_dir` | `(vault, key)` | Echoes `<vault>/Dev/Tickets/<key>` |
| `obsidian_ticket_docs_dir` | `(vault, key)` | Echoes the shared `<vault>/Dev/Tickets/<key>/docs` directory |
| `obsidian_copy_ticket_docs` | `(vault, key, relative_dir, sources...)` | Copies files/directories into the shared ticket docs directory and echoes the destination |
| `obsidian_ensure_ticket_file` | `(vault, key, filename)` | Creates the ticket dir + file with frontmatter if missing, echoes the path — idempotent |
| `obsidian_set_pr` | `(file, pr_url)` | Inserts/updates the `pr:` frontmatter line — idempotent |
| `obsidian_append_section` | `(file, body)` | Appends a dated `## <timestamp>` section |
| `obsidian_append_daily` | `(vault, line)` | Appends `- <line>` to today's daily note, creating it if needed |
| `obsidian_log_ticket` | `(vault, key, filename, section, daily_line)` | Ensures a ticket file and optionally appends a section and daily line |
| `obsidian_log_pr` | `(vault, key, pr_url, daily_line)` | Ensures `plan.md`, records the PR URL, and appends a daily line |
| `obsidian_copy_daily_artifact` | `(vault, name, source_dir)` | Copies a generated artifact directory into today's `Dev/Daily/<date>` folder and echoes the destination |
| `obsidian_granola_candidates` | `(vault, days=14)` | Lists `.md` files under `<vault>/Granola/` modified in the last `days` days |

All workflows that generate ticket documentation must use
`obsidian_ticket_docs_dir` or `obsidian_copy_ticket_docs`; do not rebuild the
`Dev/Tickets/<KEY>/docs` path or copy logic inside an individual skill.

For ordinary workflow logging, use `obsidian_log_ticket` or `obsidian_log_pr`
instead of repeating the setup, vault guard, file creation, and append boilerplate.

## Granola linking

Granola sync is handled entirely by the user's own
[Granola-to-Obsidian](https://github.com/dannymcc/Granola-to-Obsidian)
Obsidian community plugin, syncing into `<vault>/Granola/`. This plugin's
commands never talk to Granola directly — they only read that folder.

To offer a link (in `new-branch` and `cook`):

```bash
source "scripts/helpers.sh"
if [ -f "$ENV_FILE" ]; then load_env; fi
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ]; then
  obsidian_granola_candidates "${OBSIDIAN_VAULT_PATH}" 14
fi
```

If it lists anything, show the user up to 5 candidates (filename + the note's
`title:` frontmatter line) and ask which one (if any) relates to this ticket.
On a pick, append a line to `calls.md`:

```bash
source "scripts/helpers.sh"
if [ -f "$ENV_FILE" ]; then load_env; fi
CALLS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "calls.md")
echo "- [[Granola/<filename-without-.md>]] — linked $(date +%Y-%m-%d)" >> "$CALLS_FILE"
```

Never auto-pick a note — always wait for the user's explicit choice. If the
list is empty or the user declines, skip silently.
