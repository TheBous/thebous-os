#!/usr/bin/env bash
# Appends a report file's content to today's dated note in the Obsidian
# daily structure. Creates the day's folder and file if needed. Never truncates.
# Shared by morning-briefing and end-of-day (same append pattern, different note).
#
# Usage: append_daily_note.sh <vault_path> <report_file> <note_filename> <note_title>
set -euo pipefail

VAULT="$1"
REPORT_FILE="$2"
NOTE_FILENAME="$3"
NOTE_TITLE="$4"

DAILY_DIR="$VAULT/Dev/Daily/$(date +%Y-%m-%d)"
NOTE_FILE="$DAILY_DIR/$NOTE_FILENAME"

mkdir -p "$DAILY_DIR"

if [ ! -f "$NOTE_FILE" ]; then
  echo "# $NOTE_TITLE — $(date +%Y-%m-%d)" > "$NOTE_FILE"
fi

# Append the report (which already contains sections from the skill)
{
  echo
  cat "$REPORT_FILE"
} >> "$NOTE_FILE"

echo "$NOTE_FILE"
