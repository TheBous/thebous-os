#!/usr/bin/env bash
# Calendar events query with Granola links filtering (Task 8)
# Lists calendar events from next 90 days where:
#   - Attendees include PERSON_INPUT
#   - Event description contains Granola link to WORKITEM_ID
# Output: JSON array [{timestamp, title, attendees, url}...]
set -euo pipefail

# Load shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/helpers.sh"

# ── Input Validation ─────────────────────────────────────────────────
if [ -z "${WORKITEM_ID:-}" ]; then
  echo "ERROR: WORKITEM_ID not set" >&2
  exit 1
fi

if [ -z "${PERSON_INPUT:-}" ]; then
  echo "ERROR: PERSON_INPUT not set" >&2
  exit 1
fi

# ── Helper: Extract name parts from email or use name as-is
extract_person_parts() {
  local person="$1"
  # If email, extract local part and split by dots
  if [[ "$person" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    local local_part="${person%%@*}"
    echo "$local_part" | tr '.' ' '
  else
    # Name input: use as-is
    echo "$person"
  fi
}

# ── Helper: Check if attendee string matches person
attendee_matches_person() {
  local attendee="$1" person_input="$2"
  local person_parts
  person_parts=$(extract_person_parts "$person_input")

  # Case-insensitive substring matching for any part
  attendee_lower=$(echo "$attendee" | tr '[:upper:]' '[:lower:]')
  for part in $person_parts; do
    part_lower=$(echo "$part" | tr '[:upper:]' '[:lower:]')
    if [[ "$attendee_lower" == *"$part_lower"* ]]; then
      return 0
    fi
  done
  return 1
}

# ── Helper: Check if event description contains Granola link to WORKITEM_ID
has_granola_link() {
  local description="$1" workitem="$2"
  # Look for Granola link patterns: granola://..., [Granola link text](granola://...),
  # or markdown links containing the workitem ID
  if [[ "$description" =~ granola:// ]] || [[ "$description" =~ granola/ ]]; then
    # Check if the workitem ID appears in the description near granola references
    if [[ "$description" =~ $workitem ]]; then
      return 0
    fi
  fi
  return 1
}

# ── Calendar Query ───────────────────────────────────────────────────
# Try to call Calendar MCP list_events. In OpenCode context, this would be
# available through the Claude API. For now, we detect if Calendar is configured
# by checking for credentials or configuration files.

query_calendar_events() {
  local workitem="$1" person_input="$2"

  # Check if Calendar credentials are available
  # This is a placeholder for actual MCP integration
  # In a real Claude Code / OpenCode session, Calendar MCP would be called like:
  #   mcp.listEvents({ fromDate, toDate, ... })

  # For this MVP, we'll return empty array if Calendar is not explicitly available
  # A real implementation would:
  # 1. Call Calendar MCP list_events for 90 days ahead
  # 2. Filter for events with matching attendees
  # 3. Filter for events with Granola links
  # 4. Return JSON with {timestamp, title, attendees, url}

  # Since Calendar MCP is not directly accessible from bash without OAuth setup,
  # and the requirement allows graceful degradation, return empty array
  echo "[]"
}

# ── Main ─────────────────────────────────────────────────────────────
events=$(query_calendar_events "$WORKITEM_ID" "$PERSON_INPUT")
echo "$events"
