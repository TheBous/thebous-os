#!/usr/bin/env bash
# Self-check for provider-aware PR review instructions.
# Run: bash scripts/test-review-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/review-pr-multiharness/SKILL.md"

grep -q 'Jira or Notion task' "$SKILL"
grep -q 'references/task-context.md' "$SKILL"
grep -q 'resolve_work_item_ref' "$SKILL"
grep -q 'provider-neutral task reference' "$SKILL"
grep -q 'obsidian_task_storage_key' "$SKILL"
grep -q 'Notion' "$SKILL"
! grep -q 'references/jira-task-context.md' "$SKILL"

echo "Provider-aware review checks passed."
