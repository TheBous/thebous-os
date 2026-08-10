#!/usr/bin/env bash
# Appends a report file's content to today's End of Day Recap in the Obsidian
# daily structure. Creates the day's folder and file if needed. Never truncates.
#
# Usage: append_daily_note.sh <vault_path> <report_file>
set -euo pipefail

VAULT="$1"
REPORT_FILE="$2"

DAILY_DIR="$VAULT/Dev/Daily/$(date +%Y-%m-%d)"
RECAP_FILE="$DAILY_DIR/30 - End of Day Recap.md"

mkdir -p "$DAILY_DIR"

# Create End of Day Recap file if it doesn't exist, with a header
if [ ! -f "$RECAP_FILE" ]; then
  echo "# End of Day Recap — $(date +%Y-%m-%d)" > "$RECAP_FILE"
fi

# Append the report (which already contains sections from the skill)
{
  echo
  cat "$REPORT_FILE"
} >> "$RECAP_FILE"

echo "$RECAP_FILE"
