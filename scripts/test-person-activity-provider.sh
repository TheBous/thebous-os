#!/usr/bin/env bash
# Self-check for provider-aware person activity instructions.
# Run: bash scripts/test-person-activity-provider.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/person-activity/SKILL.md"
DETECT="$ROOT_DIR/skills/person-activity/scripts/detect-workitem-type.sh"
MAIN="$ROOT_DIR/skills/person-activity/scripts/main.sh"
SYNTHESIZE="$ROOT_DIR/skills/person-activity/scripts/synthesize.sh"
NOTION_ID="6f3b2c1a-1234-4567-89ab-0123456789ab"

grep -q 'Jira or Notion task' "$SKILL"
grep -q 'references/task-context.md' "$SKILL"
grep -q 'resolve_work_item_ref' "$SKILL"
grep -q 'notion_get_page' "$SKILL"
grep -q 'notion_list_activity' "$SKILL"
grep -q 'provider source' "$SKILL"
grep -q 'coverage gap' "$SKILL"
grep -q 'query-notion.sh' "$MAIN"
grep -q 'notion' "$SYNTHESIZE"

DETECTED=$(WORKITEM_ID="notion:$NOTION_ID" bash -c "source '$DETECT'" 2>/dev/null)
grep -q "Detected: notion ($NOTION_ID)" <<<"$DETECTED"

NOTION_DATABASE_ID="11111111-2222-3333-4444-555555555555"
NOTION_USER_ID="cccccccc-dddd-eeee-ffff-000000000000"
export NOTION_API_TOKEN="test-token" NOTION_DATABASE_ID NOTION_USER_ID NOTION_ID

curl() {
  local output_file="" url=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -o) output_file="$2"; shift 2 ;;
      *) url="$1"; shift ;;
    esac
  done
  case "$url" in
    */v1/users*)
      printf '%s' "{\"object\":\"list\",\"has_more\":false,\"results\":[{\"id\":\"$NOTION_USER_ID\",\"type\":\"person\",\"person\":{\"email\":\"marco@example.com\"}}]}" >"$output_file"
      ;;
    */v1/pages/*)
      printf '%s' "{\"object\":\"page\",\"id\":\"$NOTION_ID\",\"url\":\"https://www.notion.so/example/$NOTION_ID\",\"parent\":{\"type\":\"database_id\",\"database_id\":\"$NOTION_DATABASE_ID\"},\"last_edited_time\":\"2026-09-20T09:30:00.000Z\",\"properties\":{\"Name\":{\"type\":\"title\",\"title\":[{\"plain_text\":\"Implement OAuth login\"}]},\"Description\":{\"type\":\"rich_text\",\"rich_text\":[]},\"Status\":{\"type\":\"status\",\"status\":{\"name\":\"In Progress\"}}}}" >"$output_file"
      ;;
    */v1/comments*)
      printf '%s' "{\"object\":\"list\",\"has_more\":false,\"results\":[{\"id\":\"comment-1\",\"created_time\":\"2026-09-20T09:45:00.000Z\",\"last_edited_time\":\"2026-09-20T09:45:00.000Z\",\"created_by\":{\"id\":\"$NOTION_USER_ID\"},\"rich_text\":[{\"plain_text\":\"OAuth login is ready.\"}]}]}" >"$output_file"
      ;;
    *)
      printf '%s' '{}' >"$output_file"
      ;;
  esac
  printf '200'
}
export -f curl

NOTION_ACTIVITY=$(WORKITEM_TYPE=notion WORKITEM_ID="notion:$NOTION_ID" RESOLVED_ID="$NOTION_ID" \
  PERSON_EMAIL=marco@example.com PERSON_NAME_PARTS=marco \
  TASK_REF_JSON="$(printf '{\"provider\":\"notion\",\"external_id\":\"%s\",\"url\":null}' "$NOTION_ID")" \
  bash "$ROOT_DIR/skills/person-activity/scripts/query-notion.sh")
jq -e --arg expected "$NOTION_USER_ID" '.[0].author == $expected' <<<"$NOTION_ACTIVITY" >/dev/null
jq -e '.[0].body == "OAuth login is ready."' <<<"$NOTION_ACTIVITY" >/dev/null

echo "Provider-aware person activity checks passed."
