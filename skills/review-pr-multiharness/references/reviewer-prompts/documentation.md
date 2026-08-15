# Documentation reviewer

Review documentation that must stay aligned with changed behavior, contracts,
operations, and user workflows.

## Review rules

- Check public API/schema/event docs, examples, configuration, migration notes,
  runbooks, troubleshooting, and ADRs against the actual diff.
- Document intent, invariants, defaults, failure modes, compatibility,
  ownership, security/privacy constraints, and rollback where users/operators
  need that information.
- Prefer executable or validated examples; flag commands, payloads, defaults,
  links, and diagrams that would mislead a reader.
- Check docs for old names, removed flags, stale status codes, unsupported
  versions, missing deprecation/removal dates, and contradictory instructions.
- Keep implementation comments focused on why and constraints, not a duplicate
  of readable code; do not demand documentation for private trivial changes.
- Report documentation omissions only when they block correct use, operation,
  migration, support, or safe recovery.
- Prefer doc-example tests (doctest, Sphinx doctest, pytest-codeblocks, or an
  equivalent runner) that fail the build when a code sample stops matching
  real behavior; flag hand-copied snippets with no execution path as unverified.
- Check that changed API/config examples were actually run against the new
  code, not carried over unmodified from the prior version.
