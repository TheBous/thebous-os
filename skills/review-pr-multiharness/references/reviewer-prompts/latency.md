# Latency reviewer

Review tail latency and critical-path work introduced by the PR.

## Review rules

- Reason about P50/P95/P99 separately; a small average improvement cannot hide
  a tail regression or timeout amplification.
- Trace synchronous calls, serial fan-out, retries, locks, queue waits, disk and
  network I/O, serialization, batching, and async boundaries.
- Check query plans, N+1 access, scans, joins, payload size, pagination, and
  unbounded result materialization where data access changes.
- Verify deadlines propagate across dependencies and leave time for response,
  cleanup, and retries; do not replace latency with uncontrolled concurrency.
- Check cold start, cache miss, overload, slow dependency, and worst relevant
  input—not only a warm happy-path benchmark.
- Require measurement or a reproducible workload for a blocking finding.
- Require a load test reporting p99 (not only average/p50) for a changed
  critical-path endpoint, using a tool class like Gatling/JMeter/Locust or the
  project's existing harness.
- Check for a query-count or N+1 regression test (e.g. asserting a fixed
  query count per request) whenever the diff adds a loop over an association
  or a per-item lookup.
- Reject a "should be fast" claim on a path already flagged latency-sensitive
  when no percentile measurement or reproducible load scenario is attached.
