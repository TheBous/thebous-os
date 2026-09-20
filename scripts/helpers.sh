#!/usr/bin/env bash
# Shared helpers for jira-git-sync commands. Source this file, don't execute it.

set -euo pipefail

# ── Credentials ──────────────────────────────────────────────────
# THEBOUS_OS_DATA_DIR is the provider-neutral override. Keep the Claude
# variable only as a backwards-compatible fallback for existing installs.
THEBOUS_OS_DATA_DIR="${THEBOUS_OS_DATA_DIR:-${CLAUDE_PLUGIN_DATA:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}}"
ENV_FILE="$THEBOUS_OS_DATA_DIR/.env"

load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: credenziali non trovate. Esegui /thebous-os:setup prima." >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$ENV_FILE"
}

# ── Jira ─────────────────────────────────────────────────────────
jira_get() {
  local path="$1"
  curl -sf \
    -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    -H "Accept: application/json" \
    "$JIRA_BASE_URL/rest/api/2/$path"
}

jira_post() {
  local path="$1" body="$2"
  curl -sf -o /dev/null \
    -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "$JIRA_BASE_URL/rest/api/2/$path" \
    -d "$body"
}

jira_transition() {
  local key="$1" tid="$2"
  jira_post "issue/$key/transitions" "{\"transition\":{\"id\":\"$tid\"}}"
}

jira_comment() {
  local key="$1" body="$2"
  jira_post "issue/$key/comment" "{\"body\":\"$body\"}"
}

jira_get_issue() {
  local key="$1"
  jira_get "issue/$key?fields=summary,status"
}

# ── Slack ─────────────────────────────────────────────────────────
slack_notify() {
  local msg="$1"
  curl -sf -o /dev/null -X POST "$SLACK_WEBHOOK_URL" \
    -H "Content-type: application/json" \
    -d "{\"text\":\"$msg\"}"
}

# ── GitHub ────────────────────────────────────────────────────────
gh_repo_filter() {
  # Builds --repo= flags for `gh search`/`gh pr` from comma-separated GITHUB_REPOS.
  # Echoes nothing (all repos) if GITHUB_REPOS is unset. Always exits 0.
  if [ -n "${GITHUB_REPOS:-}" ]; then
    echo "$GITHUB_REPOS" | tr ',' '\n' | sed 's/^/--repo=/' | tr '\n' ' '
  fi
}

# ── Confluence ────────────────────────────────────────────────────
confluence_page_id() {
  # Extracts the numeric page ID from a Confluence page URL (any /pages/<id> URL).
  echo "$1" | grep -oP '(?<=pages/)[0-9]+'
}

confluence_space_key() {
  # Extracts the space key from a Confluence URL (.../spaces/<KEY>/...).
  echo "$1" | grep -oP '(?<=spaces/)[^/]+'
}

# ── Utilities ─────────────────────────────────────────────────────
extract_jira_key() {
  # Accepts branch name, URL, or free text — returns uppercase key or empty
  echo "$1" \
    | grep -oiE '[A-Za-z]+-[0-9]+' \
    | head -1 \
    | tr '[:lower:]' '[:upper:]'
}

format_notion_page_id() {
  local compact
  compact=$(printf '%s' "$1" | tr -d '-' | tr '[:upper:]' '[:lower:]')
  if [[ ! "$compact" =~ ^[0-9a-f]{32}$ ]]; then
    return 1
  fi
  printf '%s-%s-%s-%s-%s\n' \
    "${compact:0:8}" "${compact:8:4}" "${compact:12:4}" \
    "${compact:16:4}" "${compact:20:12}"
}

extract_notion_page_id() {
  local input="$1"
  local pattern='([0-9A-Fa-f]{8}-?[0-9A-Fa-f]{4}-?[0-9A-Fa-f]{4}-?[0-9A-Fa-f]{4}-?[0-9A-Fa-f]{12})'

  case "$input" in
    notion:*|*notion.so*|*notion.site*|*ntn-*) ;;
    *) return 1 ;;
  esac

  if [[ "$input" =~ $pattern ]]; then
    format_notion_page_id "${BASH_REMATCH[1]}"
  else
    return 1
  fi
}

extract_notion_url() {
  local input="$1"
  local pattern='https?://(www\.)?notion\.(so|site)/[^[:space:]]+'
  local url

  if [[ "$input" =~ $pattern ]]; then
    url="${BASH_REMATCH[0]}"
    url=$(printf '%s' "$url" | sed 's/[.,;:!?)]$//')
    printf '%s\n' "$url"
  else
    return 1
  fi
}

extract_jira_url() {
  local input="$1"
  local pattern='https?://[^[:space:]]+/browse/[A-Za-z]+-[0-9]+'
  local url

  if [[ "$input" =~ $pattern ]]; then
    url="${BASH_REMATCH[0]}"
    url=$(printf '%s' "$url" | sed 's/[.,;:!?)]$//')
    printf '%s\n' "$url"
  else
    return 1
  fi
}

