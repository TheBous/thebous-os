#!/usr/bin/env bash
# Self-check for provider-aware jira-git-sync routing.
# Run: bash scripts/test-jira-git-sync-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/jira-git-sync/SKILL.md"

grep -q 'Git → Jira/Notion' "$SKILL"
grep -q 'Jira/Notion/Git/Slack/Confluence' "$SKILL"
grep -q 'Jira or Notion task' "$SKILL"
grep -q 'skills/create-task/SKILL.md' "$SKILL"
grep -q 'references/task-provider.md' "$SKILL"
! grep -q 'start a task from a Jira ticket' "$SKILL"

echo "Provider-aware jira-git-sync checks passed."
