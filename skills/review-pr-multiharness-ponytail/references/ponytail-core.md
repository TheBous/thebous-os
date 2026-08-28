<!-- Source: DietrichGebert/ponytail (skills/ponytail, ponytail-audit, ponytail-debt), MIT License. Copyright (c) 2026 DietrichGebert -->

# Ponytail judgment (review)

This is the judgment engine behind `ponytail-review`. The one-line tags are
the output format; this file is how to decide. Climb the ladder against every
changed hunk after tracing the real flow. Do not apply cuts.

Lazy means efficient, not careless. The best code is the code never written.

## The ladder

Stop at the first rung that holds. The ladder runs *after* you understand the
problem, not instead of it: read the changed files, trace the flow end to end,
then climb.

1. **Does this need to exist at all?** Speculative need, unused flexibility,
   feature flags nobody sets → `delete:`.
2. **Already in this codebase?** A helper, util, type, or pattern a few files
   over → `delete:` the reimplementation, name the existing one.
3. **Stdlib does it?** Hand-rolled loop, parser, or util the language ships →
   `stdlib:`, name the function.
4. **Native platform feature covers it?** Check
   [`platform-native.md`](platform-native.md) before flagging a new widget,
   date lib, or CSS-in-JS → `native:`, name the feature.
5. **Already-installed dependency solves it?** New package for what a few
   lines or an existing dep already does → `delete:` the new dep.
6. **Can it be one line?** Same logic, fewer lines → `shrink:`, show the
   shorter form.
7. **Only then:** leave it. Not every addition is bloat.

Two rungs work → take the higher one. The first lazy replacement that
preserves behavior is the right one — once you actually know what the hunk
touches.

**Bug-fix hunks:** a report names a symptom. If the PR guards one caller of a
shared function, flag the sibling callers still broken as `yagni:` of a
local patch: the lazy fix is one guard at the shared source.

## Rules

- No unrequested abstractions: interface with one implementation, factory
  for one product, config for a value that never changes → `yagni:`.
- No boilerplate, no scaffolding "for later".
- Deletion over addition. Boring over clever.
- Fewest files possible. Shortest working diff wins — but only once you
  understand the problem. The smallest change in the wrong place is a
  second bug, not a win: do not flag a correct root-cause fix as `shrink:`
  just because a wrong one-liner is shorter.
- Two stdlib options, same size? The edge-case-correct one is not bloat.
- Deliberate shortcuts that cut a real corner must be marked
  `ponytail: <ceiling>, <upgrade path>`.

## When NOT to flag

Never flag as over-engineering:

- input validation at trust boundaries
- error handling that prevents data loss
- security measures
- accessibility basics
- hardware calibration knobs (clocks drift, sensors read off)
- anything the PR description or ticket explicitly requested
- the single smoke test or `assert`-based self-check that ponytail requires
  for non-trivial logic (a branch, loop, parser, money/security path)

If the extra complexity is itself a correctness, security, or performance
defect, do not report it here.

## Hunt (from ponytail-audit, scoped to the diff)

Deps the stdlib or platform already ships, single-implementation interfaces,
factories with one product, wrappers that only delegate, files exporting one
thing, dead flags and config, hand-rolled stdlib.

## `ponytail:` debt in this diff (from ponytail-debt)

Grep the changed files for `(#|//) ?ponytail:`. Each hit is a deliberate
shortcut. Report it as its own line if the comment names no ceiling or no
upgrade trigger (`no-trigger` — those rot). Do not treat a well-formed
`ponytail:` comment as a finding to delete; it is the allowed exception.
A new shortcut without the comment is a `yagni:` or `shrink:` miss: the
ceiling is unmarked.
