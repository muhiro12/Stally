# Optional Item Starts and Elapsed Time

> Status: Accepted and implemented locally, September 13, 2026.
> Original proposal baseline: `56675db`; original fixture writer: `36a00d0`.
> See [implementation evidence and screen comparison](item-tracking-verification.md).
> Production CloudKit and distribution remain separate checks.

The later [read-only follow-up](fluel-integration-assessment.md#september-14-follow-up-integration)
adds start browsing, yearly milestone readings, and time sharing/Shortcuts from
these existing fields. It supplements the initial surface scope below without
changing this persisted-model or backup contract.

## Scope and Recommendation

The accepted constraints are inputs: Stally is the host, no Fluel data transfer
is required, records without Marks are supported, and Archive does not stop
elapsed time. Their investigation is complete. Fluel remains untouched.

Extend the existing `Item` aggregate with two stored properties and keep its
UUID, `ItemMark` relationship, Library, Archive, and URL/entity identity.
Use a validated value type for start knowledge and derive elapsed time through
StallyLibrary Operations. No second entity, relationship, package, timeline,
milestone, ending date, or category expansion is needed for this slice.

| Proposed Item property | Storage default | Meaning |
| --- | --- | --- |
| `recordsMarks: Bool` | `true` | Participates in choice recording |
| `startRawValue: String?` | `nil` | Canonical partial Gregorian date |

The start is independent of the Mark policy. Both kinds of Item may have an
unknown start. Existing Items become Mark-enabled with no known start, even
if they have no Marks. Do not infer a start from `createdAt`, the earliest
Mark, photo metadata, or `archivedAt`.

This is smaller than a separate relationship entity, which would add a join,
optional relationship, identity mapping, and backup coordination without a
second lifecycle to represent. Reusing `createdAt` is unsuitable: it already
drives collection ordering and the Needs First Mark age.

## Start Knowledge and Calendar Rules

Introduce a Foundation-based `ItemStart` value with validated construction,
Gregorian components, precision, and canonical serialization. Its public
construction must not allow invalid year/month/day combinations.

| Stored value | Precision | Possible start days |
| --- | --- | --- |
| `nil` | Unknown | No inferred interval |
| `"2020"` | Year | January 1 through December 31, 2020 |
| `"2020-09"` | Month | September 1 through September 30, 2020 |
| `"2020-09-13"` | Day | September 13, 2020 only |

The grammar is exactly `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`, using ASCII digits,
years 1 through 9999, and valid proleptic Gregorian dates. This shares
`LocalDay`'s calendar and bounds. Empty text, missing zero padding, year zero,
invalid leap days, timestamps, timezone suffixes, and unknown formats are
invalid; they are not aliases for unknown start.

One scalar keeps date and precision together during storage and sync. A
separate normalized date plus precision column permits mismatched combinations
and is unnecessary here. Calculating an interval's first day must never turn
an approximate start into an exact stored date.

Newly entered or changed starts must have at least one possible day on or
before the operation's captured `today`. A current month or year is allowed;
an entirely future period is rejected. Refining month/year knowledge to a
specific day requires an explicit day selection, not a default first day.
Reducing precision discards only that explicitly edited precision.

Calendar validity and input-time validation are separate. A valid stored or
imported start may appear in the future after travel or a clock change. Keep
it intact and return a not-started reading; do not fail startup, rewrite the
date, or reject an otherwise restorable backup because of the current clock.
Editing other fields while that start is unchanged remains possible.

There is no constraint relating a start to `createdAt` or Mark dates. A start
edit may precede or follow existing Marks; it never shifts, clips, creates, or
deletes them. This preserves existing choice history without inventing an
implicit history migration.

## Elapsed-Time Contract

`ItemTimeOperations` takes an explicit `LocalDay` for the reading date.
Adapters capture `now` and the current timezone once, then derive that day
using the existing Gregorian conversion. Stored starts never change when the
timezone changes. Crossing a local date boundary can change the reading by a
day; this is calendar elapsed time, not a stopwatch.

For a known start, let `L` and `U` be its earliest and latest possible days:

1. If `today < L`, return not started, without a negative duration.
2. Otherwise set the latest possible past start to `min(U, today)`.
3. The elapsed-day interval is
   `distance(min(U, today), today)...distance(L, today)`.

Use `LocalDay.distance`, not seconds divided by 86400. The start day is zero
elapsed days. There is no stored counter, scheduled daily database write, or
dependency on `archivedAt`. Recompute on foreground, local-day/timezone change,
and date editing; each system-surface invocation captures its own reading day.

The smallest initial presentation is:

- Day precision: exact elapsed days; zero reads as starting today.
- Month precision: a range of completed Gregorian months, explicitly
  approximate; suppress day-level output.
- Year precision: a range of completed Gregorian years, explicitly
  approximate; suppress month/day-level output.
- If both approximate bounds are zero, use less than one month/year.
- Unknown start: start not set; no elapsed number.

For completed months, add calendar months from a possible start, clamping its
day to the destination month's last day, and take the largest offset whose
anniversary is on or before `today`. Completed years are whole completed
months divided by twelve. This makes January 31 to February 28 one completed
month and a leap-day anniversary land on February 28 in a common year.
Compute both interval endpoints; do not expose the earliest-start estimate as
an exact duration.

Examples with `today = 2026-09-13`:

| Start | Reading | Internal elapsed-day interval |
| --- | --- | --- |
| Unknown | Start not set | None |
| `2026-09-13` | Starts today | `0...0` |
| `2026-09-01` | 12 days | `12...12` |
| `2020-09` | Approximately 71–72 months | `2174...2203` |
| `2020` | Approximately 5–6 years | `2082...2447` |
| `2026` | Less than one year | `0...255` |

## Operations and Mark Policy

Keep `ItemFormInput` and its existing create/update call sites compatible.
Introduce `ItemTrackingInput(recordsMarks:start:)` and explicit create/update
overloads that accept it and a captured `today`. The existing create overload
uses `recordsMarks = true` and unknown start. The existing update overload
preserves tracking fields; an omitted argument must not clear a known start.

The new form update validates all proposed fields before mutation and saves
once. Reuse existing unchanged photo bytes instead of preparing them again
for a start-only edit. A save failure rolls back metadata, tracking values,
and history together through the current Operations transaction boundary.

The new pure reading facade is conceptually
`ItemTimeOperations.snapshot(for:today:)`. Return structured start/elapsed
values and explicit unknown, future, or invalid-data states. Localization
belongs at the presentation boundary; views must not parse raw start strings
or calculate their own elapsed time. Invalid stored text remains visible as
a validation problem rather than silently becoming `nil`.

Recommended initial invariant: a non-Mark Item has no Marks.

- Turning Marks off is allowed only when its history is empty. If Marks exist,
  reject the switch without deleting or hiding that history. Turning Marks on
  is allowed; the existing `createdAt` can make it eligible for Review at once.
- Both `mark` and `undoMark` reject non-Mark Items, including calls from old
  shortcuts. Preserve the existing archived-item restriction, future-Mark
  check, same-day deduplication, UUID behavior, and rollback behavior.
- A shared Operations eligibility result drives Mark, Undo, and Adjust
  History presentation and action-specific suggestions. UI hiding alone is
  not the enforcement boundary.
- Archive and Move Back remain available for both kinds. They change only
  archive state and never pause or reset elapsed time.
- Read-only history access remains intact. A sync/import anomaly containing
  Marks on a non-Mark Item must preserve both the raw state and every Mark,
  surface an inconsistency, and reject unsafe edits/export. Enabling Marks
  through the existing editor is the non-destructive repair. Never delete
  history or silently change the policy as automatic repair.

## Review and Insights

All three current Review lanes are choice-oriented: Needs First Mark,
Dormant, and Recovery Candidates. Filter non-Mark Items before lane selection
and sorting. Keep Mark-enabled membership, age thresholds, and ordering
unchanged; the optional start is not a Review age or ranking input.

`ReviewOperations.performPrimaryActions` currently mutates archive state
directly. It must also skip non-Mark requests, including stale selections,
and count only actual eligible changes. Preserve batch deduplication and
single-save rollback. Direct Archive/Move Back operations remain available.

Insights must distinguish two scopes after applying the existing Archive
option:

- `scopedItems`: all items in the selected collection scope.
- `choiceItems`: only Mark-enabled items from that scope.

Build mark totals, active days, unique marked items/categories, rankings,
quiet items, streaks, category shares, weekday/monthly activity, and all
choice recommendations from `choiceItems`. Date editing and elapsed time
contribute nothing to these readings.

Keep note/photo coverage based on `scopedItems`, since those metrics describe
context for the whole collection. Label this distinction in the screen and
shared report. Add `choiceItemCount` to the snapshot so a scope containing
only non-Mark Items gets an appropriate empty choice reading and no invitation
to add a first Mark. It may still show collection context coverage.

Apply this split in the unavailable-date path and `InsightsReportOperations`
as well. Add `nonMarkHistoryConflictCount` for detected non-Mark/history
inconsistencies in the scoped collection. A nonzero value marks the choice
reading/report as incomplete, not a valid zero. Invalid start text alone does
not invalidate independent choice counts. All-Mark legacy fixtures must
retain their current values and ordering.

## Minimal App and System Surfaces

- Add a recording-method control and an optional Start section to the existing
  native Add/Edit forms. Create defaults to the current Mark behavior. Cancel
  leaves both existing and proposed fields untouched.
- Item Detail shows start knowledge and elapsed time for either kind, including
  archived items. Non-Mark records omit the Mark/Undo/history action bar and
  do not describe themselves as waiting for their first Mark.
- Library and Archive keep the same collections, ordering, search, and links.
  Non-Mark rows omit zero-Mark counts and Mark badges. Homes and plants can use
  the existing Other category; category does not determine recording policy.
- Keep `StallyItemEntity` UUIDs and general UUID/name resolution for all Items.
  Narrow Mark-action suggestions through Operations without globally removing
  non-Mark records from Open/Archive/entity lookup. A saved Mark shortcut to
  a now non-Mark record resolves the Item and returns a clear validation error.
- Keep existing Create Item shortcuts compatible. New start-editing intents,
  Fluel URL aliases, a new navigation destination, and relationship-ending
  controls are outside this slice.

## SwiftData Versioning and Migration

At the proposal baseline, `StallyMigrationPlan` exposed only V1 and no stages.
V1's model list referenced the live top-level `Item` and `ItemMark`. Adding fields
to that `Item` while leaving V1 pointing at it would redefine the baseline.

The implementation followed this order:

1. Generate synthetic disk fixtures with the current, unchanged V1 writer.
   Record entity/property/relationship metadata using the public Schema
   inspection facilities and retain the complete closed store bundle,
   including external photo storage. Do not create a supposed V1 fixture
   using a later model that already contains the new fields.
2. Freeze the exact old models under a stable V1 definition. Preserve entity
   and stored-property names, types, defaults, the optional inverse link,
   external photo storage, and cascade rule. Prove the frozen definition opens
   those original fixtures before adding the new version. Type relocation
   alone is not evidence that persistent identity/checksums match.
3. Append V2 with the two new Item properties. Keep ItemMark's stored shape and
   its inverse graph unchanged. Expose the current model through the existing
   public `Item`/`ItemMark` names so app and entity call sites remain stable.
4. Register V1 then V2 and a V1-to-V2 stage; point the factory's current schema
   at V2. Try `MigrationStage.lightweight` for the optional/defaulted additions.
   Accept that choice only after disk migration tests pass; do not call an
   in-memory test or a compiler result migration proof.

Apple's [SchemaMigrationPlan][migration-plan] and [MigrationStage][stage]
provide the version/stage mechanism. The original disk fixtures now verify the
lightweight stage for these exact models; this does not prove CloudKit sync.

Every migrated Item must have `recordsMarks = true` and unknown start.
Existing Item and Mark UUIDs, Mark day keys and creation timestamps, item
timestamps, names, notes, raw categories, photo bytes, archive state, and
relationship ownership remain identical. Reopening V2 is idempotent.

Retain the Stally store location, CloudKit container, and independent iCloud
preference. Subscription state must not gate sync. The proposal adds only
scalar fields and retains optional relationships and the existing inverse.
CloudKit production schemas are additive and require separate
promotion/verification under Apple's
[SwiftData sync guidance][cloud-sync]. No CloudKit schema is published here.

V2-to-V1 downgrade is not a supported migration. Keep an independent closed
V1 store copy and a v2 backup before conversion in migration tests. Returning
to an old binary can recover that pre-conversion state, not new starts or
non-Mark records created later. Post-conversion recovery uses the new binary
and a v3 backup. Do not erase a failed store or report a temporary fallback
container as a successful migration. Mixed old/new CloudKit writers remain
outside the supported rollout until tested; use upgraded builds for the
initial release verification.

## Backup v3 and Existing Files

The proposal baseline's portable format was v2; it accepted only that version
and rejected the earlier timestamp-based v1 Marks. New exports use v3 and
add these item-level wire fields:

```json
{
  "recordsMarks": false,
  "start": "2020-09"
}
```

`start` is an explicit nullable canonical string. Existing item and Mark
fields, dates, UUIDs, photo bytes, and the `stallybackup` extension keep their
meaning. Do not export a normalized January 1 or month-first exact date.

| Reader | Input | Result |
| --- | --- | --- |
| New | v2 | Mark-enabled and unknown start; preserve original contents |
| New | v3 | Validate and preserve both new fields |
| New | v1 or unknown version | Explicit unsupported-version result |
| Existing v2 app | v3 | Existing version guard rejects before mutation |

Read the version envelope first. Only the v2 adapter supplies legacy defaults;
v3 requires the new Boolean and nullable start key, with strict type/grammar
validation. Missing, malformed, or inconsistent v3 data must not masquerade as
an old backup. Keep v2 golden files immutable and test the adapter separately.
The current wire-format golden uses placeholder photo bytes: it proves JSON
shape, not restorable photo content. Use valid photo fixtures for import tests.
New exports are always v3; no lossy downgrade export is added. Any retained
v2 encoder for compatibility fixtures must reject non-default new fields.

Keep merge's existing rule: matching UUIDs retain local item metadata, while
new Mark days may be appended. That also preserves the local start and Mark
policy, even when local start is unknown. Incoming Items with new UUIDs get
their complete payload. Repeat merge remains idempotent.

A matching local non-Mark Item plus incoming Marks is a merge conflict.
Reject the whole merge during preview/preflight, before any item changes.
Do not silently re-enable Marks, drop incoming history, or invent a new UUID.
Explain which Item conflicts so it can be explicitly made Mark-enabled first.
Matching valid but different start/policy metadata remains local; preview copy
must explain that existing details are preserved rather than imply overwrite.

Replacement uses the incoming validated state under the existing destructive
confirmation. A merge-only destination conflict must not block a valid
replacement. The current `BackupImportPlan` derives replacement permission
from `mergePreview.canImport`; separate the two mode-specific results, adding
an explicit preview mode with merge as the backward-compatible default.
Backup Center must request the matching preview for each action. Keep common
payload and existing integrity failures fatal in both modes.

Export must still satisfy import validation and size limits before offering
a file. Validate invalid stored start text and the non-Mark/history invariant
without dropping raw values during snapshot mapping. Existing photo, duplicate
ID/day, category, encoded-size, and rollback protections remain required.
Clock-dependent future-start checks do not apply to backup restoration.

## Implementation and Regression Test Plan

This checklist records the intended coverage. Actual results and remaining
interaction/distribution limits are in [implementation evidence](item-tracking-verification.md).
The implementation reuses the StallyLibrary target and repository entrypoints.

1. **Pure values and readings:** unknown/day/month/year round trips; malformed
   strings; years 1/9999; 1900 versus 2000 leap days; month lengths; same-day
   zero; month/year endpoints and the examples above; month-end clamping;
   future/current periods; Tokyo/Los Angeles day rollover; DST; a valid civil
   date skipped by a timezone. Refining within the original known period
   narrows the possible range.
   Use an injected reading day and verify repeated reads do not write data.
2. **Item Operations:** legacy create defaults and legacy update preservation;
   new atomic create/edit/clear; unchanged photo bytes on start-only editing;
   failed validation/save leaves all fields and Mark IDs unchanged; start
   before/after existing Marks; Mark/Undo/Adjust rejection for non-Mark Items;
   same-day idempotence; mode-switch restriction and non-destructive repair.
3. **Archive:** elapsed time at a fixed reading day is identical before Archive,
   while archived, and after Move Back. A later reading advances by the same
   calendar amount. Mark history and archive action idempotence remain intact.
4. **Review:** non-Mark Items never enter any lane, even through stale bulk
   requests; mixed batches count eligible changes and roll back atomically.
   Existing all-Mark fixtures retain membership, thresholds, and order.
5. **Insights/report:** adding non-Mark Items leaves every choice metric and
   recommendation unchanged; note/photo coverage uses the full scoped count.
   Exercise both Archive options, invalid-date fallback, all-non-Mark scopes,
   invalid history combinations, and English/Japanese report scope labels.
6. **Actual disk migration:** original V1 fixture to frozen V1, then V2; empty,
   marked, archived, photo-bearing, and missing-note collections; compare
   identity/relationship tuples and photo bytes, not unspecified array order.
   Reopen V2 twice; verify defaults and stable links; retain the original copy
   after induced migration failure. Use isolated local stores with CloudKit off.
7. **Backup:** v2 adapter import/merge/replace and unchanged golden source
   files; v3 unknown/all precision/mixed-mode round trips; future stored start;
   export-to-replace equality; same-UUID local metadata preservation; v2/v3
   incoming-Mark conflict; valid replace despite merge-only conflict; repeated
   merge; missing v3 keys; invalid starts; non-Mark payload with Marks;
   existing size/photo/duplicate checks and injected import/save failures.
   Verify old-reader rejection of v3 without any source/destination mutation.
8. **App/system adapters:** existing saved UUID links and shortcuts still
   resolve; Mark to a non-Mark Item errors clearly. Build with App Intents
   metadata extraction. Use in-memory fixtures for Add/Edit cancel, approximate
   start editing, time on Archive, non-Mark rows, Review, and Insights. Verify
   labels, accessibility, and English/Japanese catalogs on the chosen UI.

After acceptance, implement in commit-sized stages: pure start/time contracts;
frozen schema and V2 migration fixtures; Operations plus backup v3
compatibility; Review/Insights/Intents guards; native form/detail presentation
and localization.
Intermediate schema work stays unshipped until all writers, readers, and backup
paths support the same semantics. No public start value should reach storage
through an incomplete vertical slice.

Run the library suite and repository rules for domain changes, Xcode-native
app builds for public/model/adapter changes, the en/ja string-catalog audit for
copy, and targeted runtime checks for the implemented UI. No new UI test target
or Fluel importer is needed. Keep the [current repository state](../README.md#current-repository-state)
and [verification entry points](../README.md#build-and-test) aligned with the
implemented boundaries.

## Accepted Implementation Choices

The three product decisions remain settled. Implementation was authorized with
the following recommended choices before changing storage:

- One Item aggregate, a Mark Boolean, and one partial-date scalar.
- No automatic start backfill; starts and Marks remain chronologically
  independent. Newly entered wholly future starts are outside this slice.
- Approximate starts show coarse elapsed ranges instead of false exact dates.
- Turning Marks off requires empty history; conflicting imports fail safely.
- V1-to-V2 store evolution and v2-to-v3 portable-backup evolution, retaining
  v2 reads and no downgrade writer for the new semantics.

Milestones, ended relationships, broader categories, and a workflow for
converting Items that retain historical Marks can be considered later without
blocking this slice.

## Independent Pre-Distribution Checks

These checks do not block integration design or isolated implementation tests.
Their last recorded evidence is in [release-readiness.md](release-readiness.md);
external state was not re-investigated for this proposal.

- **Product/ads decision:** provide and verify the intended Stally subscription
  and owned production AdMob IDs, or choose an ads-disabled offer and resolve
  the ad-removal purchase offer accordingly. The recorded empty subscription
  card, sample app ID, production consent, and medium-ad/Licenses checks remain.
- **Public destinations:** approve/publish Privacy and Support URLs and contact
  details, add the Support entry point, and verify the actual destinations.
  Existing recorded 404 responses are release issues, not model-design inputs.
- **Signing/distribution:** supply the distribution certificate/private key
  and profile, then export and inspect the shipping-toolchain build. A local
  development-signed archive is not App Store distribution evidence.
- **Real devices and CloudKit:** select the test accounts, devices, and cloud
  environment before synthetic cloud writes. Verify upgraded-device sync of
  unknown/approximate starts and policy, offline edits, concurrent Mark versus
  policy changes, repair without history loss, relaunch, purchase/restore, and
  the distributed build. Confirm additive schema promotion before release.

No purchase, URL publication, signing-asset change, CloudKit deployment, data
reset, or real-device write was performed by this implementation.

## Inspected Stally Boundaries

- [Item and mutation Operations](../StallyLibrary/Sources/Item/ItemOperations.swift)
- [LocalDay calendar contract](../StallyLibrary/Sources/Item/LocalDay.swift)
- [Review selection and bulk writes](../StallyLibrary/Sources/Review/ReviewOperations.swift)
- [Insights scope and recommendations](../StallyLibrary/Sources/Insights/InsightsOperations.swift)
- [Versioned migration plan](../StallyLibrary/Sources/Persistence/StallyMigrationPlan.swift)
- [Backup preview and import planning](../StallyLibrary/Sources/Backup/BackupOperations+Preview.swift)
- [Existing disk reopen test](../StallyLibrary/Tests/Default/Persistence/StallyPersistenceTests.swift)
- [Existing wire-format golden tests](../StallyLibrary/Tests/Default/Backup/BackupWireFormatTests.swift)

[migration-plan]: https://developer.apple.com/documentation/swiftdata/schemamigrationplan
[stage]: https://developer.apple.com/documentation/swiftdata/migrationstage
[cloud-sync]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
