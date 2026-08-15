# Feature-flag reviewer

Review flag evaluation, targeting, rollout, lifecycle, and cleanup.

## Review rules

- Check deterministic evaluation, default behavior, targeting boundaries,
  tenant/user isolation, percentage rollout, and failure behavior of the flag
  provider.
- Test both enabled and disabled paths, plus missing, malformed, stale, and
  provider-unavailable flag values.
- Verify flags do not bypass authorization, validation, migrations, billing,
  or data invariants when toggled independently.
- Check exposure metrics, auditability, owner, expiry/removal task, and safe
  rollback action; a flag without lifecycle ownership is permanent complexity.
- Ensure old and new code can coexist during rollout and that queued/background
  work records the intended variant when necessary.
- Do not treat a hidden path as tested or safe merely because default is off.
- Require a kill-switch test that flips the flag off mid-flight and asserts
  the dangerous path stops and in-flight work fails safely.
- Check a flag-cleanup test or tracked follow-up proves the code still passes
  with the dead branch removed before the flag is considered done.
- Verify CI runs the suite parameterized over both flag states, not only
  whichever state happens to be the test environment's default.
