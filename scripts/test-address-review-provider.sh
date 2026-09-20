#!/usr/bin/env bash
# Self-check for provider-aware review resolution instructions.
# Run: bash scripts/test-address-review-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/address-review/SKILL.md"

grep -q 'Jira or Notion' "$SKILL"
grep -q 'references/task-context.md' "$SKILL"
grep -q 'resolve_work_item_ref' "$SKILL"
grep -q 'obsidian_log_task' "$SKILL"
grep -q 'provider-neutral task reference' "$SKILL"
! grep -q "Only if the PR's branch matched a Jira key" "$SKILL"

echo "Provider-aware address-review checks passed."
