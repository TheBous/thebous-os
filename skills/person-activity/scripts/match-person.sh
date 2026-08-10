#!/usr/bin/env bash
# Person matching utility (Task 3)
# Matches a person (by email or name) across Jira, Slack, and GitHub
set -euo pipefail

# Load shared helpers for Jira/Slack/GitHub credentials
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/helpers.sh"

# ── Input Validation ─────────────────────────────────────────────────
if [ -z "${PERSON_INPUT:-}" ]; then
  echo "ERROR: PERSON_INPUT not set" >&2
  exit 1
fi

# ── Detect Input Type ────────────────────────────────────────────────
# Email regex: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
if [[ "$PERSON_INPUT" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  PERSON_TYPE="email"
  PERSON_EMAIL="$PERSON_INPUT"
  # Extract name parts from email local part (e.g., marco.rossi@... → marco, rossi)
  local_part="${PERSON_INPUT%%@*}"
  PERSON_NAME_PARTS=$(echo "$local_part" | tr '.' ' ')
else
  PERSON_TYPE="name"
  PERSON_EMAIL=""
  PERSON_NAME_PARTS="$PERSON_INPUT"
fi

export PERSON_TYPE PERSON_EMAIL PERSON_NAME_PARTS

# ── Jira User Matcher ────────────────────────────────────────────────
match_jira_user() {
  # If email: search Jira user by email
  # If name: return empty (not reliably exposed in Jira API, MVP limitation)
  if [ "$PERSON_TYPE" = "email" ]; then
    curl -sf \
      -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
      -H "Accept: application/json" \
      "$JIRA_BASE_URL/rest/api/2/user/search?username=${PERSON_EMAIL}" \
      2>/dev/null | jq -r '.[0].name // empty' || echo ""
  else
    # Name-based search not supported in MVP
    echo ""
  fi
}

# ── Slack User Matcher ───────────────────────────────────────────────
match_slack_user() {
  # MVP: echo input, defer full Slack user search to Task 6
  # Pattern: source-specific query scripts handle detailed matching
  echo "$PERSON_INPUT"
}

# ── GitHub User Matcher ──────────────────────────────────────────────
match_github_user() {
  # Search GitHub users by email or name
  gh search users --query="$PERSON_INPUT" --json login --limit 1 2>/dev/null | jq -r '.[0].login // empty' || echo ""
}

# Export functions for use in parent scripts
export -f match_jira_user match_slack_user match_github_user

# ── Output ───────────────────────────────────────────────────────────
echo "Person Input Analysis:"
echo "  Type: $PERSON_TYPE"
echo "  Email: ${PERSON_EMAIL:-(none)}"
echo "  Name Parts: $PERSON_NAME_PARTS"
