#!/usr/bin/env bash
# Notion adapter for thebous-os task provider contract.
# Source this file; do not execute it directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

NOTION_API_BASE_URL="${NOTION_API_BASE_URL:-https://api.notion.com}"
NOTION_API_VERSION="${NOTION_API_VERSION:-2026-03-11}"

notion_config_validate() {
  if [ -z "${NOTION_API_TOKEN:-}" ] || [ -z "${NOTION_DATABASE_ID:-}" ]; then
    echo "ERROR: AUTH_REQUIRED: configure NOTION_API_TOKEN and NOTION_DATABASE_ID" >&2
    return 2
  fi
  if ! format_notion_page_id "$NOTION_DATABASE_ID" >/dev/null 2>&1; then
    echo "ERROR: VALIDATION_ERROR: NOTION_DATABASE_ID must be a valid Notion ID" >&2
    return 2
  fi
}

notion_status() {
  local value
  value=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$value" in
    "to do"|todo|"not started"|open) echo "todo" ;;
    "in progress"|started) echo "in_progress" ;;
    "in review"|review) echo "in_review" ;;
    "in staging"|staging) echo "in_staging" ;;
    done|completed|complete) echo "done" ;;
    *) echo "unknown" ;;
  esac
}

notion_normalize_page() {
  local page_json="${1:-}"
  local expected_database="${2:-${NOTION_DATABASE_ID:-}}"
  local page_id page_url title description raw_status status assignee due_at start_at updated_at parent_id
  local normalized_id normalized_parent normalized_expected

  if ! jq -e '
    .object == "page" and
    (.id | type == "string") and
    (.properties.Name.type == "title") and
    (.properties.Description.type == "rich_text") and
    ((.properties.Status.type == "status") or (.properties.Status.type == "select")) and
    ((.properties.Assignee == null) or (.properties.Assignee.type == "people")) and
    ((.properties["Due date"] == null) or (.properties["Due date"].type == "date")) and
    ((.properties["Start date"] == null) or (.properties["Start date"].type == "date"))
  ' <<<"$page_json" >/dev/null 2>&1; then
    echo "ERROR: VALIDATION_ERROR: Notion page does not match the configured task schema" >&2
    return 2
  fi

  page_id=$(jq -r '.id' <<<"$page_json")
  normalized_id=$(format_notion_page_id "$page_id" 2>/dev/null || true)
  if [ -z "$normalized_id" ]; then
    echo "ERROR: VALIDATION_ERROR: Notion page ID is invalid" >&2
    return 2
  fi

  if [ -n "$expected_database" ]; then
    parent_id=$(jq -r '.parent.database_id // .parent.data_source_id // empty' <<<"$page_json")
    normalized_parent=$(format_notion_page_id "$parent_id" 2>/dev/null || true)
    normalized_expected=$(format_notion_page_id "$expected_database" 2>/dev/null || true)
    if [ -z "$normalized_expected" ] || [ "$normalized_parent" != "$normalized_expected" ]; then
      echo "ERROR: VALIDATION_ERROR: Notion page is outside the configured database" >&2
      return 2
    fi
  fi

  page_url=$(jq -r '.url // empty' <<<"$page_json")
  title=$(jq -r '
    .properties.Name.title
    | map(.plain_text // .text.content // "")
    | join("")
  ' <<<"$page_json")
  description=$(jq -r '
    .properties.Description.rich_text
    | map(.plain_text // .text.content // "")
    | join("")
  ' <<<"$page_json")
  raw_status=$(jq -r '.properties.Status.status.name // .properties.Status.select.name // empty' <<<"$page_json")
  status=$(notion_status "$raw_status")
  assignee=$(jq -r '.properties.Assignee.people[0].person.email // .properties.Assignee.people[0].name // empty' <<<"$page_json")
  due_at=$(jq -r '.properties["Due date"].date.start // empty' <<<"$page_json")
  start_at=$(jq -r '.properties["Start date"].date.start // empty' <<<"$page_json")
  updated_at=$(jq -r '.last_edited_time // empty' <<<"$page_json")

  jq -n \
    --arg id "$normalized_id" \
    --arg url "$page_url" \
    --arg title "$title" \
    --arg description "$description" \
    --arg status "$status" \
    --arg assignee "$assignee" \
    --arg due_at "$due_at" \
    --arg start_at "$start_at" \
    --arg updated_at "$updated_at" \
    '{
      ref: {
        provider: "notion",
        external_id: $id,
        url: (if $url == "" then null else $url end)
      },
      title: $title,
      description: $description,
      status: $status,
      assignee: (if $assignee == "" then null else $assignee end),
      due_at: (if $due_at == "" then null else $due_at end),
      start_at: (if $start_at == "" then null else $start_at end),
      updated_at: (if $updated_at == "" then null else $updated_at end)
    }'
}

notion_api_request() {
  local method="$1" path="$2" body="${3:-}"
  local response_file response http_status curl_status
  local api_base="${NOTION_API_BASE_URL:-https://api.notion.com}"

  response_file=$(mktemp)
  if [ -n "$body" ]; then
    if http_status=$(curl -sS \
      -o "$response_file" \
      -w '%{http_code}' \
      --connect-timeout 10 \
      --max-time 30 \
      -H "Authorization: Bearer $NOTION_API_TOKEN" \
      -H "Notion-Version: ${NOTION_API_VERSION:-2026-03-11}" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -X "$method" \
      --data "$body" \
      "$api_base$path" 2>/dev/null); then
      curl_status=0
    else
      curl_status=$?
    fi
  else
    if http_status=$(curl -sS \
      -o "$response_file" \
      -w '%{http_code}' \
      --connect-timeout 10 \
      --max-time 30 \
      -H "Authorization: Bearer $NOTION_API_TOKEN" \
      -H "Notion-Version: ${NOTION_API_VERSION:-2026-03-11}" \
      -H "Accept: application/json" \
      -X "$method" \
      "$api_base$path" 2>/dev/null); then
      curl_status=0
    else
      curl_status=$?
    fi
  fi
  response=$(<"$response_file")
  rm -f "$response_file"

  if [ "$curl_status" -ne 0 ] || [ -z "$http_status" ]; then
    echo "ERROR: PROVIDER_UNAVAILABLE: Notion request failed" >&2
    return 2
  fi

  case "$http_status" in
    200|201|202) printf '%s' "$response" ;;
    401|403)
      echo "ERROR: AUTH_REQUIRED: Notion rejected the connection" >&2
      return 2
      ;;
    404)
      echo "ERROR: NOT_FOUND: Notion resource was not found or is not shared" >&2
      return 2
      ;;
    409)
      echo "ERROR: CONFLICT: Notion rejected the write because the resource changed" >&2
      return 2
      ;;
    429|5??|529)
      echo "ERROR: PROVIDER_UNAVAILABLE: Notion service is temporarily unavailable" >&2
      return 2
      ;;
    *)
      echo "ERROR: VALIDATION_ERROR: Notion rejected the request" >&2
      return 2
      ;;
  esac
}

