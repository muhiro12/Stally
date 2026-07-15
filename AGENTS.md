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
Library, Archive, Review, Insights, Backup Center, Settings, shareable-link,
CloudKit persistence, App Intents, monetization, and English/Japanese
localization baselines plus the local MHPlatform runtime, logging, and route
foundation for continuing the rebuild.

This repository currently contains:

- `Stally.xcodeproj`, with the `Stally` app target and `Stally` scheme.
- `Stally/`, a SwiftUI app source tree under `Stally/Sources/`,
  configuration files under `Stally/Configurations/`, and app resources under
  `Stally/Resources/`.
- `StallyLibrary/Package.swift`, a local Swift package linked into the app
  target as the `StallyLibrary` product.
- `StallyLibrary/Sources/`, which owns the current durable item, review,
  insights, backup, link, sample-data, subscription-state,
  timezone-independent local-day mark history, versioned SwiftData model,
  persistence factory, and `*Operations` use cases, with `MHPlatformCore` used
  only for library-safe platform primitives and preference descriptors.
- `StallyLibrary/Sources/Resources/`, which owns package-local localized
  library and sample-data strings.
- `StallyLibrary/Tests/`, which owns library behavior tests for the current
  item, collection browsing, sample data, review, insights reports, backup,
  link, wire-format, and persistence contracts.
- `ci_scripts/`, which owns repository-managed lint, rule, and library-test
  entrypoints.
- `Stally.xcodeproj/xcshareddata/xcodecloud/manifest.json`, an Xcode Cloud
  manifest.
- Preserved product-intent documentation under `docs/`.

This repository does not currently contain Widget, Watch, external AI
integration, or broad advanced settings. `StallyLibrary` links
`MHPlatformCore` for shareable-link deep-link route encoding and preference
descriptors. The app target links the full MHPlatform umbrella for app-side
runtime, logging, routing, StoreKit, AdMob, and license integration, and MHUI
for visual chrome and presentation styling. CloudKit is configured through the
runtime SwiftData persistence baseline and is gated only by the persisted
iCloud preference, but real-device iCloud sync, StoreKit purchase resolution,
production AdMob serving, and production CloudKit behavior are not proven by
local simulator verification alone.

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
- `docs/rebuild-implementation-principles.md` records current rebuild
  baseline implementation principles.

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
structural work continues. Do not add Widget, Watch, external AI integration,
ads, purchases, advanced settings, broad UI redesign work, or wider App
Intents/CloudKit behavior unless the user explicitly asks for that phase.

The current versioned SwiftData schema begins with the rebuilt model rather
than the removed legacy persistence model. Future persisted schema changes
must append a version and migration stage instead of rewriting that baseline.

If a future task adds targets, schemes, packages, tests, scripts, or app
surfaces, update this file in the same task with the concrete source
boundaries and verification entrypoints that then exist. Keep Stally-specific
facts authoritative.

## Source Boundaries

The app target should stay a thin adapter over the current product surface.

- `Stally/Sources/App/` owns app lifecycle, exported library import, and root
  composition, including tab selection and sheet routing.
- `Stally/Sources/App/Intents/` owns app-wide App Shortcuts and generic route
  App Intents. Feature-specific App Intents should live under the owning
  `Features/*/Intents/` directory.
- `Stally/Sources/Platform/` owns app-side MHPlatform assembly, logging,
  runtime bootstrap, route pipeline, route inbox, monetization configuration,
  and intent URL-store plumbing. It must not own product behavior or durable
  domain use cases.
- `Stally/Sources/Features/Library/` owns the current SwiftUI Library, Add
  Item, Item Detail, Mark Today, Undo Today's Mark, Quiet History views, and
  Library-owned App Intents and App Entities.
- `Stally/Sources/Features/Archive/` owns the SwiftUI Archive surface and
  Archive-owned App Intents.
- `Stally/Sources/Features/Review/` owns the SwiftUI Review lane surface and
  Review-owned App Intents.
- `Stally/Sources/Features/Insights/` owns the SwiftUI Insights reading
  surface and Insights-owned App Intents.
- `Stally/Sources/Features/Backup/` owns the SwiftUI Backup Center surface,
  including file importer/exporter presentation, safety confirmations, and
  Backup-owned App Intents.
