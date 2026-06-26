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

Stally has re-entered rebuild implementation and now contains the rebuilt core
Library, Archive, Review, Insights, Backup Center, Settings, and shareable-link
surfaces plus the local development foundation for continuing the rebuild.

This repository currently contains:

- `Stally.xcodeproj`, with the `Stally` app target and `Stally` scheme.
- `Stally/`, a SwiftUI app source tree under `Stally/Sources/`.
- `StallyLibrary/Package.swift`, a local Swift package linked into the app
  target as the `StallyLibrary` product.
- `StallyLibrary/Sources/`, which owns the current durable item, review,
  insights, backup, link, SwiftData model, persistence factory, and
  `*Operations` use cases.
- `StallyLibrary/Tests/`, which owns library behavior tests for the current
  item, review, insights, backup, and link operations.
- `ci_scripts/`, which owns repository-managed lint, rule, and library-test
  entrypoints.
- `Stally.xcodeproj/xcshareddata/xcodecloud/manifest.json`, an Xcode Cloud
  manifest.
- Preserved product-intent documentation under `docs/`.

This repository does not currently contain App Intents, Widget, Watch,
CloudKit sync, external AI integration, ads, purchases, advanced settings,
MHPlatform runtime, or MHUI runtime surfaces.

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
- `docs/rebuild-implementation-direction.md` records explicit rebuild
  direction added after the legacy extraction.

When editing product-intent documents, preserve the existing English voice,
avoid speculation, and keep the distinction between product intent and
discarded implementation details explicit. Keep owner-directed
implementation constraints in `docs/rebuild-implementation-direction.md`
instead of blending them into extracted legacy evidence. Some docs
intentionally preserve phase-boundary language from their creation time; do not
retime them unless a stale statement would misdirect current work.

## Rebuild Boundary

Do not infer future framework choices, SwiftData schema, navigation,
UI hierarchy, routing, backup schema, or verification flow from the removed
legacy implementation.

Follow explicit owner-directed rebuild constraints in
`docs/rebuild-implementation-direction.md`. Do not expand those constraints
into a full implementation plan unless the user asks.

Keep the current rebuilt core surfaces as the behavior reference while
structural work continues. Do not add App Intents, Widget, Watch, external AI
integration, ads, purchases, CloudKit sync, advanced settings, or broad UI
redesign work unless the user explicitly asks for that phase.

If a future task adds targets, schemes, packages, tests, scripts, or app
surfaces, update this file in the same task with the concrete source
boundaries and verification entrypoints that then exist. Keep Stally-specific
facts authoritative.

## Source Boundaries

The app target should stay a thin adapter over the current product surface.

- `Stally/Sources/App/` owns app lifecycle, exported library import, and root
  composition, including tab selection, sheet routing, and incoming link
  handling.
- `Stally/Sources/Features/Library/` owns the current SwiftUI Library, Add
  Item, Item Detail, Mark Today, Undo Today's Mark, and Quiet History views.
- `Stally/Sources/Features/Archive/` owns the SwiftUI Archive surface.
- `Stally/Sources/Features/Review/` owns the SwiftUI Review lane surface.
- `Stally/Sources/Features/Insights/` owns the SwiftUI Insights reading
  surface.
- `Stally/Sources/Features/Backup/` owns the SwiftUI Backup Center surface,
  including file importer/exporter presentation and safety confirmations.
- `Stally/Sources/Features/Links/` owns app-side link-sharing presentation.
- `Stally/Sources/Features/Settings/` owns the minimal SwiftUI Settings and
  shareable-link list surface.
- `Stally/Sources/PreviewSupport/` owns DEBUG-only preview data, in-memory
  preview containers, screenshot launch routes, and screen-level previews for
  UI review. It must not become product behavior or shared-library logic.
- App views may use SwiftData environment values and `@Query` for the current
  app surface, but durable business behavior should enter through public
  `*Operations`.
- App views should not directly create `Item`, call item mark/history helper
  methods, declare `@Model` types, or duplicate business branching that belongs
  in the library.

`StallyLibrary` is the durable domain and use-case boundary.

