# Item Tracking Implementation Evidence

> September 13, 2026. Local implementation evidence, not distribution approval.
> App integration: `a8ac948`; follow-up UI correction: `54f29dc`.
> Original V1 writer: `36a00d0`.

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
the native file-import confirmation flow, and Siri/Shortcuts UI were unverified
in the initial integration run. Draft non-mutation, validation, import mode
behavior, and Intent execution have the separate code-level checks above.
The follow-up audit below records additional evidence without converting
screenshots into interaction checks.

## Follow-up Interaction and Accessibility Audit

The follow-up used a newly created iPhone 18 Pro Simulator named
`Stally Tracking Interaction Audit`, iOS 27.0, portrait, with Xcode `27A266a`.
It installed only the Debug app and launched the existing `integration` and
`timeTogether` scenarios in memory. App logs confirm preview-container creation
and startup readiness; no app fatal error was observed. No backup import,
collection replacement, account sign-in, or cloud operation was performed.

### Confirmed Defect and Bounded Correction

At the standard `large` text size in English, Edit Month displayed the selected
precision as `Year...onth`, obscuring `Year and Month`. The same synthetic Item
and launch route reproduce it. The inherited MHUI key-value layout constrained
the interactive Picker's value column.

Only the Precision Picker now opts into SwiftUI's automatic labeled-content
style. It retains the native control, strings, binding, selection, and
validation.
This follows the pinned MHUI guidance to apply key-value styling selectively and
let specialized native controls retain their own layout. No shared package,
persisted model, Operations, backup codec, or App Intent changed.

| Before: standard English size | After: same size and Item |
| --- | --- |
| ![Truncated selected precision](ui-preview-screenshots/item-tracking-interaction/edit-month-large-en.png) | ![Complete selected precision](ui-preview-screenshots/item-tracking-interaction/edit-month-large-en-after.png) |

The post-fix native build passed with zero errors. Formatter, SwiftLint and
repository boundary checks passed. This presentation-only change does not
alter the prior 143 library, 115 original-reader, or three app-adapter tests;
those suites were not rerun or counted as new evidence for the layout fix.

The full selected value is visible at `large` and `extra-extra-extra-large`.
Year Only, Japanese month precision, and the Add form's Not Set value were also
rechecked. Maximum accessibility size places the precision control below the
initial viewport, so its readability there remains a manual check.

| Retained comparison | Coverage |
| --- | --- |
| [Larger month editor](ui-preview-screenshots/item-tracking-interaction/edit-month-xxxl-en-after.png), [Japanese month editor](ui-preview-screenshots/item-tracking-interaction/edit-month-large-ja-after.png) | Complete selected precision after the fix |
| [Year editor](ui-preview-screenshots/item-tracking-interaction/edit-year-large-en-after.png), [Add form](ui-preview-screenshots/item-tracking-interaction/add-large-en-after.png) | Neighboring year/unknown states after the fix |
| [Maximum-size Add](ui-preview-screenshots/item-tracking-interaction/add-axxxxl-en.png), [maximum-size Edit](ui-preview-screenshots/item-tracking-interaction/edit-year-axxxxl-en.png) | Initial viewport only; controls below the viewport are unverified |
| [Maximum-size month detail](ui-preview-screenshots/item-tracking-interaction/month-detail-axxxxl-en.png), [Japanese year detail](ui-preview-screenshots/item-tracking-interaction/year-detail-axxxxl-ja.png) | Start and approximate elapsed values reflow |
| [Maximum-size Insights](ui-preview-screenshots/item-tracking-interaction/insights-axxxxl-en.png) | Non-Mark scope explanation reflows |
| [Dark and increased contrast](ui-preview-screenshots/item-tracking-interaction/month-detail-large-en-dark-contrast.png) | Month-detail initial viewport |

### Audited Coverage and Limits

| Capability | Result |
| --- | --- |
| Real Simulator rendering | Standard and maximum Dynamic Type captures inspected; exact month/year readings and non-Mark Insights scope wrap in the visible viewport |
| Maximum-size forms | Add/Edit controls reflow in the initial viewport; start fields fall below it, so their scrolling/reachability remains unverified |
| Dark appearance and Increase Contrast | Month detail inspected with both settings enabled; text/actions visible without overlap, with no measured contrast-ratio claim |
| Touch/keyboard workflows | Unverified: the native session failed before any tap, picker, scroll, Save/Cancel, or keyboard event |
| Accessibility hierarchy | Unverified: no hierarchy was returned by the failed interaction session or desktop fallback |
| VoiceOver operation | Unverified and unavailable on Simulator according to Apple; manual physical-device check is separate |
| Files and Shortcuts UI | Unverified: no file-import/export confirmation or system Intent UI was operated in this follow-up |
| Other device sizes/orientations | Not audited; this targeted run covers the isolated portrait iPhone only |

