# ADR 0005: App Shell State and Screen Snapshots Stay in the App Target

- Date: 2026-03-21
- Status: Accepted

## Context

Stally moved from a single-stack shell toward a tab-based SwiftUI shell with
sheet-driven item editing and secondary settings or backup destinations. The
old root navigation state and closure-heavy view interfaces made route meaning,
screen assembly, and editor presentation harder to evolve without pushing more
logic into views.

## Decision

The app target owns one app-level observable shell model, `StallyAppModel`,
which keeps selected tab, per-tab stack paths, item editor presentation, and
operation alert state. Deep-link application stays in `StallyAppRouteService`,
mutation orchestration stays in `StallyAppActionService`, and each major screen
uses a `snapshot builder -> screen model -> view` flow to adapt shared
calculators and services into presentation-ready data. Screen models own local
query, selection, visibility, and card or section state without widening the
shell model. `StallyItemEditorModel` owns editor form state, photo-loading
errors, and unsaved-change protection, while validation and persistence remain
in `ItemService`.

## Consequences

- `StallyRoute` URLs remain stable in `StallyLibrary`, while in-app navigation
  meaning remains app-owned.
- Views consume environment models and screen models instead of large closure
  bundles from the root shell.
- Reusable business rules still belong in shared services and calculators, not
  in app-side shell or snapshot types.
- New shell changes should extend `StallyAppModel`, screen models, and screen
  snapshot builders before adding reusable branching directly into views.
