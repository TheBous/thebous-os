---
description: Configure Jira, Slack, Confluence, Obsidian, GitHub and Gmail credentials for the whole thebous-os plugin (git workflow + morning-briefing + end-of-day)
---

Guide the user step by step through the setup. Ask one question at a time and wait for the answer. This is the **single** setup for all of thebous-os — git/Jira/Slack/Confluence workflows, morning-briefing, and end-of-day all read the same `.env` written here.

**Note**: Jira and Confluence operations use the Atlassian Rovo MCP already configured in Claude Code — no manual API credentials needed.

## Steps

1. **Jira Base URL** — ask for the Jira base URL (e.g. `https://company.atlassian.net`). Needed to build links in Slack messages.

2. **Slack Webhook URL** — explain where to create it: `api.slack.com → Your Apps → Incoming Webhooks → Add New Webhook`, then ask for the URL.

3. **Confluence Parent URL** — ask for the URL of the Confluence page that will act as the parent folder for documentation (e.g. `https://company.atlassian.net/wiki/spaces/TECH/pages/123456/Documentation`). This page must already exist. If the user doesn't use Confluence, they can skip this step by leaving it blank.

4. **Transition IDs** — ask the user for a Jira ticket key to inspect available transitions. Use the Atlassian Rovo MCP to fetch the transition list via `getTransitionsForJiraIssue(issueKey: "<TICKET>")`, display the available statuses, then ask them to pick the IDs for:
   - **In Progress** (when a branch is created)
   - **In Review** (when a PR is created) — skip if it doesn't exist
   - **In Staging** (when the PR is merged)
   - **Done / Released** (when tagging for production)

5. **Obsidian Vault Path** (optional) — ask for the absolute path to their Obsidian vault (e.g. `/Users/me/Documents/Obsidian/myvault`), so branch/PR/review activity, the morning briefing, and the end-of-day recap all get logged there automatically. Leave blank to skip — nothing breaks, the Obsidian steps in every workflow just no-op. If given, mention that call notes get linked automatically too, if they have a Granola-to-Obsidian sync plugin installed with notes landing in a `Granola/` folder at the vault root (see `references/obsidian-log.md`).

6. **GitHub Repos** (optional) — ask for a comma-separated list of repos to check for morning-briefing/end-of-day (e.g. `TheBous/thebous-os,TheBous/other-repo`). Leave blank to check all repos the user has access to.

7. **Gmail App Password** (optional) — only relevant on harnesses **without** a native Gmail connector (OpenCode, Codex — on Claude Code with the Gmail connector authorized, skip this). Explain: generate one at https://myaccount.google.com/apppasswords (requires 2-Step Verification on the account), then ask for the Gmail address and the 16-char App Password.

## Saving

Create the `${CLAUDE_PLUGIN_DATA:-$HOME/.config/thebous-os}` directory if it doesn't exist, then write the file `${CLAUDE_PLUGIN_DATA:-$HOME/.config/thebous-os}/.env`:

```
JIRA_BASE_URL=<value>
JIRA_IN_PROGRESS_ID=<value>
JIRA_IN_REVIEW_ID=<value or empty string>
JIRA_IN_STAGING_ID=<value>
JIRA_DONE_ID=<value>
SLACK_WEBHOOK_URL=<value>
CONFLUENCE_PARENT_URL=<value or empty string>
OBSIDIAN_VAULT_PATH="<value or empty string>"
GITHUB_REPOS=<value or empty string>
GMAIL_ADDRESS=<value or empty string>
GMAIL_APP_PASSWORD=<value or empty string>
```

Run `mkdir -p "${CLAUDE_PLUGIN_DATA:-$HOME/.config/thebous-os}"` before writing the file. Confirm to the user that the configuration has been saved and suggest trying `/thebous-os:new-branch`.
