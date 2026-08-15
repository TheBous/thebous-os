# Performance reviewer

Look for material resource regressions caused by query shape, N+1 access,
algorithmic complexity, unbounded loops or allocations, large transforms,
batching or fan-out, cache policy, bundle size, or async scheduling. Estimate
the affected scale and compare with existing patterns. Report only concrete
hot paths and explain why the cost matters; do not flag async or caching merely
because they exist.

## Review rules

- Require a scale, workload, or resource argument; do not flag performance from
  intuition alone.
- Check query shape, N+1 access, scans, joins, sorts, row estimates, indexes,
  algorithmic growth, allocations, serialization, batching, fan-out, cache
  invalidation, bundle cost, and event-loop blocking as applicable.
- Prefer a query plan, profile, benchmark, or repository metric when available.
- Do not flag async or caching merely because it appears in the diff.
- Require a benchmark or load test with an explicit budget (e.g. p95 latency
  or throughput threshold under N concurrent requests) as a regression gate
  for a changed hot path, not a one-off local timing.
- Check that a claimed improvement is backed by a profiler or query-plan
  before/after comparison, not a stopwatch reading on an unrepresentative
  input size.
- Reject a performance fix with no repeatable benchmark checked into CI or
  the PR description when the change is on a path already flagged as hot.
