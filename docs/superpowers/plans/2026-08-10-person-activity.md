# Person Activity on Work Item Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a skill that, given a work item (Jira task, GitHub PR, or git commit) and a person, collects all their interactions across 5 sources and presents a synthetic summary.

**Architecture:** Modular query scripts per source (Jira, GitHub, Slack, email, calendar), plus detection/matching utilities, feeding into a synthesizer that produces the final markdown report.

**Tech Stack:** Bash 5+, curl, `gh` CLI, MCP tools for Jira/Slack/Gmail/Calendar, jq for JSON parsing.

## Global Constraints

- All credentials from `${CLAUDE_PLUGIN_DATA:-$HOME/.config/thebous-os}/.env` (shared with thebous-os plugin)
- Output always markdown, scannable in <30 seconds
- Person matching: email OR full name, case-insensitive, handles Jira/Slack/GitHub handle variations
- Queries complete in <5 seconds
- No data modification, read-only operations
- Each source is optional (skip if credentials missing or query fails)

---

### Task 1: Skill Manifest & Input Handler

**Files:**
- Create: `skills/person-activity/SKILL.md`
- Create: `skills/person-activity/scripts/main.sh`

**Interfaces:**
- Produces: Entry point that asks for work item ID and person, returns structured input to downstream scripts

- [ ] **Step 1: Write SKILL.md manifest**

```yaml
---
name: person-activity
description: Given a work item ID (Jira task, GitHub PR, or git commit) and a person's name/email, shows all their comments, reviews, and discussions on that work item across Jira, GitHub, Slack, email, and calendar. Asks for input interactively, then presents a synthetic summary with links to each source.
---
```

Body should include:
- What the skill does
- When to use it (preparing for 1:1, context-switching, understanding history)
- Input: work item ID, person name/email
- Output: markdown summary

- [ ] **Step 2: Write main.sh entrypoint**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source shared helpers
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
load_env

# Ask for work item ID
echo "Work item ID? (e.g., DC-443, PR #250, abc123def)"
read -r WORKITEM_ID

# Ask for person
echo "Person? (email or full name)"
read -r PERSON_INPUT

# Pass to downstream scripts
export WORKITEM_ID PERSON_INPUT
bash "${SCRIPT_DIR}/detect-workitem-type.sh"
```

- [ ] **Step 3: Run manually to verify input prompts work**

```bash
bash skills/person-activity/scripts/main.sh <<< $'DC-443\nmarco@company.com'
```

Expected: No errors, outputs WORKITEM_ID and PERSON_INPUT

- [ ] **Step 4: Commit**

```bash
git add skills/person-activity/SKILL.md skills/person-activity/scripts/main.sh
git commit -m "feat(person-activity): add skill manifest and input handler"
```

---

### Task 2: Work Item Type Detection

**Files:**
- Create: `skills/person-activity/scripts/detect-workitem-type.sh`

**Interfaces:**
- Consumes: `$WORKITEM_ID` (from Task 1)
- Produces: `$WORKITEM_TYPE` (jira|github|git), `$RESOLVED_ID` (normalized), exports to env

- [ ] **Step 1: Write detection logic**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Regex patterns for detection
if [[ $WORKITEM_ID =~ ^[A-Z]+-[0-9]+$ ]]; then
  WORKITEM_TYPE="jira"
  RESOLVED_ID="$WORKITEM_ID"
elif [[ $WORKITEM_ID =~ ^(PR)?#?[0-9]+$ ]]; then
  WORKITEM_TYPE="github"
  RESOLVED_ID=$(echo "$WORKITEM_ID" | sed 's/^PR//;s/^#//')
elif [[ $WORKITEM_ID =~ ^[a-f0-9]{7,40}$ ]]; then
  WORKITEM_TYPE="git"
  RESOLVED_ID="$WORKITEM_ID"
else
  echo "ERROR: Unknown work item format: $WORKITEM_ID" >&2
  exit 1
fi

export WORKITEM_TYPE RESOLVED_ID
echo "Detected: $WORKITEM_TYPE ($RESOLVED_ID)"
```

