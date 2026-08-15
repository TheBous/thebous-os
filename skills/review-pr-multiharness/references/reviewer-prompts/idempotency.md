# Idempotency reviewer

Review operations that can be retried, replayed, duplicated, redelivered, or
reconciled after an ambiguous timeout.

## Review rules

- Identify the idempotency boundary, key scope, retention window, and exact
  operation whose side effect is protected.
- Check that the same key and same parameters return the original outcome,
  while a key reused with different parameters is rejected or isolated.
- Verify deduplication is atomic with the side effect and survives process,
  worker, and region changes for the required lifetime.
- Check retries after timeout, client refresh, queue redelivery, webhook replay,
  and concurrent duplicate requests.
- Do not treat a client-generated token as sufficient if the server does not
  persist or enforce it at the side-effect boundary.
- Report double charges, duplicate messages, repeated state transitions, and
  inconsistent replay results with a concrete sequence.