- `StallyLibrary/Sources/Item/` owns `Item`, `ItemMark`, `ItemCategory`,
  `ItemHistorySnapshot`, `ItemFormInput`, `ItemValidationError`, and
  `ItemOperations`.
- `StallyLibrary/Sources/Review/` owns Review lane values, settings,
  snapshots, and `ReviewOperations`.
- `StallyLibrary/Sources/Insights/` owns Insights range/options, reading
  values, recommendations, snapshots, and `InsightsOperations`.
- `StallyLibrary/Sources/Backup/` owns versioned backup snapshots, import
  previews/results, validation issues, reset results, and `BackupOperations`.
- `StallyLibrary/Sources/Link/` owns shareable destination and item link
  values, parsing results, and `StallyLinkOperations`.
- `StallyLibrary/Sources/Persistence/` owns `StallyModelContainerFactory`.
- Public business use cases that app UI, future App Intents, widgets, or other
  surfaces need should be exposed through public `*Operations` facades.
- Implementation helpers should stay internal unless they are stable value,
  persistence, route, wire, or presentation contracts needed by another
  surface.

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

## Package Posture

Treat package declaration and product linking as separate decisions.

- The app target currently links only the local `StallyLibrary` product.
- `SwiftLintPlugins` is declared in `Stally.xcodeproj` for repository-managed
  linting and should not be treated as a runtime dependency.
- `MHPlatform` and `MHUI` are intentionally not linked yet. Recheck Incomes and
  add or link them only when a concrete Stally implementation phase needs their
  package products.
- Do not add runtime products solely because Incomes or Fluel declares them.

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
- For shared-library logic, model, or test changes, run
  `bash ci_scripts/tasks/test_stally_library.sh`.
- For public `StallyLibrary` APIs, `*Operations`, shared contracts, SwiftData
  schema, or adapter-facing contracts, also use XcodeBuildMCP `build_sim` with
  the `Stally` scheme.
- For runtime or UI-sensitive changes, use XcodeBuildMCP `build_run_sim`,
  `launch_app_sim`, `snapshot_ui`, and `screenshot` as appropriate.

The generated project-level `StallyLibrary` package product scheme is currently
buildable through XcodeBuildMCP, but package tests are driven by
`ci_scripts/tasks/test_stally_library.sh`, which runs `xcodebuild -scheme
StallyLibrary ... test` from the package directory.

When retained repository scripts exist, agents should run the Swift formatter
after Swift edits:

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
declared in the project once package dependencies are added, not from a
separately installed `swiftlint` binary.

UI preview reports and screenshots are implementation review artifacts. Keep
them separate from preserved product-intent documents, and update them when a
task intentionally changes the visible app surface or visual-system adoption.

Xcode Cloud should own formal CI builds, tests, and archives once the rebuilt
app is ready for hosted CI.

## Release UI Smoke Audit

After the app exists again, release UI smoke auditing is separate from the
standard verification entrypoint. Keep it non-destructive by default: do not
erase simulator data, reset containers, or add UI test targets solely for the
audit unless explicitly requested.

## Verification

For current implementation work, choose the smallest evidence set that proves
the changed boundary.

Available repository-managed commands:

```sh
bash ci_scripts/tasks/format_swift.sh
bash ci_scripts/tasks/lint_swift.sh
bash ci_scripts/tasks/check_repository_rules.sh
bash ci_scripts/tasks/test_stally_library.sh
bash ci_scripts/tasks/verify_task_completion.sh
```

`verify_task_completion.sh` runs repository rules, StallyLibrary tests, and
`git diff --check`. It does not replace XcodeBuildMCP app build or runtime
evidence when app lifecycle, package linking, SwiftData container wiring, or
visible UI behavior changes.

For Swift or Xcode project changes, also run XcodeBuildMCP `build_sim` with the
`Stally` scheme. For runtime or UI-sensitive changes, run XcodeBuildMCP
`build_run_sim`, inspect the returned runtime log, and capture a screenshot.

If Xcode beta UI automation is unavailable or unreliable, fall back to
runtime logs, screenshots, and library/domain tests. Do not treat successful
launch alone as sufficient evidence for visible UI behavior.
