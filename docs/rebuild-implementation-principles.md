# Rebuild Implementation Principles

## Purpose

This document records implementation principles that became concrete during
the current rebuild. It is a short engineering memo, not a product roadmap.

## Baseline Infrastructure

CloudKit, App Intents, monetization, and English/Japanese localization are
baseline rebuild requirements for Stally.

- CloudKit belongs in the SwiftData persistence configuration, but runtime
  startup should select it when the persisted iCloud preference allows sync.
- App Intents belong beside the app target as system-facing adapters.
- StoreKit and AdMob belong in the app target through MHPlatform. Durable
  subscription-state rules belong in StallyLibrary. iCloud sync is independent
  from subscription state and must remain available without payment.
- Localization belongs in String Catalogs while UI and App Intents are being
  built, not after the visible surface is complete.

## Boundary Rules

`StallyLibrary` owns durable domain behavior, SwiftData models, persistence
factory setup, localized library resources, and public `*Operations` use
cases.

The app target owns SwiftUI presentation, navigation, App Intents, dependency
registration, incoming-link handling, monetization wiring, preview launch
routing, screenshots, and app String Catalogs.

App Intents must call existing public `*Operations` and should not reimplement
item creation, marking, archiving, search, review, insights, backup, or link
logic. Add or extend Operations before exposing a new cross-surface business
use case.

Shareable-link URL grammar belongs to `StallyLibrary` and should use the
shared app-family deep-link route primitives. The app target should apply
resolved links to its current navigation state instead of duplicating URL
parsing rules.

Preview and tests should use in-memory containers. Runtime should use the local
persistent configuration by default and the CloudKit-capable persistent
configuration only when iCloud sync is enabled, with a local persistent
fallback only for recoverable CloudKit initialization failure.

## Calendar And Persistence Rules

Marks use `LocalDay` as a timezone-independent Gregorian calendar-day value.
App adapters capture the current date and time zone once, then pass a resolved
day into public Operations. Durable mark behavior must not persist a
timezone-relative start-of-day `Date`.

The rebuilt SwiftData model is the first versioned schema baseline. Future
persisted model changes should append schema versions and migration stages;
the removed legacy persistence model is not a migration source for this
baseline.

The current backup wire contract encodes mark days as canonical ISO 8601
full-date strings. Unsupported backup versions must be diagnosed before any
merge, replacement, or deletion mutates the library.

## Localization Rules

English is the source language. Japanese is the required additional baseline
language.

Catalog-backed strings should cover:

- SwiftUI user-facing copy.
- App Intent titles, descriptions, parameters, dialog/result strings, and App
  Shortcut phrases.
- Library-owned localized errors and reusable presentation strings.

Preserve product language and tone across both languages. Do not replace
Stally's quiet vocabulary with habit-tracker, inventory, shopping, or
productivity-system language.

## Verification Rules

Choose verification by changed boundary:

- SwiftData schema, persistence, public Operations, or package resources:
  library tests, repository rules, and app `build_sim`.
- App Intents: app `build_sim`, App Intents metadata extraction evidence, and
  runtime route/log evidence when routing changes.
- Localization: string-catalog audit, app build resource-processing evidence,
  and English/Japanese screenshots.
- Runtime persistence or visible UI: `build_run_sim`, runtime log scan, and
  screenshot evidence.
- StoreKit, AdMob, or MHPlatform runtime wiring: app `build_sim`,
  `build_run_sim`, runtime log scan for StoreKit, Google Mobile Ads, SwiftData,
  CloudKit, fatal, exception, or crash output, and screenshot evidence.

Real-device iCloud sync and production CloudKit environment behavior may need
manual or hosted verification outside the local simulator. Record that
explicitly when it is not proven.
