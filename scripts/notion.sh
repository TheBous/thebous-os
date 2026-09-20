#!/usr/bin/env bash
# Read-only Notion adapter for thebous-os task provider contract.
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

notion_get_page() {
  local page_id="$1"
  local normalized_id response_file response http_status curl_status

  notion_config_validate
  normalized_id=$(format_notion_page_id "$page_id" 2>/dev/null || true)
  if [ -z "$normalized_id" ]; then
    echo "ERROR: INVALID_REFERENCE: invalid Notion page ID" >&2
    return 2
  fi

  response_file=$(mktemp)
  if http_status=$(curl -sS \
    -o "$response_file" \
    -w '%{http_code}' \
    --connect-timeout 10 \
    --max-time 30 \
    -H "Authorization: Bearer $NOTION_API_TOKEN" \
    -H "Notion-Version: ${NOTION_API_VERSION:-2026-03-11}" \
    -H "Accept: application/json" \
    "$NOTION_API_BASE_URL/v1/pages/$normalized_id"); then
    curl_status=0
  else
    curl_status=$?
  fi
  response=$(<"$response_file")
  rm -f "$response_file"

  if [ "$curl_status" -ne 0 ] || [ -z "$http_status" ]; then
    echo "ERROR: PROVIDER_UNAVAILABLE: Notion request failed" >&2
    return 2
  fi

  case "$http_status" in
    200|201) ;;
    401|403)
      echo "ERROR: AUTH_REQUIRED: Notion rejected the connection" >&2
      return 2
      ;;
    404)
      echo "ERROR: NOT_FOUND: Notion page was not found or is not shared" >&2
      return 2
      ;;
    429|5??)
      echo "ERROR: PROVIDER_UNAVAILABLE: Notion service is temporarily unavailable" >&2
      return 2
      ;;
    *)
      echo "ERROR: VALIDATION_ERROR: Notion rejected the page request" >&2
      return 2
      ;;
  esac

  notion_normalize_page "$response" "$NOTION_DATABASE_ID"
}
