#!/usr/bin/env bash
# Self-check for the Notion read-only adapter.
# Run: bash scripts/test-notion-adapter.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/notion.sh"
set +e

FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $desc — expected '$expected', got '$actual'"
    FAIL=1
  else
    echo "PASS: $desc"
  fi
}

assert_error() {
  local desc="$1" expected="$2" output="$3" status="$4"
  if [ "$status" -eq 0 ]; then
    echo "FAIL: $desc — expected failure"
    FAIL=1
  elif ! grep -q "$expected" <<<"$output"; then
    echo "FAIL: $desc — expected '$expected', got '$output'"
    FAIL=1
  else
    echo "PASS: $desc"
  fi
}

unset NOTION_API_TOKEN NOTION_DATABASE_ID NOTION_API_VERSION NOTION_DATA_SOURCE_ID

CONFIG_OUTPUT=$(notion_config_validate 2>&1)
CONFIG_STATUS=$?
assert_error "missing Notion configuration" "AUTH_REQUIRED" "$CONFIG_OUTPUT" "$CONFIG_STATUS"

NOTION_API_TOKEN="test-token"
NOTION_DATABASE_ID="11111111-2222-3333-4444-555555555555"

NOTION_DATABASE_ID="not-a-notion-id"
OUTPUT=$(notion_config_validate 2>&1)
STATUS=$?
assert_error "malformed Notion database ID" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"
NOTION_DATABASE_ID="11111111-2222-3333-4444-555555555555"

PAGE_JSON='{
  "object": "page",
  "id": "6f3b2c1a-1234-4567-89ab-0123456789ab",
  "url": "https://www.notion.so/example/Implement-OAuth-6f3b2c1a1234456789ab0123456789ab",
  "parent": {"type": "database_id", "database_id": "11111111-2222-3333-4444-555555555555"},
  "last_edited_time": "2026-09-20T09:30:00.000Z",
  "properties": {
    "Name": {
      "type": "title",
      "title": [{"type": "text", "plain_text": "Implement OAuth login"}]
    },
    "Description": {
      "type": "rich_text",
      "rich_text": [{"type": "text", "plain_text": "Implement the login flow."}]
    },
    "Status": {
      "type": "status",
      "status": {"name": "In Progress"}
    },
    "Assignee": {
      "type": "people",
      "people": [{"name": "Marco Rossi", "person": {"email": "marco@example.com"}}]
    },
    "Due date": {
      "type": "date",
      "date": {"start": "2026-10-01"}
    },
    "Start date": {
      "type": "date",
      "date": {"start": "2026-09-20"}
    }
  }
}'

TASK=$(notion_normalize_page "$PAGE_JSON" "$NOTION_DATABASE_ID")
TASK_STATUS=$?
if [ "$TASK_STATUS" -ne 0 ]; then
  echo "FAIL: valid Notion page should normalize"
  FAIL=1
else
  assert_eq "normalized provider" "notion" "$(jq -r '.ref.provider' <<<"$TASK")"
  assert_eq "normalized external ID" "6f3b2c1a-1234-4567-89ab-0123456789ab" "$(jq -r '.ref.external_id' <<<"$TASK")"
  assert_eq "normalized title" "Implement OAuth login" "$(jq -r '.title' <<<"$TASK")"
  assert_eq "normalized description" "Implement the login flow." "$(jq -r '.description' <<<"$TASK")"
  assert_eq "normalized status" "in_progress" "$(jq -r '.status' <<<"$TASK")"
  assert_eq "normalized assignee" "marco@example.com" "$(jq -r '.assignee' <<<"$TASK")"
  assert_eq "normalized due date" "2026-10-01" "$(jq -r '.due_at' <<<"$TASK")"
  assert_eq "normalized start date" "2026-09-20" "$(jq -r '.start_at' <<<"$TASK")"
  assert_eq "normalized updated date" "2026-09-20T09:30:00.000Z" "$(jq -r '.updated_at' <<<"$TASK")"
  assert_eq "raw Notion properties are hidden" "false" "$(jq -r 'has("properties")' <<<"$TASK")"
fi

MISSING_DESCRIPTION=$(jq 'del(.properties.Description)' <<<"$PAGE_JSON")
OUTPUT=$(notion_normalize_page "$MISSING_DESCRIPTION" "$NOTION_DATABASE_ID" 2>&1)
STATUS=$?
assert_error "missing required Description property" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"

