#!/usr/bin/env bash
# Self-check for provider coverage in status and briefing workflows.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT_STATUS="$ROOT_DIR/skills/current-status/SKILL.md"
MORNING_BRIEFING="$ROOT_DIR/skills/morning-briefing/SKILL.md"
END_OF_DAY="$ROOT_DIR/skills/end-of-day/SKILL.md"

for skill in "$CURRENT_STATUS" "$MORNING_BRIEFING"; do
  grep -q "Notion" "$skill"
  grep -q "list_activity" "$skill"
  grep -q "coverage gap" "$skill"
  grep -q "provider" "$skill"
  grep -q "source label" "$skill"
done

grep -q "Jira-only" "$CURRENT_STATUS"
grep -q "Notion-only" "$CURRENT_STATUS"
grep -q "both providers" "$CURRENT_STATUS"
grep -q "Exclude tasks whose normalized status is" "$MORNING_BRIEFING"
grep -q "NOTION_API_TOKEN" "$MORNING_BRIEFING"
grep -q "NOTION_USER_EMAIL" "$CURRENT_STATUS"
grep -q "NOTION_USER_EMAIL" "$MORNING_BRIEFING"
grep -q "Notion" "$END_OF_DAY"
grep -q "notion_list_tasks" "$END_OF_DAY"
grep -q "notion_list_activity" "$END_OF_DAY"
grep -q "NOTION_USER_EMAIL" "$END_OF_DAY"
grep -q "coverage gap" "$END_OF_DAY"

echo "Provider report checks passed."
