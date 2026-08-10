#!/usr/bin/env bash
# Jira comments query (Task 4)
# Extracts comments on a Jira issue filtered by person
set -euo pipefail

# ── Setup ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/helpers.sh"
load_env

# ── Input Validation ─────────────────────────────────────────────────
: "${WORKITEM_TYPE:?WORKITEM_TYPE not set}"
: "${WORKITEM_ID:?WORKITEM_ID not set}"
: "${PERSON_EMAIL:?PERSON_EMAIL not set}"
: "${PERSON_NAME_PARTS:?PERSON_NAME_PARTS not set}"

# ── Early Exit: Skip if Not Jira ─────────────────────────────────────
if [ "$WORKITEM_TYPE" != "jira" ]; then
  echo "[]"
  exit 0
fi

# ── Query Jira Issue with Comments ───────────────────────────────────
ISSUE_DATA=$(jira_get "issue/$WORKITEM_ID?fields=summary,comment,key" 2>/dev/null || echo "{}")

# ── Error Handling: Return Empty if Issue Not Found ───────────────────
if [ "$ISSUE_DATA" = "{}" ] || ! echo "$ISSUE_DATA" | jq -e '.key' >/dev/null 2>&1; then
  echo "[]"
  exit 0
fi

# Extract issue key for building the URL
ISSUE_KEY=$(echo "$ISSUE_DATA" | jq -r '.key')
JIRA_ISSUE_URL="${JIRA_BASE_URL}/browse/${ISSUE_KEY}"

# ── Filter Comments by Person ────────────────────────────────────────
# Extract comments and filter by person
# Matching strategy:
# 1. If PERSON_EMAIL is set, try exact email match
# 2. Otherwise, try name/username fuzzy match (contains check, case-insensitive)
echo "$ISSUE_DATA" | jq \
  --arg email "$PERSON_EMAIL" \
  --arg names "$PERSON_NAME_PARTS" \
  --arg issue_url "$JIRA_ISSUE_URL" \
  '[
    .fields.comment.comments[] |
    select(
      (if $email != "" then
        # Email match: exact match on emailAddress or username prefix
        ((.author.emailAddress // "" | ascii_downcase) == ($email | ascii_downcase)) or
        ((.author.emailAddress // "" | ascii_downcase) | startswith(($email | split("@")[0] | ascii_downcase)))
      else
        false
      end) or
      # Name match: fuzzy contains check (handles variations like marco.rossi vs marco rossi)
      ((.author.name // "" | ascii_downcase | gsub("[._-]"; " ") | contains(($names | ascii_downcase))) or
       (.author.displayName // "" | ascii_downcase | contains(($names | ascii_downcase))))
    ) |
    {
      timestamp: .created,
      author: .author.displayName,
      body: .body,
      url: ($issue_url + "#" + .id)
    }
  ]'
