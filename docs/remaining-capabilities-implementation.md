# Shared Product Operations and System Adapters

## Scope

The October 31, 2026 implementation continues the accepted
[product behavior](product-behavior-design.md) from the
[Item context baseline](item-context-implementation.md). It implements the
selected local capability families without restoring the earlier
PoC, Fluel, Review, Insights, or development-store compatibility code.

## Recorded Time Together

`PeriodReadingOperations` returns independent current and cumulative readings.
Current uses the ongoing period's own start. Cumulative adds recorded periods
and excludes gaps. Empty history is unavailable, not zero.

Day-precision pairs use Gregorian calendar day differences. A pair containing a
year-only endpoint uses the difference between the recorded years; a pair whose
least precise endpoint is a month uses calendar month differences. For example,
2020–2021 contributes about one year, and 2020-04–2025-10 contributes 66 months.
Mixed precision never invents a stored January 1 or other missing date.

The result retains exact days, approximate months, approximate years, included
and excluded counts, and possible-overlap information. The initial UI converts
approximate components using 365.2425 days per year and 12 months per year,
rounds the combined estimate to one fractional year, and shows the components
that explain it. These are reversible presentation choices, not persisted facts.
Unknown or future ongoing starts are excluded; a partial result is a calculable
subtotal. Definitely contradictory histories fail visibly. Possible overlap
between partial dates is disclosed as an assumption, not silently certified as
non-overlap. Exact same-day periods can contribute zero days.

## Recording and Organization

- Record Today creates a date-only Mark; Record Now adds local minute knowledge.
  Every deliberate execution creates a distinct occurrence, including repeated
  actions on the same day. Undo addresses the acknowledged UUID, not whichever
  Mark happens to be newest. Pausing blocks additions but permits correction
  and deletion.
- `ItemQuery` shares name/note/Tag search, archive scope, favorite and Tag filters,
  and ordering. The UI initially shows unarchived Items and lets the person
  choose Library, Archive, or All within a collection. UUID breaks sorting ties.
- Tag consolidation captures the chosen source, survivor, names, and memberships.
  It rechecks those facts, reassigns the reviewed Items, and deletes only the
  source in one owned-context save. It is neither name-based merging nor a
  permanent alias system, and it cannot promise to transfer unseen remote links.

## Portable File and Import Boundary

The implemented version pair is `(1, "1.0.0")`, backed by `StallySchema` and
`StallyDataContract`. Unsupported pairs and old development files are rejected.
One native `.stally` directory package contains `records.json` and optional
`media/<lowercase-photo-uuid>.<extension>` entries. The app exports
`com.muhiro12.stally.export`, conforming to `com.apple.package`, and registers
that document type without taking ownership of generic JSON.

Exports include archived Items, all owned records, and unused Tags. Required
nullable keys remain present. Item includes `representativeURL` as a nullable
string. UUIDs and membership order are canonicalized without merging identities;
registration timestamps use the accepted UTC millisecond precision. Cache and
thumbnail fields are excluded. Incomplete ownership or conflicting identities
block export instead of silently dropping records.

Included images retain their saved bytes and metadata. Import checks the exact
path grammar, byte count, SHA-256, native image format, and saved image limits;
it does not run the ingestion/recompression path. Omitted or unavailable images
never erase local bytes. A new attachment without supplied bytes remains a
metadata record with unavailable media. Auxiliary records-only JSON is readable;
JSON referencing package media requires the actual package.

File reads are security-scoped, coordinated, and bounded before review. Symbolic
links and non-regular referenced files are rejected. Unreferenced entries are
not recursively read. Immutable staged values release the provider before the
person reviews them. Initial engineering limits are 32 MiB of JSON, 8 MiB per
saved image, 128 MiB of included images, and 50,000 records per transfer. Oversized
work fails before any save; there is no partial-batch import. These limits need
real-device workload qualification and are not new persisted fields.

`TransferOperations.review` compares UUIDs and presents additions, matching
records, and whole-record differences. New records are initially selected;
conflicts keep current values by default. The review exposes current/file
values, actual photo previews, registration metadata, Tag rename impact, and
possible restoration of previously deleted identities. Children cannot be
reparented by an ordinary import. Skipped dependencies and incompatible selected
period histories are rejected without modifying the library.