The native session initially timed out. A single retry after the dedicated
Simulator had fully booted still could not connect; capture/end reported that
the session did not exist. Desktop Simulator access also timed out (`-10005`)
by both display name and the discovered bundle identifier. These are environment
failures, not app failures. Standalone Xcode-native builds and official `simctl`
installation, launch, display settings, screenshots, and logs remained usable.
No UI test target or new fixture launch hook was introduced as a workaround.

The captures are actual unedited Simulator images. Initial-viewport evidence
does not establish successful scrolling, activation, focus order, or completion
of the interaction matrix below. Apart from the reproduced precision label,
no additional defect was established in the inspected coverage.

The original Xcode scheme `Stally` and destination
`Stally MHPlatform 1.13 Audit` were restored and confirmed. The dedicated
Simulator's settings were restored
to `large`, light appearance, and disabled Increase Contrast; the app and then
the dedicated Simulator were stopped. No device was erased. The full session
ledger, 18 raw screenshots, two native build logs, app runtime logs, repository
rules, and retained-image checksums are local ignored evidence under
`.build/ci/item-tracking-interaction/`. Twelve inspected comparison images are
retained above. The earlier verification artifacts remain unchanged.

## Manual Completion Steps

These are remaining checks, not completed results. Use a separate iOS 27
Simulator with no account sign-in, and the existing Debug in-memory scenarios.
Keep the original V1 fixture directory read-only. Never perform this checklist
against a normal launch, real collection, cloud container, or distribution
build.
Stopping the preview process discards its synthetic edits.

### Safe Setup

Build the Debug `Stally` scheme for a dedicated iOS 27 Simulator. Discover its
UDID, set `AUDIT_SIMULATOR_UDID` to that value, and use it in every command,
rather than `booted`. Install the resulting Debug app using Xcode or
`simctl install`, then launch:

```sh
xcrun simctl launch --terminate-running-process "$AUDIT_SIMULATOR_UDID" \
  com.muhiro12.Stally \
  --stally-preview-scenario integration \
  --stally-preview-route library
```

Verify `model_container.preview_created` in the app log and the synthetic Home,
Window Plant, and ordinary choice items in Library. Stop if either check fails.
Use the normal Library navigation for save/cancel round trips, keeping the
process alive throughout. The direct `editYear`/`editMonth` hosts are useful for
layout inspection but do not prove presentation and dismissal from Library.
Record before/after values, screenshots, and accessibility observations for each
case; do not infer completion from an enabled button.

### Interaction Matrix

| Check | Steps in the isolated in-memory app | Required observation |
| --- | --- | --- |
| Add and cancel | Open Add Item; type a unique synthetic name, disable Record Marks, select Year Only and enter `2020`; cancel. Reopen Add, repeat, and tap Add | Cancel leaves the collection unchanged and the new form at its defaults; Add creates exactly one item with year-only start and no Mark controls |
| Edit and cancel | Open Home from Library and Edit Item; change name/start/Mark policy, then Cancel. Reopen Edit, make one valid change, Save, and reopen detail/edit | Cancel preserves all original values; Save changes only the chosen fields and retains item identity, existing note/photo, and navigation |
| Precision refinement | In Home's editor change Year Only to Year and Month, then Exact Day without filling new components | No month/day is inferred; Save stays disabled until each required component is explicitly selected |
| Calendar validation | Select exact `2020-02-29`; change year to `2021`, then choose a valid day. Try an empty year and a start later than today | The invalid day is cleared; incomplete input cannot save; a future start shows the localized error without changing the Item |
| Precision reduction | From a complete exact date select Year Only, then Exact Day again; finally select Not Set and save | Removed month/day components are not restored automatically; Not Set clears only the start and elapsed reading |
| Mark eligibility | On an unmarked synthetic item disable Marks and save; inspect detail, Library, Review, and Insights. Re-enable, Mark Today, and reopen Edit | Non-Mark controls/count prompts disappear; an item with history cannot disable Marks and has an explanatory footer; existing Marks remain |
| Archive and restore | Open Archived Plant; note its exact start and elapsed days. Move Back, archive again, and reopen it from Archive | Start/elapsed stay unchanged across those actions and Mark controls remain absent; Archive changes collection visibility only |
| Foreground/time refresh | Keep the same exact-day item across local midnight, background and foreground the app, then reopen detail | Elapsed days refresh without resetting at Archive or creating a Mark; do not change the host clock to simulate this |
| Backup cancellation and v3 | Export to a local Files folder; cancel once and confirm collection values. Choose the saved v3 file, inspect Merge, change to Replace, open each confirmation and cancel | Preview and enabled action match the selected method; Cancel changes no records; Replace is visibly destructive and separately confirmed |
| Old backup and conflict | Import a disposable copy of the original v2 fixture with Replace in the synthetic container; verify four fixture items. Export a v3 copy, edit an unmarked fixture to non-Mark, and export that state. Restore the first v3 copy, add one Mark to that same fixture item, and export the marked copy. Restore the non-Mark copy, then select the marked copy | Merge reports the policy conflict and cannot apply it; Replace has its own valid preview. Cancelling keeps the non-Mark item unchanged. Confirming Replace only in this synthetic container restores the marked copy |

