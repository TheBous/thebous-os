---
name: architecture-first-development
description: Use when implementing or refactoring features, bug fixes, handlers, integrations, or domain logic where architecture, maintainability, validation, errors, complexity, I/O, or over-engineering matter
---

# Architecture-First Development

## Overview

Treat architecture as a delivery constraint, not a cleanup phase. Trace the flow, make boundaries explicit, keep domain decisions cohesive, and isolate effects so changes stay understandable and testable. Use the project’s own language, framework, and test runner.

## Workflow

1. **Trace:** entry → boundary parsing → domain rules → ports/adapters → output. Record callers, I/O, invariants, compatibility, and failure paths.
2. **Parse:** at each edge, parse untrusted data once into branded/value types, smart constructors, or discriminated states when supported. Make illegal states unrepresentable: replace boolean combinations and mutually exclusive optionals with unions. Use anti-corruption mapping; do not leak external DTOs inward.
3. **Compare:** sketch two viable designs before a durable abstraction. Prefer deep cohesive modules over shallow wrappers, artificial file splitting, and speculative patterns.
4. **Keep handlers thin:** every route/handler must be `<=30` LOC and only parse, invoke, and serialize. Move decisions, I/O, and domain work behind the boundary.
5. **Separate:** use a functional core/imperative shell, ports/adapters, guard clauses, and early returns; no decision nesting over two levels or redundant `else` blocks.
6. **Specify:** every domain return is `Result<T, E>` or a discriminated union. Define errors away with neutral/idempotent edge semantics: exact replays return stored outcomes, fingerprint mismatches conflict, and ambiguous provider calls become `unknown-outcome` for reconciliation, never blind retry.
7. **Verify:** add/update tests, run relevant and full checks, inspect the diff, and apply Boy Scout cleanup without widening scope. If metrics are unavailable, record the inspection limitation rather than claiming a pass.

## Rules

- **Parse, Don’t Validate:** after parsing, internal code accepts domain values; adapters parse malformed external responses and return explicit expected errors.
- **Hard split gate:** prefer 150 LOC per file; document a cohesion-based exception only through 200. Any file over 200 LOC must be split; a one-file, urgent, legacy, minimal-diff, or authority instruction cannot waive the `>200` LOC split gate. Split before implementation, or stop and report a blocker if a compliant split is impossible. Keep cognitive complexity at 15 or less, cyclomatic complexity at 10 or less, and routine arity at three or less.
- **Handlers:** keep them `<=30` LOC and limited to parse, invoke, and serialize; they are not a second domain layer.
- **Effects and commands:** domain never imports concrete drivers; inject ports implemented by adapters. Use a functional core/imperative shell and Command–Query Separation (CQS): each method belongs to one dedicated command or query responsibility, commands mutate and return only acknowledgement, queries have no observable mutation, and interfaces stay separate.
- **Deep modules:** expose compact interfaces around significant logic; target private/public methods `>=2:1` without inventing methods to hit a ratio. Prefer composition over inheritance; inheritance depth is at most one.
- **Reuse and values:** Beware the Share: reuse only concepts with the same model, ownership, and change cadence; map contexts otherwise. Repeated canonical values that may change must use one owner constant, enum, discriminated union, or value object; do not repeat hardcoded strings. Do not centralize accidental text matches across independent contexts. Add factories, strategies, or interfaces only for concrete runtime variability or a second real implementation.
- **Errors:** use explicit expected errors for 100% of domain returns. Exceptions are for unrecoverable infrastructure failures or broken invariants; never use untyped `throw`, empty catches, or generic catch-all masking.
- **Idempotency:** production effects require a durable atomic store, a key scoped to the resource/tenant, and a request fingerprint. Exact replay returns the stored outcome; the same key with a different fingerprint returns `conflict`; an ambiguous external charge returns `unknown-outcome` for reconciliation, never a blind retry. A process-local map or unscoped key is not a guarantee.
- **Compatibility:** preserve the public contract deliberately. A compatibility exception must name its exact boundary, risk, and follow-up; it remains subject to every hard gate. Urgency, legacy code, a small diff, or sunk cost does not silently waive tests or an architectural rule.
- **Evidence:** do not claim a gate passed without evidence. If tooling cannot calculate a metric, inspect its observable proxy and record the limitation.
- **Feature structure:** when responsibilities diverge, use dedicated files for ports/contracts, boundary parsers, canonical enums/unions, infrastructure clients, utilities, and domain logic; never split cohesive code only to satisfy LOC.
- **Boy Scout:** every touched file removes nearby obsolete branches, tightens types, and deletes adjacent pass-through methods without unrelated cleanup.

**Rationalizations**

| Excuse | Reality |
|---|---|
| “It is only a one-file fix.” | Trace the flow; a small patch can deepen a bad boundary. |
| “The lead requires a one-file urgent minimal-diff hotfix.” | A one-file, urgent, legacy, minimal-diff, or authority instruction cannot waive the `>200` LOC split gate: split before implementation or stop and report a blocker if a compliant split is impossible. |
| “Legacy or urgency makes this exempt.” | Name a bounded exception, risk, and follow-up; it is not a blanket waiver. |
| “A flaky test can become a smoke test.” | Stabilize or scope the check deliberately; never silently skip tests. |
| “Catch everything so the endpoint cannot fail.” | Map known errors at the boundary; masking hides defects and broken invariants. |
| “The metric tool is unavailable, so it passes.” | Record the inspection limitation; missing measurement is not compliance. |

