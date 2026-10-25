# Synchronization and Data Lifetime

## Status

On October 25, 2026, the owner accepted the native-platform, proportionate-cost,
and practical-recovery policy for the five-model redesign.
The owner clarified that native platform behavior must be adopted consistently,
without app-owned compensation for account lifecycle. The earlier two-library
recommendation is withdrawn. This remains design work, not an implementation.
Acceptance covers that policy, not every lifecycle interaction or recovery
mechanism discussed below. Initial sync settings, entitlement behavior, and
explicit Tag consolidation still need their own concrete decisions.
Apple documentation, an attributed Apple engineer response, sample inspection,
and isolated local persistence probes support different parts of this review.
No real iCloud account transition or two-device CloudKit experiment was run.

The important correction is that an app-managed local library and the local
replica of an iCloud library do not have the same lifetime. The earlier intent
that Stally must not arbitrarily delete records remains valid; it cannot be
expanded into a guarantee that Apple's account-scoped replica survives sign-out.

## Proportionate Design and Recovery

The accepted decision threshold is that ordinary remote-service limitations
are accepted operating conditions, not separate product problems that each
require a mitigation, warning flow, or architecture decision. Evaluate additional
work by user impact, recovery value, implementation cost, and maintenance cost.
The existence of a worst case alone does not justify preventing it at any cost.

- Normal delivery delay, offline operation, and finite synchronization windows
  use the native baseline. Do not keep reopening them as unresolved Stally
  contracts or add infrastructure solely to eliminate them.
- Account cleanup is technically distinct from an unfinished network request,
  but neither requires Stally to guarantee survival of every user/system action.
  Respect expected platform behavior and communicate consequences where the
  actual operation warrants it; do not surround ordinary use with warnings.
- Concurrent changes justify strict serialization or version-history machinery
  only if Stally's concrete needs warrant that cost. Use native resolution and
  make surviving ambiguous domain records understandable and correctable.
- App-created destructive operations deserve focused scrutiny. Define their
  scope, preview material effects, preserve unrelated data, and handle failed
  saves. Do not knowingly discard a relationship during Tag consolidation and
  attribute the loss to generic synchronization uncertainty.

Recovery should start with capabilities already selected: editing dates and
counts, reviewing/correcting periods, archiving instead of permanently deleting
an Item when appropriate, and restoring available facts through explicit
export/import. Recovery from an export covers only what that file contains;
an overwritten value with no surviving copy cannot be reconstructed. Do not
turn this principle into a promise of universal recovery.

For each high-impact app operation, compare a narrow recovery mechanism with
reducing the operation's scope. Immediate native Undo, a retained source, or an
export opportunity can be candidates where useful; none is a blanket new 1.0
requirement. Local Undo is not cross-device rollback. Automatic backups,
permanent tombstones, and a general edit log are not selected by this principle.

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
| One cloud-backed library following native account lifecycle | Standard mirroring and account isolation remain one coherent contract | Recommended baseline for iCloud use; no promise of account-independent retention. |
| Reopen the same store with `.none` or `.private` | Short configuration code; resembles the current app | Requires a concrete product need and qualification of re-enablement/account transitions. Do not inherit this merely because a toggle already exists. |
| Separate local and iCloud libraries using the same schema | Could support independently requested local collections | Previous recommendation withdrawn: independent retention was not a requirement. Selection, copying, divergent collections, and route scope add unjustified responsibility here. |
| Local master plus custom sync or a continuously maintained second copy | Could support stronger app-owned retention | Not selected; it compensates for platform behavior beyond Stally's stated requirements. |

## Recommended Library Contract

Use a single logical collection with native SwiftData/CloudKit mirroring for
its iCloud use. Accept its account isolation, delayed delivery, and conflict
behavior consistently. Do not introduce another library, automatic export,
shadow copy, or cross-account replay to counteract those behaviors. Explicit
export/import remains a user-directed feature, not required sync plumbing.

Do not silently reinterpret an unavailable account as a request to convert the
mirrored store into an account-independent local collection. Similarly, do not
build app-controlled retention while attributing the resulting account mixing,
duplicate records, or loss to Apple. Stally owns the consequences of its own
configuration and mutations.

System iCloud controls are the proposed default surface for system-level
sync disablement and account changes. The existing app toggle is not a settled
contract: retain an app-level control only for a concrete requirement, with
verified native configuration behavior and accurate consequences. This review
neither removes optional iCloud use as a product choice nor settles its initial
setting or paid entitlement. If those choices need a different lifecycle,
review that specific requirement before adding storage infrastructure.

Stally remains responsible for correct schema/configuration, explicit local
saves and errors, safe editor lifetimes, handling missing/deleted references,
and honest descriptions of what was saved or exported. All entrypoints must
use a consistent configuration. Do not instantiate competing mirroring
containers for one store or revive deleted records from stale drafts.

Reading an inconsistent Period and asking the user to correct it is ordinary
domain validation. It does not replace CloudKit's conflict resolution or
recover overwritten edits. Account-aware invalidation of a stale review also
protects Stally's own operation, rather than intercepting native account cleanup.

No second-library selector, library identifier in routes, or model-level
`syncStatus`/`accountID` is introduced by this recommendation. Keep the existing
UUID identity design. Concrete store integration and supported configuration
transitions still require qualification.

## Lifecycle Behavior

| Event | Recommended behavior |
| --- | --- |
| App launch | Open the deliberately configured store. Account unavailability must not select a second collection or silently change its lifetime. |
| Begin iCloud use | Use native mirroring under the selected product configuration. Qualify any transition from existing local data before offering it; do not infer an empty cloud database from an initially empty replica. |
| Network unavailable or cloud throttled | Keep the current library/configuration. Permit ordinary offline changes to the available graph; native mirroring retries. Do not switch stores or perform app-owned clearing. |
| Cloud account temporarily unavailable or undetermined | Preserve the store. Recheck account status and avoid account-dependent operations that require a verified destination; do not infer sign-out. |
| System iCloud disablement, sign-out, or account switch | Respect native account isolation. Invalidate open import reviews and drafts tied to the prior account session; do not replay them into another account. Native mirrored local data may be removed. |
| Return to the same account | Let native mirroring repopulate what exists in that account. Do not promise recovery of records never uploaded or already deleted. |
| Enter a different account | Do not automatically import the previous account's values or a saved draft. Any cross-account transfer is an explicit user-reviewed import. |
| Disable iCloud through system Settings | Follow native behavior, including its account-lifetime consequences. Do not implement an automatic local-copy escape path. Explicit export remains available beforehand while data is accessible. |
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
proposal affects consistent container ownership, stale-session handling, and
accurate lifecycle presentation. The withdrawn two-library design no longer
justifies adding library scope to public routes. Tag consolidation may still require a separately
justified schema change.

## Verification and Release Boundaries

The probe below was run while comparing the earlier alternatives. Its two-store
checks remain evidence for that alternative only, not a requirement or proof of
the revised native-lifecycle recommendation. No new runtime test was run merely
for this policy correction.

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

Use disposable test accounts and signed devices for representative integration
checks before claiming observed cloud behavior. The cases below are an evidence
inventory, not a requirement to exhaust every interleaving or reproduce every
platform failure. Prioritize actual Stally mutations, selected configuration
transitions, and recovery behavior. Broaden testing for concrete failures or
requirements, not simply because another theoretical worst case exists:

1. Initial native mirroring and any explicitly selected local-to-cloud
   configuration transition, including existing records and media. Verify
   actual uploads and independent downloads; an opened container is insufficient.
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
