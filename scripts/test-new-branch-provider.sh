#!/usr/bin/env bash
# Self-check for provider-aware new-branch instructions.
# Run: bash scripts/test-new-branch-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/new-branch/SKILL.md"
COMMAND="$ROOT_DIR/commands/new-branch.md"

grep -q 'resolve_work_item_ref' "$SKILL"
grep -q 'feat/ntn-' "$SKILL"
grep -q 'notion_set_status' "$SKILL"
grep -q 'notion_add_comment' "$SKILL"
grep -q 'obsidian_log_task' "$SKILL"
grep -q 'jira-transition.md' "$SKILL"
grep -q 'JIRA_BASE_URL/browse' "$SKILL"
grep -q 'Jira or Notion' "$COMMAND"

echo "Provider-aware new-branch checks passed."