- [ ] **Step 2: Test detection with three types**

```bash
bash scripts/detect-workitem-type.sh <<< 'DC-443' # should be jira
bash scripts/detect-workitem-type.sh <<< 'PR #250' # should be github
bash scripts/detect-workitem-type.sh <<< 'abc123def' # should be git
```

- [ ] **Step 3: Commit**

```bash
git add skills/person-activity/scripts/detect-workitem-type.sh
git commit -m "feat(person-activity): add work item type detection"
```

---

### Task 3: Person Matching Utility

**Files:**
- Create: `skills/person-activity/scripts/match-person.sh`

**Interfaces:**
- Consumes: `$PERSON_INPUT` (email or name)
- Produces: Function `match_jira_user()`, `match_slack_user()`, `match_github_user()` that return normalized identifiers

- [ ] **Step 1: Write person matching functions**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Extract email or name components
if [[ $PERSON_INPUT =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  PERSON_TYPE="email"
  PERSON_EMAIL="$PERSON_INPUT"
  PERSON_NAME_PARTS=$(echo "$PERSON_EMAIL" | sed 's/@.*//' | tr '.' ' ')
else
  PERSON_TYPE="name"
  PERSON_EMAIL=""
  PERSON_NAME_PARTS="$PERSON_INPUT"
fi

export PERSON_TYPE PERSON_EMAIL PERSON_NAME_PARTS

# Jira user lookup: by email or name
match_jira_user() {
  if [ -n "$PERSON_EMAIL" ]; then
    # Jira API: /rest/api/2/user/search?username=email@domain
    curl -sf -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
      "$JIRA_BASE_URL/rest/api/2/user/search?username=${PERSON_EMAIL}" \
      | jq -r '.[0].name // empty'
  else
    # Name search: not reliably exposed via API, skip for MVP
    echo ""
  fi
}

# Similar for Slack, GitHub
match_slack_user() {
  # Slack API: users.list, filter by real_name or email
  # Deferred: use simple substring match in query
  echo "$PERSON_INPUT"
}

match_github_user() {
  # GitHub API: /search/users?q=<name-or-email>
  gh search users --query="$PERSON_INPUT" --json login --limit 1 | jq -r '.[0].login // empty'
}

export -f match_jira_user match_slack_user match_github_user
```

- [ ] **Step 2: Test with email and name inputs**

```bash
PERSON_INPUT="marco@company.com" bash scripts/match-person.sh
PERSON_INPUT="Marco Rossi" bash scripts/match-person.sh
```

- [ ] **Step 3: Commit**

```bash
git add skills/person-activity/scripts/match-person.sh
git commit -m "feat(person-activity): add person matching utility"
```

---

### Task 4: Jira Comments Query

**Files:**
- Create: `skills/person-activity/scripts/query-jira.sh`

**Interfaces:**
- Consumes: `$WORKITEM_ID`, `$PERSON_EMAIL`, `$PERSON_NAME_PARTS`
- Produces: JSON with Jira comments (author, timestamp, body, link)

- [ ] **Step 1: Write Jira query**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
load_env

JIRA_USER=$(match_jira_user)

# Get issue details and comments
ISSUE=$(jira_get "issue/$WORKITEM_ID?fields=summary,comment,key,customfield_10026")

# Filter comments by person
echo "$ISSUE" | jq --arg user "$JIRA_USER" '.fields.comment.comments[] | select(.author.name == $user or .author.emailAddress | startswith($user)) | {timestamp: .created, author: .author.displayName, body, url: ("https://jira.company.com/browse/" + env.WORKITEM_ID + "?focusedCommentId=" + .id)}'
```

- [ ] **Step 2: Test query on a real Jira task**

```bash
WORKITEM_ID="DC-443" PERSON_EMAIL="marco@company.com" bash scripts/query-jira.sh
```

- [ ] **Step 3: Commit**

```bash
git add skills/person-activity/scripts/query-jira.sh
git commit -m "feat(person-activity): add Jira comments query"
```

---

### Task 5: GitHub PR Comments & Reviews Query

**Files:**
- Create: `skills/person-activity/scripts/query-github.sh`

**Interfaces:**
- Consumes: `$WORKITEM_TYPE`, `$RESOLVED_ID`, `$PERSON_INPUT`
- Produces: JSON with PR comments, reviews, and related PRs by Jira key

- [ ] **Step 1: Write GitHub query**

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ "$WORKITEM_TYPE" != "github" ]; then
  echo "[]"
  exit 0
fi

# Get PR comments and reviews
REPO_FILTER=""
if [ -n "${GITHUB_REPOS:-}" ]; then
  REPO_FILTER=$(echo "$GITHUB_REPOS" | tr ',' '\n' | head -1)
fi

# Comments on this PR
gh api repos/$REPO_FILTER/pulls/$RESOLVED_ID/comments \
  --jq '.[] | select(.user.login == "$PERSON_INPUT" or .user.login | contains($PERSON_INPUT)) | {timestamp: .created_at, author: .user.login, body, url: .html_url}'

# Reviews on this PR
gh api repos/$REPO_FILTER/pulls/$RESOLVED_ID/reviews \
  --jq '.[] | select(.user.login == "$PERSON_INPUT") | {timestamp: .submitted_at, author: .user.login, state, url: .html_url}'
```

- [ ] **Step 2: Test on a PR**

```bash
WORKITEM_TYPE="github" RESOLVED_ID="250" PERSON_INPUT="marco" bash scripts/query-github.sh
```

- [ ] **Step 3: Commit**

```bash
git add skills/person-activity/scripts/query-github.sh
git commit -m "feat(person-activity): add GitHub PR comments/reviews query"
```

---

### Task 6: Slack Threads Query

**Files:**
- Create: `skills/person-activity/scripts/query-slack.sh`

**Interfaces:**
- Consumes: `$WORKITEM_ID`, `$PERSON_INPUT`
- Produces: JSON with Slack messages (author, timestamp, text, link)

- [ ] **Step 1: Write Slack query using MCP**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Use Slack MCP tool to search messages
# Search for: messages containing WORKITEM_ID AND from PERSON_INPUT
# Slack API: conversations.history or search.messages

# Pseudo-code; adapt to available Slack MCP tools:
# slack_search "text:$WORKITEM_ID from:$PERSON_INPUT" | jq ...
```

- [ ] **Step 2: Note limitation**

Slack search via MCP is constrained; fallback to "optional" if tool unavailable.

- [ ] **Step 3: Commit with fallback**

```bash
git add skills/person-activity/scripts/query-slack.sh
git commit -m "feat(person-activity): add Slack threads query (optional)"
```

---

### Task 7: Email Threads Query

**Files:**
- Create: `skills/person-activity/scripts/query-email.sh`

**Interfaces:**
- Consumes: `$PERSON_EMAIL`, `$WORKITEM_ID`
- Produces: JSON with emails (sender, subject, timestamp, link/reference)

- [ ] **Step 1: Write email query using MCP Gmail**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Use Gmail MCP search_threads tool
# Query: from:$PERSON_EMAIL OR to:$PERSON_EMAIL AND subject:$WORKITEM_ID
# (Gmail API limits; may be partial)
```

- [ ] **Step 2: Commit**

```bash
git add skills/person-activity/scripts/query-email.sh
git commit -m "feat(person-activity): add email threads query"
```

---

### Task 8: Calendar & Granola Links Query

**Files:**
- Create: `skills/person-activity/scripts/query-calendar.sh`

**Interfaces:**
- Consumes: `$WORKITEM_ID`, `$PERSON_INPUT`
- Produces: JSON with calendar events (title, date, attendees, url)

- [ ] **Step 1: Write calendar query**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Use Calendar MCP: list_events for next 90 days
# Check each event's Granola links for the WORKITEM_ID
# Filter by attendees matching PERSON_INPUT
```

- [ ] **Step 2: Commit**

```bash
git add skills/person-activity/scripts/query-calendar.sh
git commit -m "feat(person-activity): add calendar/Granola query"
```

---

### Task 9: Report Synthesizer

**Files:**
- Create: `skills/person-activity/scripts/synthesize.sh`

**Interfaces:**
- Consumes: JSON outputs from Tasks 4-8
- Produces: Markdown report per spec (summary, timeline, sources)

- [ ] **Step 1: Write synthesizer**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Read all JSON streams from sources
# Extract signals: decisions, approvals, blockers, timeline
# Determine role (reviewer, commenter, decision-maker)
# Find latest activity

# Build markdown report matching spec template
cat <<EOF
# Activity — $WORKITEM_ID with $PERSON_NAME

## 📋 Synthetic Summary
- **Role**: $ROLE
- **Key Decisions**: $DECISIONS
- **Latest**: $LATEST_DATE: $LATEST_EVENT
- **Status**: $STATUS

## 📍 Timeline
...

## 💬 Sources
...
EOF
```

- [ ] **Step 2: Test with sample data**

```bash
echo '{"timestamp":"2026-08-01","author":"marco","body":"Let's use approach X"}' | bash scripts/synthesize.sh
```

- [ ] **Step 3: Commit**

```bash
git add skills/person-activity/scripts/synthesize.sh
git commit -m "feat(person-activity): add report synthesizer"
```

---

### Task 10: Integration & End-to-End Test

**Files:**
- Modify: `scripts/person-activity/main.sh` (wire all scripts together)

**Interfaces:**
- Consumes: User input (work item ID, person)
- Produces: Final markdown report, printed to chat

- [ ] **Step 1: Wire main.sh to call all query scripts**

```bash
# In main.sh, after detecting type and matching person:
source scripts/detect-workitem-type.sh
source scripts/match-person.sh

JIRA_RESULTS=$(bash scripts/query-jira.sh)
GITHUB_RESULTS=$(bash scripts/query-github.sh)
SLACK_RESULTS=$(bash scripts/query-slack.sh)
EMAIL_RESULTS=$(bash scripts/query-email.sh)
CALENDAR_RESULTS=$(bash scripts/query-calendar.sh)

# Combine results
COMBINED=$(echo "$JIRA_RESULTS $GITHUB_RESULTS $SLACK_RESULTS $EMAIL_RESULTS $CALENDAR_RESULTS" | jq -s add)

# Synthesize
bash scripts/synthesize.sh <<< "$COMBINED"
```

- [ ] **Step 2: End-to-end test**

```bash
# Manual test: invoke skill on a known work item
/thebous-os:person-activity
# (enter DC-443)
# (enter marco@company.com)
```

Expected: Full markdown report with all sources, <5 seconds

- [ ] **Step 3: Commit**

```bash
git add scripts/person-activity/main.sh
git commit -m "feat(person-activity): integrate all queries and synthesizer"
```

---

### Task 11: Skill Testing & Documentation

**Files:**
- Create: `skills/person-activity/references/examples.md`
- Modify: `SKILL.md` (add full documentation with examples)

- [ ] **Step 1: Write examples documentation**

Examples: DC-443 with marco@company.com, PR #250 with sarah, commit abc123 with john@email.com

- [ ] **Step 2: Add full SKILL.md body**

Include: what it does, when to use, how it works, limitations (optional sources), sample output

- [ ] **Step 3: Commit**

```bash
git add skills/person-activity/references/examples.md
git commit -m "docs(person-activity): add examples and full skill documentation"
```

---

## Execution

Plan complete. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session, batch execution with checkpoints

Which approach?
