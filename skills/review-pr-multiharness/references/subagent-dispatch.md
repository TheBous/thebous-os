# Subagent dispatch contract

This reference turns the selected reviewer roster into actual bounded
subagent work. It is deliberately separate from lens selection so the same
review prompts work across hosts.

## 1. Detect the active dispatch primitive

Use the subagent tools exposed by the current host. Do not infer availability
from a shell command, a model name, or the number of selected lenses.

- **Claude Code adapter:** use generic `Agent` calls, with background execution
  disabled. Issue the selected calls in one foreground concurrent batch when
  the host supports same-message concurrency. The batch returns when all calls
  in that batch finish.
- **Codex adapter:** use generic `spawn_agent` calls, one per selected lens,
  then collect every returned agent id with `wait_agent`. Continue waiting until
  every id has returned; do not synthesize after the first result. Close every
  completed agent with `close_agent` before leaving dispatch.
- **Other host with an async primitive:** spawn up to its active-agent cap,
  collect all ids, close completed handles, then refill the queue until the
  roster is exhausted.
- **No supported primitive:** execute each selected lens sequentially in the
  current reviewer context, using the exact same prompt and JSON contract, and
  record `dispatch_mode: sequential-fallback`.

Never create a background shell process, write a status file, sleep, poll a
status command, or ask the user to wait. Host-managed waits are allowed because
they return the child result and are not detached polling.

## 2. Bound concurrency without dropping reviewers

The danger-score table is the requested roster size, not a promise that the
host accepts that many concurrent agents. Treat an active-agent limit as
backpressure:

1. Keep the selected roster and its lens order stable.
2. Fill only the available host slots.
3. Collect and close completed agents.
4. Refill with the next unstarted lenses.
5. Continue until every selected lens has a result.

If the host reports zero capacity on the first attempt, make one bounded
retry with the same prompt and scope. If capacity remains unavailable, use the
sequential fallback instead of silently shrinking coverage. A non-capacity
dispatch error is a reviewer failure only after the same invocation shape has
been corrected once; record the lens and error in `Coverage`.

## 3. Build one independent prompt per lens

Each child receives exactly one selected lens prompt and this common context:

```text
You are the <lens> reviewer.

Review intent:
<intent>

Review scope:
<PR or branch metadata>
<base/head refs>
<changed files>
<diff or staged diff path>
<applicable standards>

Lens instructions:
<contents of references/reviewer-prompts/<lens>.md>

Return contract:
<JSON contract below>
```

For large diffs, write the diff and file list once to the review artifact
directory and pass absolute paths instead of duplicating their contents in
every prompt. Each child may inspect code read-only. It must not edit files,
switch branches, commit, push, open PRs, create tickets, or feed findings from
another child into its own analysis.

## 4. Require structured results

Each child must return valid JSON and no surrounding prose:

```json
{
  "reviewer": "<lens>",
  "findings": [
    {
      "severity": "P0|P1|P2|P3",
      "category": "<lens category>",
      "title": "<short concrete title>",
      "file": "<repository-relative path>",
      "line": 0,
      "evidence": "<specific code or behavior evidence>",
      "impact": "<concrete user, data, security, or operational impact>",
      "suggested_fix": "<focused correction direction>",
      "confidence": 0,
      "requires_verification": false
    }
  ],
  "residual_risks": [],
  "testing_gaps": []
}
```

`line` is the best available changed-line anchor; use `0` only when no line
can be anchored. `confidence` is an integer from 0 to 100. Findings must be
evidence-backed and introduced by the reviewed change. An empty `findings`
array is a valid result. Invalid JSON is a failed reviewer result, not a
reason to invent findings.

## 5. Collect before synthesis

The orchestrator waits for all selected lenses, validates each JSON result,
marks failed or unavailable lenses, deduplicates by root cause, and only then
writes the final report. `Coverage` must include:

- `dispatch_mode`: `claude-concurrent`, `codex-async`, another host adapter, or
  `sequential-fallback`;
- selected lenses and returned lenses;
- host concurrency cap when known;
- failed/unavailable lenses and the concrete reason;
- whether any selected lens was queued because of backpressure.

The final report must never imply that a subagent ran when the host only
executed the sequential fallback, and must never imply full coverage when a
lens failed.
