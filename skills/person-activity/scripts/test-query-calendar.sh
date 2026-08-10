#!/usr/bin/env bash
# Test suite for query-calendar.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

# ── Test Helpers ─────────────────────────────────────────────────────
pass_test() {
  echo "✓ $1"
  ((TESTS_PASSED++)) || true
}

fail_test() {
  echo "✗ $1"
  ((TESTS_FAILED++)) || true
}

# ── Define helper functions for testing ──────────────────────────────
extract_person_parts() {
  local person="$1"
  if [[ "$person" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    local local_part="${person%%@*}"
    echo "$local_part" | tr '.' ' '
  else
    echo "$person"
  fi
}

attendee_matches_person() {
  local attendee="$1" person_input="$2"
  local person_parts
  person_parts=$(extract_person_parts "$person_input")

  attendee_lower=$(echo "$attendee" | tr '[:upper:]' '[:lower:]')
  for part in $person_parts; do
    part_lower=$(echo "$part" | tr '[:upper:]' '[:lower:]')
    if [[ "$attendee_lower" == *"$part_lower"* ]]; then
      return 0
    fi
  done
  return 1
}

has_granola_link() {
  local description="$1" workitem="$2"
  if [[ "$description" =~ granola:// ]] || [[ "$description" =~ granola/ ]]; then
    if [[ "$description" =~ $workitem ]]; then
      return 0
    fi
  fi
  return 1
}

# ── Test: extract_person_parts ───────────────────────────────────────
echo "Testing extract_person_parts()..."

result=$(extract_person_parts "marco.rossi@example.com")
if [ "$result" = "marco rossi" ]; then
  pass_test "Email extraction (marco.rossi@example.com)"
else
  fail_test "Email extraction: got '$result', expected 'marco rossi'"
fi

result=$(extract_person_parts "john.doe.smith@example.org")
if [ "$result" = "john doe smith" ]; then
  pass_test "Complex email extraction (john.doe.smith@example.org)"
else
  fail_test "Complex email extraction: got '$result', expected 'john doe smith'"
fi

result=$(extract_person_parts "Marco Rossi")
if [ "$result" = "Marco Rossi" ]; then
  pass_test "Name input passthrough (Marco Rossi)"
else
  fail_test "Name input passthrough: got '$result', expected 'Marco Rossi'"
fi

# ── Test: attendee_matches_person ────────────────────────────────────
echo -e "\nTesting attendee_matches_person()..."

if attendee_matches_person "marco.rossi@jira.com" "marco.rossi@example.com"; then
  pass_test "Email attendee match (marco)"
else
  fail_test "Email attendee match (marco)"
fi

if attendee_matches_person "Marco Rossi" "marco@example.com"; then
  pass_test "Name attendee match (case-insensitive)"
else
  fail_test "Name attendee match (case-insensitive)"
fi

if attendee_matches_person "Marco Rossi" "Marco"; then
  pass_test "Partial name match (Marco)"
else
  fail_test "Partial name match (Marco)"
fi

if ! attendee_matches_person "alice@example.com" "marco@example.com"; then
  pass_test "Non-matching attendee correctly rejected"
else
  fail_test "Non-matching attendee should be rejected"
fi

# ── Test: has_granola_link ───────────────────────────────────────────
echo -e "\nTesting has_granola_link()..."

if has_granola_link "See granola://DC-123 for details" "DC-123"; then
  pass_test "Granola link detection (granola://DC-123)"
else
  fail_test "Granola link detection"
fi

if ! has_granola_link "See granola://DC-456 for details" "DC-123"; then
  pass_test "Non-matching workitem in Granola link correctly rejected"
else
  fail_test "Non-matching workitem should be rejected"
fi

if ! has_granola_link "Just a regular event description" "DC-123"; then
  pass_test "Absence of Granola link correctly detected"
else
  fail_test "Should reject events without Granola links"
fi

# ── Test: Main script invocation ─────────────────────────────────────
echo -e "\nTesting main script invocation..."

result=$(WORKITEM_ID="DC-123" PERSON_INPUT="marco@example.com" bash "$SCRIPT_DIR/query-calendar.sh")
if [ "$result" = "[]" ]; then
  pass_test "Script returns empty array when Calendar unavailable"
else
  fail_test "Script should return empty array: got '$result'"
fi

result=$(WORKITEM_ID="PR-456" PERSON_INPUT="Marco Rossi" bash "$SCRIPT_DIR/query-calendar.sh")
if [ "$result" = "[]" ]; then
  pass_test "Script handles name input and returns empty array"
else
  fail_test "Script should return empty array for name input: got '$result'"
fi

# ── Test: Input validation ───────────────────────────────────────────
echo -e "\nTesting input validation..."

if ! PERSON_INPUT="marco@example.com" bash "$SCRIPT_DIR/query-calendar.sh" 2>/dev/null; then
  pass_test "Missing WORKITEM_ID causes error"
else
  fail_test "Should error when WORKITEM_ID is missing"
fi

if ! WORKITEM_ID="DC-123" bash "$SCRIPT_DIR/query-calendar.sh" 2>/dev/null; then
  pass_test "Missing PERSON_INPUT causes error"
else
  fail_test "Should error when PERSON_INPUT is missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo -e "\n========================================="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
