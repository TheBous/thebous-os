#!/usr/bin/env bash
# Self-check for append_daily_note.sh. Run: bash scripts/test_append_daily_note.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0

VAULT=$(mktemp -d)
REPORT=$(mktemp)
echo "## Section
- a line" > "$REPORT"

OUT1=$(bash "$SCRIPT_DIR/append_daily_note.sh" "$VAULT" "$REPORT" "00 - Morning Briefing.md" "Morning Briefing")
if grep -qF "a line" "$OUT1"; then echo "PASS: first call creates note with content"; else echo "FAIL: first call creates note with content"; FAIL=1; fi

echo "second run" > "$REPORT"
bash "$SCRIPT_DIR/append_daily_note.sh" "$VAULT" "$REPORT" "00 - Morning Briefing.md" "Morning Briefing" >/dev/null
if grep -qF "a line" "$OUT1" && grep -qF "second run" "$OUT1"; then
  echo "PASS: second call appends without erasing the first"
else
  echo "FAIL: second call appends without erasing the first"
  FAIL=1
fi

HEADER_COUNT=$(grep -c '^# Morning Briefing' "$OUT1")
if [ "$HEADER_COUNT" = "1" ]; then echo "PASS: header written once, not duplicated on second append"; else echo "FAIL: expected 1 header, got $HEADER_COUNT"; FAIL=1; fi

OUT2=$(bash "$SCRIPT_DIR/append_daily_note.sh" "$VAULT" "$REPORT" "30 - End of Day Recap.md" "End of Day Recap")
if [ "$OUT2" != "$OUT1" ] && grep -qF "second run" "$OUT2"; then
  echo "PASS: different note_filename writes a separate file"
else
  echo "FAIL: different note_filename writes a separate file"
  FAIL=1
fi

rm -rf "$VAULT" "$REPORT"

if [ "$FAIL" -eq 0 ]; then echo "All append_daily_note checks passed."; exit 0; else echo "Some checks FAILED."; exit 1; fi
