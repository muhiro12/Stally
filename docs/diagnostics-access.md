# Diagnostics Access

## Entry and Availability

The Library sidebar has a visible **Diagnostics** action in every build. It opens
one MHUI-backed sheet without replacing the app's sidebar/list/detail navigation.
The startup-error screen provides the same action when no store is available.
No repeated taps, hidden gesture, saved unlock flag, account role, or TestFlight
receipt check is required.

The owner's [Issue #34 clarification](https://github.com/muhiro12/Stally/issues/34#issuecomment-6465665557)
explicitly accepts this access direction. The former secret-command model was
considered and deliberately retired: discoverable access is preferable to hidden
functionality, and obscurity cannot protect privileged tools. Do not restore an
`enable debug` command or saved unlock mode during a later refactor. The current
name and secondary sidebar placement need no change to satisfy this direction.

Stally does not yet have a full Settings surface. The sidebar is the current
entry; moving this internal navigation action into Settings later does not create
an external URL or persistent identity contract. TestFlight and App Store builds
use the same Release diagnostics capability. This change must be included in a
new binary before already-installed distribution builds can expose the action.

## Read and Write Boundary

All builds show the actual open container's disk/in-memory configuration,
configured CloudKit status, record counts, app version/build, and schema version.
The counts include archived Items and other records outside the current Library
filter. A refresh performs local reads through `DiagnosticsOperations`; it does
not save pending edits, inspect image payloads, or prove CloudKit convergence.
Existing startup or read failures remain visible instead of presenting invented
zero counts. There is no upload, log export, entitlement override, reset, or
record mutation in the distributed screen.

Only DEBUG adds detailed store-location rows, a manual sample action, and the
next-launch controls for shared-store selection and initial sample creation.
Manual insertion is available only for the actual isolated development store
with no records or pending edits. It is independent of the automatic-seeding
preference and does not require a relaunch. The Operations boundary rechecks
eligibility when invoked; the disabled button is not the protection mechanism.
These actions, preferences, and seed factory remain compiled out of Release.
A confirmation explains the shared store's possible iCloud writes; the current
container does not switch in place. Selecting or opening that store never
permits developer-sample insertion.
See [development setup](fixture-architecture.md#current-development-setup).

## Reference Assessment

The owner requested comparison with Incomes and Cookle while explicitly treating
both as work in progress. The inspected Incomes working tree used a visible
Settings/Advanced diagnostics route and separated DEBUG development actions.
Cookle's inspected route was conditional on a debug preference and its screen
still combined diagnostic reads with development actions.

- Align: a visible, ordinary route to inspection that is safe to discover.
- Adapt: use Stally's existing sidebar and MHUI Form; expose only its implemented
  summary diagnostics rather than copying another app's inspectors or log UI.
- Keep: DEBUG-only store selection and initial-only automatic seeding, with no
  record reset. The later clarification adds explicit, empty-store-only manual
  insertion without making production example content part of this feature.

Neither reference checkout was changed. This is a Stally decision, not a claim
that either sibling has finished its redesign or defines the final answer.

Apple's current [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
require accessible, accurately described functionality (2.3.1(a)) and disallow
hidden or undocumented features (2.5.19). Include the Diagnostics entry and its
read-only purpose in review notes when preparing a distribution submission.
This implementation does not submit or publish a build.

## Verification

Verified on October 28, 2026:

- All 35 Library tests passed, including disk-backed diagnostic refresh and
  preservation of unsaved edits. The suite's deliberate read-only-store and
  malformed-store failures remained expected negative-test diagnostics.
- Swift formatting, repository rules, whitespace checks, and the English/Japanese
  string-catalog validation passed.
- Native Xcode DEBUG and Release iOS Simulator builds succeeded. The Release
  build log contained no warnings or errors.
- On iPhone Simulator, DEBUG retained the local development configuration and
  next-launch controls. Release exposed the sidebar route in Japanese and English,
  showed the actual shared-store counts, and omitted development controls and
  full store paths throughout the sheet. No records or preferences were changed.
- Release executable inspection found `DiagnosticsView` and
  `DiagnosticsOperations`, but no development preference/store/seed types or
  development preference-key literals.
- Owned app runs and interaction sessions were stopped. The temporary Release
  launch configuration was restored byte-for-byte, and Xcode returned to its
  original Stally / My Mac selection.

The Release Simulator reported `CKAccountStatusNoAccount` (134400). A configured
CloudKit container does not establish synchronization. Actual TestFlight or
App Store installation, physical-device behavior, CloudKit convergence, and
App Review approval remain unverified. The startup-error entry is implemented
but was not exercised in this UI pass; dark appearance, Dynamic Type, and
VoiceOver interaction also remain unverified.

The later Issue #34 clarification adds DEBUG manual insertion. Its
[follow-up verification](fixture-architecture.md#manual-insertion-follow-up)
records 42 passing Library tests, live initial-opt-out/manual-add behavior,
relaunch retention, and shared-store rejection. The screen's footer now promises
that **refreshing diagnostics** is read-only; it does not incorrectly apply that
promise to the explicit development sample action.
