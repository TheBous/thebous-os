# Morning Briefing — Setup & Usage

This skill is part of the unified **thebous-os** plugin — see the root `README.md` for installing the whole plugin. This file only covers what's specific to morning-briefing.

## Installation

### Claude Code

```bash
/plugin install thebous-os@thebous-os
```

### OpenCode / Codex

```bash
opencode plugin install github:TheBous/thebous-os
```

Restart OpenCode. Commands are immediately available, including `/morning-briefing` and `/morning-briefing-schedule`.

## Configuration (first run only, shared with the rest of thebous-os)

```bash
/thebous-os:setup       # Claude Code
/setup                  # OpenCode / Codex
```

This single setup covers Jira/Slack/Confluence (for the git workflow) plus everything morning-briefing needs:
- `GITHUB_REPOS`: list of repos to check (comma-separated, leave blank for all your repos)
- `OBSIDIAN_VAULT_PATH`: path to your Obsidian vault (leave blank to skip Obsidian logging)
- `GMAIL_ADDRESS` / `GMAIL_APP_PASSWORD`: only needed on harnesses **without** a native Gmail connector (OpenCode, Codex). On Claude Code with the Gmail connector already authorized, leave both blank.

Saved to `~/.config/thebous-os/.env`, shared across every command and skill in the plugin.

### Gmail App Password (OpenCode, Codex, or any harness without a native Gmail connector)

1. Enable 2-Step Verification on your Google account, if not already on.
2. Go to https://myaccount.google.com/apppasswords and generate a new App Password (16 characters, no spaces).
3. Set `GMAIL_ADDRESS` to your Gmail address and `GMAIL_APP_PASSWORD` to that 16-char password in the `.env`.

This uses plain IMAP under the hood — no OAuth app registration, no per-harness setup. It works identically regardless of which harness calls it, since it's just a stored secret and a stdlib IMAP connection.

## Daily Scheduling

### Claude Code (automatic)

```bash
/thebous-os:morning-briefing-schedule
```

Creates a daily cron task at 9:00 AM (local time), using Claude Code's built-in scheduled tasks. Task runs automatically when the app is open; if closed at 9:00 AM, it runs on next app launch.

### OpenCode / Codex / Command Line (manual cron fallback)

Neither tool has a guaranteed built-in scheduler — use your system's native cron. The command shape depends on how each harness's CLI works:

```bash
# Add to crontab
crontab -e

# Append this line (runs at 9:00 AM local time):
# Adjust the harness invocation to match your CLI's non-interactive mode
0 9 * * * cd /path/to/thebous-os && opencode "run /morning-briefing"
```

Consult your harness's `--help` or docs for the exact non-interactive invocation syntax.

## Manual Invocation

Run anytime:

```bash
/thebous-os:morning-briefing    # Claude Code
/morning-briefing                # OpenCode / Codex
```

Output appears in chat + saved to Obsidian daily note (if configured).

## Troubleshooting

**No output / permission denied**
- Verify `GITHUB_REPOS` and `OBSIDIAN_VAULT_PATH` in `~/.config/thebous-os/.env`
- Check GitHub CLI auth: `gh auth status`
- For Obsidian: ensure path exists and is readable

**Task ran but didn't save to Obsidian**
- `OBSIDIAN_VAULT_PATH` may be unset or invalid. Check `.env` and fix, re-run.
