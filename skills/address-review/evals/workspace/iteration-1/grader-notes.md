# Independent grading notes

Read all three eval_metadata.json files, all six response.md files, all six investigation.md files, and every fixture source file. Checked factual claims against the current fixture code. Applied the same semantic standard to both skill versions: no requirement for literal classification labels, Italian wording, or a particular response template. A direct, unambiguous source quote counts as code evidence; prose correctness alone does not satisfy an explicit file/line-evidence requirement.

| Case | with_skill | old_skill |
| --- | --- | --- |
| confirmed | 4/4 | 3/4 |
| refuted | 4/4 | 3/4 |
| unverified | 4/4 | 4/4 |
| Total | 12/12 (100%) | 10/12 (83.33%) |

Combined: 22 passed, 2 failed, 24 expectations (91.67%).

## Differences and grading decisions

Both versions correctly identify the real tenant disclosure, reject the false tenant-disclosure claim, and preserve uncertainty about the missing lease adapter. Both recommend the appropriate next action. The observed advantage of the revised skill is concrete source citations in the confirmed and refuted responses, not better substantive classification in this sample.

The old confirmed response correctly describes the session guard, lookup, and return, but does not cite lines or quote those existing code statements. Its proposed guard is not evidence of the existing path. The evidence assertion fails.

The old refuted response quotes the exact repository predicate, which satisfies that portion of the evidence requirement. Its session-derived scope is only paraphrased, without a line citation or direct source quote. The explicit requirement for file/line evidence across the chain therefore fails. Its `fixed` verdict is explained as protection already present and no changes applied; it does not concede a bug, so the keep-existing-code assertion passes. The revised response uses `not-fixed` with an explicit explanation of its meaning. Neither label alone determines the grade.

The old unverified response identifies worker.ts:3, the sole LeaseStore interface in lease-store.ts, and the unique private-adapter comment/injection in entry.ts. This is concrete and verifiable in these tiny files. That assertion asks for concrete code locations, unlike the explicit file/line requirement in the tenant cases, and passes. It does not need the literal word `unverified` because its uncertainty is explicit.

## Assertion quality and limitations

Ten of twelve assertions pass in both configurations and thus do not distinguish these particular executions. They are still meaningful behavioral checks: classification, reachable consequences, appropriate fix or deferral, and avoidance of unsupported reviewer claims. Do not describe the results as a demonstrated improvement in reasoning accuracy; both configurations reached the correct substantive conclusions in all three cases.

Citation requirements drive both failures. If location precision is intended uniformly, normalize the wording across cases: the third case currently permits an unambiguous filename/function/interface anchor while the first two explicitly require file/line evidence. Avoid changing thresholds after seeing results; this grading follows the supplied wording.

These three small fixtures, with one run per configuration, provide limited coverage and no estimate of consistency or significance. The complete tiny repositories make static tracing decisive for tenant access and deliberately make adapter atomicity undecidable. The evals do not cover ambiguous authentication provenance, more indirect tenant enforcement, runtime-only behavior, or actual post-approval fixes.

No execution transcript or independent tool trace was supplied. investigation.md contains self-reported read/command histories. Code conclusions are independently verified; claims of no fixture modifications, no external service access, and actual tool execution cannot be independently established from those reports alone. The assertions grade the first response and do not directly audit those process restrictions.

The old unverified investigation reports a missing snapshot-relative rubric reference and fallback to the embedded verdict table. The revised unverified investigation reports an initial failed save command followed by a successful retry. These issues did not alter the substantive answer; neither is an asserted behavioral failure. Reported process details are not independently corroborated.

All six timing.json files contain null metrics and explicitly state that executor timing/token data was unavailable. No timing, token, or invented execution metrics were added to grading.json. No performance comparison is supported.
