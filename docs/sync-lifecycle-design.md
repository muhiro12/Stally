# Synchronization and Data Lifetime

## Status

October 25, 2026 engineering recommendation for the five-model redesign.
This is not an accepted storage-location change or a production implementation.
Apple documentation, an attributed Apple engineer response, sample inspection,
and isolated local persistence probes support different parts of this review.
No real iCloud account transition or two-device CloudKit experiment was run.

The important correction is that an app-managed local library and the local
replica of an iCloud library do not have the same lifetime. The earlier intent
that Stally must not arbitrarily delete records remains valid; it cannot be
expanded into a guarantee that Apple's account-scoped replica survives sign-out.

## Platform Evidence

- [SwiftData synchronization][swiftdata-sync] uses NSPersistentCloudKitContainer.
  Relationship changes are not atomic, uniqueness is unsupported, and delivery
  order is not determined by the application's local save order.
- [TN3164][tn3164] describes system-controlled scheduling, automatic recovery
  from throttling, and conflicts caused by multiple mirroring containers for
  one store. There is no app-controlled synchronization timing API in that stack.
- [WWDC19 session 202][wwdc19] describes native last-writer-wins conflict
  resolution and independent child inserts as a way to avoid collisions on a
  single scalar. It does not promise preservation of both competing values,
  human edit-time ordering, or Stally-specific invariants.
- In [forum thread 811294][account-response], an Apple Frameworks Engineer
  confirms the reported removal of local mirrored data on sign-out/system
  iCloud disablement as intended behavior, including the reported unsent-change
  case. The engineer explains that an account transition generally prevents a
  final upload. The iOS 18 version attribution and SwiftData reproduction are
  the questioner's evidence; this is not an independently reproduced iOS 27
  result. It is sufficient reason not to promise unconditional local retention.
- [CKAccountChanged][account-change] and [accountStatus][account-status] provide
  account-availability signals. Availability is not account identity, upload
  completion, or proof that all relationships have arrived. Temporary
  unavailability must not trigger deletion or replacement of the store.
- [ModelConfiguration][configuration] provides explicit store URLs and `.none`
  or `.private` CloudKit configuration. Those options alone do not constitute
  a safe conversion or account-migration protocol.

## Storage Alternatives

| Approach | Benefit | Cost and recommendation |
| --- | --- | --- |
| One permanently cloud-backed library | Smallest native configuration; account lifecycle belongs to the framework | Good if the product needs only an iCloud library. It cannot also promise an account-independent local library. |
| Reopen the same store with `.none` or `.private` | Short configuration code; resembles the current app | Requires qualification of re-enablement, account changes while disabled, and unsent history. A startup toggle is not an unconditional keep-on-device contract. Do not select as the default lifetime design without that evidence. |
| Separate local and iCloud libraries using the same schema | Clear ownership boundary through ordinary store configuration | Recommended if Stally retains both local-only use and optional iCloud use. Requires explicit selection and reviewed copying, with two potentially diverging collections. |
| Local master plus custom sync or a continuously maintained second copy | Could support a stronger app-owned retention policy | Adds conflict, account-isolation, deletion, and recovery machinery. Not recommended for 1.0. |

The recommended third option is a substantive proposal, not a claim that Apple
requires two libraries. It trades a small explicit storage/transfer boundary
for avoiding a hidden promise that account-scoped data is permanently local.
If maintaining two independent collections is unacceptable product complexity,
prefer the first option and disclose its account lifetime rather than building
a custom synchronization engine to conceal that difference.

## Recommended Library Contract

Use one schema in two independently located stores, with no cross-store
relationships. The local library always uses `.none`; the iCloud library always
uses the specified private container. Present one active library, not a union of
both. Do not instantiate two active mirroring containers for the same URL.

Selecting a library is separate from copying records. A setting change does not
move records, erase a source, or continually synchronize the two libraries.
When entering iCloud use, offer reviewed copying of local records through the
identity-preserving import rules. Reuse value conversion/application logic,
not live model instances or SQLite-file copying. Keep the source until the user
explicitly deletes it. Saving the destination is a local persistence result,
not confirmation that the cloud has received the copy.

When leaving iCloud use, offer a reviewed copy of the records currently
available into the local library, or export, before switching. State that this
cannot capture records or image bytes not yet received from other devices.
Never call a partial export or local save a verified full cloud backup. A
missing required image/reference must be reported or represented by the agreed
omission contract, not silently omitted while claiming complete preservation.

Copying back into a library that already has those UUIDs uses ordinary conflict
review. The same UUID may exist in both independent libraries after copying;
do not flatten their values or guess a winner. Later edits can diverge.
Deep links, App Entities, cached selections, and saved UI state must resolve a
library as well as a UUID when both libraries are supported. Concrete route
encoding belongs to the subsequent public-reference contract.

