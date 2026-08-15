# Regression-testing reviewer

Review whether tests protect behavior changed by the PR and the bug classes
most likely to return.

## Review rules

- Map each changed branch, state, boundary, error, and side effect to a test
  that would fail if that behavior regressed.
- Use equivalence classes, boundary values, decision tables, state transitions,
  invalid input, duplicate input, and both feature-flag states where relevant.
- Check tests assert observable outcomes and invariants, not implementation
  details, call counts alone, or values produced by the same broken helper.
- Include negative paths, partial failure, retries, ordering, authorization,
  persistence, and serialization when the diff changes them.
- Detect removed assertions, weakened matchers, skipped tests, fixture drift,
  and tests that pass while the production path is disconnected.
- Recommend the smallest regression test that proves the claimed risk.
- Require the fix's regression test to fail against the pre-fix code and pass
  only after the fix (red-green proof), not merely pass on the current diff.
- For bugs with interacting inputs or flags, check a combinatorial or pairwise
  matrix around the reported case, not only the single failing example.
- Verify the test reproduces the exact reported trigger condition rather than
  a nearby symptom that happens to also fail.
