#!/usr/bin/env bash
# Self-check for the Notion read-only adapter.
# Run: bash scripts/test-notion-adapter.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/notion.sh"
set +e

FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $desc — expected '$expected', got '$actual'"
    FAIL=1
  else
    echo "PASS: $desc"
  fi
}

assert_error() {
  local desc="$1" expected="$2" output="$3" status="$4"
  if [ "$status" -eq 0 ]; then
    echo "FAIL: $desc — expected failure"
    FAIL=1
  elif ! grep -q "$expected" <<<"$output"; then
    echo "FAIL: $desc — expected '$expected', got '$output'"
    FAIL=1
  else
    echo "PASS: $desc"
  fi
}

unset NOTION_API_TOKEN NOTION_DATABASE_ID NOTION_API_VERSION

CONFIG_OUTPUT=$(notion_config_validate 2>&1)
CONFIG_STATUS=$?
assert_error "missing Notion configuration" "AUTH_REQUIRED" "$CONFIG_OUTPUT" "$CONFIG_STATUS"

NOTION_API_TOKEN="test-token"
NOTION_DATABASE_ID="11111111-2222-3333-4444-555555555555"

NOTION_DATABASE_ID="not-a-notion-id"
OUTPUT=$(notion_config_validate 2>&1)
STATUS=$?
assert_error "malformed Notion database ID" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"
NOTION_DATABASE_ID="11111111-2222-3333-4444-555555555555"

PAGE_JSON='{
  "object": "page",
  "id": "6f3b2c1a-1234-4567-89ab-0123456789ab",
  "url": "https://www.notion.so/example/Implement-OAuth-6f3b2c1a1234456789ab0123456789ab",
  "parent": {"type": "database_id", "database_id": "11111111-2222-3333-4444-555555555555"},
  "last_edited_time": "2026-09-20T09:30:00.000Z",
  "properties": {
    "Name": {
      "type": "title",
      "title": [{"type": "text", "plain_text": "Implement OAuth login"}]
    },
    "Description": {
      "type": "rich_text",
      "rich_text": [{"type": "text", "plain_text": "Implement the login flow."}]
    },
    "Status": {
      "type": "status",
      "status": {"name": "In Progress"}
    },
    "Assignee": {
      "type": "people",
      "people": [{"name": "Marco Rossi", "person": {"email": "marco@example.com"}}]
    },
    "Due date": {
      "type": "date",
      "date": {"start": "2026-10-01"}
    },
    "Start date": {
      "type": "date",
      "date": {"start": "2026-09-20"}
    }
  }
}'

TASK=$(notion_normalize_page "$PAGE_JSON" "$NOTION_DATABASE_ID")
TASK_STATUS=$?
if [ "$TASK_STATUS" -ne 0 ]; then
  echo "FAIL: valid Notion page should normalize"
  FAIL=1
else
  assert_eq "normalized provider" "notion" "$(jq -r '.ref.provider' <<<"$TASK")"
  assert_eq "normalized external ID" "6f3b2c1a-1234-4567-89ab-0123456789ab" "$(jq -r '.ref.external_id' <<<"$TASK")"
  assert_eq "normalized title" "Implement OAuth login" "$(jq -r '.title' <<<"$TASK")"
  assert_eq "normalized description" "Implement the login flow." "$(jq -r '.description' <<<"$TASK")"
  assert_eq "normalized status" "in_progress" "$(jq -r '.status' <<<"$TASK")"
  assert_eq "normalized assignee" "marco@example.com" "$(jq -r '.assignee' <<<"$TASK")"
  assert_eq "normalized due date" "2026-10-01" "$(jq -r '.due_at' <<<"$TASK")"
  assert_eq "normalized start date" "2026-09-20" "$(jq -r '.start_at' <<<"$TASK")"
  assert_eq "normalized updated date" "2026-09-20T09:30:00.000Z" "$(jq -r '.updated_at' <<<"$TASK")"
  assert_eq "raw Notion properties are hidden" "false" "$(jq -r 'has("properties")' <<<"$TASK")"
fi

MISSING_DESCRIPTION=$(jq 'del(.properties.Description)' <<<"$PAGE_JSON")
OUTPUT=$(notion_normalize_page "$MISSING_DESCRIPTION" "$NOTION_DATABASE_ID" 2>&1)
STATUS=$?
assert_error "missing required Description property" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"

WRONG_PARENT=$(jq '.parent.database_id = "99999999-8888-7777-6666-555555555555"' <<<"$PAGE_JSON")
OUTPUT=$(notion_normalize_page "$WRONG_PARENT" "$NOTION_DATABASE_ID" 2>&1)
STATUS=$?
assert_error "page from another database" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"

curl() {
  local output_file=""
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "-o" ]; then
      output_file="$2"
      shift 2
    else
      shift
    fi
  done
  printf '%s' '{"message":"fixture error"}' >"$output_file"
  printf '%s' "${FIXTURE_HTTP_STATUS:-401}"
}

FIXTURE_HTTP_STATUS=401
OUTPUT=$(notion_get_page "6f3b2c1a-1234-4567-89ab-0123456789ab" 2>&1)
STATUS=$?
assert_error "Notion auth error" "AUTH_REQUIRED" "$OUTPUT" "$STATUS"

FIXTURE_HTTP_STATUS=429
OUTPUT=$(notion_get_page "6f3b2c1a-1234-4567-89ab-0123456789ab" 2>&1)
STATUS=$?
assert_error "Notion rate limit error" "PROVIDER_UNAVAILABLE" "$OUTPUT" "$STATUS"

unset -f curl

if [ "$FAIL" -eq 0 ]; then
  echo "All Notion adapter checks passed."
  exit 0
else
  echo "Some Notion adapter checks FAILED."
  exit 1
fi
