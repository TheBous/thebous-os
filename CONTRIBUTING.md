# Contributing to thebous-os

Thanks for contributing. This repository follows
[GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow).
Every change lands on `main` through a pull request. Do not push to `main`
directly.

If you do not have write access, [fork the repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo),
push to your fork, and open a PR into `TheBous/thebous-os`.

Canonical workflow logic lives in `skills/*/SKILL.md`. Run those skills from
your coding agent instead of re-implementing the steps by hand.

## Development setup

Requirements: Node.js 18+, Git, and an authenticated `gh` CLI (`gh auth login`).

```bash
git clone https://github.com/TheBous/thebous-os.git
cd thebous-os
npm test
```

The suite validates skill frontmatter, command adapters, provider portability,
manifest version alignment and key workflow requirements.

Keep credentials in
`${THEBOUS_OS_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/thebous-os}/.env`.
Never commit API tokens, app passwords or webhooks.

## Workflow

| Step | Skill | What to do |
|---|---|---|
| Start work | `thebous-os:new-branch` | Branch from `main`. From a Jira ticket: `feat/<key>-<slug>` |
| Implement | `thebous-os:cook` | Code, tests and docs on that branch |
| Open a PR | `thebous-os:create-pr` | PR against `main`. Title `[KEY] <ticket title>` when a Jira ticket exists |
| Explain a PR | `thebous-os:explain-change` | Visual walkthrough of the PR, diff or implementation |
| Review | `thebous-os:review-pr` | Structured review with inline comments |
| Address review | `thebous-os:address-review` | Resolve review comments one by one |
| Merge | `thebous-os:merge-pr` | Squash into `main` (default), then Jira → In Staging |
| Release | `thebous-os:tag` | Create the tag, Jira → Done, notify Slack |

## Opening a pull request

1. Branch from an up-to-date `main`. Keep the branch short-lived and focused on
   one change.
2. Run `npm test` locally. Do not open a PR that fails the suite.
3. Push the branch and open a PR against `main` (`thebous-os:create-pr`).
4. Fill in a real title and description. When a Jira ticket exists, the title
   is `[KEY] <ticket title>` and the body must match the actual diff — no
   placeholder sections.
5. Request review. Use `thebous-os:explain-change` if reviewers need a
   walkthrough of the PR or diff.

## Review and merge

- Reviewers use `thebous-os:review-pr`. Authors resolve comments with
  `thebous-os:address-review`.
- CI must pass. Do not skip CI. Do not force-push to `main`.
- Prefer **squash merge** so `main` stays linear. Use a merge commit or rebase
  only if you ask for it (`thebous-os:merge-pr` defaults to squash).
- After a merge to `main`, `.github/workflows/bump-version.yml` bumps package
  and plugin manifests automatically. Do not bump versions in the PR.

## Architecture constraints

- `skills/<name>/SKILL.md` is the only place for workflow logic.
- `commands/<name>.md` is a thin adapter. It must not duplicate that logic.
- Provider manifests (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`,
  `.opencode/`) only expose the canonical skills.
