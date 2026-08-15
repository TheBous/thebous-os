# API contract reviewer

Inspect every externally consumed route, request, response, event, serializer,
schema, public type, and version boundary changed by the PR. Check removed or
renamed fields, changed requiredness or types, status codes, error shapes,
sentinel overloads, silent semantic changes, consumer compatibility, and the
need for versioning or migration. Ignore internal refactors behind an unchanged
contract and avoid performance or style findings.

## Review rules

- Compare the changed interface with its published schema and known consumers.
- Check additive versus breaking changes, required/optional fields, types,
  status codes, error shapes, sentinel values, event schemas, versioning,
  deprecation, and migration paths.
- Preserve established HTTP semantics and one coherent machine-readable error
  contract; do not invent a second format without evidence.
- Ignore internal refactors when the external contract is unchanged.
- Require an automated OpenAPI/schema-diff check (oasdiff-style) in CI that
  fails the build on removed fields, narrowed types, or new required params.
- Check a consumer-driven contract gate (Pact Broker can-i-deploy or
  equivalent) blocks deploy when known consumers are not yet compatible.
- Verify tests cover the deprecation window: old and new response/request
  shapes must both pass until the deprecated field is fully retired.
