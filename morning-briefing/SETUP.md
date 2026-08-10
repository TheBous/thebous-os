# Morning Briefing — Setup & Usage

## Installation

### Claude Code

```bash
/plugin install morning-briefing@thebous-os
```

Configuration (optional, first run only):

```bash
/morning-briefing:run
```

### OpenCode / Codex

1. Clone or sync the [thebous-os](https://github.com/TheBous/thebous-os) repository
2. Add the plugin to your `opencode.json`:

```json
{
  "plugin": ["./thebous-os/.opencode/plugins/thebous-os.mjs"]
}
```

(Adjust path if you cloned elsewhere — it should point to the thebous-os directory relative to your OpenCode config)

3. Restart OpenCode. Commands are immediately available as `/morning-briefing-run` and `/morning-briefing-schedule`

Configuration (first run only):

```bash
/morning-briefing-run
```

The first run will ask for:
- `GITHUB_REPOS`: list of repos to check (comma-separated, leave blank for all your repos)
- `OBSIDIAN_VAULT_PATH`: path to your Obsidian vault (leave blank to skip Obsidian logging)
- `GMAIL_ADDRESS` / `GMAIL_APP_PASSWORD`: only needed on harnesses **without** a native Gmail connector (OpenCode, Codex). On Claude Code with the Gmail connector already authorized, leave both blank.

These are saved to `~/.config/morning-briefing/.env` for future runs.

### Gmail App Password (OpenCode, Codex, or any harness without a native Gmail connector)

1. Enable 2-Step Verification on your Google account, if not already on.
2. Go to https://myaccount.google.com/apppasswords and generate a new App Password (16 characters, no spaces).
3. Set `GMAIL_ADDRESS` to your Gmail address and `GMAIL_APP_PASSWORD` to that 16-char password in the `.env`.

This uses plain IMAP under the hood — no OAuth app registration, no per-harness setup. It works identically regardless of which harness calls it, since it's just a stored secret and a stdlib IMAP connection.

## Daily Scheduling

### Claude Code (automatic)

```bash
/morning-briefing:schedule
```

Creates a daily cron task at 9:00 AM (local time), using Claude Code's built-in scheduled tasks. Task runs automatically when the app is open; if closed at 9:00 AM, it runs on next app launch.

### OpenCode (automatic via OpenCode's built-in scheduler)

If OpenCode has a built-in scheduler (check the docs or settings), use it to run `/morning-briefing-run` at 9:00 AM daily.

### OpenCode / Codex / Command Line (manual cron fallback)

Neither tool has a guaranteed built-in scheduler — use your system's native cron as a fallback. The command shape depends on how each harness's CLI works:

**macOS/Linux (with OpenCode CLI available):**

```bash
# Add to crontab
crontab -e

# Append this line (runs at 9:00 AM local time):
# Adjust the harness invocation to match your OpenCode CLI's non-interactive mode
0 9 * * * cd /path/to/thebous-os && opencode "run /morning-briefing-run"
```

Consult OpenCode's `--help` or docs for the exact non-interactive invocation syntax.

**Windows (Task Scheduler):**

Create a scheduled task:
- Trigger: Daily, 9:00 AM
- Action: Run OpenCode's CLI with the same command as above

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
