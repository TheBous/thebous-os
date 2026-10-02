# thebous-os — agent instructions

Git workflow automation synced with Jira, Slack, and Confluence, plus a morning briefing and an end-of-day recap. Originally packaged as a Claude Code plugin, but the workflows below are plain instructions any coding agent can follow.

Full step-by-step logic for each workflow lives in `skills/*/SKILL.md` (shared helpers in `references/*.md`, shell helpers in `scripts/helpers.sh`). Read the matching skill before running a workflow.

## Skill architecture

- `skills/<name>/SKILL.md` is the canonical, provider-neutral workflow source.
- Supporting material belongs in `references/`, `scripts/`, or the skill's own resource directories and must be referenced with relative paths.
- Provider manifests, hooks, and discovery adapters may live under provider-specific directories, but must delegate to the canonical skill.

## Workflows

| File | What it does |
|---|---|
| `skills/setup/SKILL.md` | Configure Jira, Slack, Confluence, Obsidian, GitHub, Gmail credentials (single setup for the whole plugin) |
| `skills/create-jira-task/SKILL.md` | Create a Jira task with the fixed Italian description and acceptance-criteria template |
| `skills/explain-change/SKILL.md` | Explain a PR, diff, code, implementation change, or text step by step with a visual HTML artifact |
| `skills/current-status/SKILL.md` | Show the user's current situation today across work, agenda, communication, and coding activity |
| `skills/new-branch/SKILL.md` | Create branch from Jira ticket, move ticket to In Progress, notify Slack |
| `skills/cook/SKILL.md` | Implement feature/fix: write code, run tests, update docs |
| `skills/create-pr/SKILL.md` | Open PR against main, link Jira, notify Slack |
| `skills/review-pr-multiharness/SKILL.md` | Analyze PR with risk-proportional multi-harness coverage and up to ten subagents |
| `skills/review-pr-multiharness-ponytail/SKILL.md` | Same as review-pr-multiharness, plus a required over-engineering deletion pass |
| `skills/address-review/SKILL.md` | Resolve review comments one-by-one, update docs |
| `skills/verify-resolved/SKILL.md` | Verify that your review comments on someone else's PR were correctly addressed |
| `skills/merge-pr/SKILL.md` | Merge PR, move ticket to In Staging, notify Slack |
| `skills/tag/SKILL.md` | Create release tag, transition tickets to Done, notify Slack |
| `skills/create-doc/SKILL.md` | Generate new Confluence page from code |
| `skills/update-doc/SKILL.md` | Update existing Confluence page with latest changes |
| `skills/morning-briefing/SKILL.md` | Generate the morning briefing (PR reviews, Jira, email, calendar, priority ranking) |
| `skills/end-of-day/SKILL.md` | Generate the end-of-day recap (today's work + Claude Code/OpenCode sessions) |

Version manifests are bumped automatically by `.github/workflows/bump-version.yml` after each push to `main`. The workflow keeps `package.json`, Claude manifests, and the Codex manifest aligned.

## Requirements

- Authenticated `gh` CLI (`gh auth login`)
- Jira account with API token, or an Atlassian MCP server configured in your agent (same MCP tools referenced in the skills: `getJiraIssue`, `transitionJiraIssue`, `searchConfluenceUsingCql`, etc.)
- Slack Incoming Webhook

## Credentials

Workflows read `${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}/.env` — one shared file for every skill in this plugin. Provider adapters may set `THEBOUS_OS_DATA_DIR`; otherwise credentials are read from `~/.config/thebous-os/.env`. Run `skills/setup/SKILL.md` once to create it.

## Running a workflow outside Claude Code

These are Markdown skills — no plugin runtime required for the canonical workflow. Four ways to use them:

1. **Ad hoc**: tell your agent to read the relevant `skills/<skill-name>/SKILL.md` file and follow it.
2. **Codex plugin (native)**: `codex plugin marketplace add TheBous/thebous-os` then `codex plugin add thebous-os@thebous-os`. `.codex-plugin/plugin.json` points Codex at the same `skills/` directory Claude Code uses — every skill becomes available as `@<skill-name>` (e.g. `@jira-git-sync`, `@morning-briefing`). No separate content to maintain; it's the identical `skills/` folder.
3. **OpenCode plugin (native)**: see `.opencode/README.md` — `opencode plugin install github:TheBous/thebous-os` registers the canonical skills from `skills/`.
4. **Any other agent, manually**: copy `skills/<name>/SKILL.md` into your tool's custom-prompt directory so it's invocable the same way `/thebous-os:<name>` works in Claude Code.
