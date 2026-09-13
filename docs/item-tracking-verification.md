# Item Tracking Implementation Evidence

> September 13, 2026. Local implementation evidence, not distribution approval.
> App implementation: `a8ac948`. Original V1 writer: `36a00d0`.

## Implemented Contract

The accepted [design](item-start-and-elapsed-time-proposal.md) is implemented
through StallyLibrary Operations, native forms and detail screens, Review,
Insights reports, Backup Center, and existing App Intents. Fluel was untouched.

- An Item retains its UUID and Mark relationship. `recordsMarks` defaults to
  true; an optional canonical `YYYY`, `YYYY-MM`, or `YYYY-MM-DD` start defaults
  to unknown. Existing timestamps and Marks never supply an inferred start.
- Elapsed time is a calendar reading, with zero on the start day. Approximate
  starts retain coarse ranges. Archive never pauses or resets the reading.
- Non-Mark items stay in Library/Archive and generic entity queries. Mark,
  Undo, action suggestions, all Review lanes, and choice metrics enforce the
  recording policy. Note/photo coverage still includes the whole scope.
- Disabling Marks requires empty history. Inconsistent history is retained and
  surfaced; explicitly enabling Marks repairs it without deleting history.
- New exports use backup v3. The strict reader accepts v3 and the frozen v2
  adapter. Matching IDs retain local details on merge, including unknown
  starts. Incoming Marks for a local non-Mark item reject the entire merge.
  A valid replacement has a separate preview and the existing confirmation.

No production CloudKit deployment, real-data migration/reset, purchase,
signing change, push, or publication was performed.

## Persistence and Backup Evidence

The original writer produced the checked-in
[V1 fixtures](../StallyLibrary/Tests/Default/Fixtures/V1/README.md) before any
model changes. They contain an actual closed disk store, its external photo
storage, an empty store, a v2 backup, and independent photo/link expectations.
All retained SHA-256 checksums still match.

The frozen V1 entity hashes match the original store metadata. V2 adds two
scalar properties through a lightweight migration; the old definitions remain
frozen. Migration and repeated reopen compare Item/Mark UUIDs, day keys,
timestamps, names, raw categories, notes, archive state, relationship ownership,
and the original 1,255,132-byte external JPEG. Saved Item links still resolve.
New tracking values also survive two disk reopens.

A deliberately read-only migration fails as expected and leaves the independent
original fixture intact. The associated CoreData open errors belong to this
negative test. This is not a simulated mid-migration power-loss recovery test.
V2-to-V1 downgrade is unsupported: an old binary can recover the pre-conversion
V1 copy/v2 backup, while post-conversion recovery needs the new binary and v3.

| Verification layer | Result and scope |
| --- | --- |
| Current library | 143 tests in 30 suites passed using `test_stally_library.sh` |
| Original reader | Original `36a00d0` source plus one isolated probe: 115 tests in 26 suites passed |
| Old-reader refusal | A v3 payload is rejected before merge and replacement; original records, photo, Marks, and pending-change state remain identical |
| App adapter probe | 3 tests passed using copies of current app source and explicit in-memory dependency injection |
| Static checks | Standard formatter, repository SwiftLint/boundary checks, and `git diff --check` passed |
| App build | Xcode-native build passed; final official CLI build also passed after native transport closed |
| App Intents | App metadata extraction passed; UUID/name queries, filtered suggestions, non-Mark errors, and eligible Mark/dedup/Undo passed in the adapter probe |
| Localization | Six catalogs audited for en/ja; zero incomplete entries and valid placeholders |

The library suite includes malformed/partial dates, leap/month boundaries,
timezone/DST/skipped-day readings, future stored dates, unchanged-photo edits,
save rollback, Archive continuity, stale Review batches, every choice metric,
unavailable-date scope, localized reports, v2/v3 restore and merge, strict v3
keys, non-lossy v2 encoding, and existing size/photo/duplicate protections.

The adapter probe verifies that year/month refinement requires explicit missing
components and that discarding a draft leaves the Item and context unchanged.
Malformed stored starts require explicit draft repair. Its dependency values
are manually injected as supported by App Intents; it does not simulate Siri
or the Shortcuts application's runtime injection and presentation.

The original-reader and app-adapter probes run in disposable package copies;
no app test target or production verification hook was added. Their source,
source hashes, logs, and audit results are retained locally under
`.build/ci/item-tracking/`. The normal library regression tests and original
fixtures remain part of the repository test target.

The existing `Actions` catalog key became stale during Xcode extraction and is
retained. `Stally`/`CFBundleName` source-copy notices are intentional names.
No unrelated catalog keys were removed or translations changed.

## Screen Comparison

