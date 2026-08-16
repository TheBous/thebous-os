---
name: end-of-day
description: Generate the user's end-of-day recap on request or when run as the scheduled evening task. Summarize today's work from the Obsidian daily note (or GitHub/Jira when unavailable), and report Claude Code and OpenCode sessions touched today with their title and project. Always use this skill for end-of-day recaps and scheduled evening runs.
---

# End of Day Recap

The opposite of the morning briefing: look back at what happened today. Keep
two dimensions distinct:

1. **Work completed** — branches, PRs, reviews, and Jira tasks.
2. **AI activity** — Claude Code/OpenCode sessions used today and their locations.

## Configuration

Credentials are shared by the entire plugin in
`${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}/.env`.
Use `OBSIDIAN_VAULT_PATH` and `GITHUB_REPOS` only as documented here; do not
duplicate configuration.

```bash
source "scripts/helpers.sh"
load_env
```

If the file does not exist, tell the user to run `/thebous-os:setup` first.

## Step 1: Today's window

```bash
export TZ="Europe/Rome"
TODAY=$(date +%Y-%m-%d)
TODAY_START_ISO=$(date -v0H -v0M -v0S -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d "today 00:00" -u +%Y-%m-%dT%H:%M:%SZ)
```

## Step 2: Today's work — Obsidian with fallback

If `OBSIDIAN_VAULT_PATH` is configured, look for `Dev/Daily/<TODAY>.md`:

```bash
DAILY_NOTE="${OBSIDIAN_VAULT_PATH}/Dev/Daily/${TODAY}.md"
[ -f "$DAILY_NOTE" ] && cat "$DAILY_NOTE"
```

If it contains more than its header (`# <date>`), reorganize it into a readable
summary. thebous-os commands (`new-branch`, `cook`, `review-pr`, `address-review`,
`create-pr`) already write there during the day; do not paste the note raw.

If Obsidian is unavailable, the file is missing, or it contains only the header,
query GitHub and Jira directly using the morning-briefing style. An empty note
means no thebous-os command was used, not that no work was done.

```bash
REPO_FILTER=$(source "scripts/helpers.sh"; gh_repo_filter)
gh search prs --author=@me --created=">=${TODAY}" $REPO_FILTER --json number,title,url,repository,state --limit 30
gh search prs --author=@me --merged-at=">=${TODAY}" $REPO_FILTER --json number,title,url,repository --limit 30
```

For Jira, resolve the same `cloudId` as in the morning briefing
(`getAccessibleAtlassianResources`), then query:

```
jql: assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC
fields: ["summary", "status", "project"]
```

## Step 3: Claude Code sessions today

Use `list_sessions` with a high limit (for example, 50), keeping sessions whose
`lastActivityAt` date matches `$TODAY`. Comparing the `YYYY-MM-DD` portion is
sufficient for a daily personal recap. The current recap session is excluded by
design and is not work completed today.

For every session show `title` (or a truncated `sessionId`) and `cwd`.

## Step 4: OpenCode sessions today

Use OpenCode's native APIs (`session_list` / `session_info`). They do not require
authentication and work even when the HTTP API requires a bearer token:

```bash
# Pseudo-code; use the OpenCode CLI or API available in the harness
sessions = opencode.session_list()
today_sessions = sessions.filter(s => s.time.updated.date() == today)
```

For each session show `title` (derived from the first message when absent),
`location.directory`, and optionally `cost`/`tokens`. Sort by descending
`time.updated`. If OpenCode is unavailable, return `[]`; it is optional and must
not block the recap.

## Step 5: Compose the report

```markdown
# 🌙 End of Day Recap — <TODAY>

## 📋 Today's work
<reorganized daily-note content, or fallback results>

## 🤖 Claude Code sessions
- <title or truncated sessionId> — <cwd>

## 💻 OpenCode sessions
- <title> — <location.directory>
```

If a section has no results, write `None`; do not omit it. Show the report in
the user's language.

## Step 6: Save to the Obsidian daily note

When configured, append with the bundled script and never overwrite existing text:

```bash
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  bash "scripts/append_daily_note.sh" "${OBSIDIAN_VAULT_PATH}" "<path to the report from step 5>" "30 - End of Day Recap.md" "End of Day Recap"
fi
```

## Step 7: Final confirmation

Use one line: `📓 Also saved to Obsidian` or `📓 Obsidian not configured — chat only`.
