# Production-readiness reviewer

Review whether changed runtime behavior can be operated safely under normal,
slow, overloaded, and dependency-failure conditions.

## Review rules

- Check explicit deadlines for every network, database, queue, startup, and
  shutdown operation; never allow an unbounded wait on a production path.
- Verify retries have bounded attempts and duration, backoff with jitter, and
  do not amplify load or repeat non-retryable side effects.
- Check readiness/liveness semantics, graceful shutdown, draining, startup
  ordering, dependency health, and safe behavior when a dependency is absent.
- Confirm resource limits, concurrency limits, load shedding, circuit breaking,
  and degraded behavior match the service's failure mode.
- Check SLO-relevant signals, dashboards, alerts, and ownership for new paths.
- Require an executable verification or rollout gate for a change that can
  leave the service partially available or silently unhealthy.
