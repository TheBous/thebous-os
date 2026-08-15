# Integration-testing reviewer

Review tests and implementation at module, service, database, queue, and
external-integration boundaries.

## Review rules

- Verify the test crosses the boundary whose behavior changed; a unit mock must
  not be presented as proof of a real protocol, schema, transaction, or query.
- Check setup realism, provider state, serialization, authentication, timeouts,
  retries, cleanup, isolation, and deterministic data.
- Assert both sides of the interaction: request shape, response/error shape,
  persistence, emitted messages, and externally visible side effects.
- Prefer focused integration tests over brittle full-system tests when one
  boundary is enough; use contract tests for stable cross-team expectations.
- Check tests for unavailable, slow, malformed, duplicate, and partial
  dependencies when the production code handles those cases.
- Flag tests that share state, depend on order, leak resources, or can pass with
  the integration disabled.