For 1.0, prefer library selection taking effect on the next launch over hot
replacement of the app's full container graph. Clearly show the active and
requested library; do not claim that flipping a setting immediately stops
network activity. Switching must not implicitly save or discard an editor.
All entrypoints must resolve the same selected library; stale drafts or actions
from a previous library/session must not write to the newly selected one.
Implementation must account for all scenes and background entrypoints before
offering a live switch later.

This proposal adds storage selection outside the domain models, not a
`syncStatus`, `accountID`, or shadow ownership field to every record. Exact
preference keys and store paths require deliberate selection before integration.

## Lifecycle Behavior

| Event | Recommended behavior |
| --- | --- |
| First local use | Open the independent local store. No automatic upload or cloud-store opening is implied. |
| Begin iCloud use | Check account availability, explain the destination, review any copy, and activate the cloud library explicitly. Do not treat an initially empty replica as proof of an empty cloud database. |
| Network unavailable or cloud throttled | Keep the current library/configuration. Permit ordinary offline changes to the available graph; native mirroring retries. Do not switch stores or perform app-owned clearing. |
| Cloud account temporarily unavailable or undetermined | Preserve the store. Recheck account status and avoid starting transfers that require a verified destination; do not infer sign-out. |
| System iCloud disablement, sign-out, or account switch | Respect native account isolation. Invalidate open import reviews and drafts tied to the prior account session; do not replay them into another account. Native mirrored local data may be removed. |
| Return to the same account | Let native mirroring repopulate what exists in that account. Do not promise recovery of records never uploaded or already deleted. |
| Enter a different account | Do not automatically import the previous account's values, a saved draft, or the independent local library. Any cross-account transfer is an explicit user-reviewed import. |
| Stop using the cloud library in Stally | Offer export/reviewed copy first, then explicit local-library selection. This is not cloud deletion and is not the same operation as disabling iCloud in system Settings. |
| Subscription expiry or entitlement uncertainty | Do not erase records, switch libraries, or rebuild the store as a side effect. Keep reading/export available. Any restriction on new use requires a separate product decision. |
| Container initialization failure | Show a recoverable persistence failure and preserve the source. Do not silently substitute an empty in-memory store or downgrade a mirrored store to local mode. |

Account notifications are reactive; they cannot provide a universal final-save
or export opportunity before a system change. On notification, discard stale
review authority, refresh account state and displayed model references, and
require a new session/review where appropriate. These checks reduce stale
application actions; they do not create an atomic barrier against account changes.
Do not suppress native account cleanup to retain prior-account records.

The phrase "protect facts and user intent" means Stally does not invent,
normalize, or intentionally discard facts without the selected operation. It
does not mean retaining every overwritten edit or surviving every external
account action. A stronger promise needs a separate history/backup design.

## Concurrent Changes

| Situation | Stally behavior and limit |
| --- | --- |
| Two independent Mark additions on one day | Both are valid occurrences with distinct UUIDs. Do not deduplicate by day or infer they describe the same real-world use. |
| Two edits to the same name, note, Mark date, or Period field | Accept native conflict resolution. Do not add a last-modified timestamp to invent an app-level winner. Both edits are not guaranteed to survive. |
| Another change arrives while an editor is open | Re-fetch affected values before committing; if its baseline changed, offer a fresh review instead of applying a full stale snapshot. This is local stale-edit protection, not a distributed compare-and-swap. |
| Two devices resume an ended Item | Each may validly create an ongoing Period offline. If both arrive, retain both identities and expose the ambiguity. No lowest-UUID winner, automatic end, or automatic deletion. |
| End and correction/reopen race | Validate the resulting combination on read as well as before local writes. An ongoing Period with an end value needs review; do not clear the end or flip the flag automatically. |
| Item deletion races with an edit or new child | Use native deletion and the selected local cascade. Do not promise edit-wins, delete-wins for every graph arrival, or preservation of the competing edit. Do not recreate the Item from a stale draft. |
| Child or image arrives before its relationship/content | Retain what arrived; avoid force-unwrapping and automatic orphan cleanup. Missing data is not proof of deletion or completion. |
| Same-name Tags arrive | Keep separate UUID identities; the selected tag contract still applies. |
| Two imports independently create the same UUID on separate devices | UUID attributes do not enforce CloudKit uniqueness. Retain ambiguous records for explicit handling; do not advertise globally idempotent import. |

For ambiguous Period history, keep Item editing, photos, and Mark capture
available. Block ordinary Resume and other operations that require selecting a
unique current period; withhold a definitive active-duration total. Allow
explicit review/correction/deletion of the affected periods using the existing
operations, with a refreshed preview and validation. Choosing to remove an
accidental duplicate is different from automatically collapsing it. Unresolved
partial graph arrival does not become an error eligible for deletion after a
fixed timeout.

