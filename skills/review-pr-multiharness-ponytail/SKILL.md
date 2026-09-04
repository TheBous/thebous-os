---
name: review-pr-multiharness-ponytail
description: Use when the user invokes review-pr-multiharness-ponytail, asks for a ponytail PR review, or wants a merge decision plus what to cut. Same specialist coverage as review-pr-multiharness with a required over-engineering deletion pass.
---

# PR Review Multiharness + Ponytail

A merge decision that can be defended in production, plus a deletion pass.
The diff's best extra outcome is getting shorter.

**REQUIRED SUB-SKILL:** Follow [`skills/review-pr-multiharness/SKILL.md`](../review-pr-multiharness/SKILL.md) in full.
Do not copy that workflow here. This skill only adds the ponytail lens and
how it changes roster, report, and GitHub posting. Parent steps still run:
explain-change, danger score, JSON dispatch contract, report-only GitHub rules.

## Overrides

- Always run `correctness` and `ponytail`. They are distinct lenses: never
  coalesce `ponytail` into `maintainability`.
- `ponytail` occupies one of the parent's per-score slots. Capability tier:
  `fast`. Use parent count N. Never exceed N except the 1→2 override below.
  Hard cap remains 10.
- Minimum roster size is 2. If the parent danger table would dispatch 1,
  dispatch 2 (`correctness` + `ponytail`) and record the override in
  `Coverage`.
- If required lenses plus optionals would exceed N (or 10), drop the
  lowest-ranked optional. Never drop `correctness` or `ponytail`.
- Before dispatch, inline all three ponytail files into that subagent's
  prompt (parent's one-prompt rule does not apply to this lens). The prompt
  is the output contract; the other two are the judgment engine. Do not
  dispatch ponytail with the prompt alone.
  - [`references/reviewer-prompts/ponytail.md`](references/reviewer-prompts/ponytail.md)
  - [`references/ponytail-core.md`](references/ponytail-core.md)
  - [`references/platform-native.md`](references/platform-native.md)
  Every other selected lens still loads its prompt from
  `skills/review-pr-multiharness/references/reviewer-prompts/`.
- Stay report-only. Do not apply ponytail cuts unless the user explicitly
  asks to apply them.

## Ponytail findings

Scope: over-engineering and complexity only. Correctness, security, and
performance stay on their own lenses.

One line per finding: `file:L<line>: <tag> <what>. <replacement>.`

Tags: `delete:` (dead/speculative; replacement is nothing), `stdlib:` (name
the stdlib function), `native:` (name the platform feature), `yagni:`
(abstraction with one implementation), `shrink:` (same logic, fewer lines).

Do not flag the single smoke test or `assert`-based self-check that ponytail
requires. If there is nothing to cut, write `Lean already. Ship.` and skip
the list.

End the section with `net: -<N> lines possible.`

## Report

After the parent report contract, add:

```text
## Ponytail
<one line per finding, or Lean already. Ship.>
net: -<N> lines possible.
```

Ponytail findings are non-blocking (`SUGGESTION`). They do not change the
verdict by themselves. If a cut also is a P0–P2 defect, the other lens owns
severity; do not duplicate it in Actionable Findings.

When GitHub posting is authorized, omit the Ponytail list from GitHub
(treat it like discretionary P3). Keep it in the local report.

## Rationalizations

| Excuse | Reality |
|---|---|
| "Maintainability already covers this" | Maintainability judges structure; ponytail only lists deletions in one-line form. Run both. |
| "Score is 1, no room" | Override to 2. Correctness and ponytail are both required. |
| "The PR is already small" | Small diffs still reinvent stdlib. Run the pass. |
| "Nothing to cut, skip the section" | Write `Lean already. Ship.` so coverage is visible. |