- `Stally/Sources/Features/Links/` owns app-side link-sharing presentation.
- `Stally/Sources/Features/Settings/` owns the SwiftUI Settings surface,
  independent subscription/iCloud controls, StoreKit subscription section,
  Review thresholds, Insights defaults, shareable-link list surface, and
  Settings-owned App Intents.
- `Stally/Sources/SharedUI/` owns app-local MHUI presentation adapters and
  shared visual treatment helpers, including app-local ad presentation
  wrappers. It must not contain product behavior, persistence logic, or
  reusable library operations.
- `Stally/Sources/PreviewSupport/` owns DEBUG-only preview data, in-memory
  preview containers, screenshot launch routes, and screen-level previews for
  UI review. It must not become product behavior or shared-library logic.
- `Stally/Resources/` owns app-target String Catalogs for SwiftUI, App
  Intents, and App Shortcuts strings.
- App views may use SwiftData environment values and `@Query` for the current
  app surface, but durable business behavior should enter through public
  `*Operations`.
- App views should not directly create `Item`, call item mark/history helper
  methods, declare `@Model` types, or duplicate business branching that belongs
  in the library.
- App Intents must call public `*Operations` for business behavior and should
  not reimplement domain rules in the app target.

`StallyLibrary` is the durable domain and use-case boundary.

- `StallyLibrary/Sources/Item/` owns `Item`, `ItemMark`, `LocalDay`,
  `ItemCategory`, collection browsing options, `ItemHistorySnapshot`,
  `ItemFormInput`, `ItemValidationError`, `ItemCollectionOperations`, and
  `ItemOperations`.
- `StallyLibrary/Sources/Review/` owns Review lane values, settings, action
  requests, snapshots, and `ReviewOperations`.
- `StallyLibrary/Sources/Insights/` owns Insights range/options, reading
  values, recommendations, snapshots, `InsightsOperations`, and
  `InsightsReportOperations`.
- `StallyLibrary/Sources/Backup/` owns the current versioned backup wire
  contract, import previews/results, validation issues, reset results, and
  `BackupOperations`.
- `StallyLibrary/Sources/Link/` owns shareable destination and item link
  values, MHPlatformCore deep-link route encoding, parsing results, and
  `StallyLinkOperations`.
- `StallyLibrary/Sources/Settings/` owns the ad-removal subscription-state
  values and `SubscriptionStateOperations`. iCloud preference state remains
  independent from subscription state.
- `StallyLibrary/Sources/SampleData/` owns the localized empty-Library sample
  creation use case through `SampleDataOperations`.
- `StallyLibrary/Sources/Preferences/` owns app-local preference descriptors
  used by app startup and SwiftUI settings surfaces.
- `StallyLibrary/Sources/Persistence/` owns `StallyMigrationPlan` and
  `StallyModelContainerFactory`.
- `StallyLibrary/Sources/Resources/` owns library String Catalogs and is
  processed as a Swift Package resource bundle.
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

CloudKit, App Intents, and English/Japanese localization are rebuild baseline
requirements for Stally. Add them early in rebuild work and preserve them as
future surfaces are added.

For app UI, treat Apple Human Interface Guidelines and native Apple controls
as the foundation. Use MHUI and MHDesign as a shared app-family style layer for
spacing, hierarchy, row rhythm, section treatment, metadata, badges, empty
states, summary surfaces, action emphasis, destructive and safety treatment,
feedback, and app-wide visual consistency. Do not replace native `List`,
`Form`, navigation, sharing, sheets, menus, alerts, or confirmation behavior
merely to use MHUI.

## Package Posture

Treat package declaration and product linking as separate decisions.

- The app target currently links the local `StallyLibrary` product, the full
  `MHPlatform` umbrella product for runtime/logging/routing, StoreKit, AdMob,
  and license integration, and the remote `MHUI` product for presentation
  styling.
- `StallyLibrary` declares `MHPlatform` and links the `MHPlatformCore` product
  for shared deep-link route contracts and preference descriptors.
- `SwiftLintPlugins` is declared in `Stally.xcodeproj` for repository-managed
  linting and should not be treated as a runtime dependency.
