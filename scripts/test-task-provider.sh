#!/usr/bin/env bash
# Self-check for provider-neutral task reference resolution.
# Run: bash scripts/test-task-provider.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
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

assert_ref() {
  local desc="$1" input="$2" expected_provider="$3" expected_id="$4" expected_url="$5"
  local ref provider external_id url
  ref=$(resolve_work_item_ref "$input")
  if [ "$?" -ne 0 ]; then
    echo "FAIL: $desc — resolver rejected '$input'"
    FAIL=1
    return
  fi
  provider=$(jq -r '.provider' <<<"$ref")
  external_id=$(jq -r '.external_id' <<<"$ref")
  url=$(jq -r '.url // "null"' <<<"$ref")
  assert_eq "$desc provider" "$expected_provider" "$provider"
  assert_eq "$desc external_id" "$expected_id" "$external_id"
  assert_eq "$desc url" "$expected_url" "$url"
}

JIRA_KEY="T-200"
NOTION_ID="6f3b2c1a-1234-4567-89ab-0123456789ab"
NOTION_ID_COMPACT="6f3b2c1a1234456789ab0123456789ab"
NOTION_URL="https://www.notion.so/example/Implement-OAuth-${NOTION_ID_COMPACT}"

assert_ref "bare Jira key" "t-200" "jira" "$JIRA_KEY" "null"
assert_ref "Jira URL" "https://company.atlassian.net/browse/T-200" "jira" "$JIRA_KEY" "https://company.atlassian.net/browse/T-200"
assert_ref "explicit Jira reference" "jira:T-200" "jira" "$JIRA_KEY" "null"
assert_ref "Notion page ID" "notion:$NOTION_ID" "notion" "$NOTION_ID" "null"
assert_ref "Notion URL" "$NOTION_URL" "notion" "$NOTION_ID" "$NOTION_URL"
assert_ref "Notion branch" "feat/ntn-${NOTION_ID_COMPACT}-implement-oauth" "notion" "$NOTION_ID" "null"
assert_ref "Notion branch with numeric slug" "feat/ntn-${NOTION_ID_COMPACT}-implement-oauth-6" "notion" "$NOTION_ID" "null"

AMBIGUOUS_OUTPUT=$(resolve_work_item_ref "T-200 $NOTION_URL" 2>&1)
if [ "$?" -eq 0 ]; then
  echo "FAIL: ambiguous Jira and Notion input should be rejected"
  FAIL=1
elif ! grep -q "ambiguous" <<<"$AMBIGUOUS_OUTPUT"; then
  echo "FAIL: ambiguous input error should explain the ambiguity"
  FAIL=1
else
  echo "PASS: ambiguous Jira and Notion input is rejected"
fi

if resolve_work_item_ref "plain text without a task reference" >/dev/null 2>&1; then
  echo "FAIL: invalid input should be rejected"
  FAIL=1
else
  echo "PASS: invalid input is rejected"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "All task provider checks passed."
  exit 0
else
  echo "Some task provider checks FAILED."
  exit 1
fi
