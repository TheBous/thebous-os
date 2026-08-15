# Subagent dispatch contract

This shared reference turns a selected reviewer or worker roster into bounded
subagent work. Any skill can reuse it; add task-specific instructions before
the shared JSON contract.

## 1. Detect the active dispatch primitive

Use the subagent tools exposed by the current host. Do not infer availability
from a shell command, a model name, or the number of selected workers.

- **Claude Code adapter:** use generic `Agent` calls, with background execution
  disabled. Issue selected calls in one foreground concurrent batch when the
  host supports same-message concurrency. The batch returns when all calls in
  that batch finish.
- **Codex adapter:** use generic `spawn_agent` calls, one per selected worker,
  then collect every returned agent id with `wait_agent`. Continue waiting until
  every id has returned; do not synthesize after the first result. Close every
  completed agent with `close_agent` before leaving dispatch.
- **Other async host:** spawn up to its active-agent cap, collect all ids, close
  completed handles, then refill the queue until the roster is exhausted.
- **No supported primitive:** execute each selected task sequentially in the
  current context with the same prompt and JSON contract, and record
  `dispatch_mode: sequential-fallback`.

Never create a background shell process, write a status file, sleep, poll a
status command, or ask the user to wait. Host-managed waits are allowed because
they return child results and are not detached polling.

## 2. Bound concurrency without dropping work

The caller's roster size is the requested work, not a promise that the host
accepts that many concurrent agents. Treat an active-agent limit as
backpressure:

1. Keep the selected roster and its task order stable.
2. Fill only the available host slots.
3. Collect and close completed agents.
4. Refill with the next unstarted tasks.
5. Continue until every selected task has a result.

If the host reports zero capacity on the first attempt, make one bounded retry
with the same prompt and scope. If capacity remains unavailable, use the
sequential fallback instead of silently shrinking coverage. A non-capacity
dispatch error is a failed task only after the same invocation shape has been
corrected once; record the task and error in the caller's coverage section.

## 3. Build one independent prompt per task

Each child receives exactly one task prompt and this common context:

```text
You are the <task> worker.

Task:
<task-specific instructions>

Context:
<intent or objective>
<scope and relevant paths>
<inputs or diff, inline or staged path>
<applicable standards>

Return contract:
<JSON contract below>
```

For large inputs, write them once to the caller's artifact directory and pass
absolute paths instead of duplicating contents in every prompt. Each child may
inspect inputs read-only. It must not edit files, switch branches, commit,
push, open PRs, create tickets, or consume another child's output unless the
calling skill explicitly defines a dependent phase.

## 4. Require structured results

Each child must return valid JSON and no surrounding prose. Callers may extend
this shape with task-specific fields, but must preserve a machine-readable
status and error path:

```json
{
  "worker": "<task>",
  "status": "ok|failed",
  "result": {},
  "error": null
}
```

For code-review findings, use this result shape:

```json
{
  "worker": "<lens>",
  "status": "ok",
  "result": {
    "findings": [
      {
        "severity": "P0|P1|P2|P3",
        "category": "<lens category>",
        "title": "<short concrete title>",
        "file": "<repository-relative path>",
        "line": 0,
        "evidence": "<specific evidence>",
        "impact": "<concrete impact>",
        "suggested_fix": "<focused correction direction>",
        "confidence": 0,
        "requires_verification": false
      }
    ],
    "residual_risks": [],
    "testing_gaps": []
  },
  "error": null
}
```

For code review, `line` is the best available changed-line anchor; use `0`
only when no line can be anchored. `confidence` is an integer from 0 to 100.
Findings must be evidence-backed and introduced by the reviewed change. An
empty `findings` array is valid. Invalid JSON is a failed worker result, not a
reason to invent output.

## 5. Collect before synthesis

The orchestrator waits for all selected tasks, validates every result, marks
failed or unavailable tasks, and only then synthesizes the final output. The
caller should record:

- `dispatch_mode`: `claude-concurrent`, `codex-async`, another host adapter, or
  `sequential-fallback`;
- selected and returned tasks;
- host concurrency cap when known;
- failed/unavailable tasks and the concrete reason;
- tasks queued because of backpressure.

Never imply that a subagent ran when the host only used the sequential
fallback, and never imply full coverage when a task failed.
