---
description: Configure Jira, Slack, and Confluence credentials for jira-git-sync
---

Guide the user step by step through the setup. Ask one question at a time and wait for the answer.

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

5. **Obsidian Vault Path** (optional) — ask for the absolute path to their Obsidian vault (e.g. `/Users/me/Documents/Obsidian/myvault`), so branch/PR/review activity gets logged there automatically. Leave blank to skip — nothing breaks, the Obsidian steps in every workflow just no-op. If given, mention that call notes get linked automatically too, if they have a Granola-to-Obsidian sync plugin installed with notes landing in a `Granola/` folder at the vault root (see `references/obsidian-log.md`).

## Saving

Create the `${CLAUDE_PLUGIN_DATA}` directory if it doesn't exist, then write the file `${CLAUDE_PLUGIN_DATA}/.env`:

```
JIRA_BASE_URL=<value>
JIRA_IN_PROGRESS_ID=<value>
JIRA_IN_REVIEW_ID=<value or empty string>
JIRA_IN_STAGING_ID=<value>
JIRA_DONE_ID=<value>
SLACK_WEBHOOK_URL=<value>
CONFLUENCE_PARENT_URL=<value or empty string>
OBSIDIAN_VAULT_PATH="<value or empty string>"
```

Run `mkdir -p "${CLAUDE_PLUGIN_DATA}"` before writing the file. Confirm to the user that the configuration has been saved and suggest trying `/thebous-jira-git-sync:new-branch`.