WRONG_PARENT=$(jq '.parent.database_id = "99999999-8888-7777-6666-555555555555"' <<<"$PAGE_JSON")
OUTPUT=$(notion_normalize_page "$WRONG_PARENT" "$NOTION_DATABASE_ID" 2>&1)
STATUS=$?
assert_error "page from another database" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"

WRONG_DATA_SOURCE=$(jq '.parent.data_source_id = "bbbbbbbb-cccc-dddd-eeee-ffffffffffff"' <<<"$PAGE_JSON")
OUTPUT=$(notion_normalize_page "$WRONG_DATA_SOURCE" "$NOTION_DATABASE_ID" "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" 2>&1)
STATUS=$?
assert_error "page from another data source" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"

curl() {
  local output_file=""
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "-o" ]; then
      output_file="$2"
      shift 2
    else
      shift
    fi
  done
  printf '%s' '{"message":"fixture error"}' >"$output_file"
  printf '%s' "${FIXTURE_HTTP_STATUS:-401}"
}

FIXTURE_HTTP_STATUS=401
OUTPUT=$(notion_get_page "6f3b2c1a-1234-4567-89ab-0123456789ab" 2>&1)
STATUS=$?
assert_error "Notion auth error" "AUTH_REQUIRED" "$OUTPUT" "$STATUS"

FIXTURE_HTTP_STATUS=429
OUTPUT=$(notion_get_page "6f3b2c1a-1234-4567-89ab-0123456789ab" 2>&1)
STATUS=$?
assert_error "Notion rate limit error" "PROVIDER_UNAVAILABLE" "$OUTPUT" "$STATUS"

unset -f curl

FIXTURE_HTTP_STATUS=200
FIXTURE_CALLS=0
FIXTURE_METHOD=""
FIXTURE_REQUEST_BODY=""
FIXTURE_MODE=""
FIXTURE_LOG=$(mktemp)
FIXTURE_METHOD_FILE=$(mktemp)
FIXTURE_BODY_FILE=$(mktemp)
FIXTURE_URL_FILE=$(mktemp)
trap 'rm -f "$FIXTURE_LOG" "$FIXTURE_METHOD_FILE" "$FIXTURE_BODY_FILE" "$FIXTURE_URL_FILE"' EXIT
UPDATED_PAGE_JSON=$(jq '.properties.Status.status.name = "Done" | .last_edited_time = "2026-09-20T10:00:00.000Z"' <<<"$PAGE_JSON")
DATABASE_RESPONSE=$(jq -n --arg id "$NOTION_DATABASE_ID" '{object:"database",id:$id,data_sources:[{id:"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"}]}')
USERS_RESPONSE=$(jq -n '{object:"list",has_more:false,next_cursor:null,results:[{object:"user",id:"cccccccc-dddd-eeee-ffff-000000000000",type:"person",person:{email:"marco@example.com"}}]}')
QUERY_RESPONSE=$(jq -n --argjson page "$PAGE_JSON" '{object:"list",has_more:true,next_cursor:"cursor-2",results:[$page]}')
MALFORMED_QUERY_RESPONSE=$(jq -n --argjson page "$PAGE_JSON" '{object:"list",has_more:false,next_cursor:null,results:[{object:"page",id:"not-a-page"},$page]}')
ACTIVITY_QUERY_RESPONSE=$(jq -n --argjson page "$PAGE_JSON" '{object:"list",has_more:false,next_cursor:null,results:[$page]}')
COMMENTS_RESPONSE=$(jq -n --arg page_id "6f3b2c1a-1234-4567-89ab-0123456789ab" '{object:"list",has_more:false,next_cursor:null,results:[{object:"comment",id:"comment-activity",parent:{type:"page_id",page_id:$page_id},created_time:"2026-09-20T09:45:00.000Z",last_edited_time:"2026-09-20T09:45:00.000Z",created_by:{id:"cccccccc-dddd-eeee-ffff-000000000000"},rich_text:[{plain_text:"OAuth login is ready."}]}]}')

