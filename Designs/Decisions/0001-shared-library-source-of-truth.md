# ADR 0001: Shared Library Source of Truth

- Date: 2026-03-10
- Status: Accepted

## Context

Stally already reuses the same domain operations across Home, Review,
Insights, Archive, backup restore, and deep-link entry points. If each surface
grows its own mutation or decision logic, behavior drifts and refactoring
becomes expensive.

## Decision

`StallyLibrary` is the single source of truth for reusable business logic.
Shared models, calculators, query helpers, backup import logic, and route
definitions belong there. The module stays as one shared library for now.

## Consequences

- Shared operations should be expressed through library services before they
  are reused elsewhere.
- `ItemService`, `MarkService`, `ItemReviewCalculator`,
  `ItemInsightsCalculator`, `StallyBackupImportService`, and
  `StallyDeepLinking` are primary shared entry points.
- UI and deep-link flows should depend on the same canonical shared APIs.
- Compatibility wrappers may exist during migration, but new call sites should
  target the canonical library APIs.
