# Stally

## Overview

Stally is a SwiftUI app for quietly tracking the personal items you keep
choosing over time. It stores items and daily marks with SwiftData, surfaces
review lanes for neglected or archived items, builds collection-wide insights,
and supports portable backup export and restore flows.

## Targets

- **Stally** – the iOS app under `Stally/Sources/` that owns SwiftUI screens,
  app runtime/bootstrap, preferences, TipKit guidance, file import/export, and
  app-side routing.
- **StallyLibrary** – the shared domain layer containing the SwiftData models,
  item and mark services, review and insights calculators, backup codecs and
  import logic, and shared deep-link definitions.

## Feature Highlights

### Library and marking

- Create items with categories, notes, and optional photos.
- Record daily marks to capture the things you chose on a given day.
- Search and filter active items from the main library surface.

### Review and archive

- Surface items that still need a first mark, feel dormant, or look ready to
  return from archive.
- Archive or restore items in bulk from dedicated review lanes.

### Insights and summaries

- Explore activity, streak, cadence, category, ranking, and recommendation
  summaries over configurable time ranges.
- Share or copy a generated insights report from the app.

### Backup and restore

- Export the current library as a `.stallybackup` document.
- Preview merge or replace import outcomes before restoring a backup.

## Architecture and Technologies

- **Library-first boundary** – `Stally/Sources/` stays focused on app
  composition and UI, while reusable domain and persistence logic lives in
  `StallyLibrary/`.
- **SwiftData storage** – `ModelContainerFactory.shared()` creates the
  persistent container for `Item` and `Mark`.
- **App runtime and routes** – `StallyAppAssembly` wires runtime lifecycle,
  preferences, and route handling around `StallyDeepLinking`.
- **Preview support** – the app can create an in-memory preview container and
  seed sample data for SwiftUI previews.

## Repository Layout

- `Stally/Sources/` contains the iOS app source tree, split into `Common`,
  `Main`, and feature directories such as `Home`, `Review`, `Insights`, and
  `Transfer`.
- `Stally/Resources/` contains app-facing string catalogs and bundled assets.
- `StallyLibrary/Sources/` contains the shared Swift package source of truth.
- `Designs/` contains architecture guides, ADRs, and the current repository
  overview.

## Design References

- `Designs/Architecture/ARCHITECTURE_GUIDE.md`
- `Designs/Architecture/shared-service-design.md`
- `Designs/Decisions/`
- `Designs/Overviews/stally-current-overview.md`

## Requirements

- Xcode 16 or later with the iOS 18 SDK installed
- `pre-commit`
- `swiftlint`

## Setup

1. Open the repository root.
2. Install hooks with `pre-commit install`.
3. Open `Stally.xcodeproj` in Xcode.
4. Run the **Stally** scheme on an iOS 18 simulator or device, or use the
   **StallyLibrary** scheme when iterating on shared logic and tests.

## Build and Test

Use the helper scripts in `ci_scripts/` as needed.

For full local verification:

```sh
bash ci_scripts/tasks/verify.sh
```

If you only need required builds/tests based on local changes:

```sh
bash ci_scripts/tasks/run_required_builds.sh
```

If you only need the app build:

```sh
bash ci_scripts/tasks/build_app.sh
```

If you only need shared library tests:

```sh
bash ci_scripts/tasks/test_shared_library.sh
```

If you only need pre-commit hooks:

```sh
bash ci_scripts/tasks/pre_commit.sh
```

## CI Artifact Layout

CI helper scripts write all generated artifacts under `.build/ci/`.
Run-scoped outputs are stored in `.build/ci/runs/<RUN_ID>/` (summary,
commands, meta, logs, results, work), while shared caches and build state live
in `.build/ci/shared/` (`cache/`, `DerivedData/`, `tmp/`, `home/`).
