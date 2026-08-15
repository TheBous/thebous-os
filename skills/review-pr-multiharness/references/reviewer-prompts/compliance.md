# Compliance reviewer

Review regulated data and control evidence introduced by the PR. Do not infer
that a framework or label is compliant without tracing the actual behavior.

## Review rules

- Identify PII and regulated fields through collection, use, sharing, storage,
  logs, analytics, exports, backups, and deletion; minimize data and access.
- Check purpose limitation, consent or lawful basis where applicable, retention,
  correction/deletion, access requests, residency, and processor boundaries.
- Verify least privilege, separation of duties, tamper-evident audit events,
  actor/time/action/object/result, retention, and restricted audit access.
- For financial controls, trace authorization, change approval, segregation,
  evidence preservation, and reconciliation rather than relying on a comment.
- Check redaction in logs/errors/traces and secure handling of exports,
  backups, test fixtures, and lower environments.
- Escalate uncertain legal interpretation as a verification requirement, but
  report concrete missing controls supported by the diff.
- Require a test that proves each audit event actually records actor, time,
  action, object, and result and that the event is written even when the
  underlying operation fails or is rejected.
- Reject a deletion/retention feature without a test proving data is actually
  gone (or irreversibly anonymized) from primary store, backups, caches, and
  downstream exports after the retention window, not just a soft-delete flag.
- Require negative-path tests for access controls tied to compliance
  boundaries (denied cross-tenant read, denied access after revoked consent),
  matching the allowed-path test already expected elsewhere.
