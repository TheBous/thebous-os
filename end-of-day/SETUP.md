# End of Day — Setup & Usage

## Installation

### Claude Code

```bash
/plugin install end-of-day@thebous-os
```

Configuration (optional, first run only):

```bash
/end-of-day:run
```

### OpenCode / Codex

**From npm/GitHub (recommended):**

```bash
opencode plugin install @thebous/end-of-day-opencode-plugin
```

**Or directly from GitHub:**

```bash
opencode plugin install github:TheBous/thebous-os#end-of-day
```

Restart OpenCode. The command is immediately available as `/end-of-day-run`

**Local installation (development):**

1. Clone or sync the [thebous-os](https://github.com/TheBous/thebous-os) repository
2. Add the plugin to your `opencode.json`:

```json
{
  "plugin": ["./thebous-os/.opencode/plugins/thebous-os.mjs"]
}
```

(Adjust path if you cloned elsewhere — it should point to the thebous-os directory relative to your OpenCode config)

3. Restart OpenCode

Configuration (first run only):

```bash
/end-of-day-run
```

The first run will ask for:
- `OBSIDIAN_VAULT_PATH`: path to your Obsidian vault (leave blank to skip Obsidian logging)

This is saved to `~/.config/end-of-day/.env` for future runs.

## Manual Invocation

Run anytime:

```bash
/end-of-day:run              # Claude Code
/end-of-day-run              # OpenCode / Codex
```

Output appears in chat + saved to Obsidian daily note (if configured).

## Troubleshooting

**No Claude Code or OpenCode sessions found:**

- Make sure Claude Code / OpenCode are running while you run the recap
- The script captures sessions with activity today (last `lastActivityAt` timestamp)
- Sessions archived before today won't appear
