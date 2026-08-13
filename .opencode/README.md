# thebous-os OpenCode Plugin

This directory contains the OpenCode adapter for thebous-os — a single unified package covering:
- Git/Jira/Slack/Confluence workflow (new-branch, cook, create-pr, review-pr, etc.)
- Morning briefing (PR reviews, Jira, email, calendar, priority ranking)
- End-of-day recap (today's work, Claude Code/OpenCode sessions)

The source of truth is `../skills/<name>/SKILL.md`. Root `../commands/*.md` files are thin compatibility adapters for slash-command hosts.

## How it works

- **`plugins/thebous-os.mjs`** — Entry point that self-locates via `import.meta.url`. Registers root compatibility commands and adds the canonical `skills/` directory to OpenCode's native skill discovery.
- **`plugins/thebous-os-frontmatter.cjs`** — Parser for YAML frontmatter in command files

## Zero-setup across hosts

Since the plugin self-locates, this works without:
- Installation scripts
- Symlinks with absolute paths
- Per-host configuration

**On macbook, VPS, or anywhere:** sync the repo, and `opencode.json` loads the plugin with a relative path.

## Configuration

Add to your `opencode.json`:
```json
{
  "plugin": ["./thebous-os/.opencode/plugins/thebous-os.mjs"]
}
```

Or install directly from GitHub/npm — see the root `README.md` / `package.json`.

Commands are immediately available:
- `/create-jira-task`, `/new-branch`, `/create-pr`, `/review-pr`, etc. (the git/Jira/Slack/Confluence workflow)
- `/morning-briefing` — Generate the morning briefing
- `/morning-briefing-schedule` — Set up the daily 9 AM task
- `/end-of-day` — Generate the end-of-day recap

Canonical skills are also available through OpenCode's native `skill` tool when the plugin is loaded.

## Initial Configuration (first run)

First run of any command will ask for configuration (Jira, Slack, Confluence, Obsidian, GitHub repos, Gmail) — one shared setup for the whole plugin:

```bash
/setup
```

Values are saved to `${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}/.env` for future runs. Provider adapters can set `THEBOUS_OS_DATA_DIR` when a host has its own persistent data directory.
