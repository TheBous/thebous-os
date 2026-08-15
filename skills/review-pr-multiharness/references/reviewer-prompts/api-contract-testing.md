# API-contract-testing reviewer

Review tests and gates that verify consumer/provider behavior at API or message
boundaries.

## Review rules

- Identify the authoritative contract and all meaningful consumers; test actual
  requests, responses, errors, headers, status codes, events, and semantics.
- Check provider verification against consumer expectations, including optional,
  missing, unknown, null, enum, pagination, and error cases.
- Ensure contract tests run in CI and block incompatible changes before deploy;
  local mocks alone are not provider evidence.
- Keep examples meaningful and avoid over-constraining additive fields or
  incidental ordering that the contract does not promise.
- Verify version selection, provider state, authentication, schema format, and
  backward/forward compatibility during mixed-version rollout.
- Report the exact consumer assumption that can fail and the missing gate.
- Require a machine schema-diff (OpenAPI/Buf/Avro/Protobuf) gate that flags
  removed fields, narrowed types, and new required fields independently of
  hand-written contract tests.
- Check a broker or registry (Pact Broker can-i-deploy, schema-registry
  compatibility check) verifies every known consumer/provider version pair,
  not only the latest.