curl() {
  local output_file="" method="GET" body="" url=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -o) output_file="$2"; shift 2 ;;
      -X) method="$2"; shift 2 ;;
      --data|-d) body="$2"; shift 2 ;;
      -w|-H) shift 2 ;;
      *) url="$1"; shift ;;
    esac
  done
  printf '%s\n' "$method" >>"$FIXTURE_LOG"
  printf '%s' "$method" >"$FIXTURE_METHOD_FILE"
  printf '%s' "$body" >"$FIXTURE_BODY_FILE"
  printf '%s' "$url" >"$FIXTURE_URL_FILE"
  if [ "$FIXTURE_MODE" = "list" ] && [ "$method" = "GET" ] && [[ "$url" = *"/v1/users"* ]]; then
    printf '%s' "$USERS_RESPONSE" >"$output_file"
  elif [ "$FIXTURE_MODE" = "activity" ] && [ "$method" = "GET" ] && [[ "$url" = *"/v1/comments"* ]]; then
    printf '%s' "$COMMENTS_RESPONSE" >"$output_file"
  elif [ "$FIXTURE_MODE" = "activity" ] && [ "$method" = "GET" ]; then
    printf '%s' "$DATABASE_RESPONSE" >"$output_file"
  elif { [ "$FIXTURE_MODE" = "list" ] || [ "$FIXTURE_MODE" = "malformed-list" ]; } && [ "$method" = "GET" ]; then
    printf '%s' "$DATABASE_RESPONSE" >"$output_file"
  elif [ "$FIXTURE_MODE" = "list" ] && [ "$method" = "POST" ]; then
    printf '%s' "$QUERY_RESPONSE" >"$output_file"
  elif [ "$FIXTURE_MODE" = "malformed-list" ] && [ "$method" = "POST" ]; then
    printf '%s' "$MALFORMED_QUERY_RESPONSE" >"$output_file"
  elif [ "$FIXTURE_MODE" = "activity" ] && [ "$method" = "POST" ]; then
    printf '%s' "$ACTIVITY_QUERY_RESPONSE" >"$output_file"
  elif [ "$FIXTURE_MODE" = "multi-list" ] && [ "$method" = "GET" ]; then
    printf '%s' "$(jq '.data_sources += [{id:\"bbbbbbbb-cccc-dddd-eeee-ffffffffffff\"}]' <<<"$DATABASE_RESPONSE")" >"$output_file"
  elif [ "$FIXTURE_MODE" = "multi-list" ] && [ "$method" = "POST" ]; then
    printf '%s' "$QUERY_RESPONSE" >"$output_file"
  elif [ "$method" = "GET" ]; then
    printf '%s' "$PAGE_JSON" >"$output_file"
  elif [ "$method" = "PATCH" ]; then
    printf '%s' "$UPDATED_PAGE_JSON" >"$output_file"
  elif [ "$FIXTURE_MODE" = "create" ]; then
    printf '%s' "$PAGE_JSON" >"$output_file"
  else
    printf '%s' '{"object":"comment","id":"comment-123","created_time":"2026-09-20T10:05:00.000Z"}' >"$output_file"
  fi
  printf '%s' "$FIXTURE_HTTP_STATUS"
}

