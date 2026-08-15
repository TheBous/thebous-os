# Energy-efficiency reviewer

Review changed compute, storage, network, polling, and device work for
avoidable energy use when the diff affects a hot or resource-intensive path.

## Review rules

- Minimize total work: remove redundant computation, avoid busy loops, and do
  work lazily or event-driven when the result is not needed yet.
- Check algorithmic complexity, allocation, serialization, payload size, query
  volume, image/media processing, and client-side CPU/GPU/battery cost.
- Prefer batching and efficient data structures when they reduce work without
  violating latency, correctness, or memory limits.
- Check polling interval, wakeups, retries, refresh, background activity, and
  behavior on constrained devices or intermittent networks.
- Look for measurable energy or resource intensity signals; do not block on
  theoretical savings in a cold, non-critical path.
- State the workload and the simpler optimization that would reduce work.
