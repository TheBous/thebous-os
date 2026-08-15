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
- Require the changed concurrent path to run under a race detector (Go
  `-race`, ThreadSanitizer, or the stack's equivalent) in CI; a race-prone
  change merged without it is a gap even if unit tests pass.
- Reject a claimed fix for a race/deadlock without a stress or fuzz test
  (repeated high-iteration run, injected delay, or scheduling perturbation)
  that reproduced the bug before the fix and passes after.
- Note that the race detector only catches races on executed interleavings;
  flag concurrent branches (retry-after-cancel, shutdown-during-request) left
  untriggered by any test as unverified, not assumed safe.
