---
name: setup
description: Configure Jira, Notion, Slack, Confluence and Obsidian credentials for thebous-os Git workflows
---

Guide the user step by step through the setup. Ask one question at a time and wait for the answer. This is the **single** setup for all of thebous-os — git/Jira/Notion/Slack/Confluence workflows all read the same `.env` written here.

**Note**: Jira and Confluence operations use the Atlassian Rovo MCP already configured in Claude Code — no manual API credentials needed.

## Steps

1. **Jira Base URL** (optional) — if Jira is configured, ask for the Jira base URL (e.g. `https://company.atlassian.net`). It is needed to build Jira links in Slack messages.

1a. **Jira Email + API Token** (optional on Claude Code, required elsewhere) — the Atlassian Rovo MCP covers Jira/Confluence calls on Claude Code, but a few paths always use direct REST instead of MCP: the curl fallback in `references/jira-transition.md` and `scripts/helpers.sh` (used if the MCP call errors). On Codex/OpenCode, where the Rovo MCP isn't available, this is the **only** way Jira calls work. Ask for the Jira account email and an API token (generate one at https://id.atlassian.com/manage-profile/security/api-tokens). Leave both blank to skip — MCP-only paths keep working on Claude Code, but the REST fallback paths will fail until this is set.

1b. **Notion Integration Token + Database ID** (optional) — ask for an internal integration token and the ID of the Notion database used for tasks. If the database contains multiple data sources, also ask for `NOTION_DATA_SOURCE_ID`; ask for `NOTION_USER_EMAIL` to scope task list queries to the current user's tasks. The integration needs read/insert/update content, user information, and comment access for the full task lifecycle. Jira and Notion can be configured independently: configure either provider or both, depending on which task source the user wants to use. Never display or log the token after receiving it.

2. **Slack Webhook URL** — explain where to create it: `api.slack.com → Your Apps → Incoming Webhooks → Add New Webhook`, then ask for the URL.

3. **Confluence Parent URL** — ask for the URL of the Confluence page that will act as the parent folder for documentation (e.g. `https://company.atlassian.net/wiki/spaces/TECH/pages/123456/Documentation`). This page must already exist. If the user doesn't use Confluence, they can skip this step by leaving it blank.

4. **Jira transition IDs (optional)** — If Jira is configured, ask the user for a Jira ticket key to inspect available transitions. Use the Atlassian Rovo MCP to fetch the transition list via `getTransitionsForJiraIssue(issueKey: "<TICKET>")`, display the available statuses, then ask them to pick the IDs for:
   - **In Progress** (when a branch is created)
   - **In Review** (when a PR is created) — skip if it doesn't exist
   - **In Staging** (when the PR is merged)
   - **Done / Released** (when tagging for production)
   Skip this step when Jira is not configured. Notion status mapping is handled by the Notion adapter and does not use Jira transition IDs.

5. **Obsidian Vault Path** (optional) — ask for the absolute path to their Obsidian vault (e.g. `/Users/me/Documents/Obsidian/myvault`), so branch/PR/review activity gets logged there automatically. Leave blank to skip — nothing breaks, the Obsidian steps in every workflow just no-op. If given, mention that call notes get linked automatically too, if they have a Granola-to-Obsidian sync plugin installed with notes landing in a `Granola/` folder at the vault root (see `references/obsidian-log.md`).

## Saving

Resolve `THEBOUS_OS_DATA_DIR` from the provider environment, falling back to `${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os`:

```bash
source "scripts/helpers.sh"
THEBOUS_OS_DATA_DIR="${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}"
```

Create that directory if it doesn't exist, then write `.env` there:

```
JIRA_BASE_URL=<value>
JIRA_EMAIL=<value or empty string>
JIRA_API_TOKEN=<value or empty string>
NOTION_API_TOKEN=<value or empty string>
NOTION_DATABASE_ID=<value or empty string>
NOTION_DATA_SOURCE_ID=<value or empty string when the database has one data source>
NOTION_USER_EMAIL=<value or empty string to leave task list queries unscoped>
JIRA_IN_PROGRESS_ID=<value>
JIRA_IN_REVIEW_ID=<value or empty string>
JIRA_IN_STAGING_ID=<value>
JIRA_DONE_ID=<value>
SLACK_WEBHOOK_URL=<value>
CONFLUENCE_PARENT_URL=<value or empty string>
OBSIDIAN_VAULT_PATH="<value or empty string>"
```

Run `mkdir -p "$THEBOUS_OS_DATA_DIR"` before writing the file. Confirm to the user that the configuration has been saved and suggest trying `/thebous-os:new-branch`.
