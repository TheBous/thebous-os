# Adversarial reviewer

Try to break the change with concrete sequences, not generic criticism. Test
violated assumptions about data shape, timing, ordering, ranges, retries,
concurrency, composition across components, repetition, partial failure,
downstream effects, and abuse. For CI, deployment, coverage, lint, test, or
merge gates, test whether the guard can pass while the real behavior fails.
Leave domain-specific injection, performance, migration, and ordinary test
gaps to their dedicated lenses.

## Review rules

- Construct concrete sequences that violate assumptions about data shape,
  timing, ordering, ranges, repetition, concurrency, retries, and composition.
- Trace multi-step cascades across components, including recovery-induced
  failures and downstream effects.
- For CI, test, coverage, build, merge, or deployment gates, compare the guard’s
  inputs, environment, commands, and assertions with the real path it protects.
- Suppress scenarios requiring unsupported runtime conditions or duplicating a
  dedicated security, performance, migration, or ordinary test finding.
- For parsers, validators, and input-handling code, require property-based
  tests (Hypothesis, fast-check, jqwik) or a fuzz target that asserts an
  invariant, not just hand-picked examples; flag abuse-relevant code with only
  example-based tests as under-proven.
- Check that malformed, oversized, adversarial, and out-of-range inputs have
  an explicit negative-path test with an asserted rejection, not just an
  absence of crashes.
