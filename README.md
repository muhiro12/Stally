# Stally

Stally is a pre-release iPhone and iPad app for keeping a quiet record of the
things and places that matter to you. Record everyday choices with Marks,
look back on time together, or keep both kinds of knowledge for the same Item.

The repository is in rebuild implementation. The legacy implementation was
removed after product intent was preserved under `docs/`, and the current tree
now contains a fresh Apple-platform app project plus a local library package:

- `Stally.xcodeproj`, with the `Stally` app target and `Stally` scheme.
- `Stally/`, a SwiftUI app source tree for the rebuilt Library, Archive,
  Review, Insights, Import & Export, Settings, shareable-link surfaces,
  App Intents adapters, app-side MHUI presentation chrome, English and
  Japanese string catalogs, and DEBUG-only preview support.
- `StallyLibrary/`, a local Swift package for the durable item domain,
  SwiftData models, CloudKit-aware persistence setup, localized library
  resources, and product operations.
- `StallyLibrary/Tests/`, Swift Testing coverage for the current domain
  operations.
- `ci_scripts/`, repository-managed lint, rule, and library-test entrypoints.
- `docs/ui-preview-report.md` and `docs/ui-preview-screenshots/`, a
  current-state UI preview and screenshot audit for MHUI/MHDesign adoption.
- `Stally.xcodeproj/xcshareddata/xcodecloud/manifest.json`, an Xcode Cloud
  manifest.

The current implementation is intentionally small. It is not a restoration of
the removed legacy architecture, navigation, persistence model, or feature set.

## Rebuild Documentation

Start with the documentation relevant to the changed boundary:

| Decision | Current entry point |
| --- | --- |
| Product purpose, domain, workflows, and language | [Product brief](docs/product-brief.md), [purpose](docs/product-purpose.md), [preserved concepts](docs/preserved-concepts.md), [domain](docs/domain-concepts.md), [workflows](docs/user-workflows.md), [experience principles](docs/user-experience-principles.md), [language](docs/product-language.md) |
| Owner-directed baseline and scope | [Rebuild implementation direction](docs/rebuild-implementation-direction.md), [implementation principles](docs/rebuild-implementation-principles.md) |
| Live SwiftData read ownership and value lifetimes | [App data flow](docs/swiftdata-app-data-flow.md) |
| Durable writes and cross-surface use cases | [Domain Operations](docs/domain-operations.md) |
| Selected first-release model and retained compatibility | [First release data model](docs/first-release-data-model.md) |
| Export/import identity, versions, validation, and review | [Portable data contract](docs/portable-data-contract.md) |
| App Intents, entity identity, replay, and Widget/Watch scope | [System interface contract](docs/system-interface-contract.md) |
| Samples, DEBUG profiles, frozen migration evidence, and scale | [Fixture architecture](docs/fixture-architecture.md), [original V1 fixtures](StallyLibrary/Tests/Default/Fixtures/V1/README.md), [current interchange fixtures](StallyLibrary/Tests/Default/Fixtures/Interchange/README.md) |
| Accepted combined Item behavior | [Item start and elapsed time](docs/item-start-and-elapsed-time-proposal.md) |
| Current UI and integration evidence | [Tracking verification](docs/item-tracking-verification.md), [combined interface](docs/combined-interface-design.md), [near-term brief](docs/near-term-development-brief.md) |
| Legacy extraction evidence | [Rebuild handoff](docs/rebuild-handoff.md) |

These documents describe what Stally is, why it exists, which concepts must
survive, and which legacy implementation details were intentionally discarded.
`docs/rebuild-implementation-direction.md` separately records explicit rebuild
direction that did not come from the removed legacy source.

Some documents preserve the phase-boundary language from when they were
created. This README describes the current repository state. The selected
first-release model and accepted implementation choices govern current model
work; earlier integration assessments and their approval gates are historical
evidence. Do not infer architecture, persistence, routes, or future features
from removed legacy implementation details. Keep product-intent documents in
their existing English voice and distinguish extracted evidence from later
owner-directed decisions.

## Current Repository State

This repository currently contains rebuilt core Stally surfaces for Library,
Archive, Review, Insights, Import & Export, Settings, shareable links, CloudKit
persistence baseline, App Intents, monetization, and English/Japanese
localization. The app target owns SwiftUI presentation, app lifecycle wiring,
navigation, MHUI visual chrome, file import/export presentation, route handling,
App Intents adapters, and app string catalogs. The local `StallyLibrary` package owns SwiftData
models, timezone-independent mark days, the versioned model-container factory,
localized library resources, and durable operations for items, review lanes,
insights, backups, and links.

Further implementation decisions should continue to use the preserved product
intent and owner-directed rebuild direction in `docs/`, without inferring
requirements from the removed legacy implementation.

The project currently targets the iOS 27 family. Use the matching Xcode/SDK
family and record the exact toolchain used. Match distribution verification to
the candidate's actual Xcode Cloud build.

