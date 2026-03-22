# Stally Current Product and Architecture Overview

Current as of March 22, 2026.

## Purpose

Stally is a SwiftUI iPhone app for quietly tracking the personal items a user
keeps choosing over time. The product is implemented as one iOS app plus one
shared domain library, with an app-side XCTest target covering adapter logic.
The current deployment baseline is iOS 26 or newer:

- An iPhone app for library browsing, review lanes, insights, settings, backup
  export and restore, and deep-link navigation
- A shared library for SwiftData models, mutation services, calculations,
  backup payloads, and route definitions
- An app test target for route mapping, editor model behavior, and screen model
  presentation assembly

The current implementation is intentionally biased toward a single source of
truth for business logic in `StallyLibrary`, with platform adapters and UI
living in the app target.

## Product Surface Summary

| Surface | Current role | Key responsibilities |
| --- | --- | --- |
| `Stally` | Primary product surface | Item browsing, item editing, review lanes, archive browsing, backup tools, settings, deep-link sharing, tips, runtime wiring |
| `StallyLibrary` | Shared domain layer | SwiftData models, item and mark mutations, review and insights calculations, backup codecs and import logic, routes |

## Current End-User Features

### 1. Item library and capture

- Create an item with a name, category, optional note, and optional photo.
- Edit or delete an existing item.
- Search and filter active items from the main library surface.
- Toggle today's mark directly from Home or item detail.

### 2. Review and archive flows

- Identify items that still need a first mark.
- Identify items that feel dormant according to configurable thresholds.
- Identify archived items that look ready to return.
- Archive or unarchive single items or bulk selections from review lanes.
- Browse archived items separately without crowding the active library.

### 3. Insights and summaries

- Calculate activity, streak, cadence, category, ranking, and recommendation
  summaries over configurable time ranges.
- Switch between ranges and optionally include archived items.
- Share or copy a generated insights report.

### 4. Backup and restore

- Export the current library as a `.stallybackup` file.
- Import a backup and preview how many items would merge, replace, or fail
  validation.
- Replace the current library after explicit confirmation.
- Delete all items from the current library from the backup workspace.

### 5. Settings and deep links

- Tune review thresholds and visibility behavior.
- Change default Insights range and archive inclusion behavior.
- Copy or share deep links to major app surfaces.
- Reset TipKit guidance and inspect build metadata.

### 6. App shell and navigation

- Move between `Library`, `Review`, `Insights`, and `Archive` from a tab shell.
- Open `Settings` as a secondary destination rather than a top-level tab.
- Reach `Backup Center` from inside Settings while keeping backup actions grouped together.
- Open item creation and editing from a sheet-driven editor flow.

### 7. Preview and sample data support

- Build an in-memory preview container for SwiftUI previews.
- Seed sample data for previews and debug-style exploration.

## Current Architecture and Design Policies

Accepted ADRs and the current codebase agree on one rule: reusable business
logic belongs in `StallyLibrary`, while app runtime, navigation meaning, and
Apple-framework adapters belong in `Stally`.

Current app-side directories under `Stally/Sources/` follow this shape:

- `Common` for shared app support such as runtime assembly, preferences,
  preview, and tips
- `Main` for app launch, navigation state, and root-level routing or mutation
  adapters
- feature directories such as `Home`, `Review`, `Insights`, `Item`,
  `Archive`, `Transfer`, and `Settings`

This layout intentionally mirrors the stronger repository boundary used in
Incomes while staying scoped to Stally's simpler single-app product surface.

Runtime startup is currently built from `MHAppRuntimeCore` composed with
`MHAppRuntimeDefaultsBundle`, `MHAppRuntimeAdsBundle`,
`MHAppRuntimeLicensesBundle`, and `MHAppRuntimeBootstrap`, while Stally keeps
app-specific route meaning, tab and sheet state, screen snapshot builders,
screen models, and feature presentation in the app target.

Shared presentation chrome comes from the public
`https://github.com/muhiro12/MHUI.git` package, while `StallyDesign` keeps
app-local tint and visual token choices inside the app target.

The app shell is now centered on `StallyAppModel`, which owns the selected tab,
per-tab stack paths, modal item editor state, operation alert state, and
preference-backed review or insights UI settings. Route application is handled
by `StallyAppRouteService`, app mutations by `StallyAppActionService`, and the
major surfaces (`Home`, `Archive`, `Review`, `Insights`, `Settings`) each use a
`snapshot builder -> screen model -> view` flow rather than assembling reusable
presentation summaries directly inside the view body.

The iOS 26 baseline allows the app target to prefer newer SwiftUI interaction
and presentation APIs, including zoom-style navigation transitions,
matched-transition sources, `scrollTargetLayout`, `safeAreaPadding`,
`contentMargins`, and glass-prominent call-to-action styling.

App adapter behavior is now verified in `StallyTests`, with coverage focused on
route application, screen models, and `StallyItemEditorModel`. The required CI
entrypoint remains `bash ci_scripts/tasks/run_required_builds.sh`, which now
includes app tests when app-side files change.
