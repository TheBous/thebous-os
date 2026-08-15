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
