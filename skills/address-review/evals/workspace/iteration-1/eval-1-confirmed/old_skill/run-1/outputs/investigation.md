# Investigation

Read the assigned old skill snapshot in full, then extracted only id, prompt and files for eval 1 from evals.json using Python. Did not inspect expected_output, assertions, other cases, results, or comparison skill versions.

Files actually read:
- skills/address-review/evals/workspace/skill-snapshot/SKILL.md
- skills/address-review/evals/evals.json (parsed to print only eval 1 id/prompt/files)
- skills/address-review/evals/fixtures/confirmed/route.ts
- skills/address-review/evals/fixtures/confirmed/repository.ts
- skills/address-review/evals/fixtures/confirmed/entry.ts
- references/naming-conventions-code.md
- references/evaluation-rubric.md

Commands executed, in order:
1. cat skills/address-review/evals/workspace/skill-snapshot/SKILL.md
2. Python json.load of skills/address-review/evals/evals.json, selecting case id 1 and printing only id/prompt/files.
3. rg --files skills/address-review/evals/fixtures/confirmed
4. cat skills/address-review/evals/fixtures/confirmed/route.ts skills/address-review/evals/fixtures/confirmed/repository.ts skills/address-review/evals/fixtures/confirmed/entry.ts
5. cat references/naming-conventions-code.md references/evaluation-rubric.md
6. mkdir -p assigned output directory; write response.md and investigation.md with shell heredocs.

Static tracing: entry.handleRequest forwards to route.getInvoice. The route requires a non-null session but passes only invoiceId to repository.readInvoice. The repository finds only by id, so org-a can receive invoice-b from org-b. No runtime execution or tests were needed or performed. Proposed a single route guard and stopped for approval at the first user response, as requested. No fixture edits or external service calls.
