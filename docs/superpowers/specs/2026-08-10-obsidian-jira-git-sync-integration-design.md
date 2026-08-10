# Obsidian integration for jira-git-sync — design

## Goal

Every action `jira-git-sync` already performs (branch creation, PR review, review
addressing, doc sync) should also leave a short, linked trace in the user's
Obsidian vault, so the daily dev workflow is fully logged without extra manual
work. This is the first sub-project of `thebous-os`; any new orchestration
skills beyond this are explicitly out of scope here.

## Where this lives

The user does not want the source repo (`TheBous/github-jira-slack-claudecode`)
touched. Instead, `thebous-os` gets its own one-time copy of the full command
set — it becomes the working copy going forward, not a patch on top of the
original:

- Copy `commands/*.md` (all 13), `references/*.md`, `scripts/helpers.sh`,
  `SKILL.md` from the source repo's `main` branch into `thebous-os` (same
  relative paths, so the existing cross-references between files keep working
  unmodified).
- Skip platform mirrors (`.opencode/`, `.codex-plugin/`, `gemini-extension.json`)
  — thebous-os only needs to work as a Claude Code skill.
- This is a snapshot, not a live fork: no sync-back mechanism to the source
  repo. Future improvements to either copy are manual.
- Obsidian hooks are added directly into the copied `commands/*.md` files
  (per the table below) plus the new `references/obsidian-log.md`.

## Vault structure

```
Dev/
  Tickets/
    <KEY>/
      plan.md            # from cook's SDD chain (sdd-spec/sdd-design/sdd-tasks)
      review.md           # from review-pr, when the user reviews someone else's PR
      address-review.md   # from address-review, fixes applied to received comments
      calls.md            # wikilinks to related Granola meeting notes (see Granola section)
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
| `new-branch`, `cook` | optional: offer to link a related Granola call into `calls.md` (see Granola section) |

`merge-pr`, `tag`, `verify-resolved`, `serve-up`/`serve-down`, `setup` are
untouched — no Obsidian-relevant state change happens there.

## Granola integration

Granola's own API is cloud-based, OAuth-gated, and currently Enterprise-only
with no public pricing/access — not usable here, and not worth reverse
engineering. Instead, sync is delegated entirely to an existing, actively
maintained community plugin:

- **[dannymcc/Granola-to-Obsidian](https://github.com/dannymcc/Granola-to-Obsidian)**
  (220 stars, actively maintained) — reads the local Granola desktop app's
  own credentials and syncs meeting notes straight into the vault on an
  interval. No API keys or OAuth flow for us to manage.
- **Manual, one-time setup** (not automated by thebous-os): the user installs
  this plugin from Obsidian's Community Plugins browser and configures its
  sync folder — default `Granola/` at the vault root. This is a GUI install
  inside Obsidian itself; thebous-os does not download or place any third-party
  plugin files into the vault.
- Each synced note carries frontmatter: `granola_id`, `title`, `created_at`,
  `granola_url` — enough to identify and link a note without needing to talk
  to Granola at all.

**thebous-os's job is only linking, not syncing.** In `new-branch` and `cook`,
add a step: search `<vault>/Granola/*.md` for notes with `created_at` near the
ticket's active window (or matching keywords from the ticket title), show the
user up to 5 candidates by title + date, and let them pick one or skip. On a
match, append a wikilink to the ticket's `calls.md`:

```
- [[Granola/2026-08-10_Sprint_Planning]] — linked 2026-08-10
```

If the `Granola/` folder doesn't exist (plugin not installed), skip this step
silently — same non-blocking rule as the Obsidian vault path itself.

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

Add one more for the Granola linking step (`new-branch` or `cook`):

```json5
{
  command: "new-branch",
  prompt: "Create a new branch for ticket DC-443, Granola/ folder has 3 recent notes",
  expected_output: "... after creating the branch, offers up to 5 candidate Granola notes near the ticket's window and links the user's choice into calls.md",
  expectations: [
    "Never auto-picks a Granola note without user confirmation",
    "Skips the linking step silently when the Granola/ folder doesn't exist"
  ]
}
```

## Out of scope (deferred)

- Automating the Granola-to-Obsidian plugin's own installation — the user
  installs it manually via Obsidian's plugin browser.
- The source repo `TheBous/github-jira-slack-claudecode` is not touched at all —
  no PR, no branch, nothing pushed there. `thebous-os` is a standalone copy.
- Platform mirrors (`.opencode/`, `.codex-plugin/`, `gemini-extension.json`) —
  not copied, thebous-os targets Claude Code only.
- Any Dataview/query layer inside Obsidian — plain markdown + frontmatter only.
