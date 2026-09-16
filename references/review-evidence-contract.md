# Review Evidence Contract

Use this contract before publishing a review finding or assigning a
revalidation verdict. The consuming workflow owns its severity, verdict names,
and GitHub actions; this reference owns the evidence standard.

## Required record

Record every judgment with:

| Field | Required content |
|---|---|
| Scope or concern | The requirement, contract, PR goal, or original review concern |
| Current-code anchor | Exact changed-line anchor for an initial review, or the current file and line or searched behavior anchor for revalidation |
| Preconditions | Concrete input, state, timing, permission, or failure condition |
| Execution path | The actual call path from the precondition to the changed code |
| Impact | Concrete user, data, security, reliability, or operational consequence |
| Evidence | Current source, call site, test result, trace, contract, or corroborated reply |
| Check or reproduction | Smallest executed check, reproduction, or explicit reason it was unavailable |
| Confidence | `high`, `medium`, or `low` |

## Decision rules

- Treat every reviewer output or author reply as a claim until current-code
  evidence supports it.
- Read the complete affected function and relevant callers or contracts.
- Try to falsify the judgment before recording it as confirmed.
- The absence of evidence is not proof of a defect.
- Missing safeguards, unspecified traffic, possible external consumers, and
  generic "may" or "could" risks remain unverified until a concrete path and
  impact are demonstrated.
- A missing anchor or missing evidence cannot support a confirmed judgment.

Map the evidence result to the consuming workflow:

| Workflow | Confirmed judgment |
|---|---|
| Initial PR review | `confirmed` only; it may become a P0-P2 finding |
| Review revalidation | `fixed` only when current code satisfies the concern; `partial` or `not-fixed` only for a concrete remaining gap; otherwise `needs-look` |

Example of sufficient evidence:

```text
IMPORTANT src/retry.js:18
When a 429 response reaches this loop, the PR retries immediately because the
changed path has no backoff or Retry-After handling. The upstream client returns
429 unchanged, so one request now produces three immediate requests. A test that
returns 429 twice and asserts request timestamps would fail before adding a
bounded delay. Add bounded backoff and test the rate-limit path.
```