`apply` uses a fresh write context with autosave disabled, rechecks the reviewed
snapshot, preflights available disk capacity where the system supplies it,
validates the selected graph, and saves once. Failed saves leave the reader and
reopened store unchanged. An identical replay performs no assignments or save.
The initial implementation conservatively invalidates review after any observed
portable library change, including unrelated records; narrowing this invalidation
is a future internal refinement. The local comparison snapshot currently shares
the export budgets. Native CloudKit can still race or arrive afterward; this is
not a cross-device transaction or deduplication engine.

## App Intent Coverage

The app contains 37 Operations-backed actions and five UUID-backed entities.
Entity queries resolve batches, explicitly filter string searches, and reject
ambiguous identities. Initial pickers suggest up to 20 current records; searches
remain available beyond those suggestions. Missing UUIDs are never replaced.

| Capability | Adapters |
| --- | --- |
| Item creation, details, independent state, deletion | Create/Edit/Get Item Details; Set Archive/Favorite/Recording; Delete Item |
| Library search and opening | Find Items; Open Item; Open Item Link |
| Mark history | Get Item Marks; Record Today/Now; Add Mark on Date; Correct/Delete Mark |
| Period history and readings | Get Item Periods; Add/Correct/End/Resume/Delete Period; Get Time Together |
| Shared Tags | Get Item Tags; Create/Rename/Delete/Consolidate Tags; Set Item Tags |
| Owned media | Get Item Photos; Attach Photo; Edit Caption; Move/Delete Photo; Get Photo File |
| Portability | Export Stally Library; Review Stally Import |

These actions read or change personal records, so each requires native
`requiresAuthentication`. Deletion and consolidation also request confirmation
before mutation. Read-only and export actions do not run the mutation gate;
all writes use the same `RemoteUpdateOperations` check as app UI. No promoted
App Shortcuts, invocation phrases, internal repair actions, or synthetic
production data are added.

Review Stally Import runs in the foreground and hands immutable reviewed data to
the app. It explicitly reports that nothing has been imported. Only the app's
reviewed selection can call apply. Export returns a native package `IntentFile`
whose temporary file is removed when the Shortcut finishes. Photo handoff
identifies the native format and preserves saved bytes.

Optional Edit Item fields leave the current value unchanged; an explicit empty
note or link clears that field. Empty optional period-boundary text means unknown,
while nonempty text must follow the canonical Gregorian forms. Get Time Together
returns localized explanatory text, not a scalar claiming exact cumulative time.
Typed entities and date strings retain their underlying identity/precision.
Before publication, the extracted type/parameter identities, defaults, policies,
and saved-workflow behavior still need release review.

## Links and External Deployment

The active destinations are `library`, `archive`, `import-export`, and
`create-item`, plus `item/<UUID>`. Unsupported provisional destinations were
removed. Creating a link or opening the creation screen never creates a record.

The app accepts HTTPS routes only under `https://muhiro12.github.io/Stally/`,
with a matching Associated Domains entitlement. Custom-scheme links remain the
currently emitted transport. The scoped association-file entry is prepared at
[stally-applinks-entry.json](deployment/stally-applinks-entry.json).

Read-back of the public association file on October 31 found Incomes and Cookle
entries, but no Stally entry. This change does not publish that file, change the
website, or claim installed Universal Link activation. Merge the prepared entry
into the owned site's association document, configure the signing capability,
and verify installed HTTPS handoff before publishing this surface.

## Remaining Contract Work

Resume from the published October 31, 2026 baseline `a498f55`. Recheck HEAD
and the paths below before starting. This baseline includes strict URL
validation shared by import and editing (`1064ca8`) and the persistent test
fixture lifetime fix (`a498f55`). Publication checks passed for 72 library tests
in 18 suites, the Simulator app build, lint and repository rules. The earlier
interaction evidence below applies only to the flows actually exercised.

### Decide the portable names before wiring new output

The [file design](export-file-format-design.md) and current reader/writer use
`.stally`, UTI `com.muhiro12.stally.export`, JSON `"format": "stally"`,
`records.json` and optional `media/`. The subsequent comparison proposed
`com.muhiro12.Stally.data` for both the UTI and the JSON format value, and
Cookle's `manifest.json` and `photos/` names. These are proposals awaiting an
owner decision. A dated suggested filename and indented JSON can be decided
separately; neither determines which files the reader accepts.

If the names change, update Info.plist, StallyDataContract, TransferCodec,
package paths and validation, app/Intent output, fixtures, tests, example
and active format documentation together. Keep UUID identity, time precision,
image availability states and the format/schema version distinction. Old
development stores and files have no compatibility commitment.

### Resume the accepted implementation

