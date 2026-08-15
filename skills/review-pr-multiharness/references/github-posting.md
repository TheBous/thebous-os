# GitHub review posting

Use this reference only after explicit authorization to publish the review.
The conversation with the user may be in any language; public GitHub review
content is always in English.

## Main review

Post one summary/index review before the inline threads:

```bash
gh pr review <NUMBER> --request-changes --body "$(cat <<'EOF'
## Review — <title>

<2–3 sentences describing the review focus and scope.>

### 🔴 Must fix before merge
- <headline> — see inline comment on `<path>:<line>`

### 🟡 Recommended
- <headline> — see inline comment on `<path>:<line>`

### 🟢 Fix if straightforward
- <headline> — see inline comment on `<path>:<line>`
EOF
)"
```

Choose `--request-changes` when there is at least one `Must fix before merge`
finding. Use `--comment` when findings are only `Recommended` or `Fix if
straightforward`. If there are only discretionary findings, do not publish
them. The top-level body is summary plus index only; technical explanations
belong in the inline threads.

Public labels map from the internal severity as follows, without exposing the
internal codes: P0 → `Must fix before merge`, P1 → `Recommended`, P2 → `Fix if
straightforward`, P3 → omitted from GitHub.

## Inline threads

Post one independent review comment per actionable finding:

```bash
gh api repos/:owner/:repo/pulls/<NUMBER>/comments \
  --method POST \
  --field commit_id='<head-sha>' \
  --field path='<file>' \
  --field side='RIGHT' \
  --field line=<line> \
  --field body='<comment text>'
```

Use `side=RIGHT` for added or modified lines and `side=LEFT` for deleted
lines. `line` is the actual file line at the PR head, not a diff offset. Do
not post an inline comment outside a diff hunk. If a valid anchor cannot be
verified, keep the finding in the local report instead of guessing.

Each comment follows this structure:

```text
<The problem — what is technically wrong>

<Why it matters — violated invariant, data loss, race condition, missing audit
trail, broken atomicity, or equivalent concrete impact>

Could we <concrete direction for the fix>?

<How to verify the fix with a focused regression test>
```

Keep one finding per thread. Do not put severity codes or severity labels in
inline bodies; severity exists only in the main index. Avoid duplicating the
inline explanation in the main review.

## Suggestions

For a trivial, self-contained correction on the commented lines, append a
GitHub suggestion block:

````text
```suggestion
<replacement lines>
```
````

For coordinated changes, new tests, migrations, generated artifacts, or a fix
that must touch other files, use an explanatory snippet instead. For generated
files, suggest the source change and explain that the artifact must be
regenerated.
