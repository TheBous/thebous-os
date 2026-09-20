#!/usr/bin/env bash
# Self-check for provider-aware cook and SDD instructions.
# Run: bash scripts/test-cook-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COOK="$ROOT_DIR/skills/cook/SKILL.md"
PLANNING="$ROOT_DIR/skills/cook-next-planning/SKILL.md"
DEVELOPMENT="$ROOT_DIR/skills/cook-next-development/SKILL.md"

for file in "$COOK" "$PLANNING" "$DEVELOPMENT"; do
  grep -q 'references/task-context.md' "$file"
  grep -q 'TaskRef' "$file"
  grep -q 'provider' "$file"
done

grep -q 'obsidian_task_storage_key' "$COOK"
grep -q 'notion' "$COOK"
grep -q 'provider-aware task directory' "$COOK"
! grep -q 'references/jira-task-context.md' "$PLANNING"
! grep -q 'references/jira-task-context.md' "$DEVELOPMENT"

echo "Provider-aware cook checks passed."
