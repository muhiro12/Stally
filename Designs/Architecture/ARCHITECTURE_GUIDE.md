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
| Adapter (`Stally/Sources/Common/Platform`, `Stally/Sources/Main`, `Stally/Sources/Transfer`) | Platform API calls, dependency wiring, file import/export orchestration, route application, follow-up orchestration around domain outcomes | Reimplemented domain branching or persistence rules already expressible in `StallyLibrary` |
| View (`Stally/Sources/**/Views`) | Query state, sheets, navigation, formatting, view composition, display-only filtering controls | Review scoring rules, archive heuristics, backup merge semantics, insights calculations duplicated from library services |

## View Rules

Allowed in views:

- Search and transient query state
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

`URL -> StallyDeepLinking codec -> StallyRootRouteService -> navigation state`

`StallyRoute` and `StallyDeepLinking` stay shared in `StallyLibrary` so route
URLs remain stable, while navigation meaning stays in the app target.

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
- Route application into navigation state

## Current Hotspots and Minimal Refactor Plans

1. Several views still read library calculators directly.
   Files:
   - `Stally/Sources/Home/Views/StallyHomeView.swift`
   - `Stally/Sources/Archive/Views/StallyArchiveView.swift`
   - `Stally/Sources/Insights/Views/StallyInsightsView.swift`
   - `Stally/Sources/Review/Views/StallyReviewView.swift`
   Minimal plan:
   - Introduce screen snapshot builders or thin app-side adapters before adding
     more branching to those views.
   - Keep UI-only query state in the view, but push reusable summary assembly
     out of the view.

2. Backup import/export must keep its split between app adapters and library rules.
   Files:
   - `Stally/Sources/Transfer/Support/StallyBackupDocument.swift`
   - `Stally/Sources/Transfer/Views/StallyBackupCenterView.swift`
   - `StallyLibrary/Sources/Transfer/StallyBackupCodec.swift`
   - `StallyLibrary/Sources/Transfer/StallyBackupImportService.swift`
   Minimal plan:
   - Keep file presentation and confirmation UI in `Stally`.
   - Keep snapshot validation and apply logic in `StallyLibrary`.

3. Main route and mutation entry points should stay thin.
   Files:
   - `Stally/Sources/Main/Services/StallyRootActionService.swift`
   - `Stally/Sources/Main/Services/StallyRootRouteService.swift`
   Minimal plan:
   - Add orchestration here only when it adapts platform concerns or navigation.
   - Move shared mutation rules into `StallyLibrary` instead of expanding these
     services into a second domain layer.
