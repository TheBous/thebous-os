#!/usr/bin/env bash
# Self-check for provider-neutral task creation instructions.
# Run: bash scripts/test-create-task-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/create-task/SKILL.md"
COMMAND="$ROOT_DIR/commands/create-task.md"

grep -q 'Jira or Notion' "$SKILL"
grep -q 'explicit' "$SKILL"
grep -q 'notion_create_task' "$SKILL"
grep -q 'create-jira-task' "$SKILL"
grep -q 'before confirmation' "$SKILL"
grep -q 'skills/create-task/SKILL.md' "$COMMAND"

echo "Provider-neutral task creation checks passed."
