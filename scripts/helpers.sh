#!/usr/bin/env bash
# Shared helpers for jira-git-sync commands. Source this file, don't execute it.

set -euo pipefail

# ── Credentials ──────────────────────────────────────────────────
ENV_FILE="${CLAUDE_PLUGIN_DATA:-$HOME/.config/jira-git-sync}/.env"

load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: credenziali non trovate. Esegui /thebous-jira-git-sync:setup prima." >&2
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

# ── Utilities ─────────────────────────────────────────────────────
extract_jira_key() {
  # Accepts branch name, URL, or free text — returns uppercase key or empty
  echo "$1" \
    | grep -oiE '[A-Za-z]+-[0-9]+' \
    | head -1 \
    | tr '[:lower:]' '[:upper:]'
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
  dir="$vault/Dev/Daily"
  file="$dir/$(date +%Y-%m-%d).md"
  mkdir -p "$dir"
  [ -f "$file" ] || echo "# $(date +%Y-%m-%d)" > "$file"
  echo "- $line" >> "$file"
}

obsidian_granola_candidates() {
  local vault="$1" days="${2:-14}"
  local dir="$vault/Granola"
  [ -d "$dir" ] || return 0
  find "$dir" -name '*.md' -mtime "-$days" | sort
}
