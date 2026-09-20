#!/usr/bin/env bash
# Self-check for provider-aware explain-change instructions.
# Run: bash scripts/test-explain-change-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/explain-change/SKILL.md"

grep -q 'Jira or Notion task' "$SKILL"
grep -q 'references/task-context.md' "$SKILL"
grep -q 'resolve_work_item_ref' "$SKILL"
grep -q 'obsidian_task_storage_key' "$SKILL"
grep -q 'obsidian_ensure_task_file' "$SKILL"
! grep -q 'Identify the Jira task' "$SKILL"
! grep -q 'obsidian_ensure_ticket_file' "$SKILL"

echo "Provider-aware explain-change checks passed."
