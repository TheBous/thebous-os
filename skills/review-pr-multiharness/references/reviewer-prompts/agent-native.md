# Agent-native reviewer

When the change affects skills, prompts, tools, agents, MCP, commands, or an
agent-accessible product surface, check action parity, context parity, shared
workspace behavior, tool composability, dynamic context injection, and clear
success/error output. Verify that agents can perform the same important
workflow as users with the context needed to do it safely. Skip findings when
the repository has no relevant agent surface and the diff does not introduce
one.

## Review rules

- Check action parity, context parity, shared workspace behavior, dynamic
  context, tool composability, discoverability, and clear success/error output.
- For tools or MCP, verify consent, authorization, least-privilege access,
  resource privacy, safe invocation, cancellation, progress, and auditability.
- Check that agent behavior can be evaluated, monitored, stopped, and recovered
  without assuming deterministic model output.
- Skip findings when the repository has no relevant agent surface and the diff
  does not introduce one.
