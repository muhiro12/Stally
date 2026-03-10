# ADR 0002: Deep Link Routes Use App Adapters

- Date: 2026-03-10
- Status: Accepted

## Context

Stally exposes shareable route URLs from Settings, Home cards, Archive rows,
and Review surfaces. The URL structure must stay stable, but the meaning of a
route inside the running app still depends on app navigation state and screen
composition.

## Decision

Keep route definitions and codec logic in `StallyLibrary`, and keep route
application in the `Stally` target. `StallyRoute` and `StallyDeepLinking`
define the shared URL contract, while `StallyRootRouteService` applies routes
to navigation state.

## Consequences

- New route URLs should be added through `StallyRoute` and
  `StallyDeepLinking`, not by hand-building URLs in views.
- Navigation meaning remains app-owned, so route handling can evolve without
  moving app state into the shared library.
- Future surfaces can reuse the shared codec without copying URL parsing logic.
