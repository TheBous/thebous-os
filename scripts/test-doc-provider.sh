#!/usr/bin/env bash
# Self-check for provider-aware documentation workflows.
# Run: bash scripts/test-doc-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for skill in create-doc update-doc; do
  FILE="$ROOT_DIR/skills/$skill/SKILL.md"
  grep -q 'Jira or Notion' "$FILE"
  grep -q 'references/task-context.md' "$FILE"
  grep -q 'resolve_work_item_ref' "$FILE"
  grep -q 'obsidian_log_task' "$FILE"
  ! grep -q 'extract_jira_key' "$FILE"
done

echo "Provider-aware documentation checks passed."
