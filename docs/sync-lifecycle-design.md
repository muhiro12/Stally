# Synchronization and Data Lifetime

## First-release Product Policy

The November 8 decision supersedes the earlier free-iCloud policy. Release 1.0
has no advertising. The monthly subscription provides Stally library sync
through private iCloud. A subsequent minor release is intended to introduce
advertising and extend the same subscription with ad removal. That later
advertising behavior is not enabled or advertised as a current paid benefit.

One logical collection uses the same explicit App Group store URL whether
mirroring is enabled or disabled. There is no second library, store copy,
automatic export or cloud-open fallback. Errors surface without replacing or
erasing the store. Local creation, editing, reading and export remain available
without a subscription.

## Subscription and Sync Selection

- StoreKit, through MHPlatform, supplies subscription state. The app mirrors
  resolved active/inactive state in an App Group preference. Unknown preserves
  the last resolved state; the mirror is startup evidence, not purchase authority.
- The separate Use iCloud preference defaults to off. A recognized subscription
  permits enabling it. Purchase or restore does not silently enable upload.
- A resolved inactive subscription clears the entitlement mirror but preserves
  the person's sync selection. The next process disables mirroring while access
  is inactive. After renewal is resolved as active, the next process resumes
  mirroring only if the saved selection is on. A first purchase does not opt in.
- The person can turn a retained selection off even while access is inactive;
  enabling sync requires recognized subscription access. Explicit off remains
  off after renewal. No additional preference or library migration is required.
- The app opens the store synchronously for UI and App Intent dependencies using
  the last resolved entitlement and saved selection. Native StoreKit observation
  also starts for a process launched by an App Intent without a scene.
- The selected mirroring configuration is fixed for that process. Changes take
  effect on the next app launch, so a purchase, cancellation or setting change
  does not replace active model contexts or discard drafts. Returning from the
  background alone does not reopen the store. Settings distinguishes the current
  session's configuration from the requested selection.
- Consequently, a session already mirroring can continue until it ends even
  after an inactive entitlement is observed. The next process uses the retained
  selection together with the last resolved entitlement. Offline/unknown
  evidence does not erase either preference, erase data, or force a store reset.
  This is a bounded session policy, not instantaneous revocation.

Settings describes the saved choice separately from the current session's
enabled/disabled configuration. When the next-launch decision differs, it gives
direction-specific guidance and explains that background resume does not apply
the change. A retained ON without access has its own subscription explanation,
even when the current session is already local and no configuration change is
pending. These messages do not claim synchronization has completed or guarantee
data retention under native account changes.

A new entitlement result received after startup changes only a subsequent
launch's decision. Purchase, restore, or expiry recognition can therefore require
a further launch after that result is saved. Opening existing records does not
wait for a network subscription check.

The fixed-per-process configuration deliberately avoids two simultaneous
mirroring containers and scene-dependent App Intent initialization. Immediate
switching would need a separately qualified context/draft handoff; it is not a
prerequisite for this first implementation. No billing state is stored on Items
or included in portable files.

The November 14 review adopts the saved-choice, access, and session distinction
from [Incomes' assessment][incomes-assessment]. No live replacement, manual
Apply now action, or process-termination action is selected. Reconsidering live
switching requires an app-wide operation drain and a supported old-sync-stack
handoff, including failure recovery; waiting for a form or saving a context alone
does not establish those prerequisites. Account-transition invalidation remains
independent of subscription and preference changes.

## Native Account Lifetime

Stally adopts native account isolation, delayed delivery and conflict behavior.
An unavailable account does not trigger a new local store. The app does not
maintain a shadow copy or replay one account's collection into another.
Turning off app sync or losing a subscription does not issue app-owned deletes.
This does not guarantee that Apple's mirrored replica survives system sign-out
or system-level iCloud disablement, including changes not yet uploaded.

When native CloudKit signals an account transition, the app invalidates old
write sessions and import reviews. Mutation checks run after asynchronous update
checks immediately before save. Missing or ambiguous identities fail visibly;
CloudKit delivery is not an atomic transaction for the whole graph.

Ordinary recovery uses editing, correction, archive and reviewed export/import.
An export restores only facts it contains. No automatic backups, permanent
change log, account-independent retention or distributed exactly-once engine is
selected. Independent same-day Marks remain valid distinct occurrences.

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

## Release Qualification

The setting and entitlement wiring is implemented. Library tests cover saved
ON/OFF across lapse and renewal, preference reload, unresolved access, explicit
OFF during a lapse, and first purchase without opt-in. Local integration tests
keep a pending draft and import review valid through access and preference
changes, while account invalidation still rejects stale writers. Changing
`cloudKitDatabase` alone is not proof of safe device/account transitions.
Before distribution, qualify local-to-cloud enablement on the same
store, cloud-to-local disablement, renewal, expired/revoked purchases, offline
startup, StoreKit restore and background Intent startup. Include photo bytes,
existing records and pending drafts, then verify independent device convergence.

Confirm that current-session mirroring persists until relaunch and that the next
process uses the intended setting. Native account sign-out and system iCloud
switches require their own evidence; local disk probes do not establish them.
Validate the production CloudKit schema, subscription product, public disclosures
and submitted distribution artifact. See [release readiness](release-readiness.md).

[swiftdata-sync]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
[tn3164]: https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer
[wwdc19]: https://developer.apple.com/videos/play/wwdc2019/202/
[account-response]: https://developer.apple.com/forums/thread/811294
[account-change]: https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/ckaccountchanged
[account-status]: https://developer.apple.com/documentation/cloudkit/ckcontainer/accountstatus(completionhandler:)
[configuration]: https://developer.apple.com/documentation/swiftdata/modelconfiguration
[sample]: https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users
[incomes-assessment]: https://github.com/muhiro12/Incomes/blob/cc822199caf391f02e33525d23b36e1d8508fb99/Designs/Architecture/subscription-and-icloud.md
