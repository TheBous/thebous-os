#!/usr/bin/env bash
# Self-check for provider-aware PR workflows.
# Run: bash scripts/test-pr-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CREATE="$ROOT_DIR/skills/create-pr/SKILL.md"
MERGE="$ROOT_DIR/skills/merge-pr/SKILL.md"

grep -q 'references/task-context.md' "$CREATE"
grep -q 'references/task-context.md' "$MERGE"
grep -q 'resolve_work_item_ref' "$MERGE"
grep -q 'notion_add_comment' "$CREATE"
grep -q 'notion_set_status' "$CREATE"
grep -q 'notion_add_comment' "$MERGE"
grep -q 'notion_set_status' "$MERGE"
grep -q 'provider calls' "$CREATE"
grep -q 'provider calls' "$MERGE"
grep -q 'obsidian_log_pr_task' "$CREATE"

echo "Provider-aware PR workflow checks passed."
