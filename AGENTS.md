# thebous-os — agent instructions

Git workflow automation synced with Jira, Slack, and Confluence, plus a morning briefing and an end-of-day recap. Originally packaged as a Claude Code plugin, but the workflows below are plain instructions any coding agent can follow.

Full step-by-step logic for each workflow lives in `skills/*/SKILL.md` (shared helpers in `references/*.md`, shell helpers in `scripts/helpers.sh`). Root `commands/*.md` files are compatibility adapters for command-based hosts. Read the matching skill before running a workflow.

## Skill architecture

- `skills/<name>/SKILL.md` is the canonical, provider-neutral workflow source.
- `commands/<name>.md` is a thin compatibility adapter for command-based hosts; it must not contain workflow logic.
- Supporting material belongs in `references/`, `scripts/`, or the skill's own resource directories and must be referenced with relative paths.
- Provider manifests, hooks, and discovery adapters may live under provider-specific directories, but must delegate to the canonical skill.

## Workflows

| File | What it does |
|---|---|
| `commands/setup.md` | Configure Jira, Slack, Confluence, Obsidian, GitHub, Gmail credentials (single setup for the whole plugin) |
| `commands/create-jira-task.md` | Create a Jira task with the fixed Italian description and acceptance-criteria template |
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

Commands read `${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}/.env` — one shared file for every workflow and skill in this plugin. Provider adapters may set `THEBOUS_OS_DATA_DIR`; otherwise credentials are read from `~/.config/thebous-os/.env`. Run through `commands/setup.md` once to create it.

## Running a workflow outside Claude Code

These are Markdown skills with optional command adapters — no plugin runtime required for the canonical workflow. Four ways to use them:

1. **Ad hoc**: tell your agent to read the relevant `skills/<skill-name>/SKILL.md` file and follow it.
2. **Codex plugin (native)**: `codex plugin marketplace add TheBous/thebous-os` then `codex plugin add thebous-os@thebous-os`. `.codex-plugin/plugin.json` points Codex at the same `skills/` directory Claude Code uses — every skill becomes available as `@<skill-name>` (e.g. `@jira-git-sync`, `@morning-briefing`). No separate content to maintain; it's the identical `skills/` folder.
3. **OpenCode plugin (native)**: see `.opencode/README.md` — `opencode plugin install github:TheBous/thebous-os` registers every command from `commands/*.md` automatically, no symlinks needed.
4. **Any other agent, manually**: copy the file into your tool's custom-prompt/command directory so it's invocable the same way `/thebous-os:<name>` works in Claude Code.
