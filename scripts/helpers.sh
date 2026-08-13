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
    awk -v pr="$pr" '{ print } /^ticket: / && !inserted { print "pr: " pr; inserted=1 }' "$file" > "$tmp"
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
