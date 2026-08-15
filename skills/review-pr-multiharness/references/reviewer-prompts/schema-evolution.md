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
