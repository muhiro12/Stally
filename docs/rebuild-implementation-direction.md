# Rebuild Implementation Direction

## Purpose

This document records owner-directed rebuild constraints that were added after
the legacy product-intent extraction.

The documents created during Phase 1 preserve what the old repository showed
about Stally's product intent. This document is different: it records explicit
future implementation direction for the rebuild.

## Relationship To Product Intent

The product-intent documents remain authoritative for what Stally is, why it
exists, and which user-facing concepts must survive.

This document guides how the future implementation should be shaped when the
new Xcode project is created. It must not be used to reinterpret the legacy
implementation as a technical reference.

## Application Philosophy

Stally should treat the focused-app model for an AI-assisted platform future as
a high-priority product and implementation constraint.

The app should remain focused on one deep area of concern: a quiet personal
record of items the user keeps choosing. Stally should not try to become a
super app, a broad lifestyle platform, a social network, or a general
assistant.

The rebuilt app should own clean, high-quality domain data and expose reliable
structured operations around that domain. The human SwiftUI experience remains
first-class, but the domain model and use cases should also be shaped so App
Intents, Siri, Apple Intelligence, and future AI surfaces can operate over
Stally's focused domain without scraping UI state or duplicating business
logic.

This is not a requirement to add generic AI features. It is a product-shape
principle: Stally should be valuable because it owns a focused, trustworthy,
well-structured record that platform intelligence can understand and act on.

## Reference Projects

Origami and Incomes are the highest-priority app reference projects for the
Stally rebuild.

- Use Origami and Incomes as read-only reference projects when they are
  available in the local workspace.
- Inspect those projects before major app shell, UI, package, workflow,
  domain-interface, App Intents, or platform-integration decisions.
- Treat Incomes as the concrete Apple app architecture, package, verification,
  and workflow reference when a more specific Stally decision has not yet been
  made.
- Do not copy product-specific behavior, domain language, screen flows, data
  models, or accidental complexity from either reference project.

## Platform Baseline

The rebuilt app should target the iOS 27 family as its minimum supported iOS
version unless the owner explicitly changes that decision.

This Stally-specific direction overrides the broader cross-repository default
of supporting the latest two iOS versions. Do not add iOS 26 or earlier
compatibility work unless a later product decision requires it.

When the project is created, use the Xcode and iOS SDK that match the iOS 27
baseline rather than preserving compatibility with the removed legacy project.

## Package Direction

The rebuilt Stally project should use the same package family as Incomes unless
the owner explicitly changes that direction.

As of June 22, 2026, the Incomes package baseline includes:

- `MHPlatform` from `https://github.com/muhiro12/MHPlatform.git`.
- `MHUI` from `https://github.com/muhiro12/MHUI`.
- `SwiftLintPlugins` from
  `https://github.com/SimplyDanny/SwiftLintPlugins`.

For a future shared library package, use Incomes as the reference for choosing
library-level package products such as `MHPlatformCore` when only core platform
support is needed.

For app targets, use Incomes as the reference for package products such as
`MHPlatform`, `MHPreferences`, and the relevant MHUI products. Recheck Incomes
at project creation time and align with its then-current package set rather
than freezing this document as a stale package lock.

## MHUI Direction

Stally should use MHUI intentionally and should take full advantage of the SDK
capabilities available at the iOS 27 baseline.

Do not constrain Stally to a minimal or legacy-compatible MHUI adoption unless
there is a concrete product or technical reason. Prefer current MHUI and
MHDesign APIs, native SwiftUI behavior, HIG alignment, system materials, and
the package's active design direction where they fit Stally's quiet product
tone.

MHUI should support the presentation layer. It must not own Stally's domain
model, business rules, persistence meaning, navigation meaning, backup policy,
or product language.

## Architecture Implications

The rebuild should keep Stally's durable domain behavior independent of UI
surfaces.

The core concepts in `docs/` should be expressed through clear domain data and
use cases that can be called from app UI and future system surfaces. App
Intents should expose existing Stally concepts and operations; they should not
be a separate business-logic implementation.

Important domain concepts for future structured access include:

- Items.
- Marks.
- Mark history.
- Library.
- Archive.
- Review lanes.
- Insights readings.
- Backup actions.
- Shareable destinations and item links.

Use platform-native persistence and Apple framework patterns when choosing the
future implementation, but do not treat the removed legacy SwiftData schema as
the required design.

## Boundaries

This document does not create the new Xcode project.

It does not select the final persistence schema, navigation hierarchy, backup
file format, App Intents surface, or UI composition. Those decisions should be
made during the rebuild using this direction, the preserved product intent,
the current Apple SDK, and the selected reference projects.
