---
name: cook-execute
description: Use when an approved changes/{CHG_ID}/tasks.md contains pending implementation tasks that must be executed with strict TDD inside an isolated Git worktree
allowed-tools: "Read,Write,Edit,Glob,Grep,Bash(git:*),Bash(bash .spec-framework/bin/*)"
version: 1.1.0
license: MIT
compatibility: "Universal Agent Skills (Claude Code, OpenAI Codex, OpenCode)"
metadata:
  workflow: spec-driven-development
  phase: execution
  discipline: test-driven-development
---

# Cook Execute

## Overview

Execute one approved task at a time from `tasks.md` using a fresh context,
strict Red-Green-Refactor, exact file boundaries, and observable gates. This
skill changes code only inside `.worktrees/{CHG_ID}` and never starts a task
whose dependencies or approval gates are incomplete. The enforcement wrapper
also locks the primary working tree, runs required quality checks, and commits
the completed task before updating its checkbox.

## Non-Negotiable Rules

- **NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.** If production code was
  written before RED, stop and report the violation; never delete or reset
  automatically.
- Use only the current task's `Allowed Paths`; reject every other changed path.
- Treat `Forbidden Paths` as a hard boundary, including generated files and
  configuration changes.
- never run eval; pass the explicitly approved test command to the isolated
  child shell used by `enforce_tdd.sh`.
- A passing command is evidence only when its exit status and output are
  recorded. A failed RED command must contain the exact assertion marker
  declared by the task, not merely a generic `failed` or `assert` string.
- Commit one completed task atomically, then mark its checkbox `[x]` only after
  static analysis, mutation testing, the global suite, and independent review
  pass.

## Context Boundary

Run each task in a fresh context, preferably with `context: fork`. Pass only the
single task card, its dependency result, `design.md` contracts, relevant
repository paths, and the current worktree commit. Do not pass the full
planning or conversation transcript. Return a compact handoff containing task
ID, AC coverage, changed paths, RED/GREEN/global results, review result, commit,
blockers, and next task.

## Preconditions

1. Select the first unchecked task whose dependencies are complete and confirm
   the exact `approve-plan changes/{CHG_ID}` line exists in
   `changes/{CHG_ID}/approval.md`:

```bash
bash .spec-framework/bin/enforce_tdd.sh approve-plan {CHG_ID}
bash .spec-framework/bin/enforce_tdd.sh select-task {CHG_ID}
```

2. Use only the returned task ID. The wrapper rejects manually skipping a
   blocked or later task.
3. Read its `Allowed Paths`, `Forbidden Paths`, `AC Coverage`, TDD protocol, and
   Definition of Done from `tasks.md`.
4. Confirm the dedicated worktree exists and is clean:

```bash
bash .spec-framework/bin/enforce_tdd.sh init {CHG_ID} {TASK_ID}
```

The gate rejects invalid identifiers, missing worktrees, dirty state, and path
traversal. It makes the primary working tree read-only until `complete` or an
explicit recovery command:

```bash
bash .spec-framework/bin/enforce_tdd.sh unlock {CHG_ID}
```

It does not remove evidence; cleanup is an explicit human action.

## Execution Loop

### RED

Write one minimal behavioral test in an allowed test path. It must name one
observable behavior and map to an `AC-NNN`. Run:

```bash
bash .spec-framework/bin/enforce_tdd.sh verify-red {CHG_ID} {TASK_ID} "{TEST_COMMAND}" "{RED_ASSERTION_MARKER}"
```

The command must fail because of an assertion such as `AssertionError` and
write this JSON contract to the `TDD_RED_EVIDENCE` path supplied by the gate:

```json
{"status":"FAIL","kind":"assertion","task":"T-001","marker":"AC-001: expected failure"}
```

A passing test, structural failure, missing evidence, or mismatched marker is
a gate failure. The marker is an AC-specific label; it is not a substitute for
the structured assertion evidence.

### GREEN

Write the smallest production change in the allowed paths. Before continuing,
check the exact diff boundary:

```bash
bash .spec-framework/bin/enforce_tdd.sh verify-paths {CHG_ID} {TASK_ID} "{ALLOWED_PATHS_CSV}" "{FORBIDDEN_PATHS_CSV}"
bash .spec-framework/bin/enforce_tdd.sh verify-green {CHG_ID} {TASK_ID} "{TEST_COMMAND}"
```

Do not add options, abstractions, refactors, or behavior not required by RED.

### REFACTOR and Global Verification

Refactor only after GREEN, preserving behavior and path boundaries. Then run:

```bash
bash .spec-framework/bin/enforce_tdd.sh verify-global {CHG_ID} {TASK_ID} "{GLOBAL_TEST_COMMAND}"
```

Prepare an independent review command that dispatches a fresh context and
checks the AC, test quality, error paths, and scope. The gate executes that
command itself. The command must write valid JSON to `TDD_REVIEW_RECEIPT`:

```json
{"status":"PASS","task":"T-001","independent":true,"findings":[]}
```

Then execute both quality commands and the reviewer command automatically:

```bash
bash .spec-framework/bin/enforce_tdd.sh verify-quality \
  {CHG_ID} {TASK_ID} "{STATIC_COMMAND}" "{MUTATION_COMMAND}" \
  "{INDEPENDENT_REVIEW_COMMAND}" "{REVIEW_RECEIPT}"
```

Missing static or mutation commands, a failing command, or a missing reviewer
command or receipt is a hard failure, not a reported limitation. Exit status,
stage logs, structured receipts, and timestamps are retained under the Git
administrative evidence directory; raw command strings are not persisted.

## Task Completion Handoff

Use this compact record after verification:

```markdown
## Agent Handoff
- **Task:** T-001
- **AC Coverage:** AC-001
- **Status:** complete | blocked
- **Changed Paths:** <allowed paths only>
- **RED:** <command, exit status, assertion evidence>
- **GREEN:** <command and exit status>
- **Global:** <command and exit status>
- **Independent Review:** <result and residual risk>
- **Commit:** <atomic commit or none>
- **Blockers:** <none or explicit blocker>
- **Next Task:** <task ID or complete>
```

Only after this record is complete may the task be committed and marked `[x]`.
The wrapper performs both actions atomically after rechecking boundaries and
quality evidence:

```bash
bash .spec-framework/bin/enforce_tdd.sh complete \
  {CHG_ID} {TASK_ID} "{ALLOWED_PATHS_CSV}" "{FORBIDDEN_PATHS_CSV}"
```

## Red Flags

- Production code exists before the failing test
- RED passed immediately or failed for a structural reason
- The worktree is not the dedicated change worktree
- A diff includes a path outside `Allowed Paths`
- A command is executed through `eval`
- The task is marked complete without global evidence or independent review

## Common Mistakes

- Passing the whole plan to every agent -> pass one task card and load files just in time.
- Testing a mock instead of behavior -> assert the real boundary or pure logic.
- Treating a non-zero exit as semantic RED -> require assertion evidence.
- Cleaning a violation automatically -> preserve evidence and stop.
- Committing code and tests together without seeing RED -> restart the task with a failing test first.
