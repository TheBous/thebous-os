#!/usr/bin/env bash
# Synthesize combined activity results into markdown report (Task 9)
# Reads JSON from stdin, outputs formatted markdown
set -euo pipefail

# ── Read Combined JSON from stdin ────────────────────────────────────
COMBINED_JSON=$(cat)

# Handle empty input
if [ -z "$COMBINED_JSON" ] || [ "$COMBINED_JSON" = "null" ]; then
  COMBINED_JSON="[]"
fi

# ── Helper: Get person display name from PERSON_INPUT ─────────────────
get_person_display_name() {
  local person_input="$PERSON_INPUT"
  # If it's an email, extract display name parts
  if [[ "$person_input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    local local_part="${person_input%%@*}"
    # Capitalize parts: marco.rossi -> Marco Rossi
    echo "$local_part" | tr '.' ' ' | sed 's/\b\(.\)/\U\1/g'
  else
    echo "$person_input"
  fi
}

PERSON_DISPLAY="$(get_person_display_name)"

# ── Count activities by source ──────────────────────────────────────
TOTAL_ACTIVITIES=$(echo "$COMBINED_JSON" | jq 'length // 0' | tr -d ' \n')
JIRA_COUNT=$(echo "$COMBINED_JSON" | jq '[.[] | select(.source == "jira")] | length // 0' | tr -d ' \n')
GITHUB_COUNT=$(echo "$COMBINED_JSON" | jq '[.[] | select(.source == "github")] | length // 0' | tr -d ' \n')
SLACK_COUNT=$(echo "$COMBINED_JSON" | jq '[.[] | select(.source == "slack")] | length // 0' | tr -d ' \n')
EMAIL_COUNT=$(echo "$COMBINED_JSON" | jq '[.[] | select(.source == "email")] | length // 0' | tr -d ' \n')
CALENDAR_COUNT=$(echo "$COMBINED_JSON" | jq '[.[] | select(.source == "calendar")] | length // 0' | tr -d ' \n')

# Extract timestamps for latest activity
if [ "$TOTAL_ACTIVITIES" -gt 0 ]; then
  LATEST_TIMESTAMP=$(echo "$COMBINED_JSON" | jq -r 'max_by(.timestamp) | .timestamp // "unknown"')
  LATEST_SOURCE=$(echo "$COMBINED_JSON" | jq -r 'max_by(.timestamp) | .source // "unknown"')
else
  LATEST_TIMESTAMP="unknown"
  LATEST_SOURCE="unknown"
fi

# ── Generate Markdown Report ────────────────────────────────────────
{
  echo "# Activity — $WORKITEM_ID with $PERSON_DISPLAY"
  echo

  # ── Synthetic Summary ────────────────────────────────────────────
  echo "## 📋 Synthetic Summary"

  if [ "$TOTAL_ACTIVITIES" -eq 0 ]; then
    echo "- **Status**: No activities found for this person on this work item"
    echo
  else
    echo "- **Total Activities**: $TOTAL_ACTIVITIES"
    [ "$JIRA_COUNT" -gt 0 ] && echo "- **Jira Comments**: $JIRA_COUNT"
    [ "$GITHUB_COUNT" -gt 0 ] && echo "- **GitHub Reviews & Comments**: $GITHUB_COUNT"
    [ "$SLACK_COUNT" -gt 0 ] && echo "- **Slack Messages**: $SLACK_COUNT"
    [ "$EMAIL_COUNT" -gt 0 ] && echo "- **Email Threads**: $EMAIL_COUNT"
    [ "$CALENDAR_COUNT" -gt 0 ] && echo "- **Calendar Events**: $CALENDAR_COUNT"
    echo "- **Latest Activity**: $LATEST_TIMESTAMP ($LATEST_SOURCE)"
    echo
  fi

  # ── Timeline (all interactions sorted by timestamp) ───────────────
  echo "## 📍 Timeline"

  if [ "$TOTAL_ACTIVITIES" -eq 0 ]; then
    echo "No activities recorded."
    echo
  else
    echo "$COMBINED_JSON" | jq -r 'sort_by(.timestamp) | .[] |
      "- **\(.timestamp | split("T")[0])** (\(.source)): \(.author // "Unknown") — \(.body // .text // .title // "Activity")"' 2>/dev/null | head -20
    if [ "$TOTAL_ACTIVITIES" -gt 20 ]; then
      echo "  ... and $((TOTAL_ACTIVITIES - 20)) more activities"
    fi
    echo
  fi

  # ── Sources Section ──────────────────────────────────────────────
  echo "## 💬 Sources"
  echo

  # Jira
  if [ "$JIRA_COUNT" -gt 0 ]; then
    echo "### Jira Comments"
    echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "jira") | "- \(.timestamp | split("T")[0]): \(.author) — \(.body | split("\n")[0])"' 2>/dev/null
    JIRA_URL=$(echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "jira") | .url' 2>/dev/null | head -1 | sed 's/#.*//')
    if [ ! -z "$JIRA_URL" ]; then
      echo "  [View on Jira]($JIRA_URL)"
    fi
    echo
  fi

  # GitHub
  if [ "$GITHUB_COUNT" -gt 0 ]; then
    echo "### GitHub PR"
    echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "github") | "- \(.timestamp | split("T")[0]): \(.author) — \(.body // .state // "Review")"' 2>/dev/null
    GITHUB_URL=$(echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "github") | .url' 2>/dev/null | head -1)
    if [ ! -z "$GITHUB_URL" ]; then
      echo "  [View PR]($GITHUB_URL)"
    fi
    echo
  fi

  # Slack
  if [ "$SLACK_COUNT" -gt 0 ]; then
    echo "### Slack"
    echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "slack") | "- \(.timestamp | split("T")[0]): \(.author) — \(.text)"' 2>/dev/null
    SLACK_URL=$(echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "slack") | .url' 2>/dev/null | head -1)
    if [ ! -z "$SLACK_URL" ]; then
      echo "  [View Thread]($SLACK_URL)"
    fi
    echo
  fi

  # Email
  if [ "$EMAIL_COUNT" -gt 0 ]; then
    echo "### Email"
    echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "email") | "- \(.timestamp | split("T")[0]): \(.author) — \(.subject // "Email")"' 2>/dev/null
    EMAIL_URL=$(echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "email") | .url' 2>/dev/null | head -1)
    if [ ! -z "$EMAIL_URL" ]; then
      echo "  [View Thread]($EMAIL_URL)"
    fi
    echo
  fi

  # Calendar
  if [ "$CALENDAR_COUNT" -gt 0 ]; then
    echo "### Calendar Events"
    echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "calendar") | "- \(.timestamp | split("T")[0]): \(.title) — Attendees: \(.attendees // "N/A")"' 2>/dev/null
    CALENDAR_URL=$(echo "$COMBINED_JSON" | jq -r '.[] | select(.source == "calendar") | .url' 2>/dev/null | head -1)
    if [ ! -z "$CALENDAR_URL" ]; then
      echo "  [View Event]($CALENDAR_URL)"
    fi
    echo
  fi

  echo "---"
  echo "*Report generated $(date '+%Y-%m-%d %H:%M:%S')*"
}
