#!/usr/bin/env bash
# Work item type detection (Task 2)
# Detects whether the work item is a Jira/Notion task, GitHub PR, or git commit
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/helpers.sh"

# Provider-qualified or recognizable Notion references are resolved by the
# shared task contract so URLs and page IDs produce the same runtime shape.
if [[ "$WORKITEM_ID" == notion:* || "$WORKITEM_ID" == *notion.so* || "$WORKITEM_ID" == *notion.site* || "$WORKITEM_ID" == *ntn-* ]]; then
  TASK_REF_JSON=$(resolve_work_item_ref "$WORKITEM_ID")
  WORKITEM_TYPE=$(jq -r '.provider' <<<"$TASK_REF_JSON")
  RESOLVED_ID=$(jq -r '.external_id' <<<"$TASK_REF_JSON")
  export TASK_REF_JSON WORKITEM_TYPE RESOLVED_ID
  echo "Detected: $WORKITEM_TYPE ($RESOLVED_ID)"
  exit 0
fi

# Regex patterns for detection
if [[ $WORKITEM_ID =~ ^[A-Z]+-[0-9]+$ ]]; then
  WORKITEM_TYPE="jira"
  RESOLVED_ID="$WORKITEM_ID"
elif [[ $WORKITEM_ID =~ ^(PR\ *)?#?[0-9]+$ ]]; then
  WORKITEM_TYPE="github"
  # Normalize: strip "PR" (with optional space) and "#"
  RESOLVED_ID=$(echo "$WORKITEM_ID" | sed 's/^PR *//;s/^#//')
elif [[ $WORKITEM_ID =~ ^[a-f0-9]{7,40}$ ]]; then
  WORKITEM_TYPE="git"
  RESOLVED_ID="$WORKITEM_ID"
else
  echo "ERROR: Unknown work item format: $WORKITEM_ID" >&2
  exit 1
fi

export WORKITEM_TYPE RESOLVED_ID
echo "Detected: $WORKITEM_TYPE ($RESOLVED_ID)"
