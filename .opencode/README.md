# thebous-os OpenCode Plugin

This directory contains the OpenCode plugin for thebous-os — a single unified plugin covering:
- Git/Jira/Slack/Confluence workflow (new-branch, cook, create-pr, review-pr, etc.)
- Morning briefing (PR reviews, Jira, email, calendar, priority ranking)
- End-of-day recap (today's work, Claude Code/OpenCode sessions)

## How it works

- **`plugins/thebous-os.mjs`** — Entry point that self-locates via `import.meta.url`. Discovers and registers every command from `commands/*.md` at the repo root — one flat directory, same commands used by the Claude Code plugin.
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

## Initial Configuration (first run)

First run of any command will ask for configuration (Jira, Slack, Confluence, Obsidian, GitHub repos, Gmail) — one shared setup for the whole plugin:

```bash
/setup
```

Values are saved to `~/.config/thebous-os/.env` for future runs.
