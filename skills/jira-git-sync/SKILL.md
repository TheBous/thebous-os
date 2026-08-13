---
name: jira-git-sync
description: Git → Jira → Slack → Confluence workflow automation. Use when the user wants to start a task from a Jira ticket, create a branch, open/review/merge a PR, tag a release, or sync Confluence docs with code. Route the request to the matching workflow skill instead of reading command adapters.
---

# jira-git-sync

Use this skill as an index for the Jira/Git/Slack/Confluence workflows. The complete workflow instructions live in the matching canonical skill under `skills/`; root `commands/*.md` files are compatibility adapters only.

Shared helpers and references, loaded only when the selected workflow requires them:

- `references/jira-transition.md` — standard Jira transition and comment pattern
- `references/run-tests.md` — how to find and run this project's test suite
- `references/naming-conventions-{code,db,nextjs}.md` — naming rules applied during `cook` and `review-pr`
- `scripts/helpers.sh` — credential loading, Jira REST, Slack, slugification

Credentials are shared with the rest of thebous-os and live in `${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}/.env`. If the file is missing, tell the user to run `/thebous-os:setup` first.

## Workflow index

Map the user's request to the matching skill:

| User intent | Skill |
|---|---|
| Configure Jira/Slack/Confluence/Obsidian/GitHub/Gmail credentials (first run) | `skills/setup/SKILL.md` |
| "Create a Jira task", "open a task with the standard template" | `skills/create-jira-task/SKILL.md` |
| "Start this ticket", "create a branch for DC-443" | `skills/new-branch/SKILL.md` |
| "Implement this", "cook the feature", "fix the bug" | `skills/cook/SKILL.md` |
| "Run it locally", "start the app", "spin up the service" | `skills/serve-up/SKILL.md` |
| "Stop the service", "tear it down", "shut it off" | `skills/serve-down/SKILL.md` |
| "Open a PR", "create pull request" | `skills/create-pr/SKILL.md` |
| "Review this PR", "look at PR #N" | `skills/review-pr/SKILL.md` |
| "Address review comments", "fix the review feedback" | `skills/address-review/SKILL.md` |
| "Verify resolved comments", "check if feedback was fixed" | `skills/verify-resolved/SKILL.md` |
| "Merge the PR", "ship it" | `skills/merge-pr/SKILL.md` |
| "Tag a release", "cut v1.2.3" | `skills/tag/SKILL.md` |
| "Create a Confluence page from this code" | `skills/create-doc/SKILL.md` |
| "Update the Confluence doc for this" | `skills/update-doc/SKILL.md` |

## Invocation

1. Identify the matching workflow skill from the table.
2. Read that `skills/<name>/SKILL.md` file in full.
3. Follow its instructions in order.
4. If it references `references/<x>.md`, read that file from `references/`.
5. If it needs a helper, source it from `scripts/helpers.sh`.

Do not read every workflow into context and do not route through a provider-specific command file.
