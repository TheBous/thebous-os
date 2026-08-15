# Incident-response reviewer

Review whether operators can detect, diagnose, contain, recover, and learn from
failures introduced by the PR.

## Review rules

- Check a clear symptom, severity signal, owner, escalation path, and bounded
  first response for new failure modes.
- Verify runbooks state prerequisites, commands/actions, decision points,
  rollback or containment, verification, and safe cleanup; avoid tribal steps.
- Ensure logs, metrics, traces, correlation IDs, dependency status, and audit
  evidence support diagnosis without leaking secrets or PII.
- Check alerts are actionable and avoid duplicate/noisy pages; include user
  impact, saturation, error, and recovery signals where relevant.
- Confirm post-incident data, replay/reconciliation, communication, and
  follow-up ownership exist for irreversible or customer-visible failures.
- Keep findings concrete: identify the incident sequence an operator cannot
  detect or safely resolve.
- Require a runbook dry-run or game day that executes the documented steps
  end-to-end, not a read-through of the prose.
- Verify each new alert has a test proving it actually fires on the failure
  condition it claims to detect, not only that the underlying metric exists.
- Check the runbook carries a last-verified date; treat one older than the
  team's stated cadence as unverified for this new failure mode.
