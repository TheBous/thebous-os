# Rollback-strategy reviewer

Review how the changed behavior is stopped, disabled, rolled back, or rolled
forward after a bad deployment.

## Review rules

- Identify the trigger, owner, decision metric, time limit, and executable
  action for stopping or reversing the rollout.
- Check whether rollback is safe with schema changes, queued work, caches,
  side effects, flags, and mixed old/new versions.
- Prefer progressive exposure, automatic health gates, and graceful degradation
  when blast radius can be reduced without hiding failures.
- Verify disabling a feature flag stops the dangerous path and does not strand
  state, jobs, or data created while it was enabled.
- Check recovery of in-flight requests and background work, plus post-rollback
  validation of data, dependencies, and user-visible behavior.
- Reject a rollback claim that is only a Git revert when external side effects
  or irreversible data changes are involved.
- Require an executed or automated rollback drill proving the previous version
  returns healthy within the stated time limit, not only a documented step.
- Check canary-analysis logic is tested to actually trigger automatic rollback
  on the failure signal it claims to watch (error rate, latency, health),
  not only that the metric is emitted.
- Verify a rollback test covers data or schema state created during the bad
  window, not code reversion alone.
