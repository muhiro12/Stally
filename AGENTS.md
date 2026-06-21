# AGENTS.md

Repository-specific agent contract for Stally.

## Repository Rules

- Use English for branch names, code comments, documentation, and identifiers
  unless UI localization or legal content requires otherwise.
- Keep repository-facing documentation portable and product-centered.
- For Apple implementation work after the rebuild begins, follow existing
  architecture and source style; keep changes small and repository-local.
- Markdown must follow
  <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>.
- Swift code must comply with the repository SwiftLint configuration once a
  SwiftLint configuration exists again.
- Treat sibling repositories and external packages as read-only reference
  material unless the user explicitly asks otherwise.
- Do not add team-process artifacts such as contribution guides, issue
  templates, or pull request templates unless they are actually useful.

## Current State

Stally is between rebuild phases.

The legacy Xcode project, Swift sources, architecture documents, and
verification scripts have been removed after product intent was preserved
under `docs/`.

This repository does not currently contain:

- A buildable app target.
- An Xcode project or workspace.
- Swift source files.
- Swift package manifests.
- CI or local verification scripts.

## Documentation Boundary

`docs/` is the source of truth for preserved product intent until the future
rebuild begins.

- `docs/product-brief.md` summarizes what Stally is.
- `docs/product-purpose.md` explains why it exists and what problem it solves.
- `docs/preserved-concepts.md` separates preserved product concepts from
  discarded implementation details.
- `docs/domain-concepts.md` defines the core product domain.
- `docs/user-workflows.md` records user-facing workflows.
- `docs/user-experience-principles.md` records the intended experience and
  tone.
- `docs/product-language.md` records preserved nouns, verbs, labels, and copy
  direction.
- `docs/rebuild-handoff.md` records the extraction audit and phase boundary.

When editing these documents, preserve the existing English voice, avoid
speculation, and keep the distinction between product intent and discarded
implementation details explicit.

## Rebuild Boundary

Do not recreate an Xcode project, Swift source tree, architecture, persistence
model, navigation model, CI scripts, or implementation plan unless the user
explicitly asks.

Do not infer future architecture, framework choices, SwiftData schema,
navigation, UI hierarchy, routing, backup schema, or verification flow from
the removed legacy implementation.

If a future task creates a new Xcode project or app implementation, update this
file in the same task with the concrete schemes, targets, source boundaries,
and verification entrypoints that then exist. At that point, align the new
contract with the current Apple app repository pattern used by Incomes and
Cookle, but keep Stally-specific facts authoritative.

## Expected Apple Implementation Contract

Once the rebuild creates a new Xcode project, agents MUST prefer
XcodeBuildMCP for Apple build, test, run, Simulator, runtime log, screenshot,
and UI snapshot verification.

Before the first XcodeBuildMCP build, test, or run call in a session, run
XcodeBuildMCP `session_show_defaults`. If defaults do not point at this
repository, set them for the current session before continuing.

Treat library tests, surface builds, retained repository rule checks, and
runtime/UI evidence as separate verification capabilities. Choose the smallest
set that proves the current change, and prefer stronger evidence when public
APIs, wire contracts, SwiftData schema, app lifecycle wiring, framework
integration, or visible UI behavior are affected.

When these schemes exist, use this expected verification shape:

- For shared-library logic, model, or test changes, use XcodeBuildMCP
  `test_sim` with the `StallyLibrary` scheme.
- For public `StallyLibrary` APIs, `*Operations`, shared contracts, SwiftData
  schema, or adapter-facing contracts, also use XcodeBuildMCP `build_sim` with
  the `Stally` scheme.
- For app compile checks, use XcodeBuildMCP `build_sim` with the `Stally`
  scheme.
- For runtime or UI-sensitive changes, use XcodeBuildMCP `build_run_sim`,
  `launch_app_sim`, `snapshot_ui`, and `screenshot` as appropriate.

When Swift files and retained repository scripts exist again, agents should
run the Swift formatter after Swift edits:

```sh
bash ci_scripts/tasks/format_swift.sh
```

Agents should also run retained repository rule checks when they exist:

```sh
bash ci_scripts/tasks/check_repository_rules.sh
```

`check_repository_rules.sh` should own SwiftLint plus repository-specific
static architecture checks that are not naturally covered by XcodeBuildMCP.
SwiftLint should be resolved from the `SimplyDanny/SwiftLintPlugins` package
declared in the future Xcode project, not from a separately installed
`swiftlint` binary.

Xcode Cloud should own formal CI builds, tests, and archives once the rebuilt
app is ready for hosted CI.

## Release UI Smoke Audit

After the app exists again, release UI smoke auditing is separate from the
standard verification entrypoint. Keep it non-destructive by default: do not
erase simulator data, reset containers, or add UI test targets solely for the
audit unless explicitly requested.

## Verification

For the current docs-only state, verify changes by inspecting the Markdown
diff and running:

```sh
git diff --check
```

Report that app build, Swift package test, SwiftLint, and repository CI checks
are unavailable until a future rebuild creates the relevant project or scripts.

If the future Apple implementation contract has become active because the
project, schemes, and scripts now exist, follow the concrete entrypoints in
that section and update this file when the actual names differ.
