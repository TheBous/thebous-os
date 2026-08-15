# Previous-feedback reviewer

Read prior PR review comments and verify each actionable request against the
current head. Check whether the fix is complete, anchored to the right
behavior, covered by tests where needed, and whether it introduced a related
regression. Distinguish resolved, partially resolved, and still-open comments.
Do not create new unrelated findings just because the PR has historical
discussion.

## Review rules

- Inspect every prior comment against the current head, not only its resolved
  or unresolved status.
- Classify feedback as resolved, partially resolved, still open, outdated, or
  out of scope, and verify the behavior or test that closes it.
- Check that a fix did not introduce a regression or merely move the problem.
- Keep out-of-scope follow-up linked to an issue instead of expanding the PR.
- Require a regression test that fails without the fix and passes with it for
  every resolved bug-report comment; a code change with no matching new or
  updated test is at best partially resolved.
- Check that the regression test targets the actual reported behavior, not an
  adjacent detail the comment didn't raise.
