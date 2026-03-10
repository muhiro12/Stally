# ADR 0003: Platform Adapters Stay in App Target

- Date: 2026-03-10
- Status: Accepted

## Context

Some Stally capabilities depend directly on Apple frameworks, including TipKit,
file import and export, pasteboard and sharing utilities, app runtime
bootstrap, and ad configuration. These dependencies do not belong in the
shared business layer.

## Decision

Keep platform-specific integrations in the `Stally` target. Do not add
platform behavior to library domain services through app-target extensions.
Instead, use dedicated adapter types in the app target.

## Consequences

- `StallyAppAssembly`, `StallyTips`, and `StallyBackupDocument` remain
  app-target types.
- App-target adapters should return or consume library models and value types
  wherever possible.
- `StallyLibrary` stays focused on platform-neutral business logic.
- When a new feature needs Apple-only APIs, the default design is an app-side
  adapter over shared services, not a new responsibility inside the library.
