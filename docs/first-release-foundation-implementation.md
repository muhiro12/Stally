# First-Release Foundation Implementation

## Scope and Status

The subsequent [October 28 interface implementation](library-interface-implementation.md)
adds unified navigation, search, Tag controls, and calendar-based editors.
The later [development setup](fixture-architecture.md#current-development-setup)
selects a separate local DEBUG store with initial-only synthetic data; shared
store selection, recovery guards, and Release startup retain the behavior below.
The statements below retain the scope of the October 27 foundation work.

The October 27, 2026 implementation follows the accepted
[contract summary](first-release-contract-summary.md) and
[model schema](model-schema-design.md). The owner explicitly permits breaking
unreleased source and behavior, requires incremental commits on main, and
selects Xcode 27.2 and OS deployment targets of 27.2 or later.

This is the first implementation unit, not first-release completion. The old
single-day Mark, fixed category, single-start, flat backup, and history-dependent
recording-disable APIs have been removed. Their source remains in Git history;
they are not compatibility adapters to the new model. The inherited design
handoff was committed separately before implementation.

## Schema and Store Decisions

- `StallySchemaV3` owns the five nested model declarations. Public aliases expose
  `Item`, `ItemMark`, `ItemPeriod`, `ItemPhoto`, and `Tag` without version names at
  call sites. Keep this snapshot unchanged when adding a later schema.
- The baseline is **3.0.0**, distinguishing it from the existing development V1
  and V2 stores. `StallyMigrationPlan` starts with V3 and no migration stages.
  This does not claim a migration from V1/V2. Frozen V1 and V2 declarations remain outside the active migration plan for
  explicit future development-data inspection. The original V1 fixtures remain
  unchanged as historical evidence, not fixtures to regenerate.
- The selected export pair is `schemaVersion: "3.0.0"`, `formatVersion: 1`.
  These constants do not constitute an implemented package reader or writer.
- Production startup resolves `group.com.muhiro12.Stally` and uses
  `Library/Application Support/Stally.store` inside that container. Both app
  and future extensions must use this factory and the same URL/schema.
- The app requests native private CloudKit mirroring for
  `iCloud.com.muhiro12.Stally`. Initial behavior is enabled without a
  subscription-controlled switch. Account availability remains native system
  behavior. No code promotes a schema, resets a cloud zone, or assumes the
  production container is empty.
- Test/preview factories explicitly select CloudKit `.none`. In-memory storage
  requires an explicit call; it is never a startup fallback.

The named URL is independent of entitlement state. There is no subscription
change handler that swaps the store or erases records. App Group entitlement
source is present; successful Simulator access does not qualify the developer
account registration or a signed physical-device provisioning profile.

## Development Data Boundary

Before opening the shared store, startup checks the old app-local and shared
`default.store` locations and their SQLite sidecars/external-support directory.
If present, it reports the source location and stops. It does not copy, migrate,
open for writing, delete, or silently abandon that data. This check also applies
when a new destination already exists; coexistence needs explicit review.

A container-open failure likewise stops with an explanatory screen and a logged
error. It does not substitute a local-only or empty in-memory library.

**Not implemented:** a reviewed development-store transfer tool. Recovery work
must first identify the source container and its complete SQLite/external-data
set, stop its writers, preserve a recoverable copy, and select explicit mappings
for old category, archive timestamp, single-start, photo, and Mark data. Do not
remove a source merely to make startup succeed. Unusual/manual old store URLs
need inventory during that recovery; startup checks only the locations used by
the previous factory. Existing cloud data and deployed fields need separate
inspection before cloud evolution or publication.

## Operations and Transactions

| Boundary | Implemented behavior |
| --- | --- |
| Item | Create and edit exact confirmed name/note; independent Archive, favorite, and recording state; delete owned graph |
| Mark | Add a fresh UUID for each occurrence, including identical day/time; correct/delete exactly one record; preserve identity and registration time on correction |
| Period | Add unknown/year/month/day boundaries; end in place; resume as another record; correct an accidental ending in place; delete one period |
| Tag | Create distinct same-name identities, rename exact spelling, explicitly assign Tags, delete assignments without Items |
| Photo | Five-model storage, optional external image bytes and persisted thumbnail, caption/order metadata, ownership and cascade; ingestion Operations and UI remain pending |

Period validation uses canonical Gregorian Foundation parsing and temporary
calendar intervals. It rejects definitely reversed boundaries, ongoing periods
with an end, more than one ongoing period, and definite positive-day overlap.
Unknown or merely possible overlap remains valid; ending and resuming on the
same day is permitted. The caller supplies today's local Gregorian day for
ongoing-overlap comparison. These checks are local, not distributed constraints.
Incoming contradictory or unattached records are preserved for explicit review.

Operations require a clean context and live models owned by that context.
Unrelated pending changes cause rejection before mutation. Inputs are validated
before writes; save failure rolls back the operation. UI drafts live in value
state and the app's context disables autosave. Operations do not invent identity
from name, dates, contents, or creation ordering. UUID resolution rejects
ambiguous matches instead of returning an arbitrary record.

## App Consumer

The app now uses the new Operations from Library, Archive filtering, Item edits,
independent state controls, individual Mark editors, and partial-date Period
editors. Destructive actions require confirmation. A resumed period initially
has unknown start knowledge, which can be edited without changing its identity.
The date-entry UI is an initial functional adapter, not a finalized experience.

MHPlatform remains the shared runtime and remote-update policy provider; MHUI
remains the theme provider. The previous domain-specific Review, Insights,
sample injection, search projection, old backup UI, and old App Intent adapters
were retired with their obsolete model assumptions. Custom Item links still
resolve UUIDs and report missing/conflicting targets. The old flat-file document
registration was removed so the app does not claim to import an unsupported
format. Historical documentation remains evidence of those earlier versions.

## Remaining Work

- Photo ingestion, conditional transformation, metadata fidelity, thumbnails,
  attachment Operations, and photo UI/provider qualification.
- Explicit reviewed Tag consolidation, Tag selection/suggestions, and Tag UI.
- `.stally` package codec, identity-preserving import/conflict review and export.
- Full Operations-backed App Intent coverage, action-specific discovery,
  authentication/confirmation, extracted metadata and installed execution tests.
  Removing obsolete adapters does not narrow the accepted first-release scope.
- Universal Link routes, website association, system destinations, Spotlight,
  future Widget/Watch consumers, and any selected shared preference descriptors.
- Review/Insights and period readings; the existing readings proposal remains
  unaccepted. No new elapsed/total semantics are implicitly selected here.
- Settings, subscription presentation/policy, ad presentation, and final UI.
- Explicit development-store recovery, real CloudKit convergence/account
  lifecycle tests, production-schema inspection, and device signing.

## Verification

The initial iOS 27.2 library run passed 23 tests across five suites, including
new in-memory validation and disposable disk-store reopen tests plus retained
link, subscription-state and remote-update tests. Subsequent API refinement is
verified separately in the final evidence below. The consumer built with
Xcode 27.2 (27B48) for iOS 27.2 (24B114).

Disk tests close their scoped container/context and create a fresh container at
the same URL. This is local persistent-store evidence within the test process,
not a separate-process or CloudKit convergence claim. The synthetic two-million
byte photo payload checks external-storage byte recovery and ownership, not
image decoding or photo quality. No user-supplied validation photo was added.

### Integrated Runtime Findings

The first CloudKit-enabled app launch correctly stopped on a schema-validation
error: three nonoptional attributes lacked storage defaults after initializer
cleanup. Restoring defaults on `Item.note`, `ItemPhoto.caption`, and
`ItemPhoto.sortOrder` fixed startup. A generated Core Data model test now checks
that every nonoptional attribute has a default, every relationship is optional
with an inverse, and no deny rule or uniqueness constraint is present. This is
native schema compatibility evidence, not proof of remote convergence.

On the dedicated iPhone 17 Simulator (iOS 27.2, Japanese), manual interaction
then verified the shared-store startup and these synthetic-data flows:

- Create an Item; add two Marks for October 27; correct each independently to
  minute precision. Pause recording: both remain, new additions are disabled,
  and correction of an existing occurrence remains available.
- Add a period starting with year precision (`2024`), end it with month
  precision (`2025-06`), and resume as another ongoing period with unknown
  start. The original ended period remains visible with its original precision.
- Confirm deletion of one Mark. The other Mark, Item, and both periods remain.

The Simulator has no iCloud account. Native mirroring reports
`CKAccountStatusNoAccount` / Core Data 134400; local shared-store work remains
available. No cloud account, production schema, or remote records were changed.

### Final Evidence

After restarting the app process, the same shared store retained the synthetic
Item, its remaining minute-precision Mark, recording pause, the year-to-month
ended period, and the separate ongoing period with unknown start. This adds
actual app-process reopen evidence to the library's local container tests.

| Check | Result |
| --- | --- |
| README library test task on dedicated iOS 27.2 Simulator | 26 tests across seven suites passed |
| Read-only disk-store save failure | Native save rejected with Cocoa 513; attempted metadata rolled back, original persisted record survived reopen |
| Foreign-context mutation and duplicate UUID resolution | Rejected without selecting or altering another record |
| Repository formatter and strict SwiftLint/boundary rules | Passed |
| Final Xcode-native Stally consumer build | Succeeded with no reported errors or warning lines in the build log |
| English/Japanese catalog audit | No incomplete entries; product name `Stally` intentionally identical |
| Original V1 and interchange fixtures | Unchanged from the inherited handoff commit |
| Whitespace check | Passed |
| Dedicated Simulator runtime | Japanese create/correct/pause/end/resume/delete and process-reopen flows passed |

The library build's App Intents metadata-skipped warning is expected: this
package contains no App Intents adapters. The read-only-save test intentionally
logs its native permission error. Neither is evidence of a successful cloud
sync. No automated UI test suite was added or run.

The device-interaction session and verification run were ended. Xcode's original
`Stally` / `My Mac` selection was restored. Mac device signing was not qualified:
the initial Mac build reported unavailable account/provisioning capabilities.
The completed consumer build and runtime evidence are for iOS Simulator.

Implementation choices follow Apple's [model configuration](https://developer.apple.com/documentation/swiftdata/modelconfiguration)
and [native synchronization guidance](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices).
The generated-schema checks and actual runtime findings above bound what was
verified; real iCloud synchronization, production schema compatibility, signed
App Group access on a physical device, and first-release feature completeness
remain open. No push, deployment, or production-schema promotion occurred.
