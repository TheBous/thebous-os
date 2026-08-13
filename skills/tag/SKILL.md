---
name: tag
description: Create a release tag, transition all involved Jira tickets to Done, and notify Slack
---

## Goal

Create a git tag for the production deploy, find all Jira tickets included in the release, transition them to Done, notify Slack.

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

### 2. Find the Jira tickets in the release

Fetch the commit diff since the last tag:
```bash
LAST_TAG=$(git tag --sort=-version:refname | head -1)
if [ -n "$LAST_TAG" ]; then
  git log --pretty=format:"%s %b" "${LAST_TAG}..HEAD"
else
  git log --pretty=format:"%s %b"
fi
```

Extract all unique Jira keys from commit messages and merged branch names:
```bash
source "scripts/helpers.sh"
extract_jira_keys "<commit log from above>"
```
Show the list to the user.

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

### 5. Jira transition and comment for each ticket

For each Jira key found, follow `references/jira-transition.md` (in the plugin root) with:
- `<TRANSITION_ID>` = `$JIRA_DONE_ID`
- `<COMMENT_TEXT>` = `"🚀 Deployed to production with tag \`<TAG>\`."`

Run in sequence for all tickets found. If a ticket fails (e.g. already Done), log the error and continue.

### 6. Slack notification

Build the list of tickets as Jira links:

```bash
source "scripts/helpers.sh"
load_env
DEPLOYER=$(git config user.name 2>/dev/null || echo "unknown")

# Message with all tickets as links
slack_notify "🚀 *Deploy Production* — Tag \`<TAG>\`\n👤 $DEPLOYER\n🎫 Tickets: <TICKET_LIST_WITH_LINKS>\n<RELEASE_URL_IF_PRESENT>"
```

Ticket format in the message: `<JIRA_BASE_URL/browse/DC-443|DC-443>` for each ticket, separated by a space.

### 7. Confirmation

Show the user:
- Tag `<TAG>` created and pushed
- Tickets transitioned to Done: `<list>`
- GitHub Release: `<URL>` (if created)
- Slack: notified
