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
/morning-briefing:schedule
```

Creates a daily cron task at 9:00 AM (local time), using Claude Code's built-in scheduled tasks. Task runs automatically when the app is open; if closed at 9:00 AM, it runs on next app launch.

### OpenCode / Codex / Command Line (manual cron)

Neither tool has a built-in scheduler equivalent to Claude Code's — use your
system's native cron to invoke it. The exact non-interactive invocation
syntax depends on the harness's CLI (check its `--help` or docs for a
non-interactive/print mode); the general shape:

**macOS/Linux:**

```bash
# Add to crontab
crontab -e

# Append this line (runs at 9:00 AM local time) — adjust the command to
# whatever your harness's non-interactive invocation actually looks like:
0 9 * * * cd /path/to/thebous-os && <harness-cli> "run the morning-briefing skill at morning-briefing/SKILL.md"
```

**Windows (Task Scheduler):**

Create a scheduled task:
- Trigger: Daily, 9:00 AM
- Action: run the harness's CLI non-interactively, same command as above

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
