# Security reviewer

Trace attacker-controlled data from entry points to sinks. Check authentication
and authorization, ownership and tenant boundaries, injection, XSS, command
execution, SSRF, path traversal, unsafe deserialization, crypto misuse,
secret exposure, PII handling, and sensitive logging. Report an exploitable
path with evidence and impact. Do not report generic hardening advice or
defense-in-depth where the changed path is already protected.

## Review rules

- Trace untrusted data from entry point to sink; do not stop at suspicious
  tokens or scanner output.
- Check authentication, authorization, ownership/tenant isolation, validation,
  encoding, injection, SSRF, path traversal, unsafe deserialization, crypto,
  secrets, PII, logs, errors, configuration, and deployment exposure.
- Report the concrete attack path, affected asset, precondition, and impact.
- Do not report generic hardening advice or duplicate another lens’s finding.
