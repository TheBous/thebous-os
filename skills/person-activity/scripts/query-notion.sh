#!/usr/bin/env bash
# Notion activity query for a selected task and person.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/helpers.sh"
load_env
# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/notion.sh"

: "${WORKITEM_TYPE:?WORKITEM_TYPE not set}"
: "${WORKITEM_ID:?WORKITEM_ID not set}"
: "${PERSON_EMAIL:?PERSON_EMAIL not set}"
: "${PERSON_NAME_PARTS:?PERSON_NAME_PARTS not set}"

if [ "$WORKITEM_TYPE" != "notion" ]; then
  echo "[]"
  exit 0
fi

TASK_REF_JSON="${TASK_REF_JSON:-$(resolve_work_item_ref "notion:$RESOLVED_ID")}"
NOTION_PERSON_ID=""
if [ -n "$PERSON_EMAIL" ]; then
  NOTION_PERSON_ID=$(notion_user_id_by_email "$PERSON_EMAIL" 2>/dev/null || true)
fi

FILTERS=$(jq -n \
  --arg from "1970-01-01T00:00:00.000Z" \
  --arg to "$(date -u '+%Y-%m-%dT%H:%M:%S.000Z')" \
  --argjson ref "$TASK_REF_JSON" \
  '{from:$from,to:$to,refs:[$ref],limit:100}')

ACTIVITY=$(notion_list_activity "$FILTERS")
jq \
  --arg email "$PERSON_EMAIL" \
  --arg names "$PERSON_NAME_PARTS" \
  --arg notion_id "$NOTION_PERSON_ID" \
  '[
    .items[]
    | (.actor // "") as $actor
    | select(
        ($notion_id != "" and $actor == $notion_id)
        or ($actor != "" and (($actor | ascii_downcase | gsub("[._-]"; " ")) | contains(($names | ascii_downcase))))
        or ($email != "" and ($actor | ascii_downcase) == ($email | ascii_downcase))
      )
    | {timestamp:.at, author:(.actor // "Unknown"), body:.summary, url:.url, kind:.kind}
  ]' <<<"$ACTIVITY"
