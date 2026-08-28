---
name: create-pr
description: Use when the user asks to create or open a pull request, or to merge a branch, after development is complete
---

## Goal

Create a Pull Request for the current branch against `main`, after validating the Jira task and automatically generating the title and description from the Jira ticket and the branch diff.

## Routing

If the user asks to merge a branch or an existing pull request rather than to
create one, load `skills/merge-pr/SKILL.md` and follow that workflow instead.
Do not run the PR-creation steps for a merge request.

## Steps

### 1. Check status

```bash
git branch --show-current
git status --short
```

If there are uncommitted changes, warn the user and ask if they want to proceed anyway.

Verify the branch is pushed to origin:
```bash
git ls-remote --exit-code origin "$(git branch --show-current)" 2>/dev/null || echo "NOT_PUSHED"
```

If not pushed:
```bash
git push -u origin "$(git branch --show-current)"
```

### 2. Extract the Jira ticket and fetch details

Follow `references/jira-task-context.md` with:
- `<SOURCES>` = the current branch name
- `<REQUIRED>` = `required`
- `<DETAILS>` = `basic`

The resolved `<KEY>`, `<TASK_SUMMARY>`, and `<TASK_DESCRIPTION>` are used in the PR title and description.

### 3. Analyze the diff against the base branch

Fetch the full diff against main:
```bash
git diff main...HEAD --stat
git log main..HEAD --pretty=format:"%s" --no-merges
git diff main...HEAD -- . ':(exclude)*.lock' ':(exclude)package-lock.json'
```

Analyze the diff to identify:
- Which files were added, modified, removed
- The type of change (bug fix, new feature, refactoring, etc.)
- Whether there are breaking changes
- Whether tests were added

**Don't trust the diff hunk alone** for this — when it doesn't show the full function body, type definitions, or imports needed to judge the change, read the full file locally (it's already checked out on this branch, no need for the GitHub API).

### 4. Validate the implementation against Jira (mandatory gate)

Compare the full diff and the tests against `<TASK_REQUIREMENTS>` from `references/jira-task-context.md`.

For each requirement, record `✅ Met`, `⚠️ Partially met / unverifiable`, or `❌ Not met`, with concise evidence from the changed files or tests.

Show the checklist to the user and ask:
```
✅ Jira validation complete for <KEY>. Are all listed requirements satisfied and can I create the PR?
```

Do not create the PR unless every item is `✅ Met` and the user confirms. If any item is partial, unverifiable, or not met, stop and report what must be addressed.

### 5. Auto-generate title and description

**Title**: `[<KEY>] <Jira ticket title>`. If there is no Jira key, use a short title from the diff.

**Description**: use GitHub's Summary / Test plan format. If the repository has
`.github/PULL_REQUEST_TEMPLATE.md` or a file under `.github/PULL_REQUEST_TEMPLATE/`,
fill that template. Otherwise fill the default below. If `CONTRIBUTING.md`
exists, follow its PR title and body rules as well.

Don't leave placeholder text — each section must reflect the actual diff.

```markdown
## Summary
- [1–3 bullets: what this PR does and why]
Fixes <JIRA_BASE_URL>/browse/<KEY>

## Test plan
- [ ] [How this was verified: tests run, new tests, or manual steps]
```

Omit the `Fixes` line when there is no Jira key. Put screenshots under Summary
only if step 6 collected one.

### 6. Ask for a screenshot (only if the change is visual)

Based on the diff analysis from step 3, decide whether this change is screenshot-worthy: new or modified UI (components, pages, styles, layouts) — yes; pure backend/core logic, refactoring, config, or non-visual bug fixes — no.

If it's screenshot-worthy, ask the user:
```
📸 This looks like a UI change — got a screenshot of the result? (paste an image URL, or say no to skip)
```

- If they give a URL, add it under Summary: `![screenshot](<URL>)`.
- If they say no or have none, skip the image and continue.
- If they only have a local file path, note that `gh`/the API can't upload images — tell them to drag the file into the PR description on GitHub after it's created, then move on.

If the change isn't screenshot-worthy, skip this step silently.

### 7. Create the PR

```bash
gh pr create \
  --base main \
  --title "<generated title>" \
  --body "<generated description>"
```

Capture the PR URL from the output.

**If the command fails with a TLS/certificate error** (e.g. `tls: failed to verify certificate: x509: ...`), use this fallback:
```bash
OWNER_REPO=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+)(\.git)?$#\1#')
curl -sf \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  -X POST "https://api.github.com/repos/$OWNER_REPO/pulls" \
  -d "{\"title\":\"<generated title>\",\"body\":\"<generated description>\",\"head\":\"$(git branch --show-current)\",\"base\":\"main\"}" \
  | jq '{number, url: .html_url}'
```

### 7a. Log the PR link to Obsidian (optional)

If `OBSIDIAN_VAULT_PATH` is configured, follow `references/obsidian-log.md`:

```bash
source "scripts/helpers.sh"
load_env
obsidian_log_pr "${OBSIDIAN_VAULT_PATH:-}" "<KEY>" "<PR_URL>" "[[<KEY>]] — PR opened: <PR_URL>"
```

### 8. Jira comment (always)

Always leave a comment on the Jira issue:

```bash
source "scripts/helpers.sh"
load_env
```

Use the MCP tool `addCommentToJiraIssue` with `issueKey: "<KEY>"` and `comment: "🔍 PR opened: <PR_URL>"`.

**If the MCP call fails**, use the `jira_comment` helper as fallback:
```bash
source "scripts/helpers.sh"
jira_comment "<KEY>" "🔍 PR opened: <PR_URL>"
```

### 9. Jira transition (optional)

If `JIRA_IN_REVIEW_ID` is configured and not empty, also transition the ticket using `references/jira-transition.md` with:
- `<TRANSITION_ID>` = `$JIRA_IN_REVIEW_ID`
- `<COMMENT_TEXT>` = (empty/skip comment in jira-transition, we already left one in step 8)

If the transition fails or `JIRA_IN_REVIEW_ID` is not configured, **continue anyway** — the comment was already left in step 8.

### 10. Slack notification

```bash
source "scripts/helpers.sh"
load_env
slack_notify "🔍 PR opened: *<PR_TITLE>*\n🔗 <PR_URL>\n🎫 <$JIRA_BASE_URL/browse/<KEY>|<KEY>> → *In Review*"
```

If Slack notification fails, **continue anyway** — the PR and Jira comment were already done.

### 11. Confirmation

Show the user:
- PR created: `<PR_URL>`
- Jira comment: left on `<KEY>`
- Ticket `<KEY>` → In Review (if transition succeeded; otherwise note it was skipped)
- Slack: notified (or "notification failed, but PR and comment are done")
- Obsidian: PR link recorded (or "skipped, no vault configured")
- → Suggest the next step: `/thebous-os:review-pr` to get it reviewed
