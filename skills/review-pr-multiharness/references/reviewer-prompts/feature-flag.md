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