- `MHUI` re-exports `MHDesign`; do not add a separate `MHDesign` product link
  unless a concrete build or target-boundary need appears.
- CloudKit is enabled through SwiftData configuration and app entitlements. It
  is not a package dependency. Runtime startup selects the CloudKit-backed
  container when the persisted iCloud preference is on. Subscription status
  must not gate iCloud sync.
- Do not upgrade `StallyLibrary` to the app-facing `MHPlatform` product unless
  a concrete library-safe boundary requires it.
- The app target intentionally adopts the `MHPlatform` umbrella now that
  Stally has StoreKit and AdMob surfaces. Do not add additional runtime
  products outside the umbrella solely because Incomes or Fluel declares them.
- AdMob app configuration currently uses Google's official sample application
  ID so the umbrella-linked Google Mobile Ads SDK can initialize safely.
  Debug and preview builds use Google's official native test ad unit. Release
  builds must not invent or borrow an ad unit; keep production native ads
  disabled until a Stally-owned production AdMob ad unit exists.

## Expected Apple Implementation Contract

Agents MUST prefer the Xcode-native integration available in the current agent
environment for project discovery, active scheme and destination selection,
build, test, run, runtime logs, Preview rendering, live UI inspection, and
screenshots.

Before changing Xcode's active selection, discover the open projects, schemes,
and run destinations, identify `Stally.xcodeproj`, and record the original
active scheme and destination. Switch only to scheme and destination values
returned by discovery. After verification, restore the original scheme first,
rediscover its valid destinations, restore the original destination, and
confirm the final selection. Report any selection that cannot be restored.

Treat library tests, surface builds, retained repository rule checks, and
runtime/UI evidence as separate verification capabilities. Choose the smallest
set that proves the current change, and prefer stronger evidence when public
APIs, wire contracts, SwiftData schema, app lifecycle wiring, framework
integration, or visible UI behavior are affected.

Use this expected verification shape:

- For app compile checks, use the available Xcode-native build capability with
  project `Stally.xcodeproj`, scheme `Stally`, and a discovered iOS
  Simulator destination matching the iOS 27 baseline.
- For shared-library logic, model, or test changes, run
  `bash ci_scripts/tasks/test_stally_library.sh`.
- For public `StallyLibrary` APIs, `*Operations`, shared contracts, SwiftData
  schema, or adapter-facing contracts, also build `Stally.xcodeproj` with the
  `Stally` scheme through the available Xcode-native integration.
- For runtime or UI-sensitive changes, add a targeted Xcode-native run,
  runtime-log review, Preview rendering when appropriate, and live UI or
  screenshot evidence.

For localization changes, run the string-catalog audit with the required
English and Japanese locale set:

```sh
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
python3 "$CODEX_HOME/skills/string-catalog-maintainer/scripts/audit_xcstrings.py" \
  --project-root . \
  --required-locales en,ja \
  --format markdown
```

For App Intents changes, confirm the app build extracts App Intents metadata
and that user-facing intent strings remain catalog-backed.

For CloudKit or SwiftData container changes, run an app runtime check and
inspect logs for fatal CloudKit, SwiftData, ModelContainer, App Intents, crash,
or exception output. A local simulator run does not prove real-device iCloud
sync or production CloudKit environment behavior.

The generated project-level `StallyLibrary` package product scheme remains
available for Xcode-native builds, but package tests are driven by
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
static architecture checks that are not naturally covered by the available
Xcode-native integration.
SwiftLint should be resolved from the `SimplyDanny/SwiftLintPlugins` package
declared in the project, not from a separately installed `swiftlint` binary.

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
`git diff --check`. It does not replace Xcode-native app build or runtime
evidence when app lifecycle, package linking, SwiftData container wiring, or
visible UI behavior changes.

For Swift or Xcode project changes, also build `Stally.xcodeproj` with the
`Stally` scheme and a discovered iOS Simulator destination through the
available Xcode-native integration. For runtime or UI-sensitive changes, run
the app through that integration, inspect runtime logs, and capture live UI or
screenshot evidence.

If Xcode beta UI automation is unavailable or unreliable, fall back to
runtime logs, screenshots, and library/domain tests. Do not treat successful
launch alone as sufficient evidence for visible UI behavior.
