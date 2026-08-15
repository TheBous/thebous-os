# Stack-specific reviewer

Use the runtime or framework evidence in the diff to choose one concrete
specialist concern, then state that concern in the dispatch prompt. Inspect
only behavior that requires stack-specific knowledge: lifecycle, event order,
concurrency, state ownership, platform APIs, build configuration, or framework
contracts. Do not flag a file solely because of its extension and do not use
this lens for generic maintainability, correctness, or style issues.

## Review rules

- Identify the exact language, runtime, framework, platform, and versions before
  applying stack-specific expectations.
- Check only meaningful runtime concerns: lifecycle, event order, concurrency,
  state ownership, platform APIs, accessibility, build/signing, or contracts.
- Use version-matched project conventions; mark unsupported claims unverified
  instead of relying on memory.
- Do not flag a file solely because of its extension or duplicate generic
  correctness, maintainability, or style findings.
- State what test evidence this specific stack requires for the concern
  chosen (e.g. widget/instrumentation tests for lifecycle, concurrency
  harness for race conditions, contract tests for a framework boundary) and
  check whether that evidence exists.
