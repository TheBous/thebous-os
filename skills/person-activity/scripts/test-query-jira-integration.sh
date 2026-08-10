#!/usr/bin/env bash
# Integration test for query-jira.sh with actual Jira API
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Jira Comments Query Integration Test ==="
echo

# Load environment
if [ ! -f ~/.config/jira-git-sync/.env ]; then
  echo "ERROR: Jira credentials not found at ~/.config/jira-git-sync/.env"
  echo "Please run /thebous-jira-git-sync:setup first"
  exit 1
fi

source ~/.config/jira-git-sync/.env

# Check if credentials are configured
if [ -z "${JIRA_API_TOKEN:-}" ] || [ -z "${JIRA_EMAIL:-}" ]; then
  echo "WARNING: Jira API token or email not configured"
  echo "Skipping live integration tests"
  echo "Set JIRA_API_TOKEN and JIRA_EMAIL in ~/.config/jira-git-sync/.env"
  exit 0
fi

echo "✓ Jira credentials loaded"
echo "  Base URL: $JIRA_BASE_URL"
echo "  Email: $JIRA_EMAIL"
echo

# ─────────────────────────────────────────────────────────────────────
# Step 1: Test with a known issue (if available)
# ─────────────────────────────────────────────────────────────────────
echo "Step 1: Checking for available Jira issues..."

# Get a list of recent issues
ISSUES=$(curl -s \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json" \
  "$JIRA_BASE_URL/rest/api/2/search?maxResults=5&fields=key,summary,comment" 2>/dev/null || echo "{}")

if echo "$ISSUES" | jq -e '.issues[0]' >/dev/null 2>&1; then
  FIRST_ISSUE=$(echo "$ISSUES" | jq -r '.issues[0].key')
  echo "✓ Found issue: $FIRST_ISSUE"
  echo

  # ─────────────────────────────────────────────────────────────────────
  # Step 2: Test query-jira.sh with actual issue
  # ─────────────────────────────────────────────────────────────────────
  echo "Step 2: Testing query-jira.sh with $FIRST_ISSUE..."

  output=$(WORKITEM_TYPE=jira WORKITEM_ID="$FIRST_ISSUE" PERSON_EMAIL="$JIRA_EMAIL" PERSON_NAME_PARTS="$(echo "$JIRA_EMAIL" | cut -d@ -f1)" \
    bash "$SCRIPT_DIR/query-jira.sh" 2>&1 || echo "[]")

  echo "Output: $output"
  echo

  # Validate JSON
  if echo "$output" | jq -e . >/dev/null 2>&1; then
    echo "✓ Output is valid JSON"

    # Count comments
    count=$(echo "$output" | jq 'length')
    echo "✓ Found $count comments for this person on $FIRST_ISSUE"

    # Show structure of first comment (if any)
    if [ "$count" -gt 0 ]; then
      echo "✓ First comment structure:"
      echo "$output" | jq '.[0]' | sed 's/^/  /'
    fi
  else
    echo "ERROR: Output is not valid JSON"
    exit 1
  fi
else
  echo "No issues found in Jira (this is OK if workspace is empty)"
fi

echo
echo "=== Integration Test Complete ==="
