# Remote Update Control

Stally uses MHPlatform's standard App Store update controller with its own
[shared configuration](https://github.com/muhiro12/MHAppConfig/blob/main/stally/app.json).
The runtime endpoint is
`https://raw.githubusercontent.com/muhiro12/MHAppConfig/main/stally/app.json`.
The app identity is `com.muhiro12.Stally`, with App Store ID `6760996986`.

## Release Policy

The initial policy has revision 1, `requirement: null`, and no scheduled
requirements. Integration is active, but no minimum version is enforced before
the first public release. Future requirements use the package's validated
minimum version and UTC activation time. Increase the policy revision for every
change, including cancellation, following MHAppConfig's publishing contract.

An update blocks only after the required minimum is confirmed as publicly
available for Stally. Missing evidence or an unpublished minimum yields
`unavailable`. A failed refresh retains a confirmed requirement while its
evidence is fresh; expired evidence becomes `unavailable`. There is no
app-owned enforcement timer or arbitrary version floor.

## Lifecycle and Writes

One `RemoteUpdateOperations` instance belongs to each platform environment.
Startup and foreground hooks restore and refresh policy through MHPlatform.
The package owns revision checks, publication lookup, cache coordination, and
evidence lifetimes. Stally logs preparation failures and evaluation reasons.

Every UI mutation of collection records and the five writing App Intents
check the same service before mutating data or reporting success. The controller
merges retained evidence and reevaluates timed requirements at each check.
Stally explicitly uses
`allowWhenUnavailable` so ordinary local records remain usable offline without
adding networking to every edit. A confirmed required update always blocks.
Read-only queries and backup export do not require mutation permission.

The required-update screen covers navigation and write-capable sheets while
preserving their existing view state and unsaved input. Its actions open the
Stally App Store page or retry policy preparation. Underlying controls and
accessibility content are disabled while the requirement is confirmed.

## Isolated Verification

SwiftUI previews and explicit DEBUG fixture launches use isolated update
services and never read or write production update evidence. Adding
`--stally-preview-update-required` to a fixture launch supplies a synthetic,
confirmed requirement for screen verification. That flag has no effect on a
production data environment or a Release build.

Library tests cover blocked mutation and success effects, explicit offline
access, unpublished versions, timed activation, retained requirements after
refresh failure, evidence expiry, cancellation, and disabled previews. Local
validation does not publish MHAppConfig or prove App Store distribution.
