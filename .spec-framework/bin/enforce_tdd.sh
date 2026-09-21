#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
CHANGE_ID="${2:-}"
TASK_ID="${3:-}"
PAYLOAD="${4:-}"
SECOND_PAYLOAD="${5:-}"
THIRD_PAYLOAD="${6:-}"
FOURTH_PAYLOAD="${7:-}"

fail() { printf 'ERROR: %s\n' "$1" >&2; exit "${2:-1}"; }

[[ "$CHANGE_ID" =~ ^CHG-[0-9]{4}-[0-9]{3}$ ]] || fail "invalid change id"
if [[ "$ACTION" != select-task && "$ACTION" != unlock && "$ACTION" != approve-plan ]]; then
  [[ "$TASK_ID" =~ ^T-[0-9]{3}$ ]] || fail "invalid task id"
fi

BASE_PATH=$(git rev-parse --show-toplevel 2>/dev/null) || fail "not inside a Git repository"
WORKTREE_PATH="${BASE_PATH}/.worktrees/${CHANGE_ID}"
[[ -d "$WORKTREE_PATH" ]] || fail "worktree not found: ${WORKTREE_PATH}"
WORKTREE_ROOT=$(git -C "$WORKTREE_PATH" rev-parse --show-toplevel 2>/dev/null) || fail "not a Git worktree"
[[ "$(cd "$WORKTREE_PATH" && pwd -P)" == "$(cd "$WORKTREE_ROOT" && pwd -P)" ]] || fail "worktree root mismatch"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$BASE_PATH/.spec-framework/bin/enforce_tdd.sh")" && pwd -P)
PYTHON=$(command -v python3) || fail "python3 is required for SDD state gates"
HELPER="$SCRIPT_DIR/cook_tdd.py"
[[ -f "$HELPER" ]] || fail "missing SDD state helper: $HELPER"
GIT_DIR=$(git -C "$WORKTREE_PATH" rev-parse --git-dir)
[[ "$GIT_DIR" = /* ]] || GIT_DIR="$WORKTREE_PATH/$GIT_DIR"
LOCK_FILE="${GIT_DIR}/cook-tdd-lock/${CHANGE_ID}.json"
cd "$WORKTREE_PATH"

LOG_FILE=""
UNLOCK_ON_EXIT=0
cleanup() {
  [[ -z "$LOG_FILE" ]] || rm -f "$LOG_FILE"
  if [[ "$UNLOCK_ON_EXIT" -eq 1 && -f "$LOCK_FILE" ]]; then
    "$PYTHON" "$HELPER" unlock "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$GIT_DIR" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

run_command() {
  TDD_RED_EVIDENCE="${3:-}" TDD_REVIEW_RECEIPT="${4:-}" bash -c -- "$2" >"$1" 2>&1
}
require_command() { [[ -n "$PAYLOAD" ]] || fail "a test command is required for ${ACTION}"; }
is_test_path() { case "$1" in test/*|tests/*|spec/*|specs/*|*_test.*|*.test.*|*.spec.*) return 0;; *) return 1;; esac; }
production_changes() {
  local entry path
  while IFS= read -r entry; do
    path="${entry:3}"
    is_test_path "$path" || printf '%s\n' "$entry"
  done < <(git status --porcelain --untracked-files=all)
}
matches_path_list() {
  local path="$1" list="$2" pattern
  [[ -n "$list" ]] || return 1
  IFS=',' read -r -a patterns <<< "$list"
  for pattern in "${patterns[@]}"; do
    [[ "$pattern" =~ ^(none|nessuno)$ ]] && continue
    [[ "$path" == $pattern ]] && return 0
  done
  return 1
}
check_paths() {
  local allowed="$1" forbidden="$2" entry path
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    path="${entry:3}"
    matches_path_list "$path" "$forbidden" && fail "path is explicitly forbidden: ${path}" 7
    matches_path_list "$path" "$allowed" || fail "path is outside Allowed Paths: ${path}" 7
  done <<< "$(git status --porcelain --untracked-files=all)"
}
record_stage() {
  mkdir -p "$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}"
  printf 'PASS\n' > "$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}/${TASK_ID}.${1}"
}
preserve_log() {
  mkdir -p "$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}"
  cp "$LOG_FILE" "$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}/${TASK_ID}.${1}.log"
  chmod 600 "$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}/${TASK_ID}.${1}.log"
}
require_stage() {
  [[ -f "$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}/${TASK_ID}.${1}" ]] || fail "${1} evidence missing; run the gate first" 9
  grep -Fxq PASS "$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}/${TASK_ID}.${1}" || fail "invalid ${1} evidence" 9
}

case "$ACTION" in
  select-task)
    "$PYTHON" "$HELPER" select-task "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID"
    ;;
  approve-plan)
    "$PYTHON" "$HELPER" approve-plan "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID"
    ;;
  init)
    "$PYTHON" "$HELPER" assert-task "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$TASK_ID" >/dev/null
    [[ -z "$(git status --porcelain --untracked-files=all)" ]] || fail "dirty worktree for ${TASK_ID}; inspect or clean it explicitly" 2
    [[ -z "$(git -C "$BASE_PATH" status --porcelain --untracked-files=all)" ]] || fail "primary worktree is dirty" 2
    "$PYTHON" "$HELPER" lock "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$GIT_DIR"
    printf 'OK: clean worktree locked and ready for %s\n' "$TASK_ID"
    ;;
  unlock)
    "$PYTHON" "$HELPER" unlock "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$GIT_DIR"
    printf 'OK: primary worktree unlocked for %s\n' "$CHANGE_ID"
    ;;
  verify-red)
    require_command
    [[ -n "$SECOND_PAYLOAD" ]] || fail "an exact RED assertion marker is required"
    CHANGES=$(production_changes)
    [[ -z "$CHANGES" ]] || { printf 'VIOLATION: production paths changed before RED:\n%s\n' "$CHANGES" >&2; fail "write the failing test before production code" 2; }
    LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/cook-tdd-red.XXXXXX")
    RED_EVIDENCE="$GIT_DIR/cook-tdd-evidence/${CHANGE_ID}/${TASK_ID}.red.json"
    mkdir -p "$(dirname "$RED_EVIDENCE")"
    rm -f "$RED_EVIDENCE"
    set +e; run_command "$LOG_FILE" "$PAYLOAD" "$RED_EVIDENCE"; RUNNER_STATUS=$?; set -e
    preserve_log red
    [[ "$RUNNER_STATUS" -ne 0 ]] || { cat "$LOG_FILE" >&2; fail "RED test passed immediately" 3; }
    if grep -Eiq 'SyntaxError|ParseError|Cannot find module|ModuleNotFoundError|compilation failed|command not found|No such file or directory' "$LOG_FILE"; then
      cat "$LOG_FILE" >&2; fail "RED test failed structurally, not by assertion" 4
    fi
    "$PYTHON" "$HELPER" require-red "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$GIT_DIR/cook-tdd-evidence" "$TASK_ID" "$SECOND_PAYLOAD"
    record_stage red
    printf 'OK: semantic RED marker verified for %s\n' "$TASK_ID"
    ;;
  verify-green|verify-global)
    require_command
    LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/cook-tdd-${ACTION}.XXXXXX")
    set +e; run_command "$LOG_FILE" "$PAYLOAD"; RUNNER_STATUS=$?; set -e
    preserve_log "${ACTION#verify-}"
    if [[ "$RUNNER_STATUS" -ne 0 ]]; then
      cat "$LOG_FILE" >&2
      [[ "$ACTION" == "verify-global" ]] && fail "global regression suite failed" 6
      fail "GREEN test failed" 5
    fi
    [[ "$ACTION" == "verify-green" ]] && record_stage green
    [[ "$ACTION" == "verify-global" ]] && record_stage global
    printf 'OK: %s passed for %s\n' "$ACTION" "$TASK_ID"
    ;;
  verify-quality)
    [[ -n "$PAYLOAD" ]] || fail "static analysis command is required"
    [[ -n "$SECOND_PAYLOAD" ]] || fail "mutation testing command is required"
    [[ -n "$THIRD_PAYLOAD" ]] || fail "independent review receipt is required"
    [[ -n "$FOURTH_PAYLOAD" ]] || fail "independent review receipt path is required"
    LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/cook-tdd-static.XXXXXX")
    set +e; run_command "$LOG_FILE" "$PAYLOAD"; RUNNER_STATUS=$?; set -e
    preserve_log static
    [[ "$RUNNER_STATUS" -eq 0 ]] || { cat "$LOG_FILE" >&2; fail "static analysis failed" 8; }
    LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/cook-tdd-mutation.XXXXXX")
    set +e; run_command "$LOG_FILE" "$SECOND_PAYLOAD"; RUNNER_STATUS=$?; set -e
    preserve_log mutation
    [[ "$RUNNER_STATUS" -eq 0 ]] || { cat "$LOG_FILE" >&2; fail "mutation testing failed" 8; }
    REVIEW_STARTED=$("$PYTHON" -c 'import time; print(time.time())')
    LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/cook-tdd-review.XXXXXX")
    set +e; run_command "$LOG_FILE" "$THIRD_PAYLOAD" "" "$FOURTH_PAYLOAD"; RUNNER_STATUS=$?; set -e
    preserve_log review
    [[ "$RUNNER_STATUS" -eq 0 ]] || { cat "$LOG_FILE" >&2; fail "independent review command failed" 8; }
    "$PYTHON" "$HELPER" record-quality "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$GIT_DIR/cook-tdd-evidence" "$TASK_ID" "$PAYLOAD" "$SECOND_PAYLOAD" "$FOURTH_PAYLOAD" "$REVIEW_STARTED"
    printf 'OK: quality and independent review gates passed for %s\n' "$TASK_ID"
    ;;
  verify-paths)
    [[ -n "$PAYLOAD" ]] || fail "Allowed Paths are required for verify-paths"
    check_paths "$PAYLOAD" "$SECOND_PAYLOAD"
    printf 'OK: task paths are within declared boundaries for %s\n' "$TASK_ID"
    ;;
  complete)
    [[ -f "$LOCK_FILE" ]] || fail "primary worktree is not locked; run init first" 10
    UNLOCK_ON_EXIT=1
    TASKS_PATH="changes/${CHANGE_ID}/tasks.md"
    require_stage red
    require_stage green
    require_stage global
    check_paths "${PAYLOAD},${TASKS_PATH}" "$SECOND_PAYLOAD"
    "$PYTHON" "$HELPER" require-quality "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$GIT_DIR/cook-tdd-evidence" "$TASK_ID"
    "$PYTHON" "$HELPER" complete "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$TASK_ID"
    check_paths "${PAYLOAD},${TASKS_PATH}" "$SECOND_PAYLOAD"
    git add --all -- .
    git diff --cached --quiet && fail "no changes to commit" 12
    git commit -m "feat(cook): implement ${TASK_ID}"
    "$PYTHON" "$HELPER" unlock "$BASE_PATH" "$WORKTREE_PATH" "$CHANGE_ID" "$GIT_DIR"
    UNLOCK_ON_EXIT=0
    printf 'OK: committed %s and marked it complete\n' "$TASK_ID"
    ;;
  *)
    fail "unsupported action; use approve-plan, select-task, init, verify-red, verify-green, verify-global, verify-quality, verify-paths, complete, or unlock"
    ;;
esac
