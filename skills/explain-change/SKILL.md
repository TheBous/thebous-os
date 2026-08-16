---
name: explain-change
description: Explain a pull request, diff, code, implementation change, file, or arbitrary text in simple step-by-step business and technical language, using a clear visual HTML artifact instead of a wall of text, and save every produced document in the corresponding Obsidian Jira task. Use when the user asks what changed, how something works, why it was implemented, or requests an easy graphical walkthrough.
---

# Explain Change

## Goal

Explain the subject progressively, clearly, and visually. Help the user
understand both the business result and the implementation without producing a
long unstructured text.

## 1. Define the subject

Identify the subject and collect only the required context:

- PR: title, description, diff, changed files, tests, and relevant comments;
- local diff or change: `git diff`, repository status, commits, and involved files;
- code or file: exact content, callers, dependencies, and entry points;
- text or requirement: structure, concepts, consequences, and terms to clarify.

If the subject is ambiguous, ask one clarification. Never invent intent,
behavior, data, or motivation: distinguish evidence, inference, and unverified
information.

Before reading details, define a guiding question:

- What problem are we trying to solve?
- What behavior do we need to understand?
- What should happen from input to output?
- Which aspects are still unknown?

For a codebase, first map entry points, main components, inputs and outputs,
dependencies, and file responsibilities. Do not start with syntax or read the
entire repository linearly.

Form an initial hypothesis and verify it in the code. Always separate:

- **Evidence** — directly visible in code, diff, tests, or documentation;
- **Inference** — reasonable but unproven interpretation;
- **Unverified** — behavior requiring a test, environment, or external clarification.

### 1a. Trace action chains

For each main behavior, start from the observable output and trace backward:

```text
output → producing function → transformation → data source → input/entry point
```

Follow the chain to the system entry point, noting what happens, why, and where
it is implemented. Repeat only for flows needed to explain the change.

## 2. Build the explanation

Organize the material as:

1. **Orientation** — guiding question, problem, and before/after.
2. **Map** — entry point, components, data, relationships, and verified hypothesis.
3. **Flow** — concrete input-to-output chain, what happens, why, and where.
4. **Implementation** — files, functions, data, states, APIs, dependencies, and responsibilities, with `file:line` references when available.
5. **Understanding** — example, counterexample, limits, risks, and unverified points.
6. **Verification** — test, command, minimal input, or experiment required.
7. **Final check** — five questions the reader can answer without rereading code.
8. **Summary** — at most three key messages.

For every step explain first **what happens**, then **why**, then **how it is
implemented technically**. Use short sentences and one idea per block. Expand
acronyms and technical terms at first use.

Make claims verifiable with an example, counterexample, prediction, or small
experiment. If a question cannot be answered from the sources, mark it
explicitly as `Unverified`.

## 3. Create the HTML artifact

Always create at least one self-contained HTML file unless the user explicitly
asks for a chat-only answer.

1. Use a dedicated temporary directory such as `${TMPDIR:-/tmp}/thebous-os-explain-<slug>-<timestamp>`.
2. For a small explanation create `index.html`.
3. For a large feature create `index.html` plus linked pages for each flow, domain, or technical area.
4. If the user specifies a destination directory, use it.
5. Report absolute artifact paths and, when supported, offer to open `index.html`.

### Visual requirements

- use inline CSS or local files; no CDNs, external fonts, or remote JavaScript;
- use cards, timelines, numbered steps, callouts, and short tables;
- represent flows and relationships with inline SVG or HTML/CSS diagrams;
- show business and technical paths separately, connecting related decisions;
- make the map, input → output flow, backward chain, example/counterexample, and evidence/inference/unverified distinction visible;
- include short annotated code snippets only when useful;
- keep readable width, accessible contrast, clear headings, and responsive layout;
- do not use one long text block or a decorative visualization that hides essential information.

Include a short header with subject, date, sources, and certainty level. Label
inferences and unchecked parts as such. End with adapted versions of:

1. What problem does the change solve?
2. What is the main data path?
3. What is the most important technical decision?
4. What happens in edge cases?
5. How can I verify the behavior?

Answers must be recoverable from the artifact except for points marked
`Unverified`.

## 4. Save all artifacts to the Obsidian task

Identify the Jira task (`<KEY>`) from the PR, branch, commit, or request context.
If it cannot be determined, ask one clarification and do not invent the key.

Save every generated file in `Dev/Tickets/<KEY>/docs/explain-change/<slug>-<timestamp>/`,
including linked pages, CSS, images, and local assets. Never overwrite an earlier
explanation. Follow `references/obsidian-log.md` and use the shared helpers:

```bash
source "scripts/helpers.sh"
if [ -f "$ENV_FILE" ]; then load_env; fi

if [ -z "${OBSIDIAN_VAULT_PATH:-}" ] || [ ! -d "${OBSIDIAN_VAULT_PATH}" ]; then
  echo "Cannot save the explanation: Obsidian is not configured or the vault does not exist."
  # Ask the user to configure the vault before declaring completion.
else
  DEST_DIR=$(obsidian_copy_ticket_docs "${OBSIDIAN_VAULT_PATH}" "<KEY>" "explain-change/<slug>-<timestamp>" <ARTIFACT_DIR>)
  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "Visual explanation: [open index.html](docs/explain-change/<slug>-<timestamp>/index.html)"
fi
```

## 5. Final response

Present only a navigable summary:

- one orientation sentence;
- three to seven main steps;
- the absolute HTML artifact path;
- unverified points or open questions.

Do not paste the complete HTML or produce a wall of text. Do not modify code,
PRs, or repository documents: this skill explains and creates artifacts but does
not implement fixes.
