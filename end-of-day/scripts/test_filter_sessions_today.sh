#!/usr/bin/env bash
# Self-check for filter_sessions_today.jq — tests the pure filtering logic
# against a fixture, no live opencode server needed.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0

FIXTURE=$(mktemp)
cat > "$FIXTURE" <<'EOF'
{
  "data": [
    {"id": "today-1", "time": {"updated": 1000000}},
    {"id": "today-2", "time": {"updated": 1500000}},
    {"id": "yesterday", "time": {"updated": 500000}},
    {"id": "tomorrow", "time": {"updated": 2500000}}
  ]
}
EOF

RESULT=$(jq --argjson start 1000000 --argjson end 2000000 -f "$SCRIPT_DIR/filter_sessions_today.jq" "$FIXTURE")
COUNT=$(echo "$RESULT" | jq 'length')

if [ "$COUNT" = "2" ]; then echo "PASS: keeps only sessions in window (2 of 4)"; else echo "FAIL: expected 2, got $COUNT"; FAIL=1; fi
if echo "$RESULT" | jq -e '.[] | select(.id == "today-1")' >/dev/null; then echo "PASS: today-1 present"; else echo "FAIL: today-1 missing"; FAIL=1; fi
if echo "$RESULT" | jq -e '.[] | select(.id == "yesterday")' >/dev/null 2>&1; then echo "FAIL: yesterday should be excluded"; FAIL=1; else echo "PASS: yesterday excluded"; fi
if echo "$RESULT" | jq -e '.[] | select(.id == "tomorrow")' >/dev/null 2>&1; then echo "FAIL: tomorrow should be excluded"; FAIL=1; else echo "PASS: tomorrow excluded (end is exclusive)"; fi

rm -f "$FIXTURE"

if [ "$FAIL" -eq 0 ]; then echo "All filter_sessions_today checks passed."; exit 0; else echo "Some checks FAILED."; exit 1; fi