notion_get_page() {
  local page_id="$1" normalized_id response

  notion_config_validate
  normalized_id=$(format_notion_page_id "$page_id" 2>/dev/null || true)
  if [ -z "$normalized_id" ]; then
    echo "ERROR: INVALID_REFERENCE: invalid Notion page ID" >&2
    return 2
  fi

  response=$(notion_api_request GET "/v1/pages/$normalized_id")
  notion_normalize_page "$response" "$NOTION_DATABASE_ID"
}

notion_status_name() {
  case "$1" in
    todo) echo "Not started" ;;
    in_progress) echo "In progress" ;;
    in_review) echo "In review" ;;
    in_staging) echo "In staging" ;;
    done) echo "Complete" ;;
    *)
      echo "ERROR: VALIDATION_ERROR: unsupported canonical Notion status" >&2
      return 2
      ;;
  esac
}

notion_create_task() {
  local title="${1:-}" description="${2:-}" database_id="${3:-${NOTION_DATABASE_ID:-}}"
  local normalized_database payload response

  notion_config_validate
  if [ -z "$title" ] || [ -z "$description" ]; then
    echo "ERROR: VALIDATION_ERROR: Notion task title and description are required" >&2
    return 2
  fi
  normalized_database=$(format_notion_page_id "$database_id" 2>/dev/null || true)
  if [ -z "$normalized_database" ]; then
    echo "ERROR: VALIDATION_ERROR: Notion database ID is invalid" >&2
    return 2
  fi

  payload=$(jq -n \
    --arg database_id "$normalized_database" \
    --arg title "$title" \
    --arg description "$description" \
    '{
      parent: {database_id: $database_id},
      properties: {
        Name: {title: [{text: {content: $title}}]},
        Description: {rich_text: [{text: {content: $description}}]},
        Status: {status: {name: "Not started"}}
      }
    }')
  response=$(notion_api_request POST "/v1/pages" "$payload")
  notion_normalize_page "$response" "$normalized_database"
}

