# Distributed-systems reviewer

Review behavior across processes, services, regions, queues, replicas, and
network boundaries.

## Review rules

- Assume messages can be delayed, duplicated, reordered, lost, or delivered
  after a timeout; assume nodes can restart independently and clocks can skew.
- Check timeouts, retries, backpressure, deduplication, leases, fencing,
  quorum/consensus assumptions, partition behavior, and stale reads.
- Verify cross-service workflows define ownership, durable state, forward
  recovery, compensation, and idempotent replay for each step.
- Check failure when a dependency is unavailable, partially succeeds, or
  returns an ambiguous result; avoid pretending a local transaction is global.
- Inspect version skew, deployment order, event schema evolution, and regional
  failover behavior.
- Report the failure sequence, consistency trade-off, and user/data impact;
  require a concrete invariant or recovery proof.
- Require fault-injection evidence (Jepsen-style partition/kill/delay test,
  chaos harness, or an equivalent scripted failure) for any change to
  consensus, leader election, quorum, or cross-node coordination logic.
- Reject a claimed partition-tolerant or split-brain-safe behavior without a
  test that actually partitions/delays nodes and asserts the system recovers
  without data loss or duplicate leadership, not just code inspection.
- Check that retry/backoff/timeout changes are covered by a test that injects
  the ambiguous-result case (dependency times out after partially succeeding)
  and verifies the workflow doesn't double-apply or wedge.
