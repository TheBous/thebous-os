---
name: person-activity
description: Given a work item ID (Jira task, GitHub PR, or git commit) and a person's name/email, shows all their comments, reviews, and discussions on that work item across Jira, GitHub, Slack, email, and calendar. Asks for input interactively, then presents a synthetic summary with links to each source.
---

# Person Activity on Work Item

Collects all interactions a specific person had on a given work item (Jira task, GitHub PR, or git commit) across five sources — Jira comments, GitHub PR reviews and comments, Slack threads, email discussions, and calendar events — and synthesizes them into a single markdown report organized by timeline and source.

## When to Use

- **Before a 1:1 with someone:** Get the full context of their recent activity on a specific task or PR
- **Context-switching to a project:** Understand what person X did on a task/PR/commit while you were away
- **Reviewing someone's contribution:** See their complete involvement (comments, decisions, approvals) in one place
- **Preparing for a retrospective or handoff:** Trace their journey through a work item

## Input

The skill asks for two pieces of information:

1. **Work Item ID** — One of:
   - Jira key (e.g., `DC-443`)
   - GitHub PR number (e.g., `#250` or `PR 250`)
   - Git commit hash, short or long (e.g., `abc123def`)

2. **Person** — Either:
   - Email address (e.g., `marco@company.com`)
   - Full name (e.g., `Marco Rossi`)

## Output

A markdown report (<30 seconds scannable) containing:

- **Synthetic Summary**: Their role, key decisions, latest activity, overall status
- **Timeline**: All interactions ordered by date across all sources
- **Sources**: Grouped by source (Jira, GitHub, Slack, email, calendar) with direct links

Each interaction shows who, when, what, and a link to the source.

## How It Works

1. Detects work item type from ID format (Jira key, GitHub PR, or git hash)
2. Matches the person across systems (email, GitHub handle, Jira username, Slack user, etc.)
3. Queries each source in parallel for interactions by that person on that work item
4. Synthesizes all results into a timeline and summary report

## Example Usage

**Command:**
```
person-activity
```

**Interaction:**
```
Enter work item ID (Jira key, GitHub PR #, or git commit hash): DC-443
Enter person's name or email: marco@company.com
```

**Output Sample:**
```markdown
# Activity — DC-443 with Marco Rossi

## 📋 Synthetic Summary
- **Role**: Reviewer, technical lead
- **Key Decisions**: Approved implementation approach on 2026-07-28; requested schema changes on 2026-07-25
- **Latest**: Added comment "Looks good, ready to merge" on 2026-08-09
- **Status**: Approved

## 📍 Timeline
- 2026-07-25 14:30: Jira comment "Let's adjust the schema to support bulk updates"
- 2026-07-28 09:15: GitHub review approved with suggestions
- 2026-08-09 16:45: Jira comment "Looks good, ready to merge"

## 💬 Sources
### Jira Comments
- 3 comments | [View on Jira](https://jira.company.com/browse/DC-443)

### GitHub PR/Reviews
- 2 reviews, 1 comment | [View PR #1842](https://github.com/company/repo/pull/1842)

### Slack
- 2 messages in #engineering channel

### Email
- 1 thread with team

### Calendar
- 1 decision meeting on 2026-07-27
```

## Notes

- Each source is **optional** — if credentials are missing or the query fails, it's skipped (no error)
- Person matching is case-insensitive and handles email-to-name variations
- All queries are read-only; no data is modified
- Typical query time: 2–5 seconds depending on source availability
- Report is always in markdown, suitable for copying into docs or sharing
- See `references/examples.md` for more detailed examples and expected outputs