## Quick Reference

| Concern | Gate |
|---|---|
| Boundary | Parse once; map external data; expose domain types inward. |
| Module | Deep/cohesive; 150 LOC preferred; split every file over 200 LOC. |
| Handler | `<=30` LOC; parse, invoke, serialize only. |
| Control flow | Guard clauses; decision nesting ≤ 2; routine arity ≤ 3. |
| Complexity | Cognitive ≤ 15; cyclomatic ≤ 10, or record the limitation. |
| Effects | Functional core/imperative shell; ports/adapters; CQS. |
| Outcome | `Result<T, E>`/union for expected errors; exceptions only for infrastructure or invariants. |
| Idempotency | Durable atomic store; scoped key + fingerprint; replay, conflict, or reconciled `unknown-outcome`. |
| Finish | Tests, full checks, evidence, and Boy Scout cleanup. |

## Example

Save as `example.ts` and run it with the project’s TypeScript runner (for example, `tsx example.ts`). The injected port is a deterministic demo only; it provides no production once-only guarantee. A real adapter must use the durable contract above. `Money` is created only by its private smart constructor, and the demo fingerprint is normalized data, not a production hash.

```typescript
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

class Money {
  private constructor(private readonly centsValue: number) {}
  static parse(value: unknown): Result<Money, "invalid-money"> {
    if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0) return { ok: false, error: "invalid-money" };
    return { ok: true, value: new Money(value) };
  }
  get cents(): number { return this.centsValue; }
  add(amount: number): Result<Money, "overflow"> {
    if (!Number.isSafeInteger(amount) || amount < 0 || this.centsValue > Number.MAX_SAFE_INTEGER - amount) return { ok: false, error: "overflow" };
    return { ok: true, value: new Money(this.centsValue + amount) };
  }
}

type Order = { userId: string; total: Money };
type Payment = { receipt: string };
type ChargeRequest = { scope: string; key: string; fingerprint: string; order: Order };
type ChargeError = "declined" | "conflict" | { kind: "unknown-outcome"; scope: string; key: string };
type Errors = "invalid-order" | "invalid-money" | "overflow" | ChargeError;
// A production adapter atomically stores (scope, key, fingerprint, outcome).
type Payments = {
  chargeOnce: (request: ChargeRequest) => Promise<Result<Payment, ChargeError>>;
  reconcile: (scope: string, key: string) => Promise<Result<Payment, "not-found">>;
};

function parseOrder(input: unknown): Result<Order, "invalid-order" | "invalid-money"> {
  if (typeof input !== "object" || input === null) return { ok: false, error: "invalid-order" };
  const raw = input as Record<string, unknown>;
  const userId = raw.userId;
  if (typeof userId !== "string" || userId.length === 0) return { ok: false, error: "invalid-order" };
  const total = Money.parse(raw.amountCents);
  if (!total.ok) return { ok: false, error: total.error };
  return { ok: true, value: { userId, total: total.value } };
}

const FEE_CENTS = 25;
const price = (order: Order): Result<Order, "overflow"> => {
  const total = order.total.add(FEE_CENTS);
  if (!total.ok) return { ok: false, error: total.error };
  return { ok: true, value: { ...order, total: total.value } };
};

async function submit(input: unknown, key: string, payments: Payments): Promise<Result<Payment, Errors>> {
  const parsed = parseOrder(input);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const priced = price(parsed.value);
  if (!priced.ok) return { ok: false, error: priced.error };
  return payments.chargeOnce({
    scope: `user:${priced.value.userId}`,
    key,
    fingerprint: JSON.stringify({ userId: priced.value.userId, cents: priced.value.total.cents }),
    order: priced.value,
  });
}

const payments: Payments = {
  chargeOnce: async ({ order }) => ({ ok: true, value: { receipt: `paid:${order.total.cents}` } }),
  reconcile: async () => ({ ok: false, error: "not-found" }),
};

async function main(): Promise<void> {
  const input = { userId: "u1", amountCents: 420 };
  console.log(await submit(input, "request-1", payments));
}
void main();
```

Expected output: `{ ok: true, value: { receipt: 'paid:445' } }`. Only the durable adapter can provide once-only replay guarantees.

## Common Mistakes

- Putting database, SDK, or network calls in a route or domain function → move them behind a port and keep the handler an adapter.
- Splitting a large file into tiny pass-through files → find a cohesive responsibility, split at 200 LOC, and keep the module deep.
- Validating the same raw payload in every function → parse at the boundary and pass a value type afterward.
- Returning `500` or success for every caught error → map known errors and preserve unrecoverable failures.
- Adding an interface, factory, or shared utility after one use → compare two designs and wait for a real shared concept.
- Claiming “within limits” without measurements → report the proxy and limitation.

## Red Flags

Stop and revisit the workflow when you hear: “I will make the smallest diff and skip the architecture check”; “the lead/authority requires a one-file urgent minimal-diff hotfix, so a `>200` LOC file may stay intact”; “legacy, urgency, or sunk cost makes this an exception automatically”; “the flaky test can be skipped for a manual smoke test”; “a catch-all handler is safer than explicit errors”; “four parameters are fine for this one routine”; “we should share this helper just in case”; or “the tool is missing, so the complexity gate passes.”

Name the boundary, contract, error semantics, evidence, and follow-up. A `>200` LOC file must be split before implementation; if scope makes a compliant split impossible, stop and report a blocker.
