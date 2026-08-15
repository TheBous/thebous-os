# Disaster-recovery reviewer

Review backups, restore, replication, failover, and recovery-region changes.

## Review rules

- Identify business recovery objectives: acceptable downtime (RTO) and data
  loss (RPO), then compare them with the actual design.
- Check backup scope, frequency, retention, encryption, isolation, integrity,
  point-in-time recovery, and protection from accidental or malicious deletion.
- Verify restore is executable, dependency-complete, ordered, observable, and
  tested; a successful backup is not proof of recoverability.
- Check failover detection, fencing, split-brain prevention, DNS/routing,
  secrets/identity, schema/version compatibility, and failback consistency.
- Require drills or recovery evidence for changed critical paths and confirm
  degraded operation while recovery is in progress.
- Report the missing recovery step, objective mismatch, and likely data/service
  impact rather than merely asking for “more redundancy.”
- Require a timed, executed restore-from-backup drill that measures actual
  RTO/RPO against the objective; a "backup completed" log is not a drill.
- Verify failover drills inject a real failure mode (chaos-engineering style
  fault injection) rather than a clean, orchestrated switch that skips
  detection, fencing, and split-brain handling.
- Check drill results carry a date and cadence; treat an untested runbook or a
  drill older than the stated interval as unverified for this change.
