# Stally Architecture Guide

## Scope

This guide defines the strict `domain-in-library, UI-as-adapter` policy for
this repository.

Related document:
[shared-service-design.md](./shared-service-design.md)

## Responsibility Boundaries

| Layer | Owns | Must not own |
| --- | --- | --- |
| Domain (`StallyLibrary`) | Validation, query helpers, review and insights calculations, backup codecs and import analysis, SwiftData schema, deep-link route definitions and codec | TipKit, `FileDocument`, `UIPasteboard`, app runtime/bootstrap wiring, SwiftUI navigation state |
| Adapter (`Stally/Sources/Common/Platform`, `Stally/Sources/Main`, `Stally/Sources/**/Models`, `Stally/Sources/Transfer`) | Platform API calls, dependency wiring, tab and sheet state, route application, screen snapshot building, screen-local query or selection models, file import/export orchestration, follow-up orchestration around domain outcomes | Reimplemented domain branching or persistence rules already expressible in `StallyLibrary` |
| View (`Stally/Sources/**/Views`) | SwiftUI binding, sheets, navigation presentation, formatting, view composition, display-only animation and layout | Search/filter/selection bookkeeping that belongs in screen models, review scoring rules, archive heuristics, backup merge semantics, insights calculations duplicated from library services |

## View Rules

Allowed in views:

- Binding to screen models and shell state
- Sheet, dialog, and navigation behavior
- Display-only formatting
- Layout and composition

Not allowed in views:

- Domain validation branching
- Backup import merge or replace rules
- Review eligibility rules
- Collection insights logic duplicated from `StallyLibrary`

## Canonical Mutation Flow

`View -> app-side action/adapter -> StallyLibrary service -> SwiftData write -> Observation/@Query updates`

App-side adapters may orchestrate alerts, navigation, tips, and file flows
after mutation completion, but the actual rules belong in `StallyLibrary`.

## Deep Link Mapping

Deep links follow this path:

`URL -> StallyDeepLinking codec -> StallyAppRouteService -> StallyAppModel`

`StallyRoute` and `StallyDeepLinking` stay shared in `StallyLibrary` so route
URLs remain stable, while tab selection, stack paths, and editor presentation
meaning stay in the app target.

## SwiftData Boundary

Keep in `StallyLibrary`:

- `@Model` types
- Query builders and calculators
- Mutation and import services
- Backup payload encoding and validation

Keep in `Stally`:

- `ModelContainer` construction
- App runtime/bootstrap wiring
- File importer and exporter UI
- TipKit and app preference wiring
- Route application into tab, stack, and sheet state
- Screen snapshot builders, screen models, and app-only form models

## Platform Baseline

- `Stally` and `StallyLibrary` both target iOS 26 or newer.
- App adapters may prefer iOS 26 SwiftUI APIs such as zoom navigation
  transitions, matched transition sources, glass-prominent buttons,
  `safeAreaPadding`, `contentMargins`, and `scrollTargetLayout`.
- Backward-compatibility branches for pre-iOS 26 behavior should not be added
  in app code unless a new ADR explicitly changes the deployment baseline.

## Current Hotspots and Minimal Refactor Plans

1. App shell state must stay centralized in `StallyAppModel`.
   Files:
   - `Stally/Sources/Main/Models/StallyAppModel.swift`
   - `Stally/Sources/Main/Services/StallyAppRouteService.swift`
   - `Stally/Sources/Main/Views/StallyRootView.swift`
   Minimal plan:
   - Keep tab selection, stack paths, editor presentation, and operation alerts
     in one app-owned model.
   - Keep `StallyRoute` stable in `StallyLibrary` and map it here instead of
     leaking app navigation meaning into shared code.

2. Screen snapshot builders must stay thin and calculator-backed.
   Files:
   - `Stally/Sources/Home/Models/StallyLibrarySnapshot.swift`
   - `Stally/Sources/Archive/Models/StallyArchiveSnapshot.swift`
   - `Stally/Sources/Review/Models/StallyReviewSnapshot.swift`
   - `Stally/Sources/Insights/Models/StallyInsightsSnapshot.swift`
   - `Stally/Sources/Settings/Models/StallySettingsSnapshot.swift`
   - `Stally/Sources/Home/Models/StallyHomeScreenModel.swift`
   - `Stally/Sources/Archive/Models/StallyArchiveScreenModel.swift`
   - `Stally/Sources/Review/Models/StallyReviewScreenModel.swift`
   - `Stally/Sources/Insights/Models/StallyInsightsScreenModel.swift`
   - `Stally/Sources/Settings/Models/StallySettingsScreenModel.swift`
   Minimal plan:
   - Keep snapshot builders pure and calculator-backed.
   - Let screen models own local query, filter, selection, and card/section
     presentation state before views grow additional branching.
   - Keep business rules in shared calculators and services, not in app-side
     snapshot structs.

3. Item editing must keep its split between app presentation state and shared
   mutation rules.
   Files:
   - `Stally/Sources/Item/Models/StallyItemEditorModel.swift`
   - `Stally/Sources/Item/Views/StallyItemEditorView.swift`
   - `StallyLibrary/Sources/Item/ItemService.swift`
   Minimal plan:
   - Keep unsaved-change protection, delete confirmation, and photo-loading
     error state in the app model.
   - Keep validation and persistence rules in `ItemService`.

4. Backup import/export must keep its split between app adapters and library rules.
   Files:
   - `Stally/Sources/Transfer/Support/StallyBackupDocument.swift`
   - `Stally/Sources/Transfer/Views/StallyBackupCenterView.swift`
   - `StallyLibrary/Sources/Transfer/StallyBackupCodec.swift`
   - `StallyLibrary/Sources/Transfer/StallyBackupImportService.swift`
   Minimal plan:
   - Keep file presentation and confirmation UI in `Stally`.
   - Keep snapshot validation and apply logic in `StallyLibrary`.

5. App adapter behavior must stay covered by XCTest.
   Files:
   - `StallyTests/StallyAppRouteServiceTests.swift`
   - `StallyTests/StallyAppModelTests.swift`
   - `StallyTests/StallyItemEditorModelTests.swift`
   - `StallyTests/StallyScreenModelTests.swift`
   - `ci_scripts/tasks/test_app.sh`
   Minimal plan:
   - Add adapter tests in `StallyTests` before pushing more route or screen
     logic into the app target.
   - Keep `run_required_builds.sh` responsible for app build plus app tests
     when app-side files change.
