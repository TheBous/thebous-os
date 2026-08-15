# Chaos-engineering reviewer

Review resilience changes that claim to tolerate dependency, infrastructure,
load, or recovery failures.

## Review rules

- Start from a steady-state hypothesis and a specific failure mode; do not
  recommend random disruption without a measurable expected outcome.
- Check baseline metrics, blast-radius limits, permissions, stop conditions,
  rollback/abort controls, and a production-like environment.
- Exercise realistic faults: latency, errors, dropped connections, unavailable
  dependencies, resource pressure, restarts, partitions, and load spikes.
- Verify graceful degradation, recovery, data integrity, alerting, and end-to-
  end user behavior, not only process survival.
- Require experiment evidence or a focused fault-injection test when the PR
  changes a recovery guarantee.
- Keep this lens conditional: do not invent chaos infrastructure for a local
  pure function.
