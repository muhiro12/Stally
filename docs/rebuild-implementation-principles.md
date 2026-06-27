# Rebuild Implementation Principles

## Purpose

This document records implementation principles that became concrete during
the current rebuild. It is a short engineering memo, not a product roadmap.

## Baseline Infrastructure

CloudKit, App Intents, and English/Japanese localization are baseline rebuild
requirements for Stally.

- CloudKit belongs in the SwiftData persistence configuration from the start.
- App Intents belong beside the app target as system-facing adapters.
- Localization belongs in String Catalogs while UI and App Intents are being
  built, not after the visible surface is complete.

## Boundary Rules

`StallyLibrary` owns durable domain behavior, SwiftData models, persistence
factory setup, localized library resources, and public `*Operations` use
cases.

The app target owns SwiftUI presentation, navigation, App Intents, dependency
registration, incoming-link handling, preview launch routing, screenshots, and
app String Catalogs.

App Intents must call existing public `*Operations` and should not reimplement
item creation, marking, archiving, search, review, insights, backup, or link
logic. Add or extend Operations before exposing a new cross-surface business
use case.

Preview and tests should use in-memory containers. Runtime should use the
CloudKit-capable persistent configuration, with a local persistent fallback
only for recoverable CloudKit initialization failure.

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

Real-device iCloud sync and production CloudKit environment behavior may need
manual or hosted verification outside the local simulator. Record that
explicitly when it is not proven.
