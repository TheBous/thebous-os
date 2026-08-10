# thebous-os — agent instructions

Git workflow automation synced with Jira, Slack, and Confluence, plus a morning briefing and an end-of-day recap. Originally packaged as a Claude Code plugin, but the workflows below are plain instructions any coding agent can follow.

Full step-by-step logic for each workflow lives in `commands/*.md` (shared helpers in `references/*.md`, shell helpers in `scripts/helpers.sh`). The morning-briefing and end-of-day skills have their own routers at `skills/morning-briefing/SKILL.md` and `skills/end-of-day/SKILL.md`. Read the matching file before running a workflow.

## Workflows

| File | What it does |
|---|---|
| `commands/setup.md` | Configure Jira, Slack, Confluence, Obsidian, GitHub, Gmail credentials (single setup for the whole plugin) |
| `commands/new-branch.md` | Create branch from Jira ticket, move ticket to In Progress, notify Slack |
| `commands/cook.md` | Implement feature/fix: write code, run tests, update docs |
| `commands/serve-up.md` | Detect the runtime (compose/Dockerfile/package.json) and start the app detached on localhost |
| `commands/serve-down.md` | Stop and clean up the local service started by serve-up |
| `commands/create-pr.md` | Open PR against main, link Jira, notify Slack |
| `commands/review-pr.md` | Analyze PR: correctness, naming, coverage + structured review |
| `commands/address-review.md` | Resolve review comments one-by-one, update docs |
| `commands/verify-resolved.md` | Verify that your review comments on someone else's PR were correctly addressed |
| `commands/merge-pr.md` | Merge PR, move ticket to In Staging, notify Slack |
| `commands/tag.md` | Create release tag, transition tickets to Done, notify Slack |
| `commands/create-doc.md` | Generate new Confluence page from code |
| `commands/update-doc.md` | Update existing Confluence page with latest changes |
| `commands/morning-briefing.md` | Generate the morning briefing (PR reviews, Jira, email, calendar, priority ranking) |
| `commands/morning-briefing-schedule.md` | Set up the daily 9 AM scheduled task for the morning briefing |
| `commands/end-of-day.md` | Generate the end-of-day recap (today's work + Claude Code/OpenCode sessions) |

## Requirements

- Authenticated `gh` CLI (`gh auth login`)
- Jira account with API token, or an Atlassian MCP server configured in your agent (same MCP tools referenced in the commands: `getJiraIssue`, `transitionJiraIssue`, `searchConfluenceUsingCql`, etc.)
- Slack Incoming Webhook

## Credentials

Commands read `${CLAUDE_PLUGIN_DATA:-$HOME/.config/thebous-os}/.env` — one shared file for every workflow and skill in this plugin. Outside Claude Code, `CLAUDE_PLUGIN_DATA` is unset, so credentials are read from `~/.config/thebous-os/.env` — run through `commands/setup.md` once to create it.

## Running a workflow outside Claude Code

These are markdown files with a `description` header and numbered steps — no plugin runtime required. Three ways to use them:

1. **Ad hoc**: tell your agent to read the relevant `commands/<name>.md` file (or `skills/<skill-name>/SKILL.md` for morning-briefing/end-of-day) and follow it.
2. **As a native custom command**: copy the file into your tool's custom-prompt/command directory (e.g. Codex CLI: `~/.codex/prompts/`) so it's invocable the same way `/thebous-os:<name>` works in Claude Code.
3. **OpenCode plugin (native)**: see `.opencode/README.md` — `opencode plugin install github:TheBous/thebous-os` registers every command from `commands/*.md` automatically, no symlinks needed.