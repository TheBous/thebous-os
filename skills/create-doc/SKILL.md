---
name: create-doc
description: Create a new documentation page in Confluence linked to an optional Jira or Notion task
---

## Goal

Create a documentation page in Confluence by reading the code, automatically generating the content, and publishing only after the user's approval.

## Steps

### 1. Load the credentials

```bash
source "scripts/helpers.sh"
load_env
```

If the file doesn't exist or `CONFLUENCE_PARENT_URL` is missing, tell the user to run `/thebous-os:setup` first.

### 1a. Resolve a linked task (optional)

Use `references/task-context.md` with the current branch as an optional
provider-neutral task source:

```bash
source "scripts/helpers.sh"
TASK_REF=$(resolve_work_item_ref "$(git branch --show-current)" 2>/dev/null || true)
```

Store the `TaskRef` if found. Jira and Notion remain independent providers;
if no task resolves, skip the task-linked Obsidian step.

### 2. Identify the target

If the user passed a file path when invoking the command (e.g. `/create-doc src/auth/login.ts`), use it directly.

If instead they described a feature verbally (e.g. "document the login flow"), search the codebase:
```bash
grep -rl "<keyword>" . --include="*.ts" --include="*.js" --include="*.py" --include="*.go" 2>/dev/null | head -20
```
Show the user the files found and ask for confirmation: "I found these files — are they the right ones, or do you want to add/exclude any?"
Wait for a reply before proceeding.

### 3. Ask for the title

Ask the user: "Title of the page?"

### 4. Analyze the code and generate the draft

Read the files identified in step 2. Based on what you find:

- **Suggest 3-5 relevant tags** (technology, domain, type: e.g. `auth`, `api`, `typescript`)
- **Generate the body** in free form: write the most useful documentation for that specific code — don't follow fixed sections, adapt the structure to what the code does. It can be prose, lists, usage examples, text diagrams, anything that helps understanding.

Show the user the complete draft:
```
📄 Documentation draft

Title: <title>
Suggested tags: <tag1>, <tag2>, <tag3>

---
<generated body>
---

Do you want to change anything before publishing to Confluence?
```

Wait for a reply. If the user asks for changes, apply them and show it again. Once confirmed, go to step 5.

### 5. Extract the space key and parent page ID

```bash
source "scripts/helpers.sh"
SPACE_KEY=$(confluence_space_key "$CONFLUENCE_PARENT_URL")
PAGE_ID=$(confluence_page_id "$CONFLUENCE_PARENT_URL")
```

### 6. Compose the final body

```html
<table>
  <tbody>
    <tr>
      <th>Last modified</th>
      <td><DD/MM/YYYY></td>
    </tr>
    <tr>
      <th>Reference files</th>
      <td><code><file1></code>, <code><file2></code></td>
    </tr>
    <tr>
      <th>Tags</th>
      <td><tag1>, <tag2>, <tag3></td>
    </tr>
  </tbody>
</table>

<generated and approved body>

<h2>Related links</h2>
<ul>
  <li></li>
</ul>
```

### 7. Publish to Confluence

Use the MCP tool `createConfluencePage` with:
- `spaceId`: SPACE_KEY extracted in step 5
- `parentId`: PAGE_ID extracted in step 5
- `title`: title confirmed by the user
- `body`: HTML composed in step 6
- `contentFormat`: `"html"`

### 7a. Log to Obsidian (optional)

Only if `TASK_REF` was found in step 1a. Follow `references/obsidian-log.md`
and use the provider-aware helper:

```bash
source "scripts/helpers.sh"
load_env
obsidian_log_task "${OBSIDIAN_VAULT_PATH:-}" "<TASK_REF>" "plan.md" \
  "Confluence page created: [<title>](<page URL>)" \
  "<PROVIDER>:<EXTERNAL_ID> — Confluence page created: <title>"
```

### 8. Confirmation

Show the user:
- Page created: `<title>` → `<page URL>`
- Obsidian: logged (or "skipped, no vault configured / no linked task")