resolve_work_item_ref() {
  local input="${1:-}"
  local provider="" candidate="$input" jira_key="" notion_id="" url=""
  local jira_source="$input" notion_url=""
  local notion_branch_pattern='^[^[:space:]]+/ntn-[0-9A-Fa-f]{32}(-[[:alnum:]-]+)?$'

  if [ -z "$input" ]; then
    echo "ERROR: task reference is empty" >&2
    return 2
  fi

  case "$input" in
    jira:*)
      provider="jira"
      candidate="${input#jira:}"
      ;;
    notion:*)
      provider="notion"
      candidate="${input#notion:}"
      ;;
    *)
      notion_id=$(extract_notion_page_id "$input" 2>/dev/null || true)
      if [ -n "$notion_id" ]; then
        notion_url=$(extract_notion_url "$input" 2>/dev/null || true)
        if [[ "$input" =~ $notion_branch_pattern ]]; then
          jira_source=""
        elif [ -n "$notion_url" ]; then
          jira_source="${input//$notion_url/}"
        else
          jira_source=$(printf '%s' "$input" | sed -E 's/ntn-[0-9A-Fa-f]{32}//g')
        fi
      fi
      jira_key=$(extract_jira_key "$jira_source" 2>/dev/null || true)
      if [ -n "$jira_key" ] && [ -n "$notion_id" ]; then
        echo "ERROR: ambiguous task reference: Jira and Notion references found" >&2
        return 2
      elif [ -n "$jira_key" ]; then
        provider="jira"
      elif [ -n "$notion_id" ]; then
        provider="notion"
      else
        echo "ERROR: unsupported task reference" >&2
        return 2
      fi
      ;;
  esac

  if [ "$provider" = "jira" ]; then
    jira_key=$(extract_jira_key "$candidate" 2>/dev/null || true)
    if [ -z "$jira_key" ]; then
      echo "ERROR: invalid Jira task reference" >&2
      return 2
    fi
    url=$(extract_jira_url "$candidate" 2>/dev/null || true)
    jq -n \
      --arg provider "$provider" \
      --arg external_id "$jira_key" \
      --arg url "$url" \
      '{provider: $provider, external_id: $external_id, url: (if $url == "" then null else $url end)}'
    return 0
  fi

  notion_id=$(extract_notion_page_id "notion:$candidate" 2>/dev/null || true)
  if [ -z "$notion_id" ]; then
    echo "ERROR: invalid Notion page reference" >&2
    return 2
  fi
  url=$(extract_notion_url "$candidate" 2>/dev/null || true)
  jq -n \
    --arg provider "$provider" \
    --arg external_id "$notion_id" \
    --arg url "$url" \
    '{provider: $provider, external_id: $external_id, url: (if $url == "" then null else $url end)}'
}

extract_jira_keys() {
  # Same pattern as extract_jira_key, but returns every unique uppercase key
  # found in the text (one per line) — for scanning commit ranges/release notes.
  echo "$1" \
    | grep -oiE '[A-Za-z]+-[0-9]+' \
    | tr '[:lower:]' '[:upper:]' \
    | sort -u
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//' \
    | cut -c1-50
}

# ── Obsidian ─────────────────────────────────────────────────────
obsidian_task_storage_key() {
  local ref_json="$1" provider external_id
  provider=$(jq -r '.provider // empty' <<<"$ref_json")
  external_id=$(jq -r '.external_id // empty' <<<"$ref_json")

  case "$provider" in
    jira)
      external_id=$(extract_jira_key "$external_id" 2>/dev/null || true)
      [ -n "$external_id" ] || return 1
      printf '%s\n' "$external_id"
      ;;
    notion)
      external_id=$(format_notion_page_id "$external_id" 2>/dev/null || true)
      [ -n "$external_id" ] || return 1
      printf 'notion-%s\n' "$external_id"
      ;;
    *) return 1 ;;
  esac
}

obsidian_task_dir() {
  local vault="$1" ref_json="$2" key
  key=$(obsidian_task_storage_key "$ref_json") || return 1
  echo "$vault/Dev/Tickets/$key"
}

obsidian_task_docs_dir() {
  local dir
  dir=$(obsidian_task_dir "$1" "$2") || return 1
  echo "$dir/docs"
}

obsidian_ensure_task_file() {
  local vault="$1" ref_json="$2" filename="$3"
  local provider external_id url dir file
  provider=$(jq -r '.provider // empty' <<<"$ref_json")
  external_id=$(jq -r '.external_id // empty' <<<"$ref_json")
  url=$(jq -r '.url // empty' <<<"$ref_json")
  dir=$(obsidian_task_dir "$vault" "$ref_json") || return 1
  [ -n "$filename" ] || return 1
  file="$dir/$filename"
  mkdir -p "$dir"
  if [ ! -f "$file" ]; then
    {
      echo "---"
      [ "$provider" = "jira" ] && echo "ticket: $external_id"
      echo "provider: $provider"
      echo "external_id: $external_id"
      if [ -n "$url" ]; then
        printf 'url: "%s"\n' "$(printf '%s' "$url" | sed 's/"/\\"/g')"
      else
        echo "url: null"
      fi
      echo "status: open"
      echo "date: $(date +%Y-%m-%d)"
      echo "---"
      echo
    } > "$file"
  fi
  echo "$file"
}

