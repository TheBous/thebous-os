#!/usr/bin/env bash
# Self-check for the provider-neutral task-context reference.
# Run: bash scripts/test-task-context.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT="$ROOT_DIR/references/task-context.md"
JIRA_CONTEXT="$ROOT_DIR/references/jira-task-context.md"
TRANSITION="$ROOT_DIR/references/jira-transition.md"

grep -q 'resolve_work_item_ref' "$CONTEXT"
grep -q 'notion_get_page' "$CONTEXT"
grep -q 'normalized Task' "$CONTEXT"
grep -q 'references/task-context.md' "$JIRA_CONTEXT"
grep -q 'TASK_REQUIREMENTS' "$JIRA_CONTEXT"
grep -q 'Jira-specific' "$TRANSITION"

echo "Provider-neutral task context checks passed."
