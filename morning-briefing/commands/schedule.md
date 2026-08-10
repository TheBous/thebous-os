---
description: Set up (or update) the daily 9:00 AM scheduled task that runs the morning briefing automatically
---

## Goal

Create the recurring scheduled task for the morning briefing, so it runs
automatically every morning without the user invoking it manually.

## Steps

### 1. Check for an existing task

Call `list_scheduled_tasks`. If a task with `taskId` `morning-briefing`
already exists, tell the user its current schedule and ask if they want to
change it (use `update_scheduled_task` if so) rather than creating a
duplicate.

### 2. Confirm the time

Default to 9:00 AM local time. Ask the user to confirm or give a different
time before creating anything — don't rely on an approval prompt to catch a
wrong guess.

### 3. Create the task

Call `create_scheduled_task` with:
- `taskId`: `morning-briefing`
- `cronExpression`: `0 9 * * *` (or the confirmed time, `minute hour * * *`)
- `description`: "Briefing mattutino: PR review notturne, PR in sospeso, commenti, scadenze Jira, task in partenza, call di oggi"
- `prompt`: a fully self-contained prompt (future runs have no memory of this
  conversation) instructing Claude to:
  1. Read `${CLAUDE_PLUGIN_ROOT}/SKILL.md` in full and execute every step in
     order, using `gh`, the Atlassian MCP tools, and the Google Calendar MCP
     tools.
  2. Since `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` may not be set
     in a scheduled-task context, substitute the actual absolute path to this
     skill's directory and `~/.config/morning-briefing` respectively,
     everywhere the SKILL.md references them.
  3. If the `.env` doesn't exist yet, create it with `GITHUB_REPOS=` (empty)
     and ask the user for `OBSIDIAN_VAULT_PATH` — but since this runs
     unattended, fall back to leaving it empty (skip Obsidian) rather than
     blocking on an answer nobody will give.
  4. Show the report as the final message, and follow the SKILL.md's own
     Obsidian-saving step if a vault path is configured.

Tell the user the task was created, its schedule, and that scheduled tasks
only run while the app is open (they run on next launch otherwise).