obsidian_log_task() {
  local vault="$1" ref_json="$2" filename="$3" section="${4:-}" daily_line="${5:-}"
  local file
  [ -n "$vault" ] && [ -d "$vault" ] && [ -n "$ref_json" ] || return 0
  file="$(obsidian_ensure_task_file "$vault" "$ref_json" "$filename")"
  [ -z "$section" ] || obsidian_append_section "$file" "$section"
  [ -z "$daily_line" ] || obsidian_append_daily "$vault" "$daily_line"
  echo "$file"
}

obsidian_log_pr_task() {
  local vault="$1" ref_json="$2" pr_url="$3" daily_line="$4"
  local file
  [ -n "$vault" ] && [ -d "$vault" ] && [ -n "$ref_json" ] || return 0
  file="$(obsidian_log_task "$vault" "$ref_json" "plan.md" "" "$daily_line")"
  obsidian_set_pr "$file" "$pr_url"
  echo "$file"
}

obsidian_ticket_dir() {
  local vault="$1" key="$2"
  echo "$vault/Dev/Tickets/$key"
}

obsidian_ticket_docs_dir() {
  local vault="$1" key="$2"
  echo "$(obsidian_ticket_dir "$vault" "$key")/docs"
}

obsidian_copy_ticket_docs() {
  local vault="$1" key="$2" relative_dir="$3" destination source
  shift 3
  [ "$#" -gt 0 ] || return 1

  destination="$(obsidian_ticket_docs_dir "$vault" "$key")/$relative_dir"
  mkdir -p "$destination"
  for source in "$@"; do
    if [ -d "$source" ]; then
      cp -R "$source"/. "$destination"/
    else
      cp "$source" "$destination"/
    fi
  done
  echo "$destination"
}

obsidian_ensure_ticket_file() {
  local vault="$1" key="$2" filename="$3"
  local dir file
  dir="$(obsidian_ticket_dir "$vault" "$key")"
  file="$dir/$filename"
  mkdir -p "$dir"
  if [ ! -f "$file" ]; then
    {
      echo "---"
      echo "ticket: $key"
      echo "status: open"
      echo "date: $(date +%Y-%m-%d)"
      echo "---"
      echo
    } > "$file"
  fi
  echo "$file"
}

obsidian_set_pr() {
  local file="$1" pr="$2" tmp
  tmp="$(mktemp)"
  if grep -q '^pr: ' "$file"; then
    sed "s|^pr: .*|pr: $pr|" "$file" > "$tmp"
  else
    awk -v pr="$pr" '{ print } !inserted && (/^ticket: / || /^external_id: /) { print "pr: " pr; inserted=1 } END { if (!inserted) print "pr: " pr }' "$file" > "$tmp"
  fi
  mv "$tmp" "$file"
}

obsidian_append_section() {
  local file="$1" body="$2"
  {
    echo
    echo "## $(date '+%Y-%m-%d %H:%M')"
    echo "$body"
  } >> "$file"
}

obsidian_append_daily() {
  local vault="$1" line="$2"
  local dir file
  dir="$vault/Dev/Daily/$(date +%Y-%m-%d)"
  file="$dir/10 - Work Log.md"
  mkdir -p "$dir"
  [ -f "$file" ] || echo "# Work Log — $(date +%Y-%m-%d)" > "$file"
  echo "- $line" >> "$file"
}

obsidian_log_ticket() {
  local vault="$1" key="$2" filename="$3" section="${4:-}" daily_line="${5:-}"
  local file
  [ -n "$vault" ] && [ -d "$vault" ] && [ -n "$key" ] || return 0
  file="$(obsidian_ensure_ticket_file "$vault" "$key" "$filename")"
  [ -z "$section" ] || obsidian_append_section "$file" "$section"
  [ -z "$daily_line" ] || obsidian_append_daily "$vault" "$daily_line"
  echo "$file"
}

obsidian_log_pr() {
  local vault="$1" key="$2" pr_url="$3" daily_line="$4"
  local file
  [ -n "$vault" ] && [ -d "$vault" ] && [ -n "$key" ] || return 0
  file="$(obsidian_log_ticket "$vault" "$key" "plan.md" "" "$daily_line")"
  obsidian_set_pr "$file" "$pr_url"
  echo "$file"
}

obsidian_copy_daily_artifact() {
  local vault="$1" name="$2" source_dir="$3" destination
  [ -d "$source_dir" ] || return 1
  destination="$vault/Dev/Daily/$(date +%Y-%m-%d)/$name"
  mkdir -p "$destination"
  cp -R "$source_dir"/. "$destination"/
  echo "$destination"
}

obsidian_granola_candidates() {
  local vault="$1" days="${2:-14}"
  local dir="$vault/Granola"
  [ -d "$dir" ] || return 0
  find "$dir" -name '*.md' -mtime "-$days" | sort
}
