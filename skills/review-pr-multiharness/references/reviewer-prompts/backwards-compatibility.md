# Backwards-compatibility reviewer

Review whether old clients, workers, data, binaries, and integrations can
coexist with the changed implementation.

## Review rules

- Enumerate producers and consumers, then check old-to-new and new-to-old
  interactions during a rolling deployment.
- Treat removed/renamed fields, changed types, enum values, defaults, status
  codes, event meaning, ordering, and error semantics as compatibility risks.
- Prefer additive changes, tolerant readers, explicit versioning, and a staged
  deprecation path with an owner and removal condition.
- Check unknown fields, absent fields, old serialized data, old database rows,
  and clients that do not understand newly introduced values.
- Verify compatibility tests or a migration gate cover the real consumer
  contract, not only the producer's local unit tests.
- Do not call a change backward compatible because compilation still succeeds.
- Run mixed-version tests with old and new instances live concurrently, not a
  sequential upgrade-then-test, to catch version-skew failures.
- Replay serialized fixtures captured from production against the new code
  path to prove old data still decodes correctly.
- Require a compatibility test matrix (old client x new server, new client x
  old server) naming the actual consumers, not a single latest-vs-latest run.
