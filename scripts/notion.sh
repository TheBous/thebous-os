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

notion_data_source_id() {
  local configured="${NOTION_DATA_SOURCE_ID:-}" response data_source_id data_source_count

  if [ -n "$configured" ]; then
    data_source_id=$(format_notion_page_id "$configured" 2>/dev/null || true)
  else
    if ! response=$(notion_api_request GET "/v1/databases/$NOTION_DATABASE_ID"); then
      return 2
    fi
    data_source_count=$(jq -r '.data_sources | length' <<<"$response")
    if [ "$data_source_count" != "1" ]; then
      echo "ERROR: VALIDATION_ERROR: configure NOTION_DATA_SOURCE_ID when the database has multiple data sources" >&2
      return 2
    fi
    data_source_id=$(jq -r '.data_sources[0].id // empty' <<<"$response")
    data_source_id=$(format_notion_page_id "$data_source_id" 2>/dev/null || true)
  fi
  if [ -z "$data_source_id" ]; then
    echo "ERROR: VALIDATION_ERROR: Notion data source ID is invalid or unavailable" >&2
    return 2
  fi
  printf '%s' "$data_source_id"
}

notion_user_id_by_email() {
  local email="$1" cursor="" path response user_id encoded_cursor

  while :; do
    path="/v1/users?page_size=100"
    if [ -n "$cursor" ]; then
      encoded_cursor=$(jq -rn --arg cursor "$cursor" '$cursor | @uri')
      path="$path&start_cursor=$encoded_cursor"
    fi
    if ! response=$(notion_api_request GET "$path"); then
      return 2
    fi
    if ! jq -e '.object == "list" and (.results | type == "array")' <<<"$response" >/dev/null 2>&1; then
      echo "ERROR: VALIDATION_ERROR: Notion user list response is malformed" >&2
      return 2
    fi
    user_id=$(jq -r --arg email "$email" '
      first(.results[]
        | select(.type == "person" and ((.person.email // "") | ascii_downcase) == ($email | ascii_downcase))
        | .id
      ) // empty
    ' <<<"$response")
    if [ -n "$user_id" ]; then
      if ! user_id=$(format_notion_page_id "$user_id" 2>/dev/null); then
        echo "ERROR: VALIDATION_ERROR: Notion user ID is invalid" >&2
        return 2
      fi
      printf '%s' "$user_id"
      return 0
    fi
    if [ "$(jq -r '.has_more // false' <<<"$response")" != "true" ]; then
      break
    fi
    cursor=$(jq -r '.next_cursor // empty' <<<"$response")
    [ -n "$cursor" ] || break
  done

  echo "ERROR: NOT_FOUND: No Notion user matches the assignee email" >&2
  return 2
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
  local expected_data_source="${3:-${NOTION_DATA_SOURCE_ID:-}}"
  local page_id page_url title description raw_status status assignee due_at start_at updated_at parent_database_id parent_data_source_id
  local normalized_id normalized_parent normalized_expected normalized_source normalized_expected_source

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
    parent_database_id=$(jq -r '.parent.database_id // empty' <<<"$page_json")
    parent_data_source_id=$(jq -r '.parent.data_source_id // empty' <<<"$page_json")
    normalized_parent=$(format_notion_page_id "$parent_database_id" 2>/dev/null || true)
    normalized_expected=$(format_notion_page_id "$expected_database" 2>/dev/null || true)
    normalized_source=$(format_notion_page_id "$parent_data_source_id" 2>/dev/null || true)
    normalized_expected_source=$(format_notion_page_id "$expected_data_source" 2>/dev/null || true)
    if [ -z "$normalized_expected" ] \
      || { [ "$normalized_parent" != "$normalized_expected" ] && { [ -z "$normalized_expected_source" ] || [ "$normalized_source" != "$normalized_expected_source" ]; }; } \
      || { [ -n "$normalized_expected_source" ] && [ -n "$normalized_source" ] && [ "$normalized_source" != "$normalized_expected_source" ]; }; then
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

notion_list_tasks() {
  local filters_json="${1:-}" data_source_id response filter payload page_size cursor items next_cursor status_names statuses status normalized_page assignee_email="" assignee_user_id=""
  local -a normalized_items=()

  notion_config_validate
  [ -n "$filters_json" ] || filters_json='{}'
  if ! jq -e 'type == "object"' <<<"$filters_json" >/dev/null 2>&1; then
    echo "ERROR: VALIDATION_ERROR: Notion task filters must be a JSON object" >&2
    return 2
  fi
  assignee_email=$(jq -r 'if .assignee == null then "" else .assignee end' <<<"$filters_json")
  if [ -n "$assignee_email" ]; then
    if ! jq -e '(.assignee | type) == "string"' <<<"$filters_json" >/dev/null 2>&1; then
      echo "ERROR: VALIDATION_ERROR: Notion assignee filter must be an email string" >&2
      return 2
    fi
    if ! assignee_user_id=$(notion_user_id_by_email "$assignee_email"); then
      return 2
    fi
  fi
  page_size=$(jq -r '(.limit // 100)' <<<"$filters_json")
  if ! [[ "$page_size" =~ ^[0-9]+$ ]] || [ "$page_size" -lt 1 ] || [ "$page_size" -gt 100 ]; then
    echo "ERROR: VALIDATION_ERROR: Notion task limit must be between 1 and 100" >&2
    return 2
  fi
  cursor=$(jq -r '.cursor // empty' <<<"$filters_json")
  statuses=$(jq -r '(.status // empty) | if type == "array" then .[] else . end' <<<"$filters_json")
  for status in $statuses; do
    case "$status" in
      todo|in_progress|in_review|in_staging|done) ;;
      *)
        echo "ERROR: VALIDATION_ERROR: unsupported canonical Notion status" >&2
        return 2
        ;;
    esac
  done
  status_names=$(printf '%s\n' "$statuses" \
    | while IFS= read -r status; do
        [ -n "$status" ] && notion_status_name "$status"
      done \
    | jq -R -s 'split("\n") | map(select(length > 0))')
  filter=$(jq -c --argjson status_names "$status_names" --arg assignee_user_id "$assignee_user_id" '
    [
      (if $assignee_user_id == "" then empty else {property:"Assignee",people:{contains:$assignee_user_id}} end),
      (if ($status_names | length) == 0 then empty
       elif ($status_names | length) == 1 then {property:"Status",status:{equals:$status_names[0]}}
       else {or:($status_names | map({property:"Status",status:{equals:.}}))}
       end),
      (if (.due_from // "") == "" then empty else {property:"Due date",date:{on_or_after:.due_from}} end),
      (if (.due_to // "") == "" then empty else {property:"Due date",date:{on_or_before:.due_to}} end),
      (if (.start_from // "") == "" then empty else {property:"Start date",date:{on_or_after:.start_from}} end),
      (if (.start_to // "") == "" then empty else {property:"Start date",date:{on_or_before:.start_to}} end),
      (if (.updated_from // "") == "" then empty else {timestamp:"last_edited_time",last_edited_time:{on_or_after:.updated_from}} end),
      (if (.updated_to // "") == "" then empty else {timestamp:"last_edited_time",last_edited_time:{on_or_before:.updated_to}} end)
    ] as $filters
    | if ($filters | length) == 0 then null
      elif ($filters | length) == 1 then $filters[0]
      else {and:$filters}
      end
  ' <<<"$filters_json")
  if ! data_source_id=$(notion_data_source_id); then
    return 2
  fi
  payload=$(jq -n \
    --arg cursor "$cursor" \
    --argjson page_size "$page_size" \
    --argjson filter "$filter" \
    '{page_size:$page_size}
     | if $cursor == "" then . else .start_cursor = $cursor end
     | if $filter == null then . else .filter = $filter end')
  response=$(notion_api_request POST "/v1/data_sources/$data_source_id/query" "$payload")
  if ! jq -e '.object == "list" and (.results | type == "array")' <<<"$response" >/dev/null 2>&1; then
    echo "ERROR: VALIDATION_ERROR: Notion task list response is malformed" >&2
    return 2
  fi
  while IFS= read -r page; do
    if ! normalized_page=$(notion_normalize_page "$page" "$NOTION_DATABASE_ID" "$data_source_id"); then
      return 2
    fi
    normalized_items+=("$normalized_page")
  done < <(jq -c '.results[]' <<<"$response")
  if [ "${#normalized_items[@]}" -eq 0 ]; then
    items='[]'
  else
    items=$(printf '%s\n' "${normalized_items[@]}" | jq -s '.')
  fi
  next_cursor=$(jq -r 'if .has_more then (.next_cursor // "") else "" end' <<<"$response")
  jq -n \
    --argjson items "$items" \
    --arg next_cursor "$next_cursor" \
    '{items:$items,next_cursor:(if $next_cursor == "" then null else $next_cursor end)}'
}

notion_list_activity() {
  local filters_json="${1:-}" from to cursor limit refs task_filters task_page task_json task_ref page_id updated_at
  local comment_cursor comment_path encoded_cursor comment_response next_cursor items event
  local -a task_items=() activity_items=()

  notion_config_validate
  [ -n "$filters_json" ] || filters_json='{}'
  if ! jq -e 'type == "object"' <<<"$filters_json" >/dev/null 2>&1; then
    echo "ERROR: VALIDATION_ERROR: Notion activity filters must be a JSON object" >&2
    return 2
  fi
  from=$(jq -r '.from // empty' <<<"$filters_json")
  to=$(jq -r '.to // empty' <<<"$filters_json")
  if [ -z "$from" ] || [ -z "$to" ]; then
    echo "ERROR: VALIDATION_ERROR: Notion activity requires from and to timestamps" >&2
    return 2
  fi
  limit=$(jq -r '(.limit // 100)' <<<"$filters_json")
  if ! [[ "$limit" =~ ^[0-9]+$ ]] || [ "$limit" -lt 1 ] || [ "$limit" -gt 100 ]; then
    echo "ERROR: VALIDATION_ERROR: Notion activity limit must be between 1 and 100" >&2
    return 2
  fi
  cursor=$(jq -r '.cursor // empty' <<<"$filters_json")
  refs=$(jq -c '.refs // []' <<<"$filters_json")
  if ! jq -e 'type == "array"' <<<"$refs" >/dev/null 2>&1; then
    echo "ERROR: VALIDATION_ERROR: Notion activity refs must be an array" >&2
    return 2
  fi

  if [ "$(jq 'length' <<<"$refs")" -gt 0 ]; then
    if [ -n "$cursor" ]; then
      echo "ERROR: VALIDATION_ERROR: Notion activity cursor cannot be combined with refs" >&2
      return 2
    fi
    while IFS= read -r ref; do
      if ! jq -e '.provider == "notion" and (.external_id | type == "string")' <<<"$ref" >/dev/null 2>&1; then
        echo "ERROR: VALIDATION_ERROR: Notion activity ref is invalid" >&2
        return 2
      fi
      if ! task_json=$(notion_get_page "$(jq -r '.external_id' <<<"$ref")"); then
        return 2
      fi
      task_items+=("$task_json")
    done < <(jq -c '.[]' <<<"$refs")
    next_cursor=""
  else
    task_filters=$(jq -n \
      --arg from "$from" \
      --arg to "$to" \
      --arg cursor "$cursor" \
      --argjson limit "$limit" \
      '{updated_from:$from,updated_to:$to,limit:$limit}
       | if $cursor == "" then . else .cursor = $cursor end')
    if ! task_page=$(notion_list_tasks "$task_filters"); then
      return 2
    fi
    while IFS= read -r task_json; do
      task_items+=("$task_json")
    done < <(jq -c '.items[]' <<<"$task_page")
    next_cursor=$(jq -r '.next_cursor // empty' <<<"$task_page")
  fi

  for task_json in "${task_items[@]}"; do
    task_ref=$(jq -c '.ref' <<<"$task_json")
    page_id=$(jq -r '.ref.external_id' <<<"$task_json")
    updated_at=$(jq -r '.updated_at // empty' <<<"$task_json")
    if [ -n "$updated_at" ] \
      && { [[ "$updated_at" == "$from" || "$updated_at" > "$from" ]]; } \
      && { [[ "$updated_at" == "$to" || "$updated_at" < "$to" ]]; }; then
      activity_items+=("$(jq -n \
        --argjson ref "$task_ref" \
        --arg at "$updated_at" \
        '{kind:"updated",ref:$ref,at:$at,actor:null,summary:"Task updated",url:$ref.url}')")
    fi

    comment_cursor=""
    while :; do
      comment_path="/v1/comments?block_id=$page_id&page_size=100"
      if [ -n "$comment_cursor" ]; then
        encoded_cursor=$(jq -rn --arg cursor "$comment_cursor" '$cursor | @uri')
        comment_path="$comment_path&start_cursor=$encoded_cursor"
      fi
      if ! comment_response=$(notion_api_request GET "$comment_path"); then
        return 2
      fi
      if ! jq -e '.object == "list" and (.results | type == "array")' <<<"$comment_response" >/dev/null 2>&1; then
        echo "ERROR: VALIDATION_ERROR: Notion comment list response is malformed" >&2
        return 2
      fi
      while IFS= read -r event; do
        [ -n "$event" ] && activity_items+=("$event")
      done < <(jq -c \
        --arg from "$from" \
        --arg to "$to" \
        --argjson ref "$task_ref" \
        '.results[]
         | . as $comment
         | ([.rich_text[]? | (.plain_text // .text.content // "")] | join("")) as $summary
         | [
             (if .created_time >= $from and .created_time <= $to then
               {kind:"commented",ref:$ref,at:.created_time,actor:(.display_name.resolved_name // .created_by.id // null),summary:(if $summary == "" then "Notion comment" else $summary end),url:$ref.url}
              else empty end),
             (if .last_edited_time != .created_time and .last_edited_time >= $from and .last_edited_time <= $to then
               {kind:"updated",ref:$ref,at:.last_edited_time,actor:(.display_name.resolved_name // .created_by.id // null),summary:(if $summary == "" then "Notion comment updated" else "Comment updated: " + $summary end),url:$ref.url}
              else empty end)
           ][]' <<<"$comment_response")
      if [ "$(jq -r '.has_more // false' <<<"$comment_response")" != "true" ]; then
        break
      fi
      comment_cursor=$(jq -r '.next_cursor // empty' <<<"$comment_response")
      [ -n "$comment_cursor" ] || break
    done
  done

  if [ "${#activity_items[@]}" -eq 0 ]; then
    items='[]'
  else
    items=$(printf '%s\n' "${activity_items[@]}" | jq -s --argjson limit "$limit" 'sort_by(.at) | .[:$limit]')
  fi
  jq -n \
    --argjson items "$items" \
    --arg next_cursor "$next_cursor" \
    '{items:$items,next_cursor:(if $next_cursor == "" then null else $next_cursor end)}'
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
