#!/usr/bin/env bash
# Self-check for provider-aware security-review comments.
# Run: bash scripts/test-check-security-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE="$ROOT_DIR/references/check-security.md"

grep -q 'Jira or Notion task' "$REFERENCE"
grep -q 'references/task-context.md' "$REFERENCE"
grep -q 'resolve_work_item_ref' "$REFERENCE"
grep -q 'notion_add_comment' "$REFERENCE"
! grep -q 'If the current branch matches a Jira key' "$REFERENCE"

echo "Provider-aware security-review checks passed."
