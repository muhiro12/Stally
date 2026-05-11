# Stally and Incomes Architecture Comparison

Current as of May 11, 2026.

## Scope

This comparison uses `../Incomes` as a read-only architectural reference and
uses `../MHPlatform` as the higher-level source of truth for shared platform
adoption rules. It compares outer architecture, repository workflow, package
boundaries, and compatibility posture rather than product behavior.

## Reference Paths

- `AGENTS.md`
- `README.md`
- `Stally/Sources/`
- `StallyLibrary/Sources/`
- `StallyLibrary/Tests/`
- `ci_scripts/`
- `Designs/Architecture/`
- `Designs/Decisions/`
- `../Incomes/AGENTS.md`
- `../Incomes/IncomesLibrary/Package.swift`
- `../Incomes/IncomesLibrary/Sources/`
- `../Incomes/ci_scripts/`
- `../Incomes/Designs/Architecture/`
- `../Incomes/Designs/Decisions/`
- `../MHPlatform/Designs/Architecture/adoption-policy.md`
- `../MHPlatform/Designs/Architecture/consumer-boundaries.md`

## Difference Assessment

### Align: Agent and Hook Workflow

Incomes exposes an optional `verify_pre_push.sh` wrapper around the same
non-destructive verify gate. Stally had only `verify_pre_commit.sh`, so adding
the wrapper improves workflow parity without replacing the existing
pre-commit contract.

### Align: Pre-Release Compatibility

Stally is pre-release, so the Incomes migration-tolerance language should not
be copied as-is. Stally should reject unsupported current-format backup data
instead of silently adapting it.

### Align: Testing Boundary

Incomes keeps repository-owned unit tests in `IncomesLibrary/Tests` because
app, watch, widget, and intent adapters are responsibility-thin. Stally now
uses the same posture: no separate app unit test target, app changes are
verified by app build, and durable rules should move into `StallyLibrary`
before receiving repository-owned tests.

### Adapt: MHPlatform Adoption

Incomes and Stally both use `MHPlatformCore` in the shared library and
`MHPlatform` in the app target. This matches the current MHPlatform consumer
matrix, so direct copy is unnecessary.

### Keep: Product Target Topology

Incomes has iOS, watchOS, widget, App Intent, and sync surfaces. Stally is
currently a single iOS app plus shared library. Adding parallel surfaces for
symmetry would create fake architecture.

### Align: CI Guardrails

Stally previously had extra secret-scan and `MHUI` adoption checks in the
standard gate. Those were removed from the standard verification path so the
workflow matches Incomes more closely: environment, MHPlatform boundary,
models-directory consistency, app build, and shared-library tests.

## Actioned Changes

- Added an optional `ci_scripts/tasks/verify_pre_push.sh` wrapper.
- Documented the Incomes comparison and alignment decisions here.
- Clarified thin-target and testing boundaries in
  `Designs/Architecture/ARCHITECTURE_GUIDE.md`.
- Added ADR 0008 for the pre-release compatibility posture.
- Removed stale compatibility-wrapper language from ADR 0001.
- Corrected stale service names in architecture docs.

## Deferred Items

- Do not add Incomes-only product surfaces such as watchOS, widgets, or App
  Intents for architectural symmetry.
- Do not copy Incomes `ci_post_clone.sh`; it writes an Xcode user default and
  is not required for Stally's current verification contract.
