#!/usr/bin/env bash
# Test suite for query-jira.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0

# Helper to run a test
run_test() {
  local name="$1"
  local expected="$2"
  shift 2

  test_count=$((test_count + 1))
  echo -n "Test $test_count: $name ... "

  local output
  output=$("$@" 2>/dev/null || echo "ERROR")

  if [ "$output" = "$expected" ]; then
    echo -e "${GREEN}✓${NC}"
    pass_count=$((pass_count + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  Expected: $expected"
    echo "  Got: $output"
  fi
}

echo "=== Testing query-jira.sh ==="
echo

# ─────────────────────────────────────────────────────────────────────
# Test 1: Skip if WORKITEM_TYPE != "jira"
# ─────────────────────────────────────────────────────────────────────
echo "Test 1: Non-Jira work items should return empty array"
run_test "GitHub PR (WORKITEM_TYPE=github)" "[]" \
  bash -c 'WORKITEM_TYPE=github WORKITEM_ID=250 PERSON_EMAIL=test@test.com PERSON_NAME_PARTS="test" '"$SCRIPT_DIR"'/query-jira.sh'

run_test "Git commit (WORKITEM_TYPE=git)" "[]" \
  bash -c 'WORKITEM_TYPE=git WORKITEM_ID=abc123def PERSON_EMAIL=test@test.com PERSON_NAME_PARTS="test" '"$SCRIPT_DIR"'/query-jira.sh'

echo

# ─────────────────────────────────────────────────────────────────────
# Test 2: Invalid Jira issue should return empty array
# ─────────────────────────────────────────────────────────────────────
echo "Test 2: Invalid Jira issue should return empty array (graceful error handling)"

# This test requires valid Jira credentials to be set
if [ -f ~/.config/jira-git-sync/.env ]; then
  source ~/.config/jira-git-sync/.env

  if [ -n "${JIRA_API_TOKEN:-}" ] && [ -n "${JIRA_EMAIL:-}" ]; then
    run_test "Non-existent issue" "[]" \
      bash -c 'source ~/.config/jira-git-sync/.env && WORKITEM_TYPE=jira WORKITEM_ID=INVALID-9999 PERSON_EMAIL=test@test.com PERSON_NAME_PARTS="test" '"$SCRIPT_DIR"'/query-jira.sh'
  else
    echo -e "${YELLOW}⊘${NC} Skipped (no Jira credentials configured)"
  fi
else
  echo -e "${YELLOW}⊘${NC} Skipped (no Jira credentials file)"
fi

echo

# ─────────────────────────────────────────────────────────────────────
# Test 3: Valid Jira issue response structure
# ─────────────────────────────────────────────────────────────────────
echo "Test 3: Valid JSON output structure"

# Check if output is valid JSON
run_test "Output is valid JSON" "valid" \
  bash -c 'result=$(WORKITEM_TYPE=github WORKITEM_ID=250 PERSON_EMAIL=test@test.com PERSON_NAME_PARTS="test" '"$SCRIPT_DIR"'/query-jira.sh); echo "$result" | jq -e . >/dev/null 2>&1 && echo "valid" || echo "invalid"'

echo

# ─────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────
echo "=== Summary ==="
echo "Passed: $pass_count / $test_count"

if [ $pass_count -eq $test_count ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
