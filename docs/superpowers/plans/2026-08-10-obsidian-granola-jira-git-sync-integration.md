# Obsidian + Granola integration for a local jira-git-sync copy — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `thebous-os` its own working copy of the `jira-git-sync` command set (copied once from `TheBous/github-jira-slack-claudecode`, never pushed back to it), with every workflow logging a short trace into the user's Obsidian vault, and an optional link to the matching Granola meeting note.

**Architecture:** `commands/*.md` are prompt-instruction files read on demand by an agent (not compiled code) — each gets one extra numbered step added, pointing at a new shared reference (`references/obsidian-log.md`) and calling deterministic bash helper functions added to `scripts/helpers.sh`. The helpers, not the prose, own the actual file-writing logic, so they can be unit-tested with a plain bash assertion script.

**Tech Stack:** Bash (helpers + command steps), Markdown (commands/references), JSON5 (evals), Claude Code plugin conventions (`CLAUDE_PLUGIN_DATA`, `CLAUDE_PLUGIN_ROOT`).

## Global Constraints

- Vault layout is fixed: `Dev/Tickets/<KEY>/{plan,review,address-review,calls}.md` + `Dev/Daily/<YYYY-MM-DD>.md`. Ticket files get frontmatter (`ticket`, `pr`, `status`, `date`); writes are **additive** (append a dated section or bullet, never truncate/overwrite).
- Every Obsidian/Granola step is **optional and non-blocking**: if `OBSIDIAN_VAULT_PATH` is unset, the directory doesn't exist, or no Jira ticket was matched, skip silently — never fail or warn-spam the primary workflow (branch creation, PR review, etc.).
- The source repo `TheBous/github-jira-slack-claudecode` is never modified, branched, or pushed to. Everything happens inside `thebous-os`.
- The copied plugin is renamed from `jira-git-sync` to `thebous-jira-git-sync` (marketplace name `thebous-os`) specifically to avoid colliding with the already-installed `jira-git-sync` plugin elsewhere on this machine.
- Target platform is macOS/Darwin. Avoid GNU-only flags (e.g. `sed -i` without a backup suffix behaves differently on BSD sed) — use the `mktemp` + redirect + `mv` pattern instead, matching the portable style already used for JSON edits with `jq`.
- Granola sync itself is out of scope — it's handled entirely by the user's own community Obsidian plugin ([dannymcc/Granola-to-Obsidian](https://github.com/dannymcc/Granola-to-Obsidian)) syncing into `<vault>/Granola/`. This plan only reads that folder to offer links; it never talks to Granola directly.
- Full design context: [`docs/superpowers/specs/2026-08-10-obsidian-jira-git-sync-integration-design.md`](../specs/2026-08-10-obsidian-jira-git-sync-integration-design.md).

---

### Task 1: Copy and rename the jira-git-sync file set into thebous-os

**Files:**
- Create: `commands/{setup,new-branch,cook,serve-up,serve-down,create-pr,review-pr,address-review,verify-resolved,merge-pr,tag,create-doc,update-doc}.md`
- Create: `references/{check-security,evaluation-rubric,jira-transition,naming-conventions-code,naming-conventions-db,naming-conventions-nextjs,run-tests}.md`
- Create: `scripts/{helpers.sh,get-viewer-threads,reopen-pr-thread,reply-to-pr-thread}`
- Create: `SKILL.md`, `AGENTS.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Create: `evals/evals.json5`, `evals/evals.json`

**Interfaces:**
- Produces: a local, byte-identical-then-renamed copy of the upstream command set at `thebous-os` root, with slash-command prefix `/thebous-jira-git-sync:` and plugin name `thebous-jira-git-sync` (marketplace `thebous-os`). Every later task edits files that exist after this task.

- [ ] **Step 1: Clone the source repo to a temp dir and copy the required paths**

```bash
cd /Users/lucvalse/lucvalse/personal/thebous-os
TMPDIR=$(mktemp -d)
git clone --depth 1 https://github.com/TheBous/github-jira-slack-claudecode "$TMPDIR/source"

mkdir -p commands references scripts evals .claude-plugin
cp "$TMPDIR/source"/commands/*.md commands/
cp "$TMPDIR/source"/references/*.md references/
cp "$TMPDIR/source"/scripts/helpers.sh "$TMPDIR/source"/scripts/get-viewer-threads \
   "$TMPDIR/source"/scripts/reopen-pr-thread "$TMPDIR/source"/scripts/reply-to-pr-thread scripts/
cp "$TMPDIR/source"/SKILL.md "$TMPDIR/source"/AGENTS.md .
cp "$TMPDIR/source"/.claude-plugin/plugin.json "$TMPDIR/source"/.claude-plugin/marketplace.json .claude-plugin/
cp "$TMPDIR/source"/evals/evals.json5 "$TMPDIR/source"/evals/evals.json evals/
chmod +x scripts/get-viewer-threads scripts/reopen-pr-thread scripts/reply-to-pr-thread
```

Deliberately **not** copied: `README.md`, `package.json`, `opencode.json`, `.gitignore`, `.opencode/`, `.codex-plugin/`, `gemini-extension.json`, `docs/agent-portability.md`, `scripts/publish-plugin.sh` — none of it applies to a personal, Claude-Code-only, non-published copy.

- [ ] **Step 2: Verify the copy landed completely, before removing the clone**

```bash
test "$(ls commands/*.md | wc -l | tr -d ' ')" = "13" && echo "OK: 13 commands"
test "$(ls references/*.md | wc -l | tr -d ' ')" = "7" && echo "OK: 7 references"
test -f SKILL.md && test -f AGENTS.md && test -f .claude-plugin/plugin.json && test -f .claude-plugin/marketplace.json && echo "OK: root files present"
test -x scripts/get-viewer-threads && test -x scripts/reopen-pr-thread && test -x scripts/reply-to-pr-thread && echo "OK: scripts executable"
diff -q "$TMPDIR/source/commands/new-branch.md" commands/new-branch.md && echo "OK: content matches source"
```

All five checks must print `OK: ...`. If `diff -q` reports a difference, re-run the `cp` for that file before continuing.

- [ ] **Step 3: Remove the temp clone**

```bash
rm -rf "$TMPDIR"
```

- [ ] **Step 4: Rename the plugin identity to avoid colliding with the already-installed `jira-git-sync` plugin**

```bash
OLD_NAME="jira-git-sync"
NEW_NAME="thebous-jira-git-sync"

# Slash-command invocation prefix: /jira-git-sync:xyz -> /thebous-jira-git-sync:xyz
for f in $(grep -rl "/${OLD_NAME}:" commands SKILL.md AGENTS.md 2>/dev/null); do
  sed "s|/${OLD_NAME}:|/${NEW_NAME}:|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# SKILL.md frontmatter name field
sed "s/^name: ${OLD_NAME}\$/name: ${NEW_NAME}/" SKILL.md > SKILL.md.tmp && mv SKILL.md.tmp SKILL.md

# Plugin + marketplace identity (JSON, edited with jq for correctness on nested fields)
jq --arg n "$NEW_NAME" '.name = $n' .claude-plugin/plugin.json > /tmp/plugin.json.tmp && mv /tmp/plugin.json.tmp .claude-plugin/plugin.json
jq --arg mn "thebous-os" --arg pn "$NEW_NAME" \
   '.name = $mn | .plugins[0].name = $pn | .plugins[0].source = "./"' \
   .claude-plugin/marketplace.json > /tmp/marketplace.json.tmp && mv /tmp/marketplace.json.tmp .claude-plugin/marketplace.json
```

- [ ] **Step 5: Verify the rename**

```bash
! grep -rq "/jira-git-sync:" commands SKILL.md AGENTS.md && echo "OK: no leftover old prefix"
grep -q '^name: thebous-jira-git-sync$' SKILL.md && echo "OK: SKILL.md renamed"
grep -q '"name": "thebous-jira-git-sync"' .claude-plugin/plugin.json && echo "OK: plugin.json renamed"
grep -q '"name": "thebous-os"' .claude-plugin/marketplace.json && echo "OK: marketplace.json renamed"
```

All four checks must print `OK: ...`.

- [ ] **Step 6: Commit**

```bash
git add commands references scripts SKILL.md AGENTS.md .claude-plugin evals
git commit -m "$(cat <<'EOF'
feat: copy jira-git-sync command set from TheBous/github-jira-slack-claudecode

One-time snapshot, renamed to thebous-jira-git-sync to avoid colliding
with the separately-installed jira-git-sync plugin. No sync-back to the
source repo.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Add Obsidian + Granola bash helper functions to scripts/helpers.sh

**Files:**
- Modify: `scripts/helpers.sh` (append a new `## Obsidian` section at the end)
- Create: `scripts/test-obsidian-helpers.sh`

**Interfaces:**
- Consumes: nothing (pure bash, no dependency on Jira/Slack functions already in the file).
- Produces (used by Tasks 4-10 via `source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"`):
  - `obsidian_ticket_dir(vault, key)` → echoes `<vault>/Dev/Tickets/<key>`
  - `obsidian_ensure_ticket_file(vault, key, filename)` → creates the ticket dir + file with frontmatter if missing, echoes the full file path (idempotent — safe to call every time)
  - `obsidian_set_pr(file, pr_url)` → inserts or updates the `pr:` frontmatter line, idempotent
  - `obsidian_append_section(file, body)` → appends `## <timestamp>\n<body>` to the file, never truncates
  - `obsidian_append_daily(vault, line)` → creates `<vault>/Dev/Daily/<today>.md` if missing (with an `# <today>` header) and appends `- <line>`
  - `obsidian_granola_candidates(vault, days)` → lists `.md` files under `<vault>/Granola/` modified in the last `days` days (default 14), one per line, empty output (not an error) if the folder doesn't exist

- [ ] **Step 1: Write the failing test**

Create `scripts/test-obsidian-helpers.sh`:

```bash
#!/usr/bin/env bash
# Self-check for the Obsidian helper functions in helpers.sh.
# Run: bash scripts/test-obsidian-helpers.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
set +e  # helpers.sh sets -e; these checks need to keep running after a failed one

FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $desc — expected '$expected', got '$actual'"
    FAIL=1
  else
    echo "PASS: $desc"
  fi
}

assert_file_contains() {
  local desc="$1" file="$2" pattern="$3"
  if grep -qF "$pattern" "$file"; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc — '$pattern' not found in $file"
    FAIL=1
  fi
}

VAULT=$(mktemp -d)

# obsidian_ticket_dir
assert_eq "ticket_dir path" "$VAULT/Dev/Tickets/DC-443" "$(obsidian_ticket_dir "$VAULT" "DC-443")"

# obsidian_ensure_ticket_file — creates with frontmatter, idempotent
FILE=$(obsidian_ensure_ticket_file "$VAULT" "DC-443" "plan.md")
assert_eq "ensure_ticket_file path" "$VAULT/Dev/Tickets/DC-443/plan.md" "$FILE"
assert_file_contains "frontmatter has ticket key" "$FILE" "ticket: DC-443"
obsidian_ensure_ticket_file "$VAULT" "DC-443" "plan.md" >/dev/null
COUNT=$(grep -c '^ticket: DC-443$' "$FILE"); assert_eq "frontmatter not duplicated on 2nd call" "1" "$COUNT"

# obsidian_set_pr — inserts then updates idempotently
obsidian_set_pr "$FILE" "https://github.com/x/y/pull/1"
assert_file_contains "pr field set" "$FILE" "pr: https://github.com/x/y/pull/1"
obsidian_set_pr "$FILE" "https://github.com/x/y/pull/2"
PR_COUNT=$(grep -c '^pr: ' "$FILE"); assert_eq "pr field updated not duplicated" "1" "$PR_COUNT"
assert_file_contains "pr field holds latest value" "$FILE" "pr: https://github.com/x/y/pull/2"

# obsidian_append_section — appends without truncating prior content
echo "existing body line" >> "$FILE"
obsidian_append_section "$FILE" "did a thing"
assert_file_contains "prior content preserved" "$FILE" "existing body line"
assert_file_contains "new section appended" "$FILE" "did a thing"

# obsidian_append_daily — creates file, appends bullets across calls
obsidian_append_daily "$VAULT" "[[DC-443]] — branch created"
obsidian_append_daily "$VAULT" "[[DC-443]] — PR opened"
DAILY_FILE="$VAULT/Dev/Daily/$(date +%Y-%m-%d).md"
assert_file_contains "daily bullet 1" "$DAILY_FILE" "branch created"
assert_file_contains "daily bullet 2" "$DAILY_FILE" "PR opened"
BULLET_COUNT=$(grep -c '^- ' "$DAILY_FILE"); assert_eq "two bullets total" "2" "$BULLET_COUNT"

# obsidian_granola_candidates — only lists recent .md files, empty when folder missing
mkdir -p "$VAULT/Granola"
cat > "$VAULT/Granola/recent.md" <<'NOTE'
---
title: Recent Call
---
NOTE
cat > "$VAULT/Granola/old.md" <<'NOTE'
---
title: Old Call
---
NOTE
touch -d "40 days ago" "$VAULT/Granola/old.md" 2>/dev/null || touch -t "$(date -v-40d +%Y%m%d0000)" "$VAULT/Granola/old.md"

CANDIDATES=$(obsidian_granola_candidates "$VAULT" 14)
echo "$CANDIDATES" | grep -q "recent.md" && echo "PASS: recent note listed" || { echo "FAIL: recent note listed"; FAIL=1; }
echo "$CANDIDATES" | grep -q "old.md" && { echo "FAIL: old note should be excluded"; FAIL=1; } || echo "PASS: old note excluded"

rm -rf "$VAULT/Granola"
obsidian_granola_candidates "$VAULT" 14 >/dev/null && echo "PASS: missing Granola/ folder does not error"

rm -rf "$VAULT"

if [ "$FAIL" -eq 0 ]; then
  echo "All Obsidian helper checks passed."
  exit 0
else
  echo "Some Obsidian helper checks FAILED."
  exit 1
fi
```

```bash
chmod +x scripts/test-obsidian-helpers.sh
```

- [ ] **Step 2: Run it to verify it fails**

```bash
bash scripts/test-obsidian-helpers.sh
```

Expected: fails immediately with `command not found: obsidian_ticket_dir` (or similar) — the functions don't exist in `helpers.sh` yet.

- [ ] **Step 3: Implement the helper functions**

Append to `scripts/helpers.sh` (after the existing `## Utilities` section, keeping the file's own `set -euo pipefail` at the top untouched):

```bash

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
```

- [ ] **Step 4: Run the test again to verify it passes**

```bash
bash scripts/test-obsidian-helpers.sh
```

Expected: every line prints `PASS: ...` and the script exits 0 with `All Obsidian helper checks passed.`

- [ ] **Step 5: Commit**

```bash
git add scripts/helpers.sh scripts/test-obsidian-helpers.sh
git commit -m "$(cat <<'EOF'
feat: add Obsidian/Granola bash helpers with a self-check script

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Write the shared reference doc

**Files:**
- Create: `references/obsidian-log.md`

**Interfaces:**
- Consumes: the six function names from Task 2 (must match exactly).
- Produces: the doc every modified command in Tasks 4-10 points to via "Follow `references/obsidian-log.md`".

- [ ] **Step 1: Write the reference file**

Create `references/obsidian-log.md`:

```markdown
# Obsidian logging (standard pattern)

Whenever a step needs to log activity to the user's Obsidian vault or link a
Granola call, follow this pattern. It is always optional and non-blocking:
if `OBSIDIAN_VAULT_PATH` is unset, the directory doesn't exist, or there's no
Jira ticket in scope, **skip the step silently** — never fail or warn about it.

## Setup (every time)

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
```

Then guard every Obsidian write with:

```bash
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  ...
fi
```

## Vault structure

```
Dev/
  Tickets/
    <KEY>/
      plan.md            # from cook's SDD chain
      review.md          # from review-pr
      address-review.md  # from address-review
      calls.md           # wikilinks to related Granola notes
  Daily/
    <YYYY-MM-DD>.md      # index for the day
```

Every ticket file starts with frontmatter (`ticket`, `pr`, `status`, `date`).
Writes are additive: append a dated section or bullet, never truncate.

## Helper functions (`scripts/helpers.sh`)

| Function | Signature | Does |
|---|---|---|
| `obsidian_ticket_dir` | `(vault, key)` | Echoes `<vault>/Dev/Tickets/<key>` |
| `obsidian_ensure_ticket_file` | `(vault, key, filename)` | Creates the ticket dir + file with frontmatter if missing, echoes the path — idempotent |
| `obsidian_set_pr` | `(file, pr_url)` | Inserts/updates the `pr:` frontmatter line — idempotent |
| `obsidian_append_section` | `(file, body)` | Appends a dated `## <timestamp>` section |
| `obsidian_append_daily` | `(vault, line)` | Appends `- <line>` to today's daily note, creating it if needed |
| `obsidian_granola_candidates` | `(vault, days=14)` | Lists `.md` files under `<vault>/Granola/` modified in the last `days` days |

## Granola linking

Granola sync is handled entirely by the user's own
[Granola-to-Obsidian](https://github.com/dannymcc/Granola-to-Obsidian)
Obsidian community plugin, syncing into `<vault>/Granola/`. This plugin's
commands never talk to Granola directly — they only read that folder.

To offer a link (in `new-branch` and `cook`):

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ]; then
  obsidian_granola_candidates "${OBSIDIAN_VAULT_PATH}" 14
fi
```

If it lists anything, show the user up to 5 candidates (filename + the note's
`title:` frontmatter line) and ask which one (if any) relates to this ticket.
On a pick, append a line to `calls.md`:

```bash
CALLS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "calls.md")
echo "- [[Granola/<filename-without-.md>]] — linked $(date +%Y-%m-%d)" >> "$CALLS_FILE"
```

Never auto-pick a note — always wait for the user's explicit choice. If the
list is empty or the user declines, skip silently.
```

- [ ] **Step 2: Verify the reference doc matches the real function names**

```bash
DOC_FNS=$(grep -oE '`obsidian_[a-z_]+`' references/obsidian-log.md | tr -d '`' | sort -u)
CODE_FNS=$(grep -oE '^obsidian_[a-z_]+\(\)' scripts/helpers.sh | sed 's/()$//' | sort -u)
diff <(echo "$DOC_FNS") <(echo "$CODE_FNS") && echo "OK: doc and code function names match"
```

Expected: `OK: doc and code function names match` with no diff output above it. If there's a mismatch, fix the doc (not the code) unless the doc caught a real naming bug in Task 2.

- [ ] **Step 3: Commit**

```bash
git add references/obsidian-log.md
git commit -m "$(cat <<'EOF'
docs: add references/obsidian-log.md shared convention

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Add OBSIDIAN_VAULT_PATH to setup.md

**Files:**
- Modify: `commands/setup.md`

- [ ] **Step 1: Edit commands/setup.md**

Replace:
```markdown
4. **Transition IDs** — ask the user for a Jira ticket key to inspect available transitions. Use the Atlassian Rovo MCP to fetch the transition list via `getTransitionsForJiraIssue(issueKey: "<TICKET>")`, display the available statuses, then ask them to pick the IDs for:
   - **In Progress** (when a branch is created)
   - **In Review** (when a PR is created) — skip if it doesn't exist
   - **In Staging** (when the PR is merged)
   - **Done / Released** (when tagging for production)

## Saving

Create the `${CLAUDE_PLUGIN_DATA}` directory if it doesn't exist, then write the file `${CLAUDE_PLUGIN_DATA}/.env`:

```
JIRA_BASE_URL=<value>
JIRA_IN_PROGRESS_ID=<value>
JIRA_IN_REVIEW_ID=<value or empty string>
JIRA_IN_STAGING_ID=<value>
JIRA_DONE_ID=<value>
SLACK_WEBHOOK_URL=<value>
CONFLUENCE_PARENT_URL=<value or empty string>
```

Run `mkdir -p "${CLAUDE_PLUGIN_DATA}"` before writing the file. Confirm to the user that the configuration has been saved and suggest trying `/thebous-jira-git-sync:new-branch`.
```

With:
```markdown
4. **Transition IDs** — ask the user for a Jira ticket key to inspect available transitions. Use the Atlassian Rovo MCP to fetch the transition list via `getTransitionsForJiraIssue(issueKey: "<TICKET>")`, display the available statuses, then ask them to pick the IDs for:
   - **In Progress** (when a branch is created)
   - **In Review** (when a PR is created) — skip if it doesn't exist
   - **In Staging** (when the PR is merged)
   - **Done / Released** (when tagging for production)

5. **Obsidian Vault Path** (optional) — ask for the absolute path to their Obsidian vault (e.g. `/Users/me/Documents/Obsidian/myvault`), so branch/PR/review activity gets logged there automatically. Leave blank to skip — nothing breaks, the Obsidian steps in every workflow just no-op. If given, mention that call notes get linked automatically too, if they have a Granola-to-Obsidian sync plugin installed with notes landing in a `Granola/` folder at the vault root (see `references/obsidian-log.md`).

## Saving

Create the `${CLAUDE_PLUGIN_DATA}` directory if it doesn't exist, then write the file `${CLAUDE_PLUGIN_DATA}/.env`:

```
JIRA_BASE_URL=<value>
JIRA_IN_PROGRESS_ID=<value>
JIRA_IN_REVIEW_ID=<value or empty string>
JIRA_IN_STAGING_ID=<value>
JIRA_DONE_ID=<value>
SLACK_WEBHOOK_URL=<value>
CONFLUENCE_PARENT_URL=<value or empty string>
OBSIDIAN_VAULT_PATH=<value or empty string>
```

Run `mkdir -p "${CLAUDE_PLUGIN_DATA}"` before writing the file. Confirm to the user that the configuration has been saved and suggest trying `/thebous-jira-git-sync:new-branch`.
```

- [ ] **Step 2: Verify**

```bash
grep -q "Obsidian Vault Path" commands/setup.md && echo "OK: step added"
grep -q "OBSIDIAN_VAULT_PATH=<value or empty string>" commands/setup.md && echo "OK: env template updated"
```

- [ ] **Step 3: Commit**

```bash
git add commands/setup.md
git commit -m "$(cat <<'EOF'
feat: ask for Obsidian vault path during setup

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Log new-branch.md to Obsidian + offer a Granola link

**Files:**
- Modify: `commands/new-branch.md`

**Interfaces:**
- Consumes: `obsidian_ensure_ticket_file`, `obsidian_append_daily`, `obsidian_granola_candidates` (Task 2).

- [ ] **Step 1: Edit commands/new-branch.md**

Replace:
```markdown
If there was no Jira ticket, the Slack message is just: `🌿 New branch: \`<branch-name>\``

### 7. Confirmation

Show the user:
- Branch created: `<branch-name>`
- Ticket transitioned: `<KEY>` → In Progress (if applicable)
- Slack: notified
```

With:
```markdown
If there was no Jira ticket, the Slack message is just: `🌿 New branch: \`<branch-name>\``

### 7. Log to Obsidian (optional)

Only if a Jira ticket was found in step 2 (`<KEY>` is set). Follow `references/obsidian-log.md`; in short:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md" >/dev/null
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — branch \`<branch-name>\` created"
fi
```

### 8. Link a Granola call (optional)

Only if `OBSIDIAN_VAULT_PATH` is set and `<KEY>` is set. Follow `references/obsidian-log.md`'s Granola section:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"
[ -n "${OBSIDIAN_VAULT_PATH:-}" ] && obsidian_granola_candidates "${OBSIDIAN_VAULT_PATH}" 14
```

If it lists anything, show up to 5 candidates (filename + `title:` frontmatter) and ask: "Vuoi collegare una di queste call a `<KEY>`? (numero o 'no')". On a pick:

```bash
CALLS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "calls.md")
echo "- [[Granola/<chosen-filename-without-.md>]] — linked $(date +%Y-%m-%d)" >> "$CALLS_FILE"
```

If the list is empty or the user declines, skip silently.

### 9. Confirmation

Show the user:
- Branch created: `<branch-name>`
- Ticket transitioned: `<KEY>` → In Progress (if applicable)
- Slack: notified
- Obsidian: logged (or "skipped, no vault configured")
- Granola call linked: `<note>` (if applicable, otherwise omit this line)
```

- [ ] **Step 2: Verify**

```bash
grep -q "### 7. Log to Obsidian (optional)" commands/new-branch.md && echo "OK: obsidian step added"
grep -q "### 8. Link a Granola call (optional)" commands/new-branch.md && echo "OK: granola step added"
grep -q "obsidian_append_daily" commands/new-branch.md && echo "OK: helper referenced"
```

- [ ] **Step 3: Commit**

```bash
git add commands/new-branch.md
git commit -m "$(cat <<'EOF'
feat: log new-branch to Obsidian, offer a Granola call link

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Log cook.md to Obsidian + offer a Granola link

**Files:**
- Modify: `commands/cook.md`

- [ ] **Step 1: Edit commands/cook.md**

Replace:
```markdown
Wait for confirmation. For each confirmed doc, update the relevant content to reflect the implemented changes.

### 7. Final confirmation

Show the user:
- ✅ Feature/fix implemented via SDD
- ✅ Spec, design, and tasks completed and archived
- ✅ Tests: full suite green (all scripts passed)
- ✅ Documentation updated: `<list of files/pages>` (if applicable)
- → Suggest the next step: `/thebous-jira-git-sync:serve-up` to try it in a browser, or `/thebous-jira-git-sync:create-pr` to open the PR
```

With:
```markdown
Wait for confirmation. For each confirmed doc, update the relevant content to reflect the implemented changes.

### 7. Log to Obsidian (optional)

Only if a Jira ticket was found in step 1 (`<KEY>` is set). Follow `references/obsidian-log.md`. Summarize what the SDD chain produced into a few sentences (`<SDD_SUMMARY>` — not the full spec/design docs) and append it to the ticket's plan:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "<SDD_SUMMARY>"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — implemented via SDD"
fi
```

### 8. Link a Granola call (optional)

Same procedure as `new-branch.md` step 8 — offer up to 5 candidates from `obsidian_granola_candidates`, append the pick to `calls.md`. Skip silently if the folder is missing or the user declines.

### 9. Final confirmation

Show the user:
- ✅ Feature/fix implemented via SDD
- ✅ Spec, design, and tasks completed and archived
- ✅ Tests: full suite green (all scripts passed)
- ✅ Documentation updated: `<list of files/pages>` (if applicable)
- ✅ Obsidian: logged (or "skipped, no vault configured")
- ✅ Granola call linked: `<note>` (if applicable, otherwise omit this line)
- → Suggest the next step: `/thebous-jira-git-sync:serve-up` to try it in a browser, or `/thebous-jira-git-sync:create-pr` to open the PR
```

- [ ] **Step 2: Verify**

```bash
grep -q "### 7. Log to Obsidian (optional)" commands/cook.md && echo "OK: obsidian step added"
grep -q "### 8. Link a Granola call (optional)" commands/cook.md && echo "OK: granola step added"
grep -q "obsidian_append_section" commands/cook.md && echo "OK: helper referenced"
```

- [ ] **Step 3: Commit**

```bash
git add commands/cook.md
git commit -m "$(cat <<'EOF'
feat: log cook's SDD output to Obsidian, offer a Granola call link

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Log review-pr.md to Obsidian

**Files:**
- Modify: `commands/review-pr.md`

- [ ] **Step 1: Edit commands/review-pr.md**

Replace:
```markdown
If yes, follow `references/jira-transition.md` for the comment call only — **do not transition the ticket**, just post:
```
🔍 Review PR #<NUMBER>: <Approved|Changes requested|Commented> — <PR_URL>
```

### 10. Confirmation

Show the user:
- Review submitted: `<Approved|Changes requested|Commented>`
- Inline comments posted: `<count>`
- Jira comment: yes/no
```

With:
```markdown
If yes, follow `references/jira-transition.md` for the comment call only — **do not transition the ticket**, just post:
```
🔍 Review PR #<NUMBER>: <Approved|Changes requested|Commented> — <PR_URL>
```

### 10. Log to Obsidian (optional)

Only if a Jira ticket was matched in step 1 (`<KEY>` is set). Follow `references/obsidian-log.md`:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  REVIEW_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "review.md")
  obsidian_append_section "$REVIEW_FILE" "PR #<NUMBER> — <Approved|Changes requested|Commented>. <count> findings posted."
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — reviewed PR #<NUMBER>"
fi
```

### 11. Confirmation

Show the user:
- Review submitted: `<Approved|Changes requested|Commented>`
- Inline comments posted: `<count>`
- Jira comment: yes/no
- Obsidian: logged (or "skipped, no vault configured / no linked ticket")
```

- [ ] **Step 2: Verify**

```bash
grep -q "### 10. Log to Obsidian (optional)" commands/review-pr.md && echo "OK: obsidian step added"
grep -q "obsidian_ensure_ticket_file" commands/review-pr.md && echo "OK: helper referenced"
```

- [ ] **Step 3: Commit**

```bash
git add commands/review-pr.md
git commit -m "$(cat <<'EOF'
feat: log review-pr verdicts to Obsidian

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Log address-review.md to Obsidian

**Files:**
- Modify: `commands/address-review.md`

- [ ] **Step 1: Edit commands/address-review.md**

Replace:
```markdown
**Confluence**: use the MCP tool `updateConfluencePage` for each confirmed page.

If no document was found or the user declines, skip this step silently.

### 13. Confirmation

Show the user:
- Fixes applied for the review comments
- Tests: `<list of scripts>` — all green (if run)
- Replies posted on the PR with their emoji statuses
- Documentation updated: `<list of files/pages>` (if applicable)
- Suggest pushing the branch with `git push`
```

With:
```markdown
**Confluence**: use the MCP tool `updateConfluencePage` for each confirmed page.

If no document was found or the user declines, skip this step silently.

### 13. Log to Obsidian (optional)

Only if the PR's branch matched a Jira key in step 1 (`<KEY>` is set). Follow `references/obsidian-log.md`. Summarize the resolved items (`<RESOLUTION_SUMMARY>`, e.g. "3 comments addressed: 2 fixed, 1 outdated"):

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  ADDRESS_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "address-review.md")
  obsidian_append_section "$ADDRESS_FILE" "<RESOLUTION_SUMMARY>"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — addressed review comments"
fi
```

### 14. Confirmation

Show the user:
- Fixes applied for the review comments
- Tests: `<list of scripts>` — all green (if run)
- Replies posted on the PR with their emoji statuses
- Documentation updated: `<list of files/pages>` (if applicable)
- Obsidian: logged (or "skipped, no vault configured / no linked ticket")
- Suggest pushing the branch with `git push`
```

- [ ] **Step 2: Verify**

```bash
grep -q "### 13. Log to Obsidian (optional)" commands/address-review.md && echo "OK: obsidian step added"
grep -q "obsidian_append_section" commands/address-review.md && echo "OK: helper referenced"
```

- [ ] **Step 3: Commit**

```bash
git add commands/address-review.md
git commit -m "$(cat <<'EOF'
feat: log address-review resolutions to Obsidian

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Record the PR link in Obsidian from create-pr.md

**Files:**
- Modify: `commands/create-pr.md`

**Interfaces:**
- Consumes: `obsidian_set_pr` (Task 2) — this is the only command that fills the `pr:` frontmatter field introduced by the design.

- [ ] **Step 1: Edit commands/create-pr.md — record the PR link right after it's created**

Replace:
```markdown
  -d "{\"title\":\"<generated title>\",\"body\":\"<generated description>\",\"head\":\"$(git branch --show-current)\",\"base\":\"main\"}" \
  | jq '{number, url: .html_url}'
```

### 7. Jira comment (always)
```

With:
```markdown
  -d "{\"title\":\"<generated title>\",\"body\":\"<generated description>\",\"head\":\"$(git branch --show-current)\",\"base\":\"main\"}" \
  | jq '{number, url: .html_url}'
```

### 6a. Log the PR link to Obsidian (optional)

Only if a Jira ticket was found in step 2 (`<KEY>` is set). Follow `references/obsidian-log.md`:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_set_pr "$PLAN_FILE" "<PR_URL>"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — PR opened: <PR_URL>"
fi
```

### 7. Jira comment (always)
```

- [ ] **Step 2: Edit commands/create-pr.md — add the Obsidian line to the final confirmation**

Replace:
```markdown
### 11. Confirmation

Show the user:
- PR created: `<PR_URL>`
- Jira comment: left on `<KEY>` (if ticket found)
- Ticket `<KEY>` → In Review (if transition succeeded; otherwise note it was skipped)
- Slack: notified (or "notification failed, but PR and comment are done")
- → Suggest the next step: `/thebous-jira-git-sync:review-pr` to get it reviewed
```

With:
```markdown
### 11. Confirmation

Show the user:
- PR created: `<PR_URL>`
- Jira comment: left on `<KEY>` (if ticket found)
- Ticket `<KEY>` → In Review (if transition succeeded; otherwise note it was skipped)
- Slack: notified (or "notification failed, but PR and comment are done")
- Obsidian: PR link recorded (or "skipped, no vault configured / no linked ticket")
- → Suggest the next step: `/thebous-jira-git-sync:review-pr` to get it reviewed
```

- [ ] **Step 3: Verify**

```bash
grep -q "### 6a. Log the PR link to Obsidian (optional)" commands/create-pr.md && echo "OK: obsidian step added"
grep -q "obsidian_set_pr" commands/create-pr.md && echo "OK: helper referenced"
grep -q "Obsidian: PR link recorded" commands/create-pr.md && echo "OK: confirmation updated"
```

- [ ] **Step 4: Commit**

```bash
git add commands/create-pr.md
git commit -m "$(cat <<'EOF'
feat: record the PR link in the ticket's Obsidian frontmatter

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 10: Link Confluence docs to Obsidian from create-doc.md and update-doc.md

**Files:**
- Modify: `commands/create-doc.md`
- Modify: `commands/update-doc.md`

Neither command currently derives a Jira key — both need it added before the Obsidian step can know which ticket to link to.

- [ ] **Step 1: Edit commands/create-doc.md — detect the ticket**

Replace:
```markdown
If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-jira-git-sync:setup` first.

### 2. Identify the target
```

With:
```markdown
If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-jira-git-sync:setup` first.

### 1a. Detect a linked Jira ticket (optional)

Extract a Jira key from the current branch name (pattern `[A-Za-z]+-[0-9]+`, case-insensitive), uppercased (e.g. `dc-443` → `DC-443`), same rule used in `cook.md`. Store it as `<KEY>` if found — used later to link this doc into Obsidian. If no key is found, `<KEY>` stays empty and the Obsidian step at the end is skipped.

### 2. Identify the target
```

- [ ] **Step 2: Edit commands/create-doc.md — log after publishing**

Replace:
```markdown
### 7. Publish to Confluence

Use the MCP tool `createConfluencePage` with:
- `spaceId`: SPACE_KEY extracted in step 5
- `parentId`: PAGE_ID extracted in step 5
- `title`: title confirmed by the user
- `body`: HTML composed in step 6
- `contentFormat`: `"html"`

### 8. Confirmation

Show the user:
- Page created: `<title>` → `<page URL>`
```

With:
```markdown
### 7. Publish to Confluence

Use the MCP tool `createConfluencePage` with:
- `spaceId`: SPACE_KEY extracted in step 5
- `parentId`: PAGE_ID extracted in step 5
- `title`: title confirmed by the user
- `body`: HTML composed in step 6
- `contentFormat`: `"html"`

### 7a. Log to Obsidian (optional)

Only if `<KEY>` was found in step 1a. Follow `references/obsidian-log.md`:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ] && [ -n "<KEY>" ]; then
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "Confluence page created: [<title>](<page URL>)"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — Confluence page created: <title>"
fi
```

### 8. Confirmation

Show the user:
- Page created: `<title>` → `<page URL>`
- Obsidian: logged (or "skipped, no vault configured / no linked ticket")
```

- [ ] **Step 3: Edit commands/update-doc.md — detect the ticket**

Replace:
```markdown
If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-jira-git-sync:setup` first.

### 2. Identify the page
```

With:
```markdown
If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-jira-git-sync:setup` first.

### 1a. Detect a linked Jira ticket (optional)

Extract a Jira key from the current branch name (pattern `[A-Za-z]+-[0-9]+`, case-insensitive), uppercased (e.g. `dc-443` → `DC-443`), same rule used in `cook.md`. Store it as `<KEY>` if found — used later to link this doc into Obsidian. If no key is found, `<KEY>` stays empty and the Obsidian step at the end is skipped.

### 2. Identify the page
```

- [ ] **Step 4: Edit commands/update-doc.md — log after updating**

Replace:
```markdown
### 5. Apply the changes

Use the MCP tool `updateConfluencePage` with the page ID and the updated content (`contentFormat: "html"`).

For tag changes: update the Tags row directly in the metadata table in the HTML body.

### 6. Confirmation

Show the user:
- Page updated: `<title>` → `<page URL>`
```

With:
```markdown
### 5. Apply the changes

Use the MCP tool `updateConfluencePage` with the page ID and the updated content (`contentFormat: "html"`).

For tag changes: update the Tags row directly in the metadata table in the HTML body.

### 5a. Log to Obsidian (optional)

Only if `<KEY>` was found in step 1a. Follow `references/obsidian-log.md`:

```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
source "${CLAUDE_PLUGIN_ROOT}/scripts/helpers.sh"

if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ] && [ -n "<KEY>" ]; then
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "Confluence page updated: [<title>](<page URL>)"
  obsidian_append_daily "${OBSIDIAN_VAULT_PATH}" "[[<KEY>]] — Confluence page updated: <title>"
fi
```

### 6. Confirmation

Show the user:
- Page updated: `<title>` → `<page URL>`
- Obsidian: logged (or "skipped, no vault configured / no linked ticket")
```

- [ ] **Step 5: Verify**

```bash
grep -q "### 1a. Detect a linked Jira ticket" commands/create-doc.md && echo "OK: create-doc ticket detection"
grep -q "### 7a. Log to Obsidian (optional)" commands/create-doc.md && echo "OK: create-doc obsidian step"
grep -q "### 1a. Detect a linked Jira ticket" commands/update-doc.md && echo "OK: update-doc ticket detection"
grep -q "### 5a. Log to Obsidian (optional)" commands/update-doc.md && echo "OK: update-doc obsidian step"
```

- [ ] **Step 6: Commit**

```bash
git add commands/create-doc.md commands/update-doc.md
git commit -m "$(cat <<'EOF'
feat: detect linked ticket and log Confluence doc changes to Obsidian

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 11: Add eval entries for the new Obsidian/Granola behavior

**Files:**
- Modify: `evals/evals.json5`

- [ ] **Step 1: Append eval entries**

Open `evals/evals.json5` and add these entries to the `evals` array (keep incrementing `id` from whatever the last existing entry is):

```json5
{
  id: 14,
  command: "new-branch",
  prompt: "Create a new branch for ticket DC-443, OBSIDIAN_VAULT_PATH configured and Granola/ has 2 recent notes",
  expected_output: "Creates the branch, transitions DC-443, then creates Dev/Tickets/DC-443/plan.md, appends today's daily note, offers the 2 recent Granola notes and links the user's pick into calls.md",
  expectations: [
    "Does not write to Obsidian before the branch and Jira transition succeed",
    "Never auto-picks a Granola note without explicit user confirmation",
    "Skips both Obsidian steps silently when OBSIDIAN_VAULT_PATH is unset"
  ]
},
{
  id: 15,
  command: "cook",
  prompt: "Implement the fix on branch dc-500-fix-login with OBSIDIAN_VAULT_PATH configured",
  expected_output: "After SDD completes and tests pass, appends a short summary section to Dev/Tickets/DC-500/plan.md and a daily note entry",
  expectations: [
    "The Obsidian section is a short summary, not the full SDD documents",
    "Skips silently when OBSIDIAN_VAULT_PATH is unset"
  ]
},
{
  id: 16,
  command: "review-pr",
  prompt: "Review PR #128 on branch dc-600-x, OBSIDIAN_VAULT_PATH configured",
  expected_output: "After the review is submitted, appends the verdict summary to Dev/Tickets/DC-600/review.md and a daily note entry",
  expectations: [
    "Only logs after the user has confirmed and the review was actually submitted",
    "Skips silently when no Jira key was matched from the branch"
  ]
},
{
  id: 17,
  command: "address-review",
  prompt: "Address the review comments on the open PR for branch dc-700-y, OBSIDIAN_VAULT_PATH configured",
  expected_output: "After all comments are resolved, appends a resolution summary to Dev/Tickets/DC-700/address-review.md and a daily note entry",
  expectations: [
    "Logs once at the end of the cycle, not per-comment",
    "Skips silently when no Jira key was matched from the branch"
  ]
},
{
  id: 18,
  command: "create-pr",
  prompt: "Open a PR for branch dc-800-z, OBSIDIAN_VAULT_PATH configured",
  expected_output: "After the PR is created, sets the pr: frontmatter field on Dev/Tickets/DC-800/plan.md to the new PR URL and appends a daily note entry",
  expectations: [
    "Updates the existing pr: field in place rather than duplicating it if called again",
    "Skips silently when no Jira key was matched from the branch"
  ]
},
{
  id: 19,
  command: "create-doc",
  prompt: "Document src/auth/login.ts on branch dc-900-w, OBSIDIAN_VAULT_PATH configured",
  expected_output: "Derives DC-900 from the branch, publishes the Confluence page, then appends the page link to Dev/Tickets/DC-900/plan.md and a daily note entry",
  expectations: [
    "Never fails the Confluence publish step because no ticket was found — the doc step and the Obsidian step are independent",
    "Skips the Obsidian step silently when no branch ticket key is found"
  ]
},
{
  id: 20,
  command: "setup",
  prompt: "Run setup and leave the Obsidian vault path blank",
  expected_output: "Writes OBSIDIAN_VAULT_PATH= (empty) to .env without erroring, and confirms the config was saved",
  expectations: [
    "Setup completes successfully with an empty Obsidian path",
    "Mentions that leaving it blank just skips the Obsidian steps everywhere else"
  ]
}
```

- [ ] **Step 2: Verify the file is still valid JSON5**

```bash
node -e "require('json5').parse(require('fs').readFileSync('evals/evals.json5', 'utf8'))" 2>/dev/null && echo "OK: valid JSON5" \
  || node -e "console.log(require('fs').readFileSync('evals/evals.json5','utf8').replace(/\/\/.*$/gm,'').replace(/,(\s*[}\]])/g,'\$1'))" > /tmp/evals-stripped.json && python3 -c "import json; json.load(open('/tmp/evals-stripped.json')); print('OK: valid JSON after comment/trailing-comma strip')"
```

If neither check is available in the environment, at minimum confirm brace/bracket balance:

```bash
python3 - <<'EOF'
import re
text = open('evals/evals.json5').read()
text = re.sub(r'//.*', '', text)
assert text.count('{') == text.count('}'), "unbalanced braces"
assert text.count('[') == text.count(']'), "unbalanced brackets"
print("OK: braces and brackets balanced")
EOF
```

- [ ] **Step 3: Commit**

```bash
git add evals/evals.json5
git commit -m "$(cat <<'EOF'
test: add evals for the Obsidian/Granola logging behavior

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 12: Structural smoke test + manual live-test instructions

**Files:**
- None created/modified — verification only.

- [ ] **Step 1: Run a full structural smoke test across every touched command**

```bash
cd /Users/lucvalse/lucvalse/personal/thebous-os
FAIL=0
check() { grep -q "$2" "$1" && echo "OK: $1 — $3" || { echo "MISSING: $1 — $3"; FAIL=1; }; }

check commands/setup.md "OBSIDIAN_VAULT_PATH" "asks for vault path"
check commands/new-branch.md "obsidian_append_daily" "logs to daily note"
check commands/new-branch.md "obsidian_granola_candidates" "offers Granola link"
check commands/cook.md "obsidian_append_section" "logs plan summary"
check commands/review-pr.md "obsidian_ensure_ticket_file" "logs review"
check commands/address-review.md "obsidian_append_section" "logs resolution"
check commands/create-pr.md "obsidian_set_pr" "records PR link"
check commands/create-doc.md "obsidian_append_section" "links Confluence doc"
check commands/update-doc.md "obsidian_append_section" "links Confluence doc"
check references/obsidian-log.md "obsidian_granola_candidates" "documents Granola helper"

bash scripts/test-obsidian-helpers.sh || FAIL=1

if [ "$FAIL" -eq 0 ]; then echo "ALL STRUCTURAL CHECKS PASSED"; else echo "SOME CHECKS FAILED — see MISSING lines above"; fi
```

Expected: every line prints `OK: ...`, the helper test prints `All Obsidian helper checks passed.`, and the final line is `ALL STRUCTURAL CHECKS PASSED`.

- [ ] **Step 2: Manual live verification (not automatable in this environment — do this yourself afterward)**

This plan's execution cannot install a Claude Code plugin (that requires an interactive `/plugin` session) or exercise real Jira/Slack/Confluence credentials. Once this plan is merged, do the following yourself, once:

1. In an interactive Claude Code session: `/plugin marketplace add /Users/lucvalse/lucvalse/personal/thebous-os` then `/plugin install thebous-jira-git-sync@thebous-os`.
2. Run `/thebous-jira-git-sync:setup`, filling in real Jira/Slack/Confluence values and your vault path (`/Users/lucvalse/Documents/Obsidian/lucvalse`).
3. Pick a real or throwaway Jira ticket and run `/thebous-jira-git-sync:new-branch`.
4. Confirm `Dev/Tickets/<KEY>/plan.md` and `Dev/Daily/<today>.md` were created in the vault with the expected content.
5. If you have the Granola-to-Obsidian plugin installed with notes in `Granola/`, confirm the linking prompt appeared and, if you picked one, that `calls.md` got the wikilink.

- [ ] **Step 3: Commit the plan's completion note (if any stray files were left by testing)**

```bash
git status --short
```

If clean, nothing to commit — this task is verification-only.
