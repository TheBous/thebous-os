# End of Day — Setup & Usage

This skill is part of the unified **thebous-os** plugin — see the root `README.md` for installing the whole plugin. This file only covers what's specific to end-of-day.

## Installation

### Claude Code

```bash
/plugin install thebous-os@thebous-os
```

### OpenCode / Codex

```bash
opencode plugin install github:TheBous/thebous-os
```

Restart OpenCode. The command is immediately available as `/end-of-day`.

## Configuration (first run only, shared with the rest of thebous-os)

```bash
/thebous-os:setup       # Claude Code
/setup                  # OpenCode / Codex
```

This single setup covers Jira/Slack/Confluence (for the git workflow) plus everything end-of-day needs:
- `OBSIDIAN_VAULT_PATH`: path to your Obsidian vault (leave blank to skip Obsidian logging)
- `GITHUB_REPOS`: used only as a fallback when there's no Obsidian daily note to read from

Saved to `~/.config/thebous-os/.env`, shared across every command and skill in the plugin.

## Manual Invocation

Run anytime:

```bash
/thebous-os:end-of-day    # Claude Code
/end-of-day                # OpenCode / Codex
```

Output appears in chat + saved to Obsidian daily note (if configured).

## Troubleshooting

**No Claude Code or OpenCode sessions found:**

- Make sure Claude Code / OpenCode are running while you run the recap
- The script captures sessions with activity today (last `lastActivityAt` timestamp)
- Sessions archived before today won't appear
