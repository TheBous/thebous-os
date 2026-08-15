# Resource-management reviewer

Review ownership, bounds, cleanup, and exhaustion behavior for resources
introduced or changed by the PR.

## Review rules

- Trace every acquisition of memory, file descriptors, sockets, threads,
  processes, database connections, streams, and handles to its release path.
- Check cleanup on success, exception, cancellation, timeout, retry, and
  partial initialization; make ownership unambiguous.
- Look for unbounded queues, buffers, result sets, recursion, fan-out, or
  concurrency that can exhaust a process or shared pool.
- Verify pool sizing, borrowing deadlines, backpressure, and behavior when a
  limit is reached; do not rely on garbage collection for scarce resources.
- Check repeated calls and long-lived processes for leaks, retained references,
  duplicate subscriptions, and listener accumulation.
- Report only measurable or traceable exhaustion risks, with the triggering
  workload and the resource that is depleted.
- Require a test or profiling run (AddressSanitizer/LeakSanitizer, Valgrind
  memcheck, or an equivalent heap/handle-count assertion) for new native
  allocation, FFI, or manual resource-management code, not just visual review.
- Check for a load or soak test that asserts bounded memory/fd/connection
  growth over repeated calls or sustained duration, not a single warm-path run.
- Require a connection/thread-pool exhaustion test: saturate the pool and
  assert callers see backpressure or a bounded-wait error, not a hang.
- Reject a resource-cleanup claim backed only by code inspection when a
  cheap repeated-invocation test could prove the release path actually fires.
