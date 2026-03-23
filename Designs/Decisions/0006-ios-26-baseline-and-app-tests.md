# ADR 0006: Stally Uses an iOS 26 Baseline and App Adapter Tests

- Date: 2026-03-21
- Status: Accepted

## Context

Stally completed a second-pass SwiftUI modernization around a tab shell,
screen-model presentation flow, and a more visual iOS-first interaction style.
Keeping iOS 18 compatibility would force adapter branches around newer SwiftUI
navigation, transition, and layout APIs, while build-only verification no
longer gives enough confidence for app-owned route and presentation logic.

## Decision

`Stally` and `StallyLibrary` both target iOS 26 or newer. App-side
implementation may prefer iOS 26 SwiftUI APIs where they simplify or improve
the product flow. The repository also adds `StallyTests` as an app-side XCTest
target covering route application, screen models, and `StallyItemEditorModel`.
`bash ci_scripts/tasks/verify_repository_state.sh` becomes the change-aware CI
entrypoint and includes app tests when app-side files change.

## Consequences

- App code can use iOS 26-only SwiftUI presentation and motion APIs without
  compatibility shims.
- Screen models and editor models in the app target now have direct automated
  coverage instead of relying on build success alone.
- CI for app changes now requires simulator-backed XCTest execution in addition
  to app builds and shared-library tests.