The before capture is the original Add Item Preview from the V1 baseline.
After captures are actual iPhone 18 Pro Simulator screenshots on iOS 27.0,
using Xcode `27A266a` and synthetic in-memory launch data. Images are unedited.
The before form is presented directly; the after Add form is its normal sheet.

| Before | After |
| --- | --- |
| ![Original Add Item form](ui-preview-screenshots/item-tracking/add-before.png) | ![Add Item with tracking controls](ui-preview-screenshots/item-tracking/add-after.png) |

The existing Name, Category, Note, and Photo fields remain. The new controls
start with Marks enabled and no start date. Year/month editing keeps only the
known components, and the year retains a visible field label.

| Month precision | Archived exact day |
| --- | --- |
| ![Approximate elapsed months](ui-preview-screenshots/item-tracking/month-detail.png) | ![Archived item with continuing elapsed days](ui-preview-screenshots/item-tracking/archive-detail.png) |

At the captured date, `2020` reads approximately 5–6 years, `2020-09` reads
approximately 71–72 months, and the archived `2020-09-13` reads 2,191 days.
Detail omits Mark/Undo/Adjust for non-Mark items. Archive keeps Move Back.
The duplicate time heading found during inspection was removed.

| Surface | Observed result | Capture |
| --- | --- | --- |
| Mixed Library | Non-Mark rows omit first-Mark/count/badge language; ordinary rows retain it | [Library](ui-preview-screenshots/item-tracking/library-mixed.png) |
| Year detail | Year-only start and approximate whole-year range | [Year](ui-preview-screenshots/item-tracking/year-detail.png) |
| English month detail | Localized start and elapsed range with the same non-Mark controls | [English detail](ui-preview-screenshots/item-tracking/month-detail-en.png) |
| Year editor | Year control without an invented month/day | [Year editor](ui-preview-screenshots/item-tracking/edit-year.png) |
| Month editor | Year and month controls without an invented day | [Month editor](ui-preview-screenshots/item-tracking/edit-month.png) |
| Non-Mark Insights | Explicit empty choice scope; no first-Mark invitation in the generated recommendations | [Insights](ui-preview-screenshots/item-tracking/insights-nonmark.png) |
| Mixed Review | Only the ordinary choice item appears in Needs First Mark | [Review](ui-preview-screenshots/item-tracking/review-mixed.png) |

Six new screen-level Preview definitions have equivalent runtime captures.
Direct new Preview coverage is 0/6: the first attempted definition timed out in
`PreviewsFoundationHost`; the other five were not retried after that failure.
The existing before Preview succeeded. Runtime capture uses the actual screens
and existing in-memory scenarios; detail/edit fallback hosts receive the same
seeded Items as the screen-level Previews.

Native device sessions failed with contradictory missing/occupied-session
results on the original Simulator, then a connection failure on the fallback
Simulator. Later the Xcode transport closed. Official `xcodebuild` and `simctl`
provided the final build, launched-screen captures, and runtime logs. Early
blank/transition frames were not accepted as successful screen evidence.
The app logs show preview-container creation and startup readiness, with no
observed fatal app/persistence error. Simulator service and StoreKit diagnostics
are retained separately from the deliberate migration-refusal test output.

The original Stally scheme and Simulator destination were restored and confirmed
before native transport closed. A final native re-query was unavailable; later
CLI checks did not switch Xcode's selection. CUA access to Simulator also timed
out. A link-opening confirmation interrupted one capture; the dedicated
Simulator was restarted without erasing data before obtaining the clean frame.

Touch-based Cancel/Save, picker interaction, VoiceOver, Dynamic Type variation,
the native file-import confirmation flow, and Siri/Shortcuts UI remain
unverified in this run. Draft non-mutation, validation, import mode behavior,
and Intent execution are covered by the separate code-level checks above.
Screenshots do not substitute for those interaction checks.

## Separate Pre-Distribution Checks

External state was not re-queried for this integration. The last recorded
gates remain in [release-readiness.md](release-readiness.md):

| Required decision or evidence | Concrete alternatives / next check |
| --- | --- |
| Ads and subscription offer | Use Stally-owned production AdMob/product settings, or choose an ads-disabled release and resolve the ad-removal offer accordingly |
| Privacy and Support | Approve and publish the intended URLs/contact, or supply existing approved destinations; verify links and add Support navigation |
| Signing and distribution | Supply the distribution certificate/private key and provisioning profile; export and inspect the shipping build |
| Devices and CloudKit | Select synthetic test accounts/devices/environment before cloud writes; verify upgraded-device sync, offline/concurrent edits, repair, relaunch, and schema promotion |
| Store/runtime acceptance | Verify purchase/restore and the distributed build; complete the interaction/accessibility checks listed above |

Mixed old/new CloudKit writers and production schema promotion remain outside
the verified rollout. These gates do not reopen the accepted Item/Mark/Archive
semantics or require a Fluel migration.
