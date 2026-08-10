#!/usr/bin/env bash
# Person Activity Skill - Main Integration Script (Task 10)
# Wires all detection, matching, and query scripts together
# Outputs a synthesized markdown report to stdout
set -euo pipefail

# ── Setup ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load shared helpers
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/helpers.sh"

# ── Interactive Input ────────────────────────────────────────────────
echo "=== Person Activity Report ==="
echo
read -p "Work item ID? (e.g., DC-443, PR #250, abc123def): " WORKITEM_ID
read -p "Person? (email or full name): " PERSON_INPUT

# Export for downstream scripts
export WORKITEM_ID PERSON_INPUT

# ── Stage 1: Detect Work Item Type ──────────────────────────────────
echo "🔍 Detecting work item type..." >&2
source "${SCRIPT_DIR}/detect-workitem-type.sh"

# ── Stage 2: Match Person Across Systems ────────────────────────────
echo "👤 Matching person across systems..." >&2
source "${SCRIPT_DIR}/match-person.sh"

# ── Stage 3: Query All Sources in Parallel ──────────────────────────
echo "🔎 Querying sources (Jira, GitHub, Slack, Email, Calendar)..." >&2

JIRA_RESULTS=$(bash "${SCRIPT_DIR}/query-jira.sh" 2>/dev/null || echo "[]")
GITHUB_RESULTS=$(bash "${SCRIPT_DIR}/query-github.sh" 2>/dev/null || echo "[]")
SLACK_RESULTS=$(bash "${SCRIPT_DIR}/query-slack.sh" 2>/dev/null || echo "[]")
EMAIL_RESULTS=$(bash "${SCRIPT_DIR}/query-email.sh" 2>/dev/null || echo "[]")
CALENDAR_RESULTS=$(bash "${SCRIPT_DIR}/query-calendar.sh" 2>/dev/null || echo "[]")

# ── Stage 4: Combine Results ─────────────────────────────────────────
# Merge all arrays into one, tagging each result with its source
COMBINED=$(jq -n \
  --argjson jira "$JIRA_RESULTS" \
  --argjson github "$GITHUB_RESULTS" \
  --argjson slack "$SLACK_RESULTS" \
  --argjson email "$EMAIL_RESULTS" \
  --argjson calendar "$CALENDAR_RESULTS" \
  '
  (
    (($jira // []) | map(. + {source: "jira"})),
    (($github // []) | map(. + {source: "github"})),
    (($slack // []) | map(. + {source: "slack"})),
    (($email // []) | map(. + {source: "email"})),
    (($calendar // []) | map(. + {source: "calendar"}))
  ) | add // []
  ' 2>/dev/null || echo "[]")

# ── Stage 5: Synthesize Report ──────────────────────────────────────
echo >&2
bash "${SCRIPT_DIR}/synthesize.sh" <<< "$COMBINED"
