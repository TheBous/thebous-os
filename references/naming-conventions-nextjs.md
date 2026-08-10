# Next.js Naming Conventions

Conventions specific to a Next.js App Router project. Generic rules live in `naming-conventions-code.md` and `naming-conventions-db.md`. Only apply this file if the repo is actually a Next.js App Router project.

## App Router special files

These names are reserved by Next.js — do NOT rename, do NOT use them for anything else.

| File | Purpose | Notes |
|------|---------|-------|
| `page.tsx` | Route page | Server Component by default |
| `layout.tsx` | Shared layout for a segment | Server Component by default |
| `loading.tsx` | Suspense fallback | |
| `error.tsx` | Error boundary | Must be a Client Component (`"use client"`) |
| `not-found.tsx` | 404 boundary | |
| `route.ts` | Route handler (REST/webhook) | Lowercase HTTP verb exports: `GET`, `POST`, etc. |
| `template.tsx` | Re-rendering layout | Use sparingly |
| `default.tsx` | Parallel route fallback | |

## Route groups

- Use parentheses for non-routing folders: `app/(auth)/`, `app/(customer)/`, `app/(public)/`.
- Group by layout/access concern, not by feature.
- Route groups MUST NOT collide on resolved paths — two `(group)/page.tsx` at the same URL is an ambiguity error.

## Dynamic segments

- `[slug]` — single dynamic segment
- `[...slug]` — catch-all
- `[[...slug]]` — optional catch-all
- Folder name = param name. Keep param names descriptive (`[leadId]`, not `[id]`) when the surrounding context is generic.

## Component vs Server Code boundary

- **Server Components by default.** Add `"use client"` only when the component needs hooks, browser APIs, or event handlers.
- A `"use client"` file becomes a client boundary — everything imported into it is bundled client-side. Keep heavy server-only deps out of files that cross this line.
- **Server Actions:**
  - File-level `"use server"` directive at the top of the file.
  - Live in `src/server-actions/` (project-wide) or co-located in a `server-actions/` subfolder for feature-scoped actions.
  - NEVER add `"use server"` to a file that also exports React components.
  - Action functions: verb-prefixed (`updateDatiPersonali`, `saveUserIncome`, `createLead2026`).

## API routes / route handlers

- Path: `src/app/api/<resource>/route.ts`.
- Export named HTTP method functions (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`).
- Use `NextRequest` / `NextResponse` types from `next/server`.

## Webhook handlers

- Path: `src/app/webhooks/<provider>/route.ts` (e.g. `webhooks/stripe`, `webhooks/yousign`, `webhooks/hubspot`).
- Always verify signature before processing the body.
- Return 200 quickly; do heavy work async or queue it.

## React components

- **Component files:** `kebab-case.tsx` (`upload-document-dialog.tsx`).
- **Component identifiers:** `PascalCase` (`UploadDocumentDialog`).
- Prefer the `function` keyword over arrow functions for components.
- Default-export pages (`page.tsx`, `layout.tsx`); named-export everything else.

## Forms

- Library: `@tanstack/react-form` (NOT `react-hook-form`).
- Validation: Zod schemas, fed to TanStack Form via the Zod adapter.
- Form value types: `<FormName>FormValues` (e.g. `DatiPersonaliFormValues`).
- Schemas live in `src/lib/schemas/<form-name>.ts`.

## Path aliases

- `@/*` → `src/*`. Always use `@/` for imports across feature boundaries; keep relative imports (`./`, `../`) for siblings within the same feature folder.

## Drizzle (DB layer)

- Schema: `src/lib/db/schema.ts`.
- Drizzle table identifiers in code: `*Table` suffix (`originatorsTable`, `debitLinesTable`).
- Inferred types: `<Entity> = typeof <entity>Table.$inferSelect`, `<Entity>Insert = typeof <entity>Table.$inferInsert`.
- Relations declared via `relations()` — not via `*_id` columns alone.
- Migrations live in `.drizzle/` with auto-generated slugs (`0063_sparkling_bloodstorm.sql`) — do NOT rename.

## Metadata & SEO

- Static metadata: export a `metadata` object from the page/layout.
- Dynamic: export `generateMetadata` (typed `Metadata` from `next`).
- Don't put user-specific data in metadata of cached pages.

## Async APIs (Next.js 15+)

- `cookies()`, `headers()`, `params`, `searchParams` are async. Always `await` them.
- `params` and `searchParams` arrive as `Promise<{...}>` in `page.tsx` / `layout.tsx` props.

## Common pitfalls

- Importing a server-only module (`fs`, DB client, secrets) into a `"use client"` file → bundle leak. Use the `server-only` package as a guard on truly server-only modules.
- Mixing Server Action exports and React component exports in one file — illegal.
- Calling a Server Action from a Server Component without wrapping it in a form / button event — works but defeats the point. Server Components can call server functions directly without needing `"use server"`.
- Forgetting `revalidatePath` / `revalidateTag` after a Server Action mutation.
