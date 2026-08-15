# Secrets-vault reviewer

Review credentials, tokens, keys, certificates, secret references, and secret
store integration.

## Review rules

- Ensure secrets are never committed, hard-coded, printed, returned in errors,
  embedded in URLs, exposed to clients, or copied into fixtures and snapshots.
- Check retrieval uses an approved vault or secret manager with least privilege,
  scoped identity, encrypted transport, and no broad fallback credentials.
- Verify rotation, expiry, revocation, dual-key overlap, startup refresh, and
  behavior when a secret is unavailable or invalid.
- Check logs, traces, crash dumps, metrics, CI output, environment inheritance,
  process arguments, and support exports for indirect leakage.
- Ensure access is auditable and secret values are not used as identifiers,
  cache keys, or unbounded telemetry dimensions.
- Flag exposed material as urgent and state the required rotation/revocation
  action without reproducing the secret.
- Require a negative test that asserts a secret never appears in logs, error
  bodies, stack traces, or serialized responses (e.g. an assertion over
  captured log/log-scrubber output), not a manual claim of "we don't log it."
- Reject secret-bearing diffs without CI secret-scanning coverage (gitleaks,
  TruffleHog, or equivalent) on the changed paths; a merged scan bypass or
  allowlist addition needs explicit justification.
- Check for a demonstrated rotation/revocation drill: a test or runbook proof
  that the service keeps working through dual-key overlap and that an old key
  is actually rejected after revocation, not just documented as supported.
