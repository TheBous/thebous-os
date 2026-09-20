#!/usr/bin/env bash
# Self-check for provider-aware release tagging.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="$ROOT_DIR/skills/tag/SKILL.md"

grep -q "Jira or Notion" "$TAG"
grep -q "references/task-context.md" "$TAG"
grep -q "resolve_work_item_ref" "$TAG"
grep -q "notion_set_status" "$TAG"
grep -q "notion_add_comment" "$TAG"
grep -q "provider source" "$TAG"
grep -q "source link" "$TAG"

echo "Provider-aware tag checks passed."
