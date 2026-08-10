# Database Naming Conventions

General RDBMS rules. ORM-specific bindings (e.g. Drizzle) live in `naming-conventions-nextjs.md`.

## Casing

- **Tables:** `snake_case`, plural (`debit_lines`, `originators`, `survey_submissions`)
- **Columns:** `camelCase` quoted in SQL (`"originatorId"`, `"createdAt"`, `"netIncomeAmount"`)
- **Indexes:** `<table>_<column(s)>_<purpose>` (e.g. `originators_name_lower_trim_unique`, `debit_lines_lead_id_idx`)
- **Constraints:** descriptive (`<table>_pkey`, `<table>_<column>_fk`, `<table>_<column>_unique`)
- **Migrations:** numbered + slug, owned by the migration tool — do NOT rename.

## Column suffixes (must match code)

| Suffix in column | Type in DB | Notes |
|------------------|-----------|-------|
| `Id`             | `serial` / `integer` | Numeric identifiers |
| `Uuid`           | `uuid`    | UUID v4, stored as `uuid` not `text` |
| `At`             | `timestamp with time zone` | Always TZ-aware |
| `Date`           | `date`    | No time component |
| `Amount`         | `numeric(p,s)` or `integer` (cents) | Document the unit in the column comment |
| `Perc`           | `numeric` | 0–100 scale, not 0–1 |
| `Type`           | `text` (or `enum` if curated) | |
| `Code`           | `text`    | |

## Required columns on every table

- `id` — primary key
- `createdAt` — `timestamp with time zone NOT NULL DEFAULT NOW()`
- `updatedAt` — `timestamp with time zone NOT NULL DEFAULT NOW()` (with trigger or app-level update)

## Nullability

- **Default to `NOT NULL`.** Make nullability intentional.
- Foreign keys: `NOT NULL` unless the relationship is genuinely optional. Document the reason in the schema if nullable.
- Text columns that never make sense empty should be `NOT NULL` — let the FK / app enforce presence, not a NULL bypass.

## Indexes & constraints

- Add a `UNIQUE` index on any column the application treats as a natural key (e.g. `email`, `taxCode`).
- For case-insensitive uniqueness, use a functional index on `LOWER(...)` or `LOWER(TRIM(...))` and verify the column is `NOT NULL` — `NULL` bypasses functional unique indexes silently.
- Foreign keys: always declare `ON DELETE` behavior explicitly (`CASCADE`, `RESTRICT`, `SET NULL`).

## Avoid

- **PostgreSQL arrays** for relational data — use a join table.
- **JSONB for relational data.** Acceptable only for snapshots / opaque payloads (e.g. webhook bodies).
- Storing money as `float` / `double precision` — use `numeric` or integer cents.
- Storing dates as `text` — use `date` / `timestamp with time zone`.

## Migration hygiene

- Hand-written migrations must include a header comment explaining the *why*.
- Order matters for FK-affecting changes: repoint FKs before deleting rows.
- Idempotent operations preferred (`UPDATE ... WHERE x <> trim(x)`, `INSERT ... ON CONFLICT DO NOTHING`).
- Document any assumption the migration relies on but does not enforce (e.g. "assumes `name IS NOT NULL` per schema").

## Enums / status columns

- Prefer a `text CHECK (col IN (...))` constraint or a curated lookup table over native PostgreSQL enums (easier to evolve).
- Status values: choose one casing (kebab/snake) and stick to it project-wide.
- Mirror the union of allowed values in the application code (TypeScript union, etc.) so the type system catches drift.
