#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
ENGINE="$ROOT/.spec-framework/bin/reconcile_engine.sh"
VERIFY="$ROOT/skills/cook-verify/scripts/cook_verify.py"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/cook-reconcile.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_file() { [[ -f "$1" ]] || fail "missing file: $1"; }
assert_dir() { [[ -d "$1" ]] || fail "missing directory: $1"; }
assert_contains() { grep -Fq -- "$2" "$1" || fail "${1} does not contain: $2"; }
assert_not_contains() { ! grep -Fq -- "$2" "$1" || fail "${1} unexpectedly contains: $2"; }

new_repo() {
  local repo="$1" id="CHG-2026-042"
  mkdir -p "$repo/.spec-framework/bin" "$repo/skills/cook-verify/scripts"
  cp "$ENGINE" "$repo/.spec-framework/bin/reconcile_engine.sh"
  cp "$VERIFY" "$repo/skills/cook-verify/scripts/cook_verify.py"
  chmod +x "$repo/.spec-framework/bin/reconcile_engine.sh"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name Test
  mkdir -p "$repo/specs" "$repo/changes/$id" "$repo/.git/cook-verify-evidence/$id"
  cat >"$repo/specs/core.md" <<'EOF'
# Core

### Requirement: Existing behavior
The system accepts the original input.

#### Scenario: Existing input
- **WHEN** the original input is submitted
- **THEN** the system accepts it

#### Scenario: Other input
- **WHEN** the other input is submitted
- **THEN** the system accepts it

### Requirement: Obsolete behavior
The system exposes the old endpoint.

#### Scenario: Old endpoint
- **WHEN** the old endpoint is called
- **THEN** the old response is returned
EOF
  cat >"$repo/changes/$id/delta-spec.md" <<'EOF'
Target Domain: specs/core.md

## ADDED Requirements
### Requirement: New behavior
The system accepts the new input.

#### Scenario: New input
- **WHEN** the new input is submitted
- **THEN** the system accepts it

## MODIFIED Requirements
### Requirement: Existing behavior
The system accepts the original input and records an audit event.

#### Scenario: Existing input
- **WHEN** the original input is submitted
- **THEN** the system accepts it and records the event

#### Scenario: Other input
- **WHEN** the other input is submitted
- **THEN** the system accepts it and records the event

## REMOVED Requirements
### Requirement: Obsolete behavior
The system exposes the old endpoint.

#### Scenario: Old endpoint
- **WHEN** the old endpoint is called
- **THEN** the old response is returned
EOF
  printf '# Proposal\nScope: fixture\n' >"$repo/changes/$id/proposal.md"
  printf '# Design\n' >"$repo/changes/$id/design.md"
  printf '# Tasks\n- [x] Fixture\n' >"$repo/changes/$id/tasks.md"
  python3 - "$repo" "$id" <<'PY'
import hashlib
import hmac
import json
import os
import subprocess
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
change_id = sys.argv[2]
spec = (repo / "specs/core.md").read_text()
def block(title, text):
    marker = f"### Requirement: {title}\n"
    start = text.index(marker)
    end = text.find("\n### Requirement: ", start + len(marker))
    return text[start:] if end == -1 else text[start:end]
base = block("Existing behavior", spec).strip()
meta = {
    "change_id": change_id,
    "target": "specs/core.md",
    "requirements": {
        "Existing behavior": {
            "base_sha256": hashlib.sha256(base.encode()).hexdigest(),
            "base": base,
        },
        "Obsolete behavior": {
            "base_sha256": hashlib.sha256(block("Obsolete behavior", spec).strip().encode()).hexdigest(),
        },
    },
}
(repo / "changes" / change_id / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
report_text = "# Verification Report\n**Status:** Ready for human approval\n"
report_text += os.environ.get("RECONCILE_TEST_REPORT_EXTRA", "")
(repo / "changes" / change_id / "verification-report.md").write_text(report_text)
subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
subprocess.run(["git", "-C", str(repo), "commit", "-qm", "fixture"], check=True)
verification_commit = subprocess.check_output(
    ["git", "-C", str(repo), "rev-parse", "HEAD"], text=True
).strip()
evidence = repo / ".git" / "cook-verify-evidence" / change_id
secret = "test-secret"
report = repo / "changes" / change_id / "verification-report.md"
report_sha = hashlib.sha256(report.read_bytes()).hexdigest()
event = {
    "event": "human-checkpoint",
    "command": f"approve-verification changes/{change_id}",
    "approver": "engineer@example.com",
    "verification_commit": verification_commit,
    "report_sha256": report_sha,
}
payload = json.dumps(event, sort_keys=True, separators=(",", ":")).encode()
event["signature"] = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
attestation = evidence / "approval-event.json"
attestation.write_text(json.dumps(event, indent=2) + "\n")
approval = {
    "command": event["command"],
    "approver": event["approver"],
    "approved_at": "2026-09-21T10:00:00Z",
    "verification_commit": verification_commit,
    "report_sha256": report_sha,
    "host_attestation_path": str(attestation),
    "host_attestation_sha256": hashlib.sha256(attestation.read_bytes()).hexdigest(),
}
(repo / "changes" / change_id / "verification-approval.json").write_text(
    json.dumps(approval, indent=2) + "\n"
)
subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
subprocess.run(["git", "-C", str(repo), "commit", "-qm", "approval"], check=True)
PY
  git -C "$repo" config core.hooksPath /dev/null
}

run_engine() {
  local repo="$1" action="$2" id="$3"
  (cd "$repo" && SDD_VERIFY_ATTESTATION_KEY=test-secret bash .spec-framework/bin/reconcile_engine.sh "$action" "$id")
}

test_missing_receipt_blocks_sync() {
  local repo="$TMP/missing"
  mkdir -p "$repo/.spec-framework/bin" "$repo/specs" "$repo/changes/CHG-2026-042"
  cp "$ENGINE" "$repo/.spec-framework/bin/reconcile_engine.sh"
  chmod +x "$repo/.spec-framework/bin/reconcile_engine.sh"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name Test
  printf '# Core\n' >"$repo/specs/core.md"
  printf 'Target Domain: specs/core.md\n' >"$repo/changes/CHG-2026-042/delta-spec.md"
  git -C "$repo" add .
  git -C "$repo" commit -qm fixture
  if (cd "$repo" && bash .spec-framework/bin/reconcile_engine.sh sync-spec CHG-2026-042) 2>"$TMP/missing.err"; then
    fail "sync succeeded without verification receipt"
  fi
  assert_contains "$TMP/missing.err" "verification-report.md"
}

test_sync_and_idempotence() {
  local repo="$TMP/sync"
  new_repo "$repo"
  run_engine "$repo" sync-spec CHG-2026-042
  assert_contains "$repo/specs/core.md" "### Requirement: New behavior"
  assert_contains "$repo/specs/core.md" "records the event"
  assert_not_contains "$repo/specs/core.md" "### Requirement: Obsolete behavior"
  assert_contains "$repo/specs/core.md" "## Deprecations"
  cp "$repo/specs/core.md" "$TMP/sync.once"
  run_engine "$repo" sync-spec CHG-2026-042
  if ! cmp -s "$TMP/sync.once" "$repo/specs/core.md"; then
    diff -u "$TMP/sync.once" "$repo/specs/core.md" >&2 || true
    fail "sync is not idempotent"
  fi
}

test_conflict_preserves_live_spec() {
  local repo="$TMP/conflict"
  new_repo "$repo"
  python3 - "$repo/specs/core.md" <<'PY'
from pathlib import Path
path = Path(__import__("sys").argv[1])
text = path.read_text().replace("- **THEN** the system accepts it\n", "- **THEN** the system writes a different event\n")
path.write_text(text)
PY
  cp "$repo/specs/core.md" "$TMP/conflict.before"
  if run_engine "$repo" sync-spec CHG-2026-042 >"$TMP/conflict.out" 2>&1; then
    fail "semantic conflict was silently merged"
  fi
  cmp -s "$TMP/conflict.before" "$repo/specs/core.md" || fail "conflict changed live spec"
  assert_contains "$TMP/conflict.out" "conflict"
}

test_disjoint_semantic_merge() {
  local repo="$TMP/disjoint"
  new_repo "$repo"
  python3 - "$repo/changes/CHG-2026-042/delta-spec.md" "$repo/specs/core.md" <<'PY'
from pathlib import Path
import sys
delta = Path(sys.argv[1])
spec = Path(sys.argv[2])
delta_text = delta.read_text()
delta_text = delta_text.replace(
    "The system accepts the original input and records an audit event.",
    "The system accepts the original input.",
).replace(
    "- **THEN** the system accepts it and records the event",
    "- **THEN** the system accepts it",
    1,
)
delta.write_text(delta_text)
spec_text = spec.read_text().replace(
    "- **THEN** the system accepts it\n",
    "- **THEN** the system writes a live-only event\n",
    1,
)
spec.write_text(spec_text)
PY
  run_engine "$repo" sync-spec CHG-2026-042
  assert_contains "$repo/specs/core.md" "writes a live-only event"
  assert_contains "$repo/specs/core.md" "accepts it and records the event"
}

test_deleted_scenario_returns_conflict() {
  local repo="$TMP/deleted-scenario"
  new_repo "$repo"
  python3 - "$repo/changes/CHG-2026-042/delta-spec.md" "$repo/specs/core.md" <<'PY'
from pathlib import Path
import re
import sys
path = Path(sys.argv[1])
spec = Path(sys.argv[2])
text = path.read_text()
text = re.sub(r"\n#### Scenario: Other input\n.*?(?=\n## REMOVED Requirements)", "", text, count=1, flags=re.S)
path.write_text(text)
spec.write_text(spec.read_text().replace("- **THEN** the system accepts it\n", "- **THEN** the system changes the live behavior\n", 1))
PY
  cp "$repo/specs/core.md" "$TMP/deleted-scenario.before"
  if run_engine "$repo" sync-spec CHG-2026-042 >"$TMP/deleted-scenario.out" 2>&1; then
    fail "deleted scenario was silently accepted"
  fi
  assert_contains "$TMP/deleted-scenario.out" "conflict"
  cmp -s "$TMP/deleted-scenario.before" "$repo/specs/core.md" || fail "deleted scenario changed live spec"
}

test_critical_finding_in_table_blocks_sync() {
  local repo="$TMP/critical-table"
  RECONCILE_TEST_REPORT_EXTRA='| Review finding | Severity | Status |\n|---|---|---|\n| reviewer | CRITICAL | open |\n' new_repo "$repo"
  if run_engine "$repo" sync-spec CHG-2026-042 >"$TMP/critical-table.out" 2>&1; then
    fail "critical table finding was ignored"
  fi
  assert_contains "$TMP/critical-table.out" "CRITICAL"
}

test_open_important_finding_is_not_hidden_by_clear_critical() {
  local repo="$TMP/important-with-clear-critical"
  RECONCILE_TEST_REPORT_EXTRA='No CRITICAL findings; IMPORTANT finding remains open\n' new_repo "$repo"
  if run_engine "$repo" sync-spec CHG-2026-042 >"$TMP/important-with-clear-critical.out" 2>&1; then
    fail "open important finding was ignored"
  fi
  assert_contains "$TMP/important-with-clear-critical.out" "IMPORTANT"
}

test_invalid_fingerprint_blocks_sync() {
  local repo="$TMP/invalid-fingerprint"
  new_repo "$repo"
  python3 - "$repo/changes/CHG-2026-042/meta.json" <<'PY'
import json
from pathlib import Path
import sys
path = Path(sys.argv[1])
value = json.loads(path.read_text())
value["requirements"]["Existing behavior"]["base_sha256"] = "not-a-sha256"
path.write_text(json.dumps(value) + "\n")
PY
  if run_engine "$repo" sync-spec CHG-2026-042 >"$TMP/invalid-fingerprint.out" 2>&1; then
    fail "invalid fingerprint was accepted"
  fi
  assert_contains "$TMP/invalid-fingerprint.out" "base_sha256"
}

test_missing_removed_fingerprint_blocks_sync() {
  local repo="$TMP/missing-removed-fingerprint"
  new_repo "$repo"
  python3 - "$repo/specs/core.md" "$repo/changes/CHG-2026-042/meta.json" <<'PY'
import json
from pathlib import Path
import re
import sys
spec = Path(sys.argv[1])
meta = Path(sys.argv[2])
text = spec.read_text()
text = re.sub(r"\n### Requirement: Obsolete behavior\n.*", "\n", text, count=1, flags=re.S)
spec.write_text(text)
value = json.loads(meta.read_text())
del value["requirements"]["Obsolete behavior"]
meta.write_text(json.dumps(value) + "\n")
PY
  if run_engine "$repo" sync-spec CHG-2026-042 >"$TMP/missing-removed-fingerprint.out" 2>&1; then
    fail "removed requirement without fingerprint was accepted"
  fi
  assert_contains "$TMP/missing-removed-fingerprint.out" "fingerprint"
}

test_duplicate_requirement_title_blocks_sync() {
  local repo="$TMP/duplicate-title"
  new_repo "$repo"
  python3 - "$repo/changes/CHG-2026-042/delta-spec.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
duplicate = "### Requirement: New behavior\nA conflicting duplicate.\n\n#### Scenario: Duplicate\n- **WHEN** reached\n- **THEN** it conflicts\n\n"
path.write_text(text.replace("## MODIFIED Requirements", duplicate + "## MODIFIED Requirements", 1))
PY
  if run_engine "$repo" sync-spec CHG-2026-042 >"$TMP/duplicate-title.out" 2>&1; then
    fail "duplicate requirement title was accepted"
  fi
  assert_contains "$TMP/duplicate-title.out" "duplicate"
}

test_persist_adr_is_idempotent() {
  local repo="$TMP/adr"
  new_repo "$repo"
  cat >"$repo/changes/CHG-2026-042/design.md" <<'EOF'
# Design

### Decision ADR-01: Keep the canonical spec in Git
Decision: keep the canonical spec in Git.
Rejected: an external wiki.
Rationale: the code and contract share history.
EOF
  run_engine "$repo" persist-adr CHG-2026-042
  local adr=""
  for candidate in "$repo"/specs/adr/ADR-*.md; do
    [[ -f "$candidate" ]] && adr="$candidate" && break
  done
  assert_file "$adr"
  assert_contains "$adr" "Keep the canonical spec in Git"
  cp "$adr" "$TMP/adr.once"
  run_engine "$repo" persist-adr CHG-2026-042
  cmp -s "$TMP/adr.once" "$adr" || fail "ADR persistence is not idempotent"
}

test_archive_requires_adr_persistence() {
  local repo="$TMP/missing-adr"
  new_repo "$repo"
  cat >"$repo/changes/CHG-2026-042/design.md" <<'EOF'
# Design

### Decision ADR-01: Require an ADR
Decision: persist this decision.
EOF
  run_engine "$repo" sync-spec CHG-2026-042
  if run_engine "$repo" archive CHG-2026-042 >"$TMP/missing-adr.out" 2>&1; then
    fail "archive skipped ADR persistence"
  fi
  assert_contains "$TMP/missing-adr.out" "persist-adr"
}

test_archive_requires_audit_artifacts() {
  local repo="$TMP/missing-audit-artifact"
  new_repo "$repo"
  rm "$repo/changes/CHG-2026-042/tasks.md"
  run_engine "$repo" sync-spec CHG-2026-042
  if run_engine "$repo" archive CHG-2026-042 >"$TMP/missing-audit-artifact.out" 2>&1; then
    fail "archive accepted incomplete audit artifacts"
  fi
  assert_contains "$TMP/missing-audit-artifact.out" "tasks.md"
}

test_archive_and_safe_teardown() {
  local repo="$TMP/archive" worktree="$TMP/archive/.worktrees/CHG-2026-042"
  new_repo "$repo"
  mkdir -p "$repo/.worktrees"
  git -C "$repo" worktree add -q -b feature/CHG-2026-042 "$worktree" HEAD
  run_engine "$repo" sync-spec CHG-2026-042
  run_engine "$repo" archive CHG-2026-042
  assert_dir "$repo/changes/archives"
  local archived=""
  for candidate in "$repo"/changes/archives/*; do
    [[ -d "$candidate" ]] && archived="$candidate" && break
  done
  assert_dir "$archived"
  assert_file "$archived/verification-report.md"
  run_engine "$repo" teardown CHG-2026-042
  [[ ! -e "$worktree" ]] || fail "worktree was not removed"
  ! git -C "$repo" show-ref --verify --quiet refs/heads/feature/CHG-2026-042 || fail "branch was not removed"
}

test_dirty_worktree_blocks_teardown() {
  local repo="$TMP/dirty" worktree="$TMP/dirty/.worktrees/CHG-2026-042"
  new_repo "$repo"
  mkdir -p "$repo/.worktrees"
  git -C "$repo" worktree add -q -b feature/CHG-2026-042 "$worktree" HEAD
  run_engine "$repo" sync-spec CHG-2026-042
  run_engine "$repo" archive CHG-2026-042
  printf 'unreviewed\n' >"$worktree/unreviewed.txt"
  if run_engine "$repo" teardown CHG-2026-042 >"$TMP/dirty.out" 2>&1; then
    fail "dirty worktree was removed"
  fi
  [[ -d "$worktree" ]] || fail "dirty worktree was destroyed"
  assert_contains "$TMP/dirty.out" "dirty"
}

test_missing_receipt_blocks_sync
test_sync_and_idempotence
test_conflict_preserves_live_spec
test_disjoint_semantic_merge
test_deleted_scenario_returns_conflict
test_critical_finding_in_table_blocks_sync
test_open_important_finding_is_not_hidden_by_clear_critical
test_invalid_fingerprint_blocks_sync
test_missing_removed_fingerprint_blocks_sync
test_duplicate_requirement_title_blocks_sync
test_persist_adr_is_idempotent
test_archive_requires_adr_persistence
test_archive_requires_audit_artifacts
test_archive_and_safe_teardown
test_dirty_worktree_blocks_teardown
printf 'PASS: reconcile engine tests\n'
