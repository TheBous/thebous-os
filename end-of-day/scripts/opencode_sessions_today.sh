#!/usr/bin/env bash
# Starts a temporary headless OpenCode server, lists sessions touched today
# (local time), prints them as a JSON array, and shuts the server down.
# Requires the `opencode` CLI and `jq`. Prints `[]` (not an error) if
# opencode isn't installed or no server could start — this data source is
# optional, not having it shouldn't break the rest of the briefing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"

if ! command -v "$OPENCODE_BIN" >/dev/null 2>&1; then
  echo "[]"
  exit 0
fi

PORT=$(( (RANDOM % 20000) + 40000 ))
LOG_FILE=$(mktemp)
"$OPENCODE_BIN" serve --port "$PORT" --hostname 127.0.0.1 > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null; rm -f "$LOG_FILE"' EXIT

UP=0
for _ in $(seq 1 25); do
  if curl -s -o /dev/null "http://127.0.0.1:$PORT/api/health"; then
    UP=1
    break
  fi
  sleep 0.2
done

if [ "$UP" -ne 1 ]; then
  echo "[]"
  exit 0
fi

TODAY_START_S=$(date -v0H -v0M -v0S +%s 2>/dev/null || date -d "today 00:00" +%s)
TODAY_START_MS=$((TODAY_START_S * 1000))
TODAY_END_MS=$((TODAY_START_MS + 86400000))

curl -s "http://127.0.0.1:$PORT/api/session?limit=200" \
  | jq --argjson start "$TODAY_START_MS" --argjson end "$TODAY_END_MS" -f "$SCRIPT_DIR/filter_sessions_today.jq"