FIXTURE_HTTP_STATUS=200
FIXTURE_MODE=list
: >"$FIXTURE_LOG"
LIST_PAGE=$(notion_list_tasks '{"status":"in_progress","cursor":"cursor-1","limit":25,"due_from":"2026-09-20","due_to":"2026-10-01","start_from":"2026-09-20","updated_from":"2026-09-20T00:00:00Z"}')
FIXTURE_CALLS=$(wc -l <"$FIXTURE_LOG" | tr -d ' ')
FIXTURE_METHOD=$(<"$FIXTURE_METHOD_FILE")
FIXTURE_REQUEST_BODY=$(<"$FIXTURE_BODY_FILE")
FIXTURE_URL=$(<"$FIXTURE_URL_FILE")
assert_eq "list resolves data source and queries once" "2" "$FIXTURE_CALLS"
assert_eq "list uses data source endpoint" "https://api.notion.com/v1/data_sources/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/query" "$FIXTURE_URL"
assert_eq "list uses POST" "POST" "$FIXTURE_METHOD"
assert_eq "list forwards page size" "25" "$(jq -r '.page_size' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "list forwards cursor" "cursor-1" "$(jq -r '.start_cursor' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "list maps canonical status" "In progress" "$(jq -r '.filter.and[0].status.equals' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "list maps due range" "2026-10-01" "$(jq -r '.filter.and[2].date.on_or_before' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "list maps start range" "2026-09-20" "$(jq -r '.filter.and[3].date.on_or_after' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "list maps updated range" "2026-09-20T00:00:00Z" "$(jq -r '.filter.and[4].last_edited_time.on_or_after' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "list normalizes task" "Implement OAuth login" "$(jq -r '.items[0].title' <<<"$LIST_PAGE")"
assert_eq "list preserves pagination" "cursor-2" "$(jq -r '.next_cursor' <<<"$LIST_PAGE")"

ASSIGNEE_LIST=$(notion_list_tasks '{"assignee":"marco@example.com","limit":25}')
ASSIGNEE_REQUEST_BODY=$(<"$FIXTURE_BODY_FILE")
assert_eq "list resolves assignee email" "cccccccc-dddd-eeee-ffff-000000000000" "$(jq -r '.filter.people.contains' <<<"$ASSIGNEE_REQUEST_BODY")"
assert_eq "assignee list still returns tasks" "Implement OAuth login" "$(jq -r '.items[0].title' <<<"$ASSIGNEE_LIST")"

OUTPUT=$(notion_list_tasks '{"assignee":"nobody@example.com"}' 2>&1)
STATUS=$?
assert_error "unknown assignee is reported" "NOT_FOUND" "$OUTPUT" "$STATUS"

FIXTURE_MODE=multi-list
: >"$FIXTURE_LOG"
OUTPUT=$(notion_list_tasks '{}' 2>&1)
STATUS=$?
FIXTURE_CALLS=$(wc -l <"$FIXTURE_LOG" | tr -d ' ')
assert_error "multiple data sources require explicit selection" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"
assert_eq "multiple data sources stop before query" "1" "$FIXTURE_CALLS"

NOTION_DATA_SOURCE_ID="bbbbbbbb-cccc-dddd-eeee-ffffffffffff"
: >"$FIXTURE_LOG"
EXPLICIT_LIST=$(notion_list_tasks '{}')
assert_eq "explicit data source skips database lookup" "1" "$(wc -l <"$FIXTURE_LOG" | tr -d ' ')"
assert_eq "explicit data source is queried" "https://api.notion.com/v1/data_sources/bbbbbbbb-cccc-dddd-eeee-ffffffffffff/query" "$(<"$FIXTURE_URL_FILE")"
assert_eq "explicit data source returns tasks" "Implement OAuth login" "$(jq -r '.items[0].title' <<<"$EXPLICIT_LIST")"
unset NOTION_DATA_SOURCE_ID

FIXTURE_MODE=list
: >"$FIXTURE_LOG"
OUTPUT=$(notion_list_tasks '{"status":"blocked"}' 2>&1)
STATUS=$?
assert_error "unknown canonical status is rejected" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"
assert_eq "invalid status makes no request" "0" "$(wc -l <"$FIXTURE_LOG" | tr -d ' ')"

OUTPUT=$(notion_list_tasks '{"assignee":123}' 2>&1)
STATUS=$?
assert_error "invalid assignee filter is explicit" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"

FIXTURE_MODE=malformed-list
OUTPUT=$(notion_list_tasks '{}' 2>&1)
STATUS=$?
assert_error "malformed task page is rejected" "VALIDATION_ERROR" "$OUTPUT" "$STATUS"

FIXTURE_MODE=activity
ACTIVITY=$(notion_list_activity '{"from":"2026-09-20T00:00:00.000Z","to":"2026-09-20T23:59:59.000Z","limit":20}')
assert_eq "activity includes page update" "1" "$(jq '[.items[] | select(.kind == "updated")] | length' <<<"$ACTIVITY")"
assert_eq "activity includes comment" "1" "$(jq '[.items[] | select(.kind == "commented")] | length' <<<"$ACTIVITY")"
assert_eq "activity normalizes task ref" "6f3b2c1a-1234-4567-89ab-0123456789ab" "$(jq -r '.items[0].ref.external_id' <<<"$ACTIVITY")"
assert_eq "activity preserves comment summary" "OAuth login is ready." "$(jq -r '.items[] | select(.kind == "commented") | .summary' <<<"$ACTIVITY")"
assert_eq "activity has no next cursor" "null" "$(jq -r '.next_cursor' <<<"$ACTIVITY")"

: >"$FIXTURE_LOG"
FIXTURE_MODE=create
CREATE_DESCRIPTION=$'## Descrizione\n\nImplementare il lavoro.\n\n## Acceptance Criteria\n\n[ ] Verificare il risultato.'
CREATED_TASK=$(notion_create_task "Nuovo task" "$CREATE_DESCRIPTION")
FIXTURE_CALLS=$(wc -l <"$FIXTURE_LOG" | tr -d ' ')
FIXTURE_METHOD=$(<"$FIXTURE_METHOD_FILE")
FIXTURE_REQUEST_BODY=$(<"$FIXTURE_BODY_FILE")
assert_eq "created task provider" "notion" "$(jq -r '.ref.provider' <<<"$CREATED_TASK")"
assert_eq "create uses POST" "POST" "$FIXTURE_METHOD"
assert_eq "create targets configured database" "$NOTION_DATABASE_ID" "$(jq -r '.parent.database_id' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "create preserves Italian description" "$CREATE_DESCRIPTION" "$(jq -r '.properties.Description.rich_text[0].text.content' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "status map todo" "Not started" "$(notion_status_name todo)"
assert_eq "status map in progress" "In progress" "$(notion_status_name in_progress)"
assert_eq "status map in review" "In review" "$(notion_status_name in_review)"
assert_eq "status map in staging" "In staging" "$(notion_status_name in_staging)"
assert_eq "status map done" "Complete" "$(notion_status_name done)"

FIXTURE_CALLS=0
: >"$FIXTURE_LOG"
FIXTURE_MODE=update
UPDATED_TASK=$(notion_set_status "6f3b2c1a-1234-4567-89ab-0123456789ab" "todo")
FIXTURE_CALLS=$(wc -l <"$FIXTURE_LOG" | tr -d ' ')
FIXTURE_METHOD=$(<"$FIXTURE_METHOD_FILE")
FIXTURE_REQUEST_BODY=$(<"$FIXTURE_BODY_FILE")
assert_eq "status update makes one read and one write" "2" "$FIXTURE_CALLS"
assert_eq "status update uses PATCH" "PATCH" "$FIXTURE_METHOD"
assert_eq "status update maps todo" "Not started" "$(jq -r '.properties.Status.status.name' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "status update returns normalized task" "done" "$(jq -r '.status' <<<"$UPDATED_TASK")"

FIXTURE_CALLS=0
: >"$FIXTURE_LOG"
FIXTURE_MODE=update
IDEMPOTENT_TASK=$(notion_set_status "6f3b2c1a-1234-4567-89ab-0123456789ab" "in_progress")
FIXTURE_CALLS=$(wc -l <"$FIXTURE_LOG" | tr -d ' ')
assert_eq "same status is idempotent" "1" "$FIXTURE_CALLS"
assert_eq "idempotent status" "in_progress" "$(jq -r '.status' <<<"$IDEMPOTENT_TASK")"

FIXTURE_CALLS=0
: >"$FIXTURE_LOG"
FIXTURE_MODE=comment
RECEIPT=$(notion_add_comment "6f3b2c1a-1234-4567-89ab-0123456789ab" "Commento di test")
FIXTURE_CALLS=$(wc -l <"$FIXTURE_LOG" | tr -d ' ')
FIXTURE_METHOD=$(<"$FIXTURE_METHOD_FILE")
FIXTURE_REQUEST_BODY=$(<"$FIXTURE_BODY_FILE")
assert_eq "comment uses POST" "POST" "$FIXTURE_METHOD"
assert_eq "comment body" "Commento di test" "$(jq -r '.rich_text[0].text.content' <<<"$FIXTURE_REQUEST_BODY")"
assert_eq "comment receipt ID" "comment-123" "$(jq -r '.external_id' <<<"$RECEIPT")"
assert_eq "comment receipt timestamp" "2026-09-20T10:05:00.000Z" "$(jq -r '.created_at' <<<"$RECEIPT")"

FIXTURE_HTTP_STATUS=504
: >"$FIXTURE_LOG"
OUTPUT=$(notion_add_comment "6f3b2c1a-1234-4567-89ab-0123456789ab" "timeout" 2>&1)
STATUS=$?
FIXTURE_CALLS=$(wc -l <"$FIXTURE_LOG" | tr -d ' ')
assert_error "comment timeout is not retried" "PROVIDER_UNAVAILABLE" "$OUTPUT" "$STATUS"
assert_eq "comment timeout makes one request" "1" "$FIXTURE_CALLS"

if [ "$FAIL" -eq 0 ]; then
  echo "All Notion adapter checks passed."
  exit 0
else
  echo "Some Notion adapter checks FAILED."
  exit 1
fi
