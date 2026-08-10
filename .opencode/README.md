# thebous-os OpenCode Plugin

This directory contains the OpenCode plugin for thebous-os, dynamically discovering commands from all three skills:
- **thebous-jira-git-sync** — Git/Jira/Slack/Confluence workflow
- **morning-briefing** — Daily briefing (PR reviews, Jira, email, calendar)
- **end-of-day** — End-of-day recap (today's work, Claude Code/OpenCode sessions)

## How it works

- **`plugins/thebous-os.mjs`** — Entry point that self-locates via `import.meta.url`. Discovers and registers:
  - Commands from `commands/*.md` (thebous-jira-git-sync)
  - Commands from `morning-briefing/commands/*.md`
  - Commands from `end-of-day/commands/*.md`
  - Prefixed as `morning-briefing-run`, `morning-briefing-schedule`, `end-of-day-run`, etc.

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

Commands are immediately available:
- `/thebous-jira-git-sync:new-branch`, `/thebous-jira-git-sync:create-pr`, etc.
- `/morning-briefing-run` — Generate the morning briefing
- `/morning-briefing-schedule` — Set up the daily 9 AM task
- `/end-of-day-run` — Generate the end-of-day recap

## Initial Configuration (first run)

First run of either briefing skill will ask for configuration (GitHub repos, Obsidian vault path, Gmail):

```bash
/morning-briefing-run
```

Values are saved to `~/.config/morning-briefing/.env` for future runs.
