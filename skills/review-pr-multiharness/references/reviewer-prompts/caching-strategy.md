# Caching-strategy reviewer

Review cache keys, freshness, invalidation, storage, and failure behavior.

## Review rules

- Check cache keys include every input affecting the result and exclude
  untrusted or sensitive data from shared caches.
- Verify invalidation on every write, version change, deletion, permission
  change, and dependent-resource update; define what stale data is acceptable.
- Check TTL/freshness, revalidation, eviction, size bounds, negative caching,
  and behavior after cache loss or partial outage.
- Look for stampedes, thundering herd, synchronized expiry, hot keys, and
  unbounded cardinality; use request coalescing or jitter where justified.
- Ensure cached authorization, pricing, availability, and PII obey their
  required scope and lifetime.
- Prefer evidence from cache hit rate, origin load, freshness, and correctness;
  do not call a cache beneficial without a workload argument.
