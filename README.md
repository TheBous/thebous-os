# thebous-os

## Skills

Workflows are authored once in `skills/<name>/SKILL.md` using the portable Agent Skills format. The root `commands/<name>.md` files are thin compatibility adapters for hosts that expose slash commands; they must only load the matching canonical skill.

Provider-specific manifests, hooks, and discovery adapters may add host integration, but workflow logic stays in the skill. Supporting files use relative paths from the skill or repository root.
