#!/usr/bin/env bash
# Email threads query (Task 7)
# Searches Gmail for email threads involving a person on a work item
# MVP: returns empty array (Gmail MCP integration deferred to Claude Code context)
set -euo pipefail

# ── Input Validation ────────────────────────────────────────────────
if [ -z "${PERSON_EMAIL:-}" ] || [ -z "${WORKITEM_ID:-}" ]; then
  echo "[]"
  exit 0
fi

# ── Load Credentials ────────────────────────────────────────────────
ENV_FILE="${CLAUDE_PLUGIN_DATA:-$HOME/.config/thebous-os}/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "[]"
  exit 0
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

# ── Gmail Query ────────────────────────────────────────────────────
# Gracefully degrade if Gmail not configured
if [ -z "${GMAIL_ADDRESS:-}" ]; then
  echo "[]"
  exit 0
fi

# MVP: Return empty for now
# Integration point: When running in Claude Code context, use Gmail MCP tool:
#   - Tool: search_threads
#   - Query: from:$PERSON_EMAIL OR to:$PERSON_EMAIL AND subject:$WORKITEM_ID
#   - Parse response into JSON: {timestamp, sender, subject, link}
echo "[]"
