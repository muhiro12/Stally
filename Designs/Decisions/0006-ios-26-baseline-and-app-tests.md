# ADR 0006: Stally Uses an iOS 26 Baseline and Library-Owned Tests

- Date: 2026-03-21
- Status: Accepted

## Context

Stally completed a second-pass SwiftUI modernization around a tab shell,
screen-model presentation flow, and a more visual iOS-first interaction style.
Keeping iOS 18 compatibility would force adapter branches around newer SwiftUI
navigation, transition, and layout APIs.

## Decision

`Stally` and `StallyLibrary` both target iOS 26 or newer. App-side
implementation may prefer iOS 26 SwiftUI APIs where they simplify or improve
the product flow.

Automated unit coverage belongs in `StallyLibrary/Tests`. The app target stays
responsibility-thin and is verified by building the `Stally` scheme. If an app
adapter path needs durable coverage, the reusable rule or wire contract should
move into `StallyLibrary` first.

## Consequences

- App code can use iOS 26-only SwiftUI presentation and motion APIs without
  compatibility shims.
- `Stally` does not maintain a separate app unit test target.
- CI for app changes builds the app scheme, while shared-library changes also
  run the shared-library tests.
