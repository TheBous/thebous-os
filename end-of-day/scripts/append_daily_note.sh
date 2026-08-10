#!/usr/bin/env bash
# Appends a report file's content as a new dated section to today's Obsidian
# daily note, creating the note if it doesn't exist yet. Never truncates.
#
# Usage: append_daily_note.sh <vault_path> <report_file>
set -euo pipefail

VAULT="$1"
REPORT_FILE="$2"

DAILY_DIR="$VAULT/Dev/Daily"
DAILY_FILE="$DAILY_DIR/$(date +%Y-%m-%d).md"

mkdir -p "$DAILY_DIR"
[ -f "$DAILY_FILE" ] || echo "# $(date +%Y-%m-%d)" > "$DAILY_FILE"

{
  echo
  echo "## Morning Briefing — $(date '+%H:%M')"
  cat "$REPORT_FILE"
} >> "$DAILY_FILE"

echo "$DAILY_FILE"
