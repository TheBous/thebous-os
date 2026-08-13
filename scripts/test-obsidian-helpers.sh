#!/usr/bin/env bash
# Self-check for the Obsidian helper functions in helpers.sh.
# Run: bash scripts/test-obsidian-helpers.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
set +e  # helpers.sh sets -e; these checks need to keep running after a failed one

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

assert_file_contains() {
  local desc="$1" file="$2" pattern="$3"
  if grep -qF "$pattern" "$file"; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc — '$pattern' not found in $file"
    FAIL=1
  fi
}

VAULT=$(mktemp -d)

# obsidian_ticket_dir
assert_eq "ticket_dir path" "$VAULT/Dev/Tickets/T-200" "$(obsidian_ticket_dir "$VAULT" "T-200")"
assert_eq "ticket_docs_dir path" "$VAULT/Dev/Tickets/T-200/docs" "$(obsidian_ticket_docs_dir "$VAULT" "T-200")"

# obsidian_copy_ticket_docs — copies a complete artifact directory
ARTIFACT_DIR=$(mktemp -d)
echo '<html></html>' > "$ARTIFACT_DIR/index.html"
mkdir -p "$ARTIFACT_DIR/assets"
echo 'body {}' > "$ARTIFACT_DIR/assets/style.css"
COPIED_DIR=$(obsidian_copy_ticket_docs "$VAULT" "T-200" "explain-change/run-1" "$ARTIFACT_DIR")
assert_eq "copy_ticket_docs destination" "$VAULT/Dev/Tickets/T-200/docs/explain-change/run-1" "$COPIED_DIR"
assert_file_contains "artifact html copied" "$COPIED_DIR/index.html" '<html></html>'
assert_file_contains "artifact asset copied" "$COPIED_DIR/assets/style.css" 'body {}'
rm -rf "$ARTIFACT_DIR"

# obsidian_copy_daily_artifact — copies a generated report into today's folder
DAILY_ARTIFACT=$(mktemp -d)
echo '<html>status</html>' > "$DAILY_ARTIFACT/index.html"
DAILY_COPIED=$(obsidian_copy_daily_artifact "$VAULT" "current-status-1" "$DAILY_ARTIFACT")
assert_eq "copy_daily_artifact destination" "$VAULT/Dev/Daily/$(date +%Y-%m-%d)/current-status-1" "$DAILY_COPIED"
assert_file_contains "daily artifact copied" "$DAILY_COPIED/index.html" '<html>status</html>'
rm -rf "$DAILY_ARTIFACT"

# obsidian_ensure_ticket_file — creates with frontmatter, idempotent
FILE=$(obsidian_ensure_ticket_file "$VAULT" "T-200" "plan.md")
assert_eq "ensure_ticket_file path" "$VAULT/Dev/Tickets/T-200/plan.md" "$FILE"
assert_file_contains "frontmatter has ticket key" "$FILE" "ticket: T-200"
obsidian_ensure_ticket_file "$VAULT" "T-200" "plan.md" >/dev/null
COUNT=$(grep -c '^ticket: T-200$' "$FILE"); assert_eq "frontmatter not duplicated on 2nd call" "1" "$COUNT"

# obsidian_set_pr — inserts then updates idempotently
obsidian_set_pr "$FILE" "https://github.com/x/y/pull/1"
assert_file_contains "pr field set" "$FILE" "pr: https://github.com/x/y/pull/1"
obsidian_set_pr "$FILE" "https://github.com/x/y/pull/2"
PR_COUNT=$(grep -c '^pr: ' "$FILE"); assert_eq "pr field updated not duplicated" "1" "$PR_COUNT"
assert_file_contains "pr field holds latest value" "$FILE" "pr: https://github.com/x/y/pull/2"

# obsidian_append_section — appends without truncating prior content
echo "existing body line" >> "$FILE"
obsidian_append_section "$FILE" "did a thing"
assert_file_contains "prior content preserved" "$FILE" "existing body line"
assert_file_contains "new section appended" "$FILE" "did a thing"

# obsidian_append_daily — creates file, appends bullets across calls
obsidian_append_daily "$VAULT" "[[T-200]] — branch created"
obsidian_append_daily "$VAULT" "[[T-200]] — PR opened"
DAILY_FILE="$VAULT/Dev/Daily/$(date +%Y-%m-%d)/10 - Work Log.md"
assert_file_contains "daily bullet 1" "$DAILY_FILE" "branch created"
assert_file_contains "daily bullet 2" "$DAILY_FILE" "PR opened"
BULLET_COUNT=$(grep -c '^- ' "$DAILY_FILE"); assert_eq "two bullets total" "2" "$BULLET_COUNT"

# obsidian_granola_candidates — only lists recent .md files, empty when folder missing
mkdir -p "$VAULT/Granola"
cat > "$VAULT/Granola/recent.md" <<'NOTE'
---
title: Recent Call
---
NOTE
cat > "$VAULT/Granola/old.md" <<'NOTE'
---
title: Old Call
---
NOTE
touch -d "40 days ago" "$VAULT/Granola/old.md" 2>/dev/null || touch -t "$(date -v-40d +%Y%m%d0000)" "$VAULT/Granola/old.md"

CANDIDATES=$(obsidian_granola_candidates "$VAULT" 14)
echo "$CANDIDATES" | grep -q "recent.md" && echo "PASS: recent note listed" || { echo "FAIL: recent note listed"; FAIL=1; }
echo "$CANDIDATES" | grep -q "old.md" && { echo "FAIL: old note should be excluded"; FAIL=1; } || echo "PASS: old note excluded"

rm -rf "$VAULT/Granola"
obsidian_granola_candidates "$VAULT" 14 >/dev/null && echo "PASS: missing Granola/ folder does not error"

rm -rf "$VAULT"

if [ "$FAIL" -eq 0 ]; then
  echo "All Obsidian helper checks passed."
  exit 0
else
  echo "Some Obsidian helper checks FAILED."
  exit 1
fi
