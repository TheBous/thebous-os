#!/usr/bin/env bash
# Appends a report file's content to today's Morning Briefing in the Obsidian
# daily structure. Creates the day's folder and file if needed. Never truncates.
#
# Usage: append_daily_note.sh <vault_path> <report_file>
set -euo pipefail

VAULT="$1"
REPORT_FILE="$2"

DAILY_DIR="$VAULT/Dev/Daily/$(date +%Y-%m-%d)"
BRIEFING_FILE="$DAILY_DIR/00 - Morning Briefing.md"

mkdir -p "$DAILY_DIR"

# Create Morning Briefing file if it doesn't exist, with a header
if [ ! -f "$BRIEFING_FILE" ]; then
  echo "# Morning Briefing — $(date +%Y-%m-%d)" > "$BRIEFING_FILE"
fi

# Append the report (which already contains sections from the skill)
{
  echo
  cat "$REPORT_FILE"
} >> "$BRIEFING_FILE"

echo "$BRIEFING_FILE"
