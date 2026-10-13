# thebous-os OpenCode Plugin

This directory contains the OpenCode adapter for thebous-os — a single unified package covering:
- Git/Jira/Slack/Confluence workflow (new-branch, create-pr, PR review, merge, release)

The source of truth is `../skills/<name>/SKILL.md`.

## How it works

- **`plugins/thebous-os.mjs`** — Entry point that self-locates via `import.meta.url`. Adds the canonical `skills/` directory to OpenCode's native skill discovery.

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

Canonical skills are available through OpenCode's native `skill` tool when the plugin is loaded: `create-jira-task`, `new-branch`, `create-pr`, `review-pr-multiharness`, `address-review`, and the rest of `skills/`.

## Initial Configuration (first run)

First run of any workflow will ask for configuration (Jira, Notion, Slack, Confluence and Obsidian) — one shared setup for the whole plugin:

```text
@setup
```

Values are saved to `${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}/.env` for future runs. Provider adapters can set `THEBOUS_OS_DATA_DIR` when a host has its own persistent data directory.
