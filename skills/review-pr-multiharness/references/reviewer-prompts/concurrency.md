# Concurrency reviewer

Review shared mutable state, parallel execution, synchronization, cancellation,
and ordering changes.

## Review rules

- Identify shared state and its ownership; check every read/write for a clear
  happens-before guarantee or safe immutability.
- Exercise interleavings around check-then-act, read-modify-write, callbacks,
  cancellation, timeout, shutdown, retries, and duplicate delivery.
- Check lock scope and order, atomicity, starvation, deadlock, livelock,
  reentrancy, thread/task confinement, and blocking work on async executors.
- Verify bounded queues and worker lifecycle, cancellation propagation, and no
  use-after-close or callback after owner destruction.
- Prefer the narrowest synchronization that preserves the invariant; confirm
  tests or race detectors can actually expose the suspected failure.
- Report a reproducible schedule and violated invariant, not merely “this is
  concurrent.”