Permanent deletion still means deletion, including propagation to the account's
other devices. Archive is the reversible way to remove an Item from ordinary
presentation while keeping its history. Do not introduce a trash service,
tombstones, an edit log, or background orphan repair in this proposal.

## Apple Sample Comparison

The cached Apple sample [Sharing Core Data objects between iCloud users][sample]
was inspected through `apple-sample-code-advisor`: its
`PersistenceController+Deduplicate.swift` describes loss of late-arriving
relationships when a duplicate Tag is deleted immediately. Its
`TaggingView.swift` handles a photo being deleted remotely. These support
incomplete-graph tolerance and stale-target handling, not adoption of automatic
name deduplication or a SwiftData synchronization-completion detector.

The cache was inspected read-only; no download, refresh, or cache mutation was
performed. The inspected sample has Xcode 15.3-era requirements and is not
proof of current iOS 27 account-switch behavior. Its custom history queue,
deduplication lifecycle, and delayed deletion are not copied into Stally.
Explicit Tag consolidation still needs a subsequent decision; source deletion
cannot be justified merely by the relationships currently visible locally.

## Current Implementation Gap

The current `StallyModelContainerFactory` selects `.none` or `.private` with
otherwise implicit store configuration. `SettingsICloudSection` applies the
toggle on next launch. `StallyApp` falls back from cloud initialization to local
configuration, and then to an in-memory container on further failure.
The recommendation above changes these behaviors and must not be described as
already implemented. The subscription-state modifier currently updates the
subscription preference, not the CloudKit configuration.

No five-model attribute change is currently justified by this review. The new
proposal affects container ownership, store selection, stale-session handling,
and public route scope. Tag consolidation may still require a separately
justified schema change.

## Verification and Release Boundaries

The standalone probe uses the complete five-model illustration, including
external image data and thumbnailData, in disposable stores outside Git.
It uses distinct explicit URLs with `.none` for both executing containers.
The `.private` configuration is inspected as a value only; it is never opened.
The second store is a local replica fixture, not a working CloudKit replica.

Five separate processes cover seed, synthetic arrivals, review, deletion, and
reopen verification. They check independent libraries (including equal UUIDs),
same-day Marks, external binary reads, duplicate ongoing periods, inconsistent
period fields, unresolved children, explicit correction, stale-draft detection,
and cascade/nullify behavior. Synthetic arrivals exercise possible input
shapes, not Apple's transport or actual concurrent merge policy.

Observed results with Xcode 27.2 / Swift 6.4.2:

| Stage | macOS 27.2 checks | iOS 27.2 Simulator checks |
| --- | ---: | ---: |
| Seed and explicit configuration | 5 | 5 |
| Reopen and synthetic arrivals | 9 | 9 |
| Review and explicit correction | 10 | 10 |
| Stale draft and deletion | 7 | 7 |
| Final independent reopen | 11 | 11 |
| Total | 42 | 42 |

All ten final stage processes exited successfully. Runtime logs had no warning,
error, or fatal diagnostics. The first standalone compilation was blocked by
the sandbox's compiler-cache restriction; approved execution resolved it.
An initial iOS compilation inherited a macOS SDKROOT warning; recompilation
with the explicit iPhoneSimulator27.2 SDKROOT completed without diagnostics
before the iOS runs. A newly created iPhone 18 Pro Simulator without an iCloud
account was used, without disturbing other apps' running simulators. No app build or UI
verification is claimed. The temporary probe source and logs remain outside Git.

Before implementation can claim qualified cloud behavior, use disposable test
accounts and two signed devices on supported OS versions to check:

1. Local-to-cloud and cloud-to-local reviewed copies, including media and
   interrupted saves; preserve the source and verify destination reopen.
2. Independent offline Marks, simultaneous resumes, end/reopen races, same-field
   edits, and distinct imports carrying equal UUIDs; inspect both devices.
3. Delete versus concurrent edit/child creation, partial relationship arrival,
   and explicit Tag source removal; do not infer a winner from a local probe.
4. System per-app iCloud disablement, sign-out, same-account return, account
   switch, and unsent offline changes; verify native privacy behavior and
   absence of app-driven cross-account replay.
5. Network outage, quota/throttling, account unavailability, initialization
   failure, and entitlement changes without automatic source replacement.

The owner account, existing cloud records, entitlements, and production schema
were not changed for this investigation. Cloud qualification remains open;
local verification is not grounds to label this lifecycle shipping-ready.

[swiftdata-sync]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
[tn3164]: https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer
[wwdc19]: https://developer.apple.com/videos/play/wwdc2019/202/
[account-response]: https://developer.apple.com/forums/thread/811294
[account-change]: https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/ckaccountchanged
[account-status]: https://developer.apple.com/documentation/cloudkit/ckcontainer/accountstatus(completionhandler:)
[configuration]: https://developer.apple.com/documentation/swiftdata/modelconfiguration
[sample]: https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users
