# Diagnostics Access

## Entry and Availability

The Library sidebar has a visible **Diagnostics** action in every build. It opens
one MHUI-backed sheet without replacing the app's sidebar/list/detail navigation.
The startup-error screen provides the same action when no store is available.
No repeated taps, hidden gesture, saved unlock flag, account role, or TestFlight
receipt check is required.

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

Only DEBUG adds the detailed store-location rows and the next-launch controls
for shared-store selection and initial sample creation. Their preferences and
seed factory remain compiled out of Release. A confirmation explains the shared
store's possible iCloud writes; the current container does not switch in place.
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
- Keep: DEBUG-only store selection and sample lifecycle, with no record reset.

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
