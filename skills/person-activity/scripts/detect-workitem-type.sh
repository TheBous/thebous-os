#!/usr/bin/env bash
# Work item type detection (Task 2)
# Detects whether the work item is a Jira task, GitHub PR, or git commit
set -euo pipefail

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
