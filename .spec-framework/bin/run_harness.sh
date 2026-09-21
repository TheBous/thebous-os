#!/usr/bin/env bash
set -euo pipefail

CHANGE_ID="${1:-}"
BASE_SHA="${2:-}"
TYPECHECK_COMMAND="${3:-}"
STATIC_COMMAND="${4:-}"
ARCHITECTURE_COMMAND="${5:-}"
GLOBAL_COMMAND="${6:-}"
COMMAND_MANIFEST="${7:-}"
EVIDENCE_PATH="${8:-}"

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

[[ "$CHANGE_ID" =~ ^CHG-[0-9]{4}-[0-9]{3}$ ]] || fail "invalid change id"
[[ "$BASE_SHA" =~ ^[0-9a-f]{40}$ ]] || fail "base commit must be a full SHA-1"
[[ -n "$TYPECHECK_COMMAND" && -n "$STATIC_COMMAND" && -n "$ARCHITECTURE_COMMAND" && -n "$GLOBAL_COMMAND" ]] || fail "all four harness commands are required"
[[ -n "$COMMAND_MANIFEST" ]] || fail "approved command manifest is required"
[[ -n "$EVIDENCE_PATH" ]] || fail "evidence path is required"

BASE_DIR=$(git rev-parse --show-toplevel 2>/dev/null) || fail "not inside a Git repository"
WORKTREE_PATH="$BASE_DIR/.worktrees/$CHANGE_ID"
[[ -d "$WORKTREE_PATH" ]] || fail "worktree not found: $WORKTREE_PATH"

HELPER="$BASE_DIR/skills/sdd-verify/scripts/sdd_verify.py"
[[ -f "$HELPER" ]] || fail "missing harness helper: $HELPER"
PYTHON=$(command -v python3) || fail "python3 is required"

exec "$PYTHON" "$HELPER" run-harness \
  "$BASE_DIR" "$CHANGE_ID" "$BASE_SHA" "$EVIDENCE_PATH" "$COMMAND_MANIFEST" \
  "$TYPECHECK_COMMAND" "$STATIC_COMMAND" "$ARCHITECTURE_COMMAND" "$GLOBAL_COMMAND"
