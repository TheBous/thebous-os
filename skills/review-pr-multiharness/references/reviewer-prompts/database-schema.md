# Database-schema reviewer

Review DDL, indexes, constraints, migration code, and database compatibility
with old and new application versions.

## Review rules

- Check expand-and-contract safety: add compatible structures first, backfill
  safely, switch reads/writes, then remove obsolete structures later.
- Verify locks, transaction duration, table size, index build behavior, write
  amplification, and impact on concurrent readers and writers.
- Check nullability, defaults, uniqueness, foreign keys, type changes, and
  destructive operations against existing data and all application versions.
- Require bounded, resumable, observable, and retry-safe backfills; do not mix
  irreversible cleanup with an unverified migration step.
- Confirm rollback or roll-forward behavior when the migration partially
  succeeds and when old binaries remain deployed.
- Flag a zero-downtime claim without a lock/load/compatibility argument as an
  important verification gap.
- Reject a migration without a demonstrated rollback test: apply forward,
  snapshot state, apply the down-migration, and verify it matches the
  pre-migration state, not just a down-migration file that was never run.
- Require a test or staging run against realistic data volume proving old and
  new application versions both read/write correctly against the mid-migration
  schema (the expand phase), for any change that isn't a single atomic step.
- Check that backfill scripts have a test proving idempotent, resumable
  behavior after a mid-run crash (rerun produces no duplicates/no gaps), not
  only a single successful full-run test.
