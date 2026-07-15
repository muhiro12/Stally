# Stally

Stally is an unfinished iPhone app for quietly tracking the personal items a
user keeps choosing over time.

The repository is in rebuild implementation. The legacy implementation was
removed after product intent was preserved under `docs/`, and the current tree
now contains a fresh Apple-platform app project plus a local library package:

- `Stally.xcodeproj`, with the `Stally` app target and `Stally` scheme.
- `Stally/`, a SwiftUI app source tree for the rebuilt Library, Archive,
  Review, Insights, Backup Center, Settings, shareable-link surfaces,
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

Use the documents under `docs/` as the rebuild documentation set:

- `docs/product-brief.md`
- `docs/product-purpose.md`
- `docs/preserved-concepts.md`
- `docs/domain-concepts.md`
- `docs/user-workflows.md`
- `docs/user-experience-principles.md`
- `docs/product-language.md`
- `docs/rebuild-handoff.md`
- `docs/rebuild-implementation-direction.md`
- `docs/rebuild-implementation-principles.md`

These documents describe what Stally is, why it exists, which concepts must
survive, and which legacy implementation details were intentionally discarded.
`docs/rebuild-implementation-direction.md` separately records explicit rebuild
direction that did not come from the removed legacy source.

Some documents preserve the phase-boundary language from when they were
created. This README and `AGENTS.md` describe the current repository state.

## Current Repository State

This repository currently contains rebuilt core Stally surfaces for Library,
Archive, Review, Insights, Backup Center, Settings, shareable links, CloudKit
persistence baseline, App Intents, and English/Japanese localization. The app
target owns SwiftUI presentation, app lifecycle wiring, navigation, MHUI visual
chrome, file import/export presentation, route handling, App Intents adapters,
and app string catalogs. The local `StallyLibrary` package owns SwiftData
models, timezone-independent mark days, the versioned model-container factory,
localized library resources, and durable operations for items, review lanes,
insights, backups, and links.

Further implementation decisions should continue to use the preserved product
intent and owner-directed rebuild direction in `docs/`, without inferring
requirements from the removed legacy implementation.

The project currently targets the iOS 27 family. Compile checks should build
the `Stally` scheme for iOS Simulator with a matching Xcode and SDK.

Useful local checks:

```sh
bash ci_scripts/tasks/check_repository_rules.sh
bash ci_scripts/tasks/test_stally_library.sh
bash ci_scripts/tasks/verify_task_completion.sh
```

Use the Xcode-native integration available in the agent environment for app
build, run, runtime-log, Preview, live UI, and screenshot evidence.

## Support and Privacy

- [Support](https://muhiro12.github.io/Stally/)
- [Privacy Policy](https://muhiro12.github.io/Stally/privacy.html)
