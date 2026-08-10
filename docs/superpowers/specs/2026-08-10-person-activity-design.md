# Person Activity on Work Item — Design

> **Goal:** Given a work item (Jira task, GitHub PR, or git commit) and a person, visualize all discussions, comments, and interactions that person had on that work item, with a synthetic summary of key decisions and recent activity.

## Core Concept

When you're context-switching or preparing for a meeting, you need to quickly understand **what did this person say/decide on this specific work item?** This skill collects all traces of their involvement across multiple platforms and surfaces a synthetic summary instead of raw data.

## Interaction Flow

1. **User invokes skill** → skill asks for work item ID
2. **User provides ID** → skill detects type (Jira task, GitHub PR, git commit)
3. **Skill asks for person** → user provides email or full name
4. **Skill searches 5 sources** → collects all their comments/messages/activity
5. **Skill synthesizes** → presents summary + sources with links

## Input

**Work item ID (manual entry):**
- Jira task: `DC-443`, `PROJ-123`
- GitHub PR: `PR #250`, `#250`
- Git commit: `abc123def` (any valid commit hash)

**Person (interactive):**
- Email: `marco@company.com`
- Full name: `Marco Rossi` (searches Jira/Slack/email for matches)

## Data Sources

Each source contributes different signals about the person's involvement:

### 1. Jira Comments
- **Query:** All comments on the task by the person (matched by email or name)
- **Window:** All time (full task history)
- **Signal:** Technical decisions, blockers, status updates

### 2. GitHub PR Comments & Reviews
- **Query:** 
  - Comments on the PR (if work item is a PR)
  - Reviews the person submitted on that PR
  - Comments/reviews on related PRs (same Jira key in branch/PR title)
- **Window:** All time
- **Signal:** Code review feedback, approval/rejection, design feedback

### 3. Slack Threads
- **Query:** Messages containing the work item ID (e.g., `DC-443`, `#250`) AND from the person OR mentioning the person
- **Filter:** Only threads where both the work item ID AND the person appear
- **Signal:** Informal discussion, blockers, coordination, quick decisions

### 4. Email Threads
- **Query:** Emails with the person (to/from/cc) in subject OR body mentioning the work item ID
- **Filter:** Threaded conversations, not just mentions
- **Signal:** Status updates, formal decisions, stakeholder input

### 5. Calendar Events & Granola Links
- **Query:** Calendar events with both the person AND attendees, filtered by Granola links pointing to the work item
- **Signal:** Meeting context, decision moments, alignment sessions

**Bonus: Cross-PR Reviews**
- If work item is a task, find all PRs tagged with that task (Jira key in PR title/body)
- Show if the person reviewed any of those PRs

## Output Structure

```markdown
# Activity — <WORK_ITEM_ID> with <PERSON_NAME>

## 📋 Synthetic Summary
- **Role**: <their role on this task — reviewer, commenter, decision-maker, etc.>
- **Key Decisions**: <1-2 bullet points of decisions they made or strongly advocated>
- **Latest**: <last activity timestamp and what happened>
- **Status**: <their current involvement — waiting for them, approved, closed, etc.>

## 📍 Timeline
<1-3 key events in chronological order>
- <date>: <event> (<source>)

## 💬 Sources
### Jira Comments
- <count> comments total
- <link to task>

### GitHub PR/Reviews
- <count> reviews/comments
- <links to each PR>

### Slack
- <count> messages
- <sample snippet or summary>

### Email
- <count> threads
- <recent email subject>

### Calendar
- <count> events
- <event titles + dates>
```

## Key Constraints

1. **Person matching**: Must handle both email and full name. Jira/Slack/GitHub use different identifiers (email, handle, display name) — fuzzy match where needed.
2. **Work item type detection**: Auto-detect from ID format (key pattern for Jira, # for GitHub PR, 40-char hash for git).
3. **Synthetic summary**: NOT a raw dump. Extract signals like decisions, approvals, blockers, timeline. Keep to 3-4 lines max.
4. **Privacy**: Only show messages/activity the user can already see (no new access).

## Success Criteria

- ✅ Queries all 5 sources and finds activity in <5 seconds
- ✅ Person name matching works for emails, handles, and full names
- ✅ Summary is scannable in <30 seconds
- ✅ Each source has a clickable link to the actual message/PR/event
- ✅ Works for all three work item types (task/PR/commit)

## Non-Goals

- Does not create or modify anything
- Does not compare this person's activity to others' (single-person view only)
- Does not predict future activity
- Does not store results locally (on-demand query)

## Open Questions

- Should the skill also show **what the user said** in response to the person? (Deferred: MVP is person-only)
- Should there be a date range filter? (Deferred: MVP uses full history)
- Should calendar events without Granola links be included? (Deferred: MVP only Granola-linked)