For the v2 case, copy
`StallyLibrary/Tests/Default/Fixtures/V1/backup-v2.stallybackup` to a disposable
local directory. If it is not reachable from Simulator Files,
serve only that directory with a loopback-only local HTTP server, download the
copy in Simulator Safari, and select it from Files Downloads. Do not sign in to
iCloud or expose the repository, original store, or private files through the
server. Stop the server after the check. Keep both synthetic v3 exports outside
the repository and never overwrite the original v2 file.

For example, from the repository root, prepare only the disposable backup copy:

```sh
AUDIT_FIXTURE_DIRECTORY="$(mktemp -d /tmp/stally-backup-ui.XXXXXX)"
cp StallyLibrary/Tests/Default/Fixtures/V1/backup-v2.stallybackup \
  "$AUDIT_FIXTURE_DIRECTORY/"
python3 -m http.server 8765 --bind 127.0.0.1 \
  --directory "$AUDIT_FIXTURE_DIRECTORY"
```

In Simulator Safari, open `http://127.0.0.1:8765/backup-v2.stallybackup` and
download it. If that port is already in use, choose another unused port for
both the server and URL. Stop this foreground server with Control-C when done.

### Accessibility and System Surfaces

Apple's [accessibility testing guidance][accessibility-testing] distinguishes
visual settings from actual assistive-technology operation. It explicitly
requires a physical device for VoiceOver; a Simulator hierarchy or screenshot
does not verify spoken output, focus navigation, or activation.

1. On the dedicated Simulator, inspect the Accessibility Inspector hierarchy
   for Add/Edit and detail. Confirm localized names, roles, and current values
   for Record Marks, Precision, Year, Month, Day, Cancel, Add/Save, Edit Item,
   and the start/elapsed rows. Check that disabled Save and the history-locked
   toggle expose their disabled state. Inspect both English and Japanese.
2. Repeat the interaction matrix at the largest accessibility text size. Scroll
   every form and detail section; open the precision/month/day menus and
   keyboard. Verify that values, validation text, photo controls, and toolbar
   actions remain readable and reachable without overlap. Check light/dark
   appearance and Increase Contrast. An initial viewport alone cannot pass this.
3. For actual VoiceOver, use a separately authorized isolated physical device
   with synthetic data and no cloud writes. Enable VoiceOver in Settings >
   Accessibility, then navigate the form and detail using next/previous focus
   and activation gestures. Confirm label/value/role, focus order, Save/Cancel
   completion, validation announcements, and absence of Mark actions on a
   non-Mark item. Record spoken output as well as the result. This device step
   is outside the current Simulator-only task.
4. For Shortcuts/Siri UI, first establish that the running Debug app and its
   dependency container remain the same in-memory session. If the system
   cold-launches without preview arguments, stop; do not fall back to a normal
   persistent/cloud launch. In a supported session, inspect Mark Today choices,
   save a shortcut for a never-marked item, then disable its Mark policy in the
   app and run that saved shortcut. Expect a localized refusal and no history
   mutation. Re-enable and check Mark/dedup and app-side Undo. Generic entity
   identity and hidden Open/Undo Intents already have code-level evidence;
   hidden actions are not expected to appear in the new-action browser.

Stop the audit app and restore Simulator accessibility settings and the original
Xcode scheme/destination after manual verification. Do not erase other devices.

[accessibility-testing]: https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app

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
