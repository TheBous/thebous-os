# Obsidian integration for jira-git-sync — design

## Goal

Every action `jira-git-sync` already performs (branch creation, PR review, review
addressing, doc sync) should also leave a short, linked trace in the user's
Obsidian vault, so the daily dev workflow is fully logged without extra manual
work. This is the first sub-project of `thebous-os`; Granola call-notes
integration and any new orchestration skills are explicitly out of scope here.

## Vault structure

```
Dev/
  Tickets/
    <KEY>/
      plan.md            # from cook's SDD chain (sdd-spec/sdd-design/sdd-tasks)
      review.md           # from review-pr, when the user reviews someone else's PR
      address-review.md   # from address-review, fixes applied to received comments
      calls.md            # reserved for future Granola integration — not written yet
  Daily/
    <YYYY-MM-DD>.md        # index/log for the day, links out to ticket notes touched
```

- Files are kept short and separate (user preference) — no single file accumulates
  the full history of a ticket.
- Every ticket file starts with minimal frontmatter: `ticket`, `pr` (once known),
  `status`, `date` (last updated). No prose in frontmatter.
- Writes are **additive**: an existing file gets a new dated section appended
  (`## <YYYY-MM-DD HH:mm>`), never overwritten wholesale. The daily note gets a
  new bullet line per event, e.g. `- [[DC-443]] — branch created`.

## New shared reference: `references/obsidian-log.md`

Following the repo's existing pattern (`jira-transition.md`,
`naming-conventions-*.md`), a single new reference file defines:

1. How to resolve the vault path (`$OBSIDIAN_VAULT_PATH` from `.env`).
2. The folder/file templates above, with the exact frontmatter block to write
   on first creation of a ticket file.
3. The append procedure (create parent dirs if missing, append section/bullet,
   never truncate).
4. What to do when `$OBSIDIAN_VAULT_PATH` is unset or the path doesn't exist:
   **skip silently, do not fail the workflow**, same rule already used for the
   optional `CONFLUENCE_PARENT_URL` lookup in `new-branch.md`.

Each command file gets **one extra step** added at the point where it currently
reports its own outcome, pointing to this reference instead of duplicating the
logic:

| Command | Obsidian write |
|---|---|
| `new-branch` | create `Dev/Tickets/<KEY>/` if missing, append daily note entry |
| `cook` | append/create `plan.md` with the SDD chain's output, append daily note entry |
| `review-pr` | append `review.md` with the verdict summary, append daily note entry |
| `address-review` | append `address-review.md` with resolved items summary, append daily note entry |
| `create-doc` / `update-doc` | append the Confluence page link to the ticket file (no content duplication), append daily note entry |

`merge-pr`, `tag`, `verify-resolved`, `serve-up`/`serve-down`, `setup` are
untouched — no Obsidian-relevant state change happens there.

## Configuration

- New `.env` variable: `OBSIDIAN_VAULT_PATH` (absolute path to the vault root,
  e.g. `/Users/lucvalse/Documents/Obsidian/lucvalse`).
- `commands/setup.md` gains a step asking for this path (optional — Enter to
  skip, same UX as the existing optional `CONFLUENCE_PARENT_URL` prompt).

## Error handling

- Missing/invalid `OBSIDIAN_VAULT_PATH` → skip the Obsidian step, no warning
  spam beyond a single line in the final confirmation ("Obsidian: skipped, no
  vault configured").
- Vault path set but `Dev/` doesn't exist yet → create it (and subfolders) on
  first write; this is expected on a fresh vault, not an error.
- Never let an Obsidian write failure (e.g. disk permission) abort the main
  workflow (branch creation, PR review, etc.) — catch and report, keep going.

## Testing

This repo verifies commands via `evals/evals.json5` (skill-creator eval
schema) rather than unit tests, since commands are prompt-instructions, not
code. Add one eval per touched command asserting the new Obsidian step, e.g.
for `new-branch`:

```json5
{
  command: "new-branch",
  prompt: "Create a new branch for ticket DC-443, Obsidian vault configured",
  expected_output: "... creates Dev/Tickets/DC-443/ in the vault and appends an entry to today's daily note ...",
  expectations: [
    "Does not write to Obsidian before the branch and Jira transition succeed",
    "Skips the Obsidian step without failing when OBSIDIAN_VAULT_PATH is unset"
  ]
}
```

## Out of scope (deferred)

- Granola call-notes integration (`calls.md` stays a reserved, unwritten file).
- Syncing the same instructions into `.opencode/command/*.md`, `.codex-plugin`,
  `gemini-extension.json` mirrors — this design targets the Claude Code
  `commands/*.md` + `references/` path only; multi-platform sync is a
  follow-up decision, not assumed here.
- Any Dataview/query layer inside Obsidian — plain markdown + frontmatter only.
