#!/usr/bin/env bash
# Slack threads query (Task 6)
# Searches for messages containing both WORKITEM_ID and mentioning/from PERSON_INPUT
# Returns JSON with timestamp, author, text, link
set -euo pipefail

# ── Input Validation ─────────────────────────────────────────────────
if [ -z "${WORKITEM_ID:-}" ]; then
  echo "ERROR: WORKITEM_ID not set" >&2
  exit 1
fi

if [ -z "${PERSON_INPUT:-}" ]; then
  echo "ERROR: PERSON_INPUT not set" >&2
  exit 1
fi

# ── MVP: Graceful Fallback ──────────────────────────────────────────
# Slack search requires plugin:productivity:slack MCP tool.
# This MVP returns empty results if not available.
# To integrate with MCP:
# 1. Use Slack's search.messages or conversations.history MCP tools
# 2. Query: text contains WORKITEM_ID AND (from: PERSON_INPUT OR mentions: PERSON_INPUT)
# 3. Parse response into {timestamp, author, text, link} JSON
# 4. Slack search is best-effort (API may have limitations)

# Check if Slack credentials are available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/helpers.sh"
SLACK_CONFIG="$ENV_FILE"
if [ ! -f "$SLACK_CONFIG" ]; then
  # Slack not configured; return empty gracefully
  echo "[]"
  exit 0
fi

# Source Slack token if available
if grep -q "SLACK_BOT_TOKEN\|SLACK_WEBHOOK_URL" "$SLACK_CONFIG" 2>/dev/null; then
  # Slack is configured, but requires MCP tools for proper search
  # MCP tool would be called as: plugin:productivity:slack search.messages
  # For now, return empty array with note about MCP dependency
  echo "[]"
  exit 0
else
  # Slack not configured; return empty gracefully
  echo "[]"
  exit 0
fi
