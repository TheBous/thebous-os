# Morning Briefing — Setup & Usage

## Installation

All platforms (Claude Code, OpenCode, Codex):

```bash
/plugin install morning-briefing@thebous-os
```

Configuration (optional, first run only):

```bash
/morning-briefing:run
```

The first run will ask for:
- `GITHUB_REPOS`: list of repos to check (comma-separated, leave blank for all your repos)
- `OBSIDIAN_VAULT_PATH`: path to your Obsidian vault (leave blank to skip Obsidian logging)

These are saved to `~/.config/morning-briefing/.env` for future runs.

## Daily Scheduling

### Claude Code (automatic)

```bash
/thebous-jira-git-sync:setup-morning-briefing
```

Creates a daily cron task at 9:00 AM (local time). Task runs automatically when the app is open; if closed at 9:00 AM, it runs on next app launch.

### OpenCode / Codex / Command Line (manual cron)

Use your system's native cron:

**macOS/Linux:**

```bash
# Add to crontab
crontab -e

# Append this line (runs at 9:00 AM local time):
0 9 * * * /path/to/claude /plugin run morning-briefing@thebous-os
```

**Windows (Task Scheduler):**

Create a scheduled task:
- Trigger: Daily, 9:00 AM
- Action: Run program `/path/to/claude.exe` with arguments `/plugin run morning-briefing@thebous-os`

### Manual Invocation (all platforms)

Run anytime from any platform:

```bash
/morning-briefing:run
```

Output appears in chat + saved to Obsidian daily note (if configured).

## Troubleshooting

**"command not found: /plugin"**
- You're not in Claude Code. Use `/morning-briefing:run` instead, or set up system cron (see above).

**No output / permission denied**
- Verify `GITHUB_REPOS` and `OBSIDIAN_VAULT_PATH` in `~/.config/morning-briefing/.env`
- Check GitHub CLI auth: `gh auth status`
- For Obsidian: ensure path exists and is readable

**Task ran but didn't save to Obsidian**
- `OBSIDIAN_VAULT_PATH` may be unset or invalid. Check `.env` and fix, re-run.
