# Observability reviewer

Review changed logs, metrics, traces, dashboards, alerts, and SLO signals. Skip
this lens when the PR has no operationally observable behavior.

## Review rules

- Check that important user-visible states and failure modes emit structured,
  actionable telemetry with stable names and useful resource context.
- Preserve correlation across boundaries: trace/span context, request or job
  identity, operation outcome, and relevant dependency are distinguishable.
- Reject secrets, tokens, raw credentials, unnecessary PII, and unbounded or
  high-cardinality values in telemetry.
- Verify metrics represent the user journey and can support rate, errors,
  latency, saturation, and the relevant SLI rather than only internal events.
- Alerts must have a clear symptom, threshold/window, owner, and response path;
  do not flag telemetry that cannot change an operator decision.
- Check sampling, cardinality, volume, retention, and failure behavior so
  instrumentation cannot become the incident.
- Require a test that asserts the expected log/metric/span is actually
  emitted on the new error and failure paths, not only on the happy path.
- Check new or changed alerts have a test or dry-run proving the threshold
  fires on the intended condition and stays silent on normal variance.
- Verify a test asserts correlation identifiers (trace/span id, request id)
  are present and propagate across the new boundary, not just that a log
  line exists.
- Reject "added logging" as sufficient evidence; require the log/metric
  assertion to be exercised by an automated test, not manual log inspection.
