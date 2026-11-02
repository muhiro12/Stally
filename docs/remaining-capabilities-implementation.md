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
One native `.stally` directory package contains `manifest.json` and optional
`photos/<lowercase-photo-uuid>.<extension>` entries. The app exports
`com.muhiro12.Stally.data`, conforming to `com.apple.package`, and registers
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

The app contains 38 Operations-backed actions and five UUID-backed entities.
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
| Portability | Export Stally Library; Export Records as JSON; Review Stally Import |

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

On November 2 the [published association entry](https://github.com/muhiro12/muhiro12.github.io/commit/3f3439065ddf835c88d8edd49c52fe88af64cf54)
was verified at both the site and Apple's CDN. The five Stally routes leave
the Incomes and Cookle entries unchanged. A Release build for generic iOS,
signed for development, contains the matching app ID and associated-domain
entitlement. The Simulator app also embeds that entitlement. Opening an Item
HTTPS URL via the OS and tapping it from a different web origin both stayed
in Safari (404); neither opened the Item. Keep the Item share action and Open
Item Intent on the custom scheme until an installed HTTPS handoff succeeds.
A physical device has not been tested.

## Remaining Contract Work

The November 2 implementation supersedes the October 31 gap inventory.
The previous published baseline was `a498f55`.

| Contract | Implementation and resumption point |
| --- | --- |
| Portable identity | The package UTI and JSON format are `com.muhiro12.Stally.data`. The package contains `manifest.json` and optional `photos/<lowercase-uuid>.<ext>`. Suggested filenames use a UTC timestamp. Old development packages have no fallback. |
| Records-only JSON | [Export operations](../StallyLibrary/Sources/Transfer/TransferOperations.swift), the app file exporter and [Export Records as JSON](../Stally/Sources/Intents/ExportRecordsIntent.swift) share one media-free snapshot. Reimport preserves local photo bytes. |
| Photo privacy | The app explains that included images retain embedded metadata such as location; the package Intent explains it in the photo parameter. Standalone JSON never carries image bytes. |
| iCloud account transitions | [Write session](../StallyLibrary/Sources/Persistence/RecordWriteSession.swift) binds outstanding drafts and confirmations to the observed account session. The app replaces editor state and clears pending import review when CloudKit signals a change. The last check runs after the asynchronous update check, immediately before mutation. Exercise real account changes separately. |
| Remote update | Startup and foreground entry refresh evidence. A confirmed requirement disables editing, retains the presented draft, and offers Store and retry actions. Unavailable evidence permits offline edits. |
| Universal Links | The entitlement and scoped HTTPS parser are present; the app receives browsing activities. The association file includes Stally at the origin and Apple CDN. Verify signed installed handoff before switching generated links to HTTPS. |

### Keep implementation and release qualification separate

Use the [repository verification instructions](../README.md#build-and-test)
for each change. Physical photo/file providers, multi-device CloudKit account
changes and convergence, installed Universal Links, locked-device Intent
authentication, and previously saved Shortcuts need their own evidence.
Record exactly which environment and entry point passed. Promoted Shortcuts,
Widget/Watch delivery and earlier Review/Insights screens are separate product
choices and are outside this resumption list.

## November 2 verification

The Simulator app built and all 73 library tests in 19 suites passed. The suite
checks standalone JSON reimport with omitted media, byte preservation,
stale-session rejection and fresh-session writes. Repository lint and boundary
checks passed. On the dedicated Simulator, exporting from the app with
Include Photos enabled still produced a standalone, readable JSON file with
the expected format, version pair and five development Items. The metadata
notice was visible for package export. In Shortcuts, executing Export Records
as JSON returned the expected discriminator, schema version and Mark records.
With a synthetic confirmed requirement,
the Store link and retry appeared; retry and a foreground return each
reevaluated the requirement. These checks did not use a live iCloud account.

## October 31 verification

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
