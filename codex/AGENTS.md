# How I work — global Codex instructions

Install at `$CODEX_HOME/AGENTS.md` (default `~/.codex/AGENTS.md`).
Repository-specific instructions belong in each repository's `AGENTS.md`.

## Workflow

- Analyze the request, existing code, and conventions first. Propose the
  smallest change before any edit and wait for explicit approval. Reading,
  searching, and probing are allowed before approval.
- A question is not approval and does not withdraw earlier approval. Carry
  approved work forward unless the user changes or cancels it.
- Restate the requested change, relevant edge cases, and open questions in
  the proposal. Recommend one approach and explain why.
- Near performance-sensitive paths, explain the effect on the normal path.
  Prefer recovery logic on the failure path without extra normal-path work.
- After editing, report files changed, verification, unresolved blockers,
  and manual steps, then stop. Use `TODO(human): ...` for necessary device
  or console steps in code where appropriate.
- Reply in English, using plain words and concrete explanations without hype.

## Git

- Never commit or push without an explicit request for that action.
- Use Commitizen Conventional Commits: `type(scope): imperative summary`,
  lower-case and at most 72 characters. Explain why in the body when useful.
  Write commit messages and PR descriptions in English. Do not add Claude
  attribution to Codex work; follow the project's attribution policy.
- Expect other sessions in the same working tree. Before committing, inspect
  status, staged paths, and diffs. Include only your own approved changes.
  Never use `git add -A` or `git commit -a`. If a file contains another
  session's edits, use a private index for your hunks rather than altering
  the shared index. Preserve Windows line endings when handling patches.
- Work on the team's active branch unless directed otherwise. Read release
  branches without modifying them unless explicitly authorized.

## Builds, analysis, and tests

- Run application builds only when the user asks in the current message.
  Earlier build permission does not cover subsequent changes. If an
  accidental build starts, stop its entire process tree.
- Use the installed `low-priority-build` skill for heavy builds. Keep output
  names specific to the branch or feature. Choose concurrency for the
  machine's resources; do not assume two builds are always safe.
- A request to build for device preview includes making the feature
  reachable through existing debug tools when needed. Let the user preview
  UI and motion on the device; explain what to inspect and tune.
- For Dart changes, use terminal `dart analyze` and read the diff. Avoid MCP
  analyzer tools. Stop analysis that hangs and report that limitation.
  Format only edited files.
- Include data-layer unit tests with logic changes: DTO mappings,
  repositories, services, and DAOs using an in-memory database as appropriate.
  Do not write or propose widget, golden, integration, or E2E tests.
  During UI tuning, fix tests affected by churn at the end.
- Do not launch unsolicited reviewer agents.

## Subagents

- Before every subagent, ask the user to choose a model; recommend one
  available in the current Codex client with a brief reason. A single
  approval may cover an explicitly described batch. Pass the approved model
  where supported. If the client cannot select it, disclose that limitation
  before launching. Do not substitute a model silently.
- Handle small audits directly. Verify consequential findings yourself.
- Include the user's approval verbatim, date, and branch in editing-agent
  prompts. A subagent inherits only the approved scope.
- This is an instruction-based approval rule. Codex's documented hooks do
  not support the Claude hook's `permissionDecision: "ask"`; do not install
  that hook or claim it enforces this rule in Codex.

## Editing and design

- Use the client's structured patch/edit tools. Use replacement scripts only
  for broad mechanical changes; assert the old text exists and format after.
- Match surrounding naming, comments, and idioms. Avoid sweeping lint fixes,
  whole-tree formatting, or removing possibly unfinished work.
- Tag new TODO/FIXME notes `TODO(vuntm): ...`; reserve `TODO(human)` for
  actions requiring a person.
- Localize user-facing text in every supported locale in the same change.
- Give shared widgets names matching their scope. Rename class and file
  when a second consumer makes a specific name misleading.
- Name interfaces by contract and implementations by source. Keep domain
  concepts separate from external data sources, with dependencies inward.
- Trace all code paths for close buttons, CTAs, and back navigation. Check
  interactions between guards and navigation callbacks such as `PopScope`.
- For flashes or flicker, propose a broad fix covering likely causes early;
  investigate further if it fails.
- From Figma, take colors, typography, and measurements. Preserve behavior,
  layer order, and dimming scope unless asked. Propose a Figma-versus-built
  comparison before changes; obtain approval for shared component changes.
- Use app-wide values rather than per-screen overrides unless requested.
  Ask before deciding new interaction behavior such as long-press selection.
- Respect reduced motion, centralize motion constants, and use shared
  animation widgets. Use theme tokens and prefer SVG assets to icon fonts.

## Backends, documentation, and secrets

- Check the live server cheaply before claiming a route is missing and
  state the evidence used. Account for authentication and gateways when
  interpreting status codes; a status alone is not proof of route existence.
- Backend code the user does not own is read-only. Put approved backend
  requirements in the OpenAPI contract in the same change and bump
  `info.version`. Describe the required rule, shape, limit, and reason.
- Keep contracts evergreen: requirements, not implementation-status logs.
  Backend changes must be additive and compatible with production clients.
- Fetch pagination one page at a time; do not exhaust every page in a loop.
- Keep the applicable instruction document current when approved decisions
  change it, recording date, reason, and the user's choice where relevant.
  Persist feedback using supported memory facilities if available; otherwise
  propose an appropriate durable location. Do not claim unsaved memory.
- Never commit tokens, keystores, `key.properties`, or API keys. Use secure
  storage for secrets and never print tokens. Public client configuration
  may live in code when documented as public.
