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
