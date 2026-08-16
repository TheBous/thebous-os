---
name: morning-briefing
description: Generate the user's morning briefing on request or as the scheduled 9:00 task. Cover GitHub PR reviews, open feedback, Jira deadlines and start dates, overnight Jira activity, Confluence changes and mentions, important overnight email, today's calendar calls, and a priority ranking. Always use this skill for morning briefings and scheduled daily runs.
---

# Morning Briefing

Collect and prioritize the configured sources in one report. Each section has a
specific source and time window; follow these steps and do not improvise queries.

## Configuration

Load the shared plugin environment once:

```bash
source "scripts/helpers.sh"
load_env
```

If the file or required `GITHUB_REPOS`, `OBSIDIAN_VAULT_PATH`, `GMAIL_ADDRESS`,
or `GMAIL_APP_PASSWORD` values are missing, tell the user to run
`/thebous-os:setup`. Gmail credentials are only a fallback when no native Gmail
connector is available.

## Step 1: Calculate time windows

Use `Europe/Rome` and calculate these once:

```bash
export TZ="Europe/Rome"
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY=$(date +%Y-%m-%d)
NIGHT_START_ISO=$(date -v-1d -v20H -v0M -v0S -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d "yesterday 20:00" -u +%Y-%m-%dT%H:%M:%SZ)
DUE_END=$(date -v+2d +%Y-%m-%d 2>/dev/null || date -d "+2 days" +%Y-%m-%d)
STALE_PR_CUTOFF=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d "-14 days" +%Y-%m-%d)
```

The overnight window is yesterday at 20:00 through now. `DUE_END` covers today,
tomorrow, and the day after. Ignore user PRs untouched for 14 or more days.

## Step 2: PR review requests

```bash
REPO_FILTER=$(source "scripts/helpers.sh"; gh_repo_filter)
gh search prs --review-requested=@me --state=open $REPO_FILTER \
  --json number,title,url,repository,createdAt --limit 50
```

For each PR, retrieve the latest review-request timestamp from its timeline:

```bash
gh api repos/<owner>/<repo>/issues/<number>/timeline --paginate \
  --jq '.[] | select(.event == "review_requested") | select(.requested_reviewer.login == "<username>") | .created_at' \
  | tail -1
```

Group requests into **Requested overnight**, **Pending from before**, and
**Waiting 3+ days**. If no individual request event exists, classify it as
pending from before. Items waiting at least three days go into **Things at Risk**.

## Step 3: New comments on the user's PRs

```bash
gh search prs --author=@me --state=open --updated=">=${STALE_PR_CUTOFF}" $REPO_FILTER \
  --json number,title,url,repository --limit 50
```

For each recent PR, inspect issue comments, review comments, and submitted
reviews in the overnight window, excluding the authenticated user. Keep only PRs
with at least one result.

## Step 4: Jira deadlines

Resolve `cloudId` once with `getAccessibleAtlassianResources`; if multiple sites
exist, ask which one to use. Then query:

```
jql: assignee = currentUser() AND duedate >= startOfDay() AND duedate <= "<DUE_END> 23:59" AND statusCategory != Done ORDER BY duedate ASC
fields: ["summary", "duedate", "status", "project"]
```

## Step 5: Jira tasks starting today

```
jql: assignee = currentUser() AND "Start date" = startOfDay() ORDER BY key ASC
fields: ["summary", "status", "project"]
```

`Start date` is a custom field. If the query fails, inspect available fields with
`getJiraIssueTypeMetaWithFields`, ask which field represents the start date, and
update this skill once the correct name is known.

## Step 6: Overnight Jira activity

Jira Cloud does not expose the UI notification feed through the API. Use this
proxy for real activity on the user's tickets:

```
jql: (assignee = currentUser() OR reporter = currentUser()) AND updated >= "<NIGHT_START in YYYY-MM-DD HH:MM>" ORDER BY updated DESC
fields: ["summary", "status", "project", "comment"]
```

Report comments created or updated in the overnight window and flag comments
that mention the user.

## Step 7: Confluence changes and mentions

When `CONFLUENCE_PARENT_URL` is configured, query pages modified in the overnight
window using `parent = <PARENT_PAGE_ID>` (fall back to `ancestor` if needed),
then inspect recent comments. Report page, author, time, short comment text, and
direct mentions of the username, email, or full name. Write `None` when no pages
or mentions are found.

## Step 8: Important overnight email

Prefer a native Gmail connector:

```
query: "in:inbox category:primary newer_than:1d -from:notifications@github.com is:unread"
```

Keep messages dated in the overnight window and report sender and subject, not
the full body. Without a native connector, use the bundled IMAP fallback only
when both credentials exist:

```bash
if [ -n "${GMAIL_ADDRESS:-}" ] && [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  python3 "skills/morning-briefing/scripts/gmail_imap_overnight.py" "${GMAIL_ADDRESS}" "${GMAIL_APP_PASSWORD}" \
    | python3 "skills/morning-briefing/scripts/filter_messages_in_window.py" "$NIGHT_START_ISO" "$NOW_ISO"
fi
```

## Step 9: Today's calls

Use the primary calendar with today's midnight through tomorrow's midnight,
timezone `Europe/Rome`, ordered by `startTime`. Keep only events with a
`conferenceUrl` or more than one attendee; personal reminders are not calls.
Report title, start/end, and conference URL when present.

## Step 10: Prioritize

- **🔴 Critical**: due today/overdue Jira work or a direct mention clearly awaiting a response.
- **🟠 High**: overnight review request, new feedback on the user's PR, or overnight activity on their ticket.
- **🟡 Medium**: review pending for days, deadline tomorrow/day after, or task starting today.
- **⚪ Low/FYI**: informative non-urgent email and passive reminders.

An item may appear in both the priority index and its detailed section.

## Step 11: Compose the report

Use this structure and never omit an empty section; write `None` instead:

```markdown
# 🌅 Morning Briefing — <TODAY>

## ⚠️ Things at Risk
## 🔥 Look at first
## 🌙 PR reviews requested overnight
## ⏳ PR reviews pending from before
## 💬 New comments on your PRs
## 📅 Jira tasks due today–the day after tomorrow
## 🚀 Jira tasks starting today
## 🔔 Overnight Jira activity
## 📧 Important overnight email
## 📞 Today's calls
```

Show the report in the user's language, with links, timestamps, and short reasons
for priority.

## Step 12: Save to the Obsidian daily note

When configured, append the generated report without overwriting existing content:

```bash
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  bash "scripts/append_daily_note.sh" "${OBSIDIAN_VAULT_PATH}" "<generated report file>" "00 - Morning Briefing.md" "Morning Briefing"
fi
```

If Obsidian is not configured, skip this step without treating it as an error.

## Step 13: Final confirmation

Add one line: `📓 Also saved to Obsidian` or `📓 Obsidian not configured — chat only`.
