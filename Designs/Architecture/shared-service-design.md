# Shared Service Design

## Purpose

This document describes the current boundary for shared business logic in
Stally. It explains where new code should live when the same operation must
work across the iPhone app, shared deep links, backup flows, previews, and
future app-side entry points.

## Core Principles

- `StallyLibrary` is the source of truth for shared business logic.
- `Stally` owns SwiftUI presentation and adapters for Apple frameworks.
- Deep-link navigation meaning stays in the app target.
- Views keep presentation state and navigation, but reusable business
  decisions and mutations belong in shared services.
- `StallyLibrary` remains a single module unless there is a stronger reason
  than directory organization alone.

## Responsibility Boundaries

| Concern | Lives in | Examples |
| --- | --- | --- |
| Shared domain logic | `StallyLibrary` | `Item`, `Mark`, `ItemService`, `MarkService`, `ItemReviewCalculator`, `ItemInsightsCalculator`, `StallyBackupCodec`, `StallyBackupImportService`, `StallyDeepLinking` |
| Apple framework adapters | `Stally` | `StallyTips`, `StallyBackupDocument`, `ShareLink`, `UIPasteboard`, file importer/exporter flows |
| App-side platform support | `Stally/Sources/Common/Platform` | `StallyAppAssembly`, `StallyAppConfiguration`, `MHPlatform` app-facing default pillar adoption, `MHAppRuntimeBootstrap` integration, app-wide localization and design glue |
| Presentation orchestration | `Stally/Sources/Main` and `Stally/Sources/**/Views` | SwiftUI views, navigation state, app-side route application, thin mutation adapters |

## Canonical Shared APIs

The following types are the current shared entry points for business
operations:

- `ItemFormInput`
- `ItemService`
- `MarkService`
- `ItemReviewCalculator`
- `ItemInsightsCalculator`
- `StallyBackupCodec`
- `StallyBackupImportAnalyzer`
- `StallyBackupImportService`
- `StallyDeepLinking`
- `StallyRoute`

## Placement Rules

1. If an operation is reusable across more than one app surface or screen,
   add or extend a library service first.
2. If an operation depends on Apple-only frameworks, keep it in `Stally` and
   make it call library APIs.
3. If a view starts recreating review scoring, archive heuristics, backup
   validation, or insights assembly, treat that as a missing shared or
   adapter-layer API.
4. Keep platform-specific types out of `StallyLibrary`. Convert them at the
   boundary into library models or value types.
5. If glue code is app-only but reused by multiple features, factor it into
   `Stally/Sources/Common/Platform` or a feature-local adapter directory
   instead of moving it into `StallyLibrary`.

## Current Examples

- `StallyRootActionService` stays in `Stally` because it adapts view actions
  into library mutations and app error presentation flows.
- `StallyBackupDocument` stays in `Stally` because `FileDocument` is an Apple
  framework adapter, while backup encoding and import application remain in
  `StallyLibrary`.
- `StallyAppAssembly` stays in `Stally` because runtime bootstrap assembly
  still depends on app configuration, route wiring, SwiftUI injection, and how
  Stally applies the `MHPlatform` default app-facing pillar while keeping
  `MHAppRuntime` as an advanced path rather than the repository baseline for
  app-owned navigation and persistence concerns.
- `StallyTips` stays in `Stally` because TipKit guidance is a platform concern,
  not shared business logic.

## Refactoring Heuristic

When a business rule is duplicated, the default fix is to move the rule into
`StallyLibrary` rather than duplicating it in another screen or adapter.
When the duplicated code is still Apple-framework glue, the default fix is to
extract it into `Stally/Sources/Common/Platform` or the relevant app feature
adapter directory.
