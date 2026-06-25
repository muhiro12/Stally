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
- Swift code must comply with the repository SwiftLint configuration.
- Treat sibling repositories and external packages as read-only reference
  material unless the user explicitly asks otherwise.
- Do not add team-process artifacts such as contribution guides, issue
  templates, or pull request templates unless they are actually useful.

## Current State

Stally has re-entered rebuild implementation with a seed Apple-platform app
project.

This repository currently contains:

- `Stally.xcodeproj`, with the `Stally` app target and `Stally` scheme.
- `Stally/`, a SwiftUI app source tree using SwiftData starter persistence.
- `Stally.xcodeproj/xcshareddata/xcodecloud/manifest.json`, an Xcode Cloud
  manifest.
- Preserved product-intent documentation under `docs/`.

This repository does not currently contain:

- A `StallyLibrary` target or scheme.
- Swift package manifests.
- Test targets.
- Local verification scripts.

## Documentation Boundary

`docs/` remains the source of truth for preserved product intent and
owner-directed rebuild constraints while the implementation is rebuilt.

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
- `docs/rebuild-implementation-direction.md` records explicit future rebuild
  direction added after the legacy extraction.

When editing product-intent documents, preserve the existing English voice,
avoid speculation, and keep the distinction between product intent and
discarded implementation details explicit. Keep owner-directed future
implementation constraints in `docs/rebuild-implementation-direction.md`
instead of blending them into extracted legacy evidence.

## Rebuild Boundary

Do not add architecture, a library target, a persistence model beyond the
current starter SwiftData item, a navigation model, CI scripts, or an
implementation plan unless the user explicitly asks.

Do not infer future architecture, framework choices, SwiftData schema,
navigation, UI hierarchy, routing, backup schema, or verification flow from
the removed legacy implementation.

Follow explicit owner-directed rebuild constraints in
`docs/rebuild-implementation-direction.md`. Do not expand those constraints
into a full implementation plan unless the user asks.

If a future task adds targets, schemes, packages, tests, scripts, or app
surfaces, update this file in the same task with the concrete source
boundaries and verification entrypoints that then exist. Keep Stally-specific
facts authoritative.

## Owner-Directed Rebuild Direction

The rebuild should treat Stally as a focused AI-era deep interface over its
own domain data: the app should own clean, high-quality item choice history and
make that domain reliable for app UI, App Intents, Siri, Apple Intelligence,
and future AI surfaces without becoming a broad assistant or super app.

Origami and Incomes are the highest-priority reference app projects. Treat
them as read-only references and adapt their intent rather than copying
product-specific behavior.

The project should target the iOS 27 family as the minimum supported iOS
version unless the user explicitly changes that decision.

Use the same package family as Incomes when packages are added unless the user
explicitly changes that direction. The current reference package set is
`MHPlatform`, `MHUI`, and `SwiftLintPlugins`; recheck Incomes when adding
packages and align with its then-current package set.

Use MHUI intentionally and take full advantage of SDK capabilities available at
the iOS 27 baseline. Do not restrict Stally to minimal or legacy-compatible
MHUI usage without a concrete product or technical reason.

## Expected Apple Implementation Contract

Agents MUST prefer XcodeBuildMCP for Apple build, test, run, Simulator,
runtime log, screenshot, and UI snapshot verification.

Before the first XcodeBuildMCP build, test, or run call in a session, run
XcodeBuildMCP `session_show_defaults`. If defaults do not point at this
repository, set them for the current session before continuing.

Treat library tests, surface builds, retained repository rule checks, and
runtime/UI evidence as separate verification capabilities. Choose the smallest
set that proves the current change, and prefer stronger evidence when public
APIs, wire contracts, SwiftData schema, app lifecycle wiring, framework
integration, or visible UI behavior are affected.

Use this expected verification shape:

- For app compile checks, use XcodeBuildMCP `build_sim` with the `Stally`
  scheme.
- For runtime or UI-sensitive changes, use XcodeBuildMCP `build_run_sim`,
  `launch_app_sim`, `snapshot_ui`, and `screenshot` as appropriate.

When these schemes exist later, add this stronger verification shape:

- For shared-library logic, model, or test changes, use XcodeBuildMCP
  `test_sim` with the `StallyLibrary` scheme.
- For public `StallyLibrary` APIs, `*Operations`, shared contracts, SwiftData
  schema, or adapter-facing contracts, also use XcodeBuildMCP `build_sim` with
  the `Stally` scheme.

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

For the current seed app state, verify changes by inspecting the diff and
running:

```sh
git diff --check
```

For Swift or Xcode project changes, also run XcodeBuildMCP `build_sim` with
the `Stally` scheme.

Report that Swift package tests, SwiftLint, test schemes, and local repository
CI checks are unavailable until a future rebuild creates the relevant packages,
targets, or scripts.
