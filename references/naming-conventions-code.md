# Code Naming Conventions

General language-agnostic rules. Framework-specific conventions live in sibling files (`naming-conventions-nextjs.md`, `naming-conventions-db.md`).

## Language

- **All identifiers in English.** No Italian variable, function, type, or file names. Localized strings (UI copy, translations) are not subject to this rule.

## Field suffix rules

Suffix dictates type. Mismatches are review issues.

| Suffix    | Type     | Example                          |
|-----------|----------|-----------------------------------|
| `*Id`     | `number` (numeric identifier) | `originatorId: number`     |
| `*Uuid`   | `string` (UUID)               | `leadUuid: string`         |
| `*Type`   | `string` (enum-like)          | `documentType: string`     |
| `*Amount` | `number` (money, in cents or units, NOT formatted) | `netIncomeAmount: number` |
| `*Perc`   | `number` (percentage 0–100, not 0–1) | `interestRatePerc: number` |
| `*Code`   | `string` (code/identifier, e.g. tax code) | `taxCode: string` |
| `*At`     | `Date` / `string` (ISO timestamp) | `createdAt: Date`     |
| `*Date`   | `string` (ISO date, no time) | `birthDate: string`         |
| `*Count`  | `number` (integer)            | `attemptCount: number`     |
| `*Flag`   | `boolean`                     | avoid; prefer `is*` / `has*` |

## Casing

- **Variables, functions, fields:** `camelCase`
- **Types, interfaces, classes:** `PascalCase`
- **Constants (top-level immutable):** `SCREAMING_SNAKE_CASE`
- **Files:** `kebab-case.ts` / `kebab-case.tsx`
- **Test files:** `*.test.ts` co-located in `__tests__/` next to the module under test

## Reserved / forbidden

- **Never** name a type `FormData` — it conflicts with the DOM global. Use `<Domain>FormValues` or `<Domain>FormInput`.
- Avoid `data`, `info`, `obj`, `temp` — non-descriptive.
- Avoid `*Util` / `*Helper` suffixes for type names — verb-based names communicate intent better.

## Functions

- Action functions start with a verb: `findOriginator`, `writeUserIncomeField`, `dispatchOcrField`.
- `findOrCreate*` for lookup-with-side-effect insert.
- Boolean-returning functions: `is*`, `has*`, `should*`.
- Async functions returning `T | null` should NOT be named `get*` if `null` is a routine outcome — prefer `find*`.

## Comments

- Default to writing none. Only add for non-obvious *why*.
- Never use comments to restate the code.
- Update comments when the code changes — stale comments are a review-blocker.
