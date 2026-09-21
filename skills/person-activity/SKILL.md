---
name: person-activity
description: Given a work item ID (Jira or Notion task, GitHub PR, or git commit) and a person's name/email, shows all their comments, reviews, and discussions on that work item across the selected task provider, GitHub, Slack, email, and calendar. Asks for input interactively, then presents a synthetic summary with links to each source.
---

# Person Activity on Work Item

Collects all interactions a specific person had on a given work item (Jira or Notion task, GitHub PR, or git commit) across the selected task provider, GitHub PR reviews and comments, Slack threads, email discussions, and calendar events — and synthesizes them into a single markdown report organized by timeline and source.

## When to Use

- **Before a 1:1 with someone:** Get the full context of their recent activity on a specific task or PR
- **Context-switching to a project:** Understand what person X did on a task/PR/commit while you were away
- **Reviewing someone's contribution:** See their complete involvement (comments, decisions, approvals) in one place
- **Preparing for a retrospective or handoff:** Trace their journey through a work item

## Input

The skill asks for two pieces of information:

1. **Work Item ID** — One of:
   - Jira key (e.g., `T-200`)
   - Notion page URL, page ID, or provider-qualified reference (e.g., `notion:<page-id>`)
   - GitHub PR number (e.g., `#250` or `PR 250`)
   - Git commit hash, short or long (e.g., `abc123def`)

2. **Person** — Either:
   - Email address (e.g., `marco@company.com`)
   - Full name (e.g., `Marco Rossi`)

## Output

A markdown report (<30 seconds scannable) containing:

- **Synthetic Summary**: Their role, key decisions, latest activity, overall status
- **Timeline**: All interactions ordered by date across all sources
- **Sources**: Grouped by source (Jira or Notion, GitHub, Slack, email, calendar) with direct links

Each interaction shows who, when, what, and a link to the source.

## How It Works

1. Read `references/task-context.md` and resolve the work item with
   `resolve_work_item_ref`; a provider-qualified reference is required when Jira
   and Notion candidates are both present.
2. Matches the person across systems (email, GitHub handle, Jira username, Slack user, etc.)
3. Route the selected task provider separately: for Notion, source
   `scripts/notion.sh`, call `notion_get_page`, then call `notion_list_activity`
   with the resolved Notion reference and the requested time window. Match the
   person against the activity actor when Notion supplies an identity.
4. Queries each source in parallel for interactions by that person on that work item
5. Synthesizes all results into a timeline and summary report

## Example Usage

```
Enter work item ID (Jira key, Notion page URL/ID, GitHub PR #, or git commit hash): T-200
Enter person's name or email: marco@company.com
```

→ full sample output in `references/examples.md` (Example 1).

## Notes

- Each source is **optional** — if credentials are missing or the query fails, it's skipped and reported as a coverage gap
- Jira and Notion are independent task providers; keep the selected provider source and direct link on every task interaction and never merge tasks by title
- Notion activity may expose only page updates and comments; disclose missing historical status/assignment events as a coverage gap
- Person matching is case-insensitive and handles email-to-name variations
- All queries are read-only; no data is modified
- Typical query time: 2–5 seconds depending on source availability
- Report is always in markdown, suitable for copying into docs or sharing
- See `references/examples.md` for more detailed examples and expected outputs
