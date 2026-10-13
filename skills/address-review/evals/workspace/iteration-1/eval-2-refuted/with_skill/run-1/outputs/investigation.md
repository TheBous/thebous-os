# Investigation

Read the canonical address-review skill and only the prompt/files fields for evaluation id 2. Did not inspect expected outputs, assertions, other cases, baseline comparisons, or results.

Fixture files read in full, with line numbers:

- `skills/address-review/evals/fixtures/refuted/entry.ts`
- `skills/address-review/evals/fixtures/refuted/repository.ts`
- `skills/address-review/evals/fixtures/refuted/route.ts`
- `skills/address-review/evals/fixtures/refuted/scope.ts`

Commands executed:

1. `cat skills/address-review/SKILL.md`
2. Python command loading `skills/address-review/evals/evals.json`, selecting id 2, and printing only its `prompt` and `files` fields:
   ```python
   import json
   p=json.load(open('skills/address-review/evals/evals.json'))
   e=next(x for x in p['evals'] if x['id']==2)
   print(json.dumps({k:e[k] for k in ['prompt','files'] if k in e},ensure_ascii=False,indent=2))
   ```
3. `for f in skills/address-review/evals/fixtures/refuted/*.ts; do nl -ba "$f"; done`
4. `mkdir -p skills/address-review/evals/workspace/iteration-1/eval-2-refuted/with_skill/outputs` and two quoted heredocs writing `response.md` and this `investigation.md` within that output directory.

Verification: refuted. The entry forwards the session; the wrapper rejects missing sessions and derives the organization scope from the session; the repository filters by both invoice ID and scope organization. The alleged org-a / invoice-b read returns 404 and null. Code inspection establishes this directly; no execution or tests were needed. No fixture files changed and no external services contacted. Stopped at the first substantive user response, as requested.
