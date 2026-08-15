# Schema-evolution reviewer

Review serialized, event, API, and persisted schema changes across versions.

## Review rules

- Classify the change as additive, restrictive, semantic, rename, type, or
  deletion and check forward and backward readers/writers explicitly.
- Preserve unknown fields and tolerate absent/defaulted fields where older and
  newer versions coexist.
- Check enum evolution, nullability, defaults, numeric/string changes, units,
  ordering, precision, and semantic meaning—not only syntactic validity.
- Verify event replay, historical records, dead-letter handling, snapshots,
  fixtures, and cross-region consumers.
- Require a versioning, migration, or deprecation path for breaking changes;
  a schema validator passing does not prove semantic compatibility.
- Include consumer/provider or golden-data tests for the changed cases.
- Require an automated compatibility-mode check (schema-registry
  BACKWARD/FORWARD/FULL, or Buf/protoc breaking-change detection) run in CI
  against the full registered version history, not only the prior version.
- Test dual-write/dual-read during migration: old writer with new reader and
  new writer with old reader, across the full coexistence window.
- Verify golden/replay tests use real historical payloads, not synthetic
  examples, to catch type-widening, unit, or precision drift a schema
  validator alone would miss.
