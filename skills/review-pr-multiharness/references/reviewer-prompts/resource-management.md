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
