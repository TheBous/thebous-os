---
name: tag
description: Create a release tag, transition all involved Jira or Notion tasks to Done, and notify Slack
---

## Goal

Create a git tag for the production deploy, find all Jira or Notion tasks included
in the release, transition them to `done`, and notify Slack.

## Steps

### 1. Determine the tag

Fetch the latest existing tag:
```bash
git tag --sort=-version:refname | head -5
```

Suggest the next tag: if the latest is `v1.2.3`, propose `v1.2.4` (patch bump). Show the suggestion to the user and ask for confirmation or a different name.

If there are no tags, propose `v0.1.0`.

Make sure you're on `main` and it's up to date:
```bash
git branch --show-current
git pull origin main --ff-only
```

### 2. Find task references in the release

Fetch the commit diff since the last tag:
```bash
LAST_TAG=$(git tag --sort=-version:refname | head -1)
if [ -n "$LAST_TAG" ]; then
  git log --pretty=format:"%s %b" "${LAST_TAG}..HEAD"
else
  git log --pretty=format:"%s %b"
fi
```

Inspect commit messages, merged branch names, and PR bodies for provider-qualified
references. Read `references/task-context.md` and apply its provider-neutral
resolution rules, then resolve each candidate with the task context helper:
```bash
source "scripts/helpers.sh"
resolve_work_item_ref "<one candidate Jira key, Notion URL, or Notion branch>"
```
Collect unique `{provider, external_id}` pairs, preserve each provider source and
source link, and show the list to the user. Jira-only, Notion-only, and mixed releases are valid;
never merge tasks by title or assume every release contains Jira.

### 3. Create and push the tag

```bash
git tag -a "<TAG>" -m "Release <TAG>"
git push origin "<TAG>"
```

### 4. Create the GitHub Release (optional)

Ask the user if they want to create a GitHub Release.

If yes:
```bash
gh release create "<TAG>" \
  --title "Release <TAG>" \
  --notes "$(git log --pretty=format:"- %s" "${LAST_TAG}..HEAD" | head -20)"
```

Capture the release URL.

### 5. Complete each task through its selected provider

For each resolved task, use the provider-specific adapter while keeping the
status and comment operations separate. For Jira, follow
`references/jira-transition.md` with:
- `<TRANSITION_ID>` = `$JIRA_DONE_ID`
- `<COMMENT_TEXT>` = `"🚀 Deployed to production with tag \`<TAG>\`."`

For Notion, source `scripts/notion.sh` and run:

```bash
notion_set_status "<EXTERNAL_ID>" "done"
notion_add_comment "<EXTERNAL_ID>" "🚀 Deployed to production with tag \`<TAG>\`."
```

Run in sequence for all tasks found. If a task fails (for example it is already
done or the provider is unavailable), log the semantic error and continue. Do
not claim the comment succeeded when only the status update succeeded.

### 6. Slack notification

Build the list of tasks as provider-labeled source links:

```bash
source "scripts/helpers.sh"
load_env
DEPLOYER=$(git config user.name 2>/dev/null || echo "unknown")

# Message with all provider task links
slack_notify "🚀 *Deploy Production* — Tag \`<TAG>\`\n👤 $DEPLOYER\n🎫 Tasks: <TASK_LIST_WITH_SOURCE_LINKS>\n<RELEASE_URL_IF_PRESENT>"
```

Use the direct source link for each task and include its provider label, for
example `<JIRA_BASE_URL/browse/T-200|jira:T-200>` or
`<NOTION_PAGE_URL|notion:<EXTERNAL_ID>>`, separated by spaces.

### 7. Confirmation

Show the user:
- Tag `<TAG>` created and pushed
- Tasks transitioned to Done: `<list>` with provider labels and links
- GitHub Release: `<URL>` (if created)
- Slack: notified
