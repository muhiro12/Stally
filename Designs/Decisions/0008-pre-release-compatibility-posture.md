# ADR 0008: Pre-Release Compatibility Posture

- Date: 2026-05-11
- Status: Accepted

## Context

Stally has not shipped publicly yet. Keeping compatibility branches for beta
data shapes, older local APIs, or stale backup payload interpretations would
increase maintenance cost before there is a released compatibility contract.

At the same time, Stally still accepts user-provided files and deep links. Those
inputs need validation, but validation should reject unsupported current-format
payloads instead of silently adapting them.

## Decision

Repository-owned code should not preserve migration shims, old API wrappers, or
beta backup compatibility paths by default while the app remains pre-release.
When an incompatible shape is found, prefer one of these outcomes:

- update the current source of truth destructively
- reject the unsupported input with an explicit validation error
- document a temporary TODO only when the migration is genuinely required

Do not add lower-deployment compatibility branches while the iOS 26 baseline in
ADR 0006 remains accepted.

## Consequences

- Backup import should reject unsupported categories or schema shapes instead
  of mapping them to fallback values.
- SwiftData schema changes may be destructive until a release compatibility
  contract is accepted.
- Documentation and tests should describe the current contract rather than
  preserve beta-era behavior.
- After public release, this ADR should be revisited before introducing
  user-data-breaking changes.