| Work | Current entry point | Completion evidence |
| --- | --- | --- |
| Share records as standalone JSON | [Package operations](../StallyLibrary/Sources/Transfer/TransferFileOperations.swift), [app export](../Stally/Sources/Features/Transfer/TransferView.swift), [Intent export](../Stally/Sources/Intents/ExportLibraryIntent.swift) | An external tool receives a standalone JSON file through the app and an Intent. It reimports without package media; the ordinary export still produces a package. |
| Invalidate drafts and import reviews on iCloud account transition | [Sync contract](sync-lifecycle-design.md), [Item editor](../Stally/Sources/Features/Library/ItemEditor.swift), [import apply](../StallyLibrary/Sources/Transfer/TransferOperations+Import.swift) | A draft or review opened in the prior account cannot write even when the new account has equivalent records. Reopening starts a fresh edit or review. Existing data-change checks still apply. |
| Explain photo metadata at export | [Photo export contract](export-file-format-design.md#attachment-availability), app and Intent export above | Before choosing image-inclusive output, a person can tell that the saved bytes may contain embedded information such as location. Records-only output omits the bytes. |
| Complete Universal Links | [Routing](../StallyLibrary/Sources/Link/StallyLinkOperations.swift), [association entry](deployment/stally-applinks-entry.json) | Verify the deployed association and signed entitlement, exercise installed HTTPS handoff to the intended Item, and switch shared link generation to the qualified HTTPS route. |
| Reconcile remote update lifecycle and presentation | [Update contract](remote-update.md), [app startup](../Stally/Sources/App/StallyApp.swift), [write guard](../StallyLibrary/Sources/RemoteUpdate/RemoteUpdateOperations.swift) | The October 31 comparison found startup preparation and write checks, but no foreground refresh or dedicated update/retry UI. Exercise foreground refresh and a confirmed requirement using isolated evidence, preserving drafts and the offline policy. |

The first three rows and the link integration came from the original gap
review; the last row came from the later cross-app comparison. Account
invalidation and remote update wiring can proceed independently of the naming
decision. Verify current site state and deployment ownership before external
work. The existing MHAppConfig endpoint already uses the shared policy format.

### Keep implementation and release qualification separate

Use the [repository verification instructions](../README.md#build-and-test)
for each change. Physical photo/file providers, multi-device CloudKit account
changes and convergence, installed Universal Links, locked-device Intent
authentication, and previously saved Shortcuts need their own evidence.
Record exactly which environment and entry point passed. Promoted Shortcuts,
Widget/Watch delivery and earlier Review/Insights screens are separate product
choices and are outside this resumption list.

## Verification

All 71 library tests in 18 suites pass on the assigned iOS 27.2 Simulator.
Coverage includes the complete imported graph and replay, failed-save rollback
and disk reopen, duplicate identities seen by the writer, stale review, skipped
dependencies, media corruption and preservation, strict file versions and keys,
transfer limits, a 500-Item workload, period precision, consolidation, and Mark undo.
Expected invalid-image and deliberately unwritable-store diagnostics occur in
passing negative tests.

The app builds and runs for the same Simulator. Repository SwiftLint and
boundary checks pass, and the English/Japanese catalog audit reports no incomplete
keys or translation-patch errors.

Simulator interaction verified repeated Today recording and UUID-specific undo,
paused recording, archive/favorite/search scopes, same-name Tag identification and
consolidation, records-only and image package export, and unchanged reimport.
A conflicting import initially retained current values; cancellation preserved
those values. Explicitly selecting the file value updated one record, and a
relaunch retained both that update and Marks absent from the imported file.

Shortcuts execution verified Find Items, Record Today, Get Time Together,
Export Stally Library, and foreground Review Stally Import. Import review remained
visible after the system result dialog, and cancellation performed no save.
The initial empty entity suggestions and missing foreground review presentation
were found during this verification and corrected.

New-record import is covered by library tests rather than manual file-picker
interaction. Physical-device file providers, large real-world libraries, CloudKit
concurrency, locked-device authentication, and saved-workflow compatibility are
not qualified by this Simulator pass. Shortcuts Recents displayed implausible
sizes for existing packages, although native app selection, reading, and exported
file results showed the expected kilobyte/megabyte sizes. Scene-masking diagnostics
also appeared during a successful foreground review without an observed crash.
These observations remain runtime follow-up evidence, not reasons to add a
legacy compatibility or alternate-format path.

The final Time Together screen also passed a visual alignment check after moving
the timeline into the native section content.
