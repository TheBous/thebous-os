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
