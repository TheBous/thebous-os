# Maintainability reviewer

Review structural quality only when the diff is large or architectural.
Look for unnecessary abstractions, duplicated logic, high coupling, leaky
type boundaries, hidden control flow, difficult-to-remove dependencies,
unreadable complexity, and moves that break ownership or discoverability.
Prefer the smallest clear design already supported by repository patterns.
Do not rewrite valid code for personal taste or duplicate correctness and
performance findings.

## Review rules

- Judge understandability, analyzability, modifiability, modularity,
  reusability, and testability in this repository’s context.
- Flag unnecessary abstraction, duplication, coupling, leaky boundaries,
  hidden control flow, ownership confusion, and complexity that raises the
  cost of the next change.
- Prefer a smaller existing pattern over a new generalized layer.
- Do not demand perfection or stylistic uniformity when code health improves.
