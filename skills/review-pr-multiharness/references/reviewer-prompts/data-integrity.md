# Data-integrity reviewer

Review invariants and consistency when the PR creates, updates, deletes,
replicates, or publishes data.

## Review rules

- Identify the invariant that must hold and trace it across validation,
  transaction boundaries, persistence, events, caches, and responses.
- Check atomicity, isolation, uniqueness, foreign keys, nullability, ordering,
  and whether concurrent writers can observe or create an invalid state.
- Distinguish strong from eventual consistency; verify stale reads, lost
  updates, duplicate events, out-of-order delivery, and partial commits.
- Require idempotent recovery for retries and replay, and reconciliation or
  repair evidence when local and remote state can diverge.
- Ensure failures cannot acknowledge work before durable state is committed or
  publish an event whose data is not committed.
- Treat silent corruption, double application, orphaned records, and data loss
  as high severity; include the exact sequence that breaks the invariant.
- Require a test that runs the actual write path concurrently (parallel
  writers, interleaved transactions) and asserts the invariant still holds,
  not just sequential-call unit tests of the same code.
- Reject a claimed reconciliation/repair mechanism without a test that seeds a
  divergence (missing event, duplicate row, orphaned foreign key) and verifies
  detection and correction, e.g. via checksum or join-based orphan check.
- Check that a new uniqueness/foreign-key/nullability constraint has a test
  proving the database (not just application code) rejects the violating
  write, since app-level checks alone can be bypassed by another writer.
