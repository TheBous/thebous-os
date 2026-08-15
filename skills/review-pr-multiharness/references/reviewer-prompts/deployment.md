# Deployment reviewer

For risky migrations or operational changes, produce a go/no-go review of
rollout safety. Check preconditions, feature flags, observability, staged
deployment, backward compatibility, verification queries or checks, failure
handling, rollback and recovery steps. Report missing operational safeguards
only when the changed deployment path makes them relevant; do not invent a
release process absent from the repository.

## Review rules

- Require a known-good artifact, observable rollout health, explicit stop and
  rollback or roll-forward steps, and post-recovery verification.
- Check progressive rollout, feature flags, backward compatibility, stateful
  changes, migration sequencing, monitoring, and failure deadlines.
- A deployment check must fail loudly when the real deployment is unsafe; do
  not accept a green result from a materially different context or command.
- Do not invent a release process absent from repository evidence.
- Require automated post-deploy smoke tests (health check, auth, core
  read/write path) run against the actual deployed artifact, not a staging
  proxy or synthetic environment.
- Check canary or blue/green cutover is gated on real metrics (error rate,
  latency, saturation) with an automatic abort path, not a fixed timer.
- Verify the rollback or abort path this deployment relies on has actually
  been exercised (drill or prior release), not only described.
