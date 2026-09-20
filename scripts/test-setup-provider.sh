#!/usr/bin/env bash
# Self-check for independent Jira/Notion setup guidance.
# Run: bash scripts/test-setup-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/setup/SKILL.md"

grep -q 'Jira and Notion can be configured independently' "$SKILL"
grep -q 'If Jira is configured' "$SKILL"
grep -q 'Notion status mapping is handled by the Notion adapter' "$SKILL"
! grep -q 'Leave the values blank to use Jira only' "$SKILL"
! grep -Fq '4. **Transition IDs**' "$SKILL"

echo "Provider-aware setup checks passed."