The app owns MHPlatform umbrella runtime, logging, routing, StoreKit, AdMob,
license integration, and MHUI presentation. `StallyLibrary` stays on
`MHPlatformCore` for library-safe route and preference primitives. MHUI
re-exports MHDesign. Product linking is distinct from package declaration;
recheck manifests and the owner-directed package baseline when changing it.
Subscription removes ads; it does not gate iCloud sync. Follow the
[monetization direction](docs/rebuild-implementation-direction.md#monetization-direction)
and keep production native ads disabled until a Stally-owned production native
ad unit exists. Do not borrow another app's identifiers.

Widget, Watch, external AI integrations, and wider product expansion remain
outside the current implementation. Use the selected contracts above before
extending scope. Preserve the current V2 schema, tested V1 migration, v3/v2
interchange mapping, UUID identities, and source-preserving import/export
boundaries. The model and portable contract documents govern future evolution.
Never regenerate or open checked-in original V1 stores for writing; tests use
disposable copies, retain external photo storage, and disable CloudKit. Current
golden interchange files remain independent of these original fixtures.

`StallySystemTests` is a focused iOS 27 out-of-process App Intents test bundle;
durable domain tests stay in `StallyLibrary`. Synthetic launch profiles and
their argument vocabulary are documented in the fixture architecture and are
absent from Release builds. Ordinary launch retains real clock and storage.
Keep this current-state map and the verification entry points aligned when
adding targets, schemes, scripts, or app surfaces.

Support/privacy sources live under `.github/pages/`; the Pages workflow is
manually dispatched. Source pushes do not deploy the site, and a local edit
does not establish that a public destination is live. Local Simulator evidence
does not prove real-device iCloud convergence, production CloudKit, resolved
purchases, production ad serving, or authorization for real-data/release actions.

## Build and Test

Use the Xcode-native integration available in the environment for app build,
run, runtime-log, Preview, live UI, and screenshot evidence. Resolve current
actions from its runtime inventory.

Before changing Xcode selection, record the original scheme and destination,
switch only to discovered values, and end sessions or runs started solely for
verification. Restore the original scheme first, rediscover its destinations,
restore the original destination, and confirm the selection. Report failed
restoration.

Choose the smallest evidence set proving the changed boundary:

- Shared-library logic, models, resources, or tests: run
  `bash ci_scripts/tasks/test_stally_library.sh`. Set
  `CI_IOS_SIMULATOR_DESTINATION` to a discovered iOS 27 Simulator rather than
  relying on the script's default device name.
- Public APIs, `*Operations`, persistence, wire, or adapter contracts: also
  build `Stally.xcodeproj`, scheme `Stally`, on a discovered iOS 27 Simulator.
- Swift or Xcode project changes: build the `Stally` app scheme.
- App Intents: confirm app-build metadata extraction and catalog-backed intent
  strings. For selected system journeys, use `StallySystemTests` on a discovered
  dedicated iOS 27 Simulator. The compatibility entry point is
  `bash ci_scripts/tasks/test_stally_intents.sh`, with
  `CI_IOS_SIMULATOR_DESTINATION` required and `CI_DERIVED_DATA_PATH` optional.
  These journeys do not replace library tests or physical Siri/locked-device
  evidence.
- Runtime persistence, CloudKit, or monetization wiring: run the app and review
  relevant SwiftData, CloudKit, ModelContainer, App Intents, StoreKit, Google
  Mobile Ads, fatal, crash, and exception logs.
- Visible UI: add targeted Preview, live UI, or screenshot evidence. When beta
  UI automation is unavailable, report the gap and use logs, screenshots, and
  domain tests; launch success alone does not prove visible behavior.
- Localization: audit catalogs for `en,ja`, confirm app resource processing,
  and capture the affected English/Japanese surfaces. When the
  `string-catalog-maintainer` skill is available, resolve its audit script from
  the loaded skill package and pass `--project-root . --required-locales en,ja
  --format markdown`; do not assume a provider-specific skill installation path.

After Swift edits, run the explicit formatter. Run retained rules when the
changed boundary affects their checks:

```sh
bash ci_scripts/tasks/format_swift.sh
bash ci_scripts/tasks/check_repository_rules.sh
```

The rules entry point runs repository-managed SwiftLint and architecture checks.
SwiftLint comes from the project-declared `SwiftLintPlugins` dependency.
Follow the repository SwiftLint configuration and existing Swift source style.
Markdown follows the [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md).

`bash ci_scripts/tasks/verify_task_completion.sh` is a compatibility aggregate
of retained rules, library tests, and whitespace checks. It does not replace
app build or runtime evidence. `StallyLibrary` package builds are available
through the native package scheme; the library-test script drives package tests.
Xcode Cloud owns formal CI builds, tests, and archives.

Release UI smoke auditing remains a separate, non-destructive pass. Do not
erase Simulator data, reset containers, or add test targets solely for an audit
unless explicitly requested. Keep UI review reports separate from preserved
product-intent documents.

## Support and Privacy

- [Support](https://muhiro12.github.io/Stally/)
- [Privacy Policy](https://muhiro12.github.io/Stally/privacy.html)
