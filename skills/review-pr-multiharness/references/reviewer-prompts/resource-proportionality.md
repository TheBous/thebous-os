# Resource-proportionality reviewer

Review whether work and resource use scale with the actual request, viewport,
dataset, tenant, or workload instead of a worst-case maximum.

## Review rules

- Check lazy loading, pagination, streaming, bounded concurrency, memoization,
  and incremental computation where the changed path can avoid unused work.
- Verify memoization keys, invalidation, memory bounds, lifecycle, and whether
  caching a result costs more than recomputing it.
- Look for over-fetching, eager initialization, loading all records/assets,
  duplicate parsing, redundant renders, and unconditional background work.
- Ensure optimization does not return stale, cross-tenant, unauthorized, or
  incorrectly shared results.
- Check small, empty, large, repeated, and changed-input workloads and the
  behavior when resources are constrained.
- Report disproportionate work only with a concrete input-to-resource path.
- Require a test with a small and a large/repeated input asserting work
  (query count, allocations, elapsed time) grows sub-linearly or stays flat,
  not just that the large-input case returns correct output.
- Check pagination, lazy-load, and streaming paths have a test proving the
  full dataset is never materialized when only a page or viewport is needed.
- Reject an "it scales" claim on a new loop, fan-out, or background job with
  no test at more than one workload size.
