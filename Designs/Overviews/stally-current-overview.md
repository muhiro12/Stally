# Stally Current Product and Architecture Overview

Current as of March 10, 2026.

## Purpose

Stally is a SwiftUI iPhone app for quietly tracking the personal items a user
keeps choosing over time. The product is implemented as one iOS app plus one
shared domain library:

- An iPhone app for library browsing, review lanes, insights, settings, backup
  export and restore, and deep-link navigation
- A shared library for SwiftData models, mutation services, calculations,
  backup payloads, and route definitions

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

### 6. Preview and sample data support

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

Runtime startup is currently built from `MHAppRuntime(configuration:)` and
`MHAppRuntimeBootstrap`, while Stally keeps app-specific route meaning,
navigation state, and feature presentation in the app target.
