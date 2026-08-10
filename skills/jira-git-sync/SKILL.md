---
name: jira-git-sync
description: Git → Jira → Slack → Confluence workflow automation. Use when the user wants to start a task from a Jira ticket, create a branch, open/review/merge a PR, tag a release, or sync Confluence docs with code. Invocable per-workflow (e.g. "run new-branch", "merge the PR via jira-git-sync") — the relevant command file is read on demand, not all loaded at once.
---

# jira-git-sync

A bundle of 13 git/Jira/Slack/Confluence workflows, part of the thebous-os plugin. Each one lives as a plain markdown file under `${CLAUDE_PLUGIN_ROOT}/commands/`. **Do not read them all** — only read the specific one the user is asking for, then follow its numbered steps.

Shared helpers (read on demand when a step references them):
- `${CLAUDE_PLUGIN_ROOT}/references/jira-transition.md` — standard Jira transition + comment pattern
- `${CLAUDE_PLUGIN_ROOT}/references/run-tests.md` — how to find and run this project's test suite
- `${CLAUDE_PLUGIN_ROOT}/references/naming-conventions-{code,db,nextjs}.md` — naming rules applied during `cook` and `review-pr`
- `${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh` — bash helpers for credential loading, Jira REST, Slack, slugification

Credentials are shared with the rest of thebous-os (morning-briefing, end-of-day), read from `${CLAUDE_PLUGIN_DATA:-$HOME/.config/thebous-os}/.env`. If missing, tell the user to run `/thebous-os:setup` first.

## Workflows

Map the user's request to one of these files and `read` it before acting:

| User intent | File |
|---|---|
| Configure Jira/Slack/Confluence/Obsidian/GitHub/Gmail credentials (first run) | `commands/setup.md` |
| "Start this ticket", "create a branch for DC-443" | `commands/new-branch.md` |
| "Implement this", "cook the feature", "fix the bug" | `commands/cook.md` |
| "Run it locally", "start the app", "spin up the service" | `commands/serve-up.md` |
| "Stop the service", "tear it down", "shut it off" | `commands/serve-down.md` |
| "Open a PR", "create pull request" | `commands/create-pr.md` |
| "Review this PR", "look at PR #N" | `commands/review-pr.md` |
| "Address review comments", "fix the review feedback" | `commands/address-review.md` |
| "Verify resolved comments", "check if feedback was fixed" | `commands/verify-resolved.md` |
| "Merge the PR", "ship it" | `commands/merge-pr.md` |
| "Tag a release", "cut v1.2.3" | `commands/tag.md` |
| "Create a Confluence page from this code" | `commands/create-doc.md` |
| "Update the Confluence doc for this" | `commands/update-doc.md` |

## How to invoke

1. Identify which workflow the user wants from the table above.
2. `read` the matching `${CLAUDE_PLUGIN_ROOT}/commands/<name>.md` file.
3. Follow its numbered steps exactly — those steps are the source of truth, this `SKILL.md` is only a router.
4. If a step says "Follow `references/<x>.md`", `read` that file (under `${CLAUDE_PLUGIN_ROOT}/references/`) too and apply the pattern.
5. Source `${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh` when a step needs bash helpers.

The full workflow table and same instructions also live in `AGENTS.md` at the repo root (for agents that read AGENTS.md directly instead of loading skills).