notion_set_status() {
  local page_id="$1" canonical_status="$2"
  local normalized_id raw_page current_status property_type provider_status payload response

  notion_config_validate
  normalized_id=$(format_notion_page_id "$page_id" 2>/dev/null || true)
  if [ -z "$normalized_id" ]; then
    echo "ERROR: INVALID_REFERENCE: invalid Notion page ID" >&2
    return 2
  fi
  provider_status=$(notion_status_name "$canonical_status")
  raw_page=$(notion_api_request GET "/v1/pages/$normalized_id")
  current_status=$(notion_normalize_page "$raw_page" "$NOTION_DATABASE_ID")
  if [ "$(jq -r '.status' <<<"$current_status")" = "$canonical_status" ]; then
    printf '%s' "$current_status"
    return 0
  fi

  property_type=$(jq -r '.properties.Status.type // empty' <<<"$raw_page")
  case "$property_type" in
    status)
      payload=$(jq -n --arg name "$provider_status" '{properties:{Status:{status:{name:$name}}}}')
      ;;
    select)
      payload=$(jq -n --arg name "$provider_status" '{properties:{Status:{select:{name:$name}}}}')
      ;;
    *)
      echo "ERROR: VALIDATION_ERROR: Notion Status property type is unsupported" >&2
      return 2
      ;;
  esac

  response=$(notion_api_request PATCH "/v1/pages/$normalized_id" "$payload")
  notion_normalize_page "$response" "$NOTION_DATABASE_ID"
}

notion_add_comment() {
  local page_id="$1" body="${2:-}"
  local normalized_id payload response comment_id created_at

  notion_config_validate
  normalized_id=$(format_notion_page_id "$page_id" 2>/dev/null || true)
  if [ -z "$normalized_id" ]; then
    echo "ERROR: INVALID_REFERENCE: invalid Notion page ID" >&2
    return 2
  fi
  if [ -z "$body" ]; then
    echo "ERROR: VALIDATION_ERROR: comment body is required" >&2
    return 2
  fi

  payload=$(jq -n \
    --arg page_id "$normalized_id" \
    --arg body "$body" \
    '{parent:{page_id:$page_id},rich_text:[{text:{content:$body}}]}')
  response=$(notion_api_request POST "/v1/comments" "$payload")
  if ! jq -e '(.id | type == "string") and (.created_time | type == "string")' <<<"$response" >/dev/null 2>&1; then
    echo "ERROR: VALIDATION_ERROR: Notion comment response is malformed" >&2
    return 2
  fi
  comment_id=$(jq -r '.id' <<<"$response")
  created_at=$(jq -r '.created_time' <<<"$response")
  jq -n \
    --arg page_id "$normalized_id" \
    --arg comment_id "$comment_id" \
    --arg created_at "$created_at" \
    '{
      ref: {provider: "notion", external_id: $page_id, url: null},
      external_id: $comment_id,
      url: null,
      created_at: $created_at
    }'
}
