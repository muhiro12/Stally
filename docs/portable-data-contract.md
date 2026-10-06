# Portable Data Contract

## First Public Format

Import & Export transfers the complete collection selected in the
[first-release data model](first-release-data-model.md). A saved export can also
restore that collection. The internal Backup types and `backup-center` route
continue to implement this capability; they do not narrow the visible product
purpose to recovery.

Keep `.stallybackup` and `com.muhiro12.stally.backup`, conforming to `public.json`.
The registered document name is Stally Data. These identifiers already describe
a complete restorable snapshot and have development fixtures and links. A new
extension would add conversion and type-resolution work without improving
readability. Sharing suggests `Stally Data.stallybackup`; saving suggests the
localized Stally Data title with the same extension. The JSON content, rather
than the extension alone, determines compatibility.

`StallyDataContract` is the explicit version source:

| Interchange | Persisted contract | Conversion |
| --- | --- | --- |
| v3, current | SwiftData V2 | Independent Mark policy; optional partial start |
| v2, development | SwiftData V1 | Mark enabled; start unknown, then V2 |
| v1 or unknown | Unsupported | Preview rejection; no mutation |

The sequences intentionally differ because portable v1 predates the rebuilt
SwiftData baseline. Relabeling existing v2 files as persisted V2 would change
their meaning. A future durable-model revision must review this table, codec,
conversion tests, and fixtures together. v2 encoding cannot discard v3 tracking
fields. Frozen original V1 stores and v2 files remain compatibility evidence;
current combined-model tests cover v3. No original fixture is regenerated.

## Scope and Encoding

A UTF-8 JSON object has three required top-level keys:

| Key | Representation |
| --- | --- |
| `schemaVersion` | Integer, currently `3` |
| `exportedAt` | Recording instant, described below |
| `items` | Array of complete Item payloads, including Archive |

Each Item contains these fields:

| Key | Representation |
| --- | --- |
| `id` | Stable UUID string |
| `name` | Nonblank string; exact whitespace and Unicode preserved |
| `categoryRawValue` | `Clothing`, `Shoes`, `Bags`, `Notebooks`, or `Other` |
| `note` | String, including empty, whitespace, and line breaks |
| `photoData` | Optional Base64 image bytes; absent or null means no photo |
| `createdAt` | Recording instant |
| `archivedAt` | Optional recording instant; absent or null means Library |
| `marks` | Array of Mark payloads belonging to this Item |
| `recordsMarks` | Required Boolean in v3; independent of Archive and start |
| `start` | Required nullable string in v3: `YYYY`, `YYYY-MM`, or `YYYY-MM-DD` |

Each Mark contains `id` (UUID), `day` (canonical Gregorian `YYYY-MM-DD`), and
`createdAt` (recording instant). Its enclosing Item supplies the relationship.
There is at most one Mark per Item/local day; Mark UUIDs are unique throughout
the payload. A non-Mark Item cannot contain Marks. Unknown start never becomes
creation time, January 1, or another inferred date.

Recording instants are JSON numbers: **seconds since 2001-01-01 00:00:00 UTC**,
including fractional seconds. This is the Foundation Date Codable reference
interval, not Unix seconds, an ISO date string, or a local calendar day. Use a
numeric type that preserves the binary64 value when transforming these fields.
BackupCoding explicitly fixes these date and Data strategies for every
Operations entry point. Caller-selectable encoder/decoder strategies are
removed before first release so they cannot silently create another format.
Photo bytes are preserved rather than recompressed by import/export. Object
key order and Item array order are not semantic. Unknown additional object keys
are ignored; required current keys are never supplied by incidental defaults.

A minimal valid v3 example is:

```json
{
  "schemaVersion": 3,
  "exportedAt": 812345678.125,
  "items": [
    {
      "id": "00000000-0000-0000-0000-000000000001",
      "name": "Home",
      "categoryRawValue": "Other",
      "note": "A place to return to.",
      "createdAt": 812345000.5,
      "marks": [],
      "recordsMarks": false,
      "start": "2000"
    }
  ]
}
```

Excluded environment/presentation state includes iCloud preference, Review
thresholds and Insights defaults, subscription/consent resolution, app settings,
derived reports, navigation paths, SwiftData internal IDs, and runtime caches.
They do not reconstruct the collection and must not change the receiving
person's device/account policy. There is no account identifier, secret, remote
URL, executable code, or future AI instruction field in the portable contract.
Photos and notes are user content; sharing them is an explicit native action.

## Review and Mutation

Selecting or opening a file copies its bytes into a bounded immutable request,
then builds the same `BackupOperations.review` preview. Preview never mutates.
The selected method and complete current collection, including metadata/photos,
are captured in `BackupImportReview`. Before confirmation and again inside the
synchronous import operation, the current collection is compared with that
baseline. A changed name, note, photo, policy, placement, start, history, or
pending insertion requires a fresh visible review, even if counts are equal.
The pending confirmation retains its exact review. Changing the file or method
invalidates it; an old action cannot approve a newly selected candidate. Changes
to the original external file after selection do not change the copied request.

Merge preserves every existing Item's metadata, photo, placement, policy, start,
and history. It inserts new identities and adds missing Marks. An already known
Mark UUID or already marked day is skipped, preserving local history. A Mark
incoming for a local non-Mark Item blocks the merge. Merge is additive and
idempotent; it is not an external edit overwrite mechanism.

Replacement has a separate preview and destructive confirmation that explicitly
includes Archive, notes, photos, starts, and Marks. It removes
the current collection and restores the candidate's complete Item/Mark values,
including identity and Archive. People can retain a recent export first.
External tools that intend to change existing metadata must use this explicitly
reviewed replacement path. Neither receiving a URL nor decoding triggers it.
Both mutation paths revalidate and save together; a save failure rolls back.
The caller owns ModelContext isolation. Baseline checking and application do
not suspend or transfer live models to another actor.

Names must remain nonblank, categories known, starts canonical, and photos valid
under ItemPhotoOperations. Imported name/note text is preserved exactly after
validation; interactive form normalization does not silently change a portable
round trip. Duplicate Item UUIDs, Mark UUIDs, or per-Item days, malformed content,
unsupported versions, tracking conflicts, and invalid photos block import.
Current duplicate Item identity also blocks ambiguous application. Validation
issues remain visible rather than permitting a partial import.

Encoded files are capped at 100,663,296 bytes (96 MiB); aggregate decoded photos
at 67,108,864 bytes (64 MiB), with the existing per-photo size/pixel limits.
File reading is coordinated and security scoped, accepts regular files only,
and reads at most the encoded limit plus one rejection byte. A growth between
metadata and reading cannot force an unbounded read. Exports validate the
snapshot and encoded-size limit before offering a restorable file, without
changing source data on failure.

## Native Transfer and Reference Decisions

Export Data prepares one immutable validated snapshot. The native export sheet
then offers Save to Files and Share Data. FileExporter and ShareLink use those
same bytes. Sharing uses a typed Core Transferable FileRepresentation, allowing
file-oriented services to receive a temporary copy. Transient share staging is
in temporary storage and is not a second durable store or portable dataset.
Cancelling either native presentation does not mutate the collection.

Library, Archive, and Review Item rows also offer native outbound dragging of
that Item's existing `StallyLink` URL. The representation carries only the
canonical UUID reference; it does not export names, notes, photos, Marks, or
start knowledge. Like Share Item Link, it opens the receiving device's matching
Item and is not a way to copy an Item to another collection. Normal row
navigation, contextual actions, and the visible Share Item Link remain available.

Dragging is a read-only accelerator. There is no collection reordering, internal
move/copy, generic content drop target, or new transfer format. Complete
collection transfer continues to use the explicitly reviewed data file flow.

Files/another app can open the registered document type into Stally. Root URL
handling discriminates file URLs before passing navigation URLs to MHPlatform;
this prevents a data file from being reported as an unsupported deep link.
The normal import picker and opened files use the same bounded file adapter,
review UI, and Operations engine. `LSSupportsOpeningDocumentsInPlace` permits
native providers; access ends after the immutable read. No Share Extension,
background importer, automatic replacement, or AI integration is introduced.

Incomes' native FileExporter/FileImporter and user cancellation behavior are
read-only references for explicit portable transfer. Cookle's file transfer
modifier and reviewed-import service demonstrate keeping the selected archive
with its review and refusing a stale approval before mutation. Stally adapts
that baseline comparison to its smaller complete collection; it keeps its own
UUID, Mark-day, partial-start, and additive merge contract. Cookle's ISO date
codec is not copied because Stally's numeric dates retain fractional precision
and its existing development wire compatibility.

Apple's [FileRepresentation][file-transfer] and [ShareLink][share-link] guide the
native file handoff; [onOpenURL][opened-url] supplies document opening. A
DocumentGroup editing shell would add autosave/document ownership to a snapshot
import workflow, so the existing collection app remains the owning interface.

## Verification

Library checks cover full combined round trips, original v2 conversion and V1
migration, malformed/unsupported/duplicate/photo/oversized rejection,
non-Mark conflicts, repeated merge, and changed review baselines. App build and
catalog checks cover registration, adapters, and English/Japanese copy. Native
saving, sharing to an available receiving app, opened-file preview, cancellation,
and deep-link continuity require separate runtime evidence.

Current synthetic verification uses Xcode 27.0 (27A266a) and iOS 27.0
(24A434). The library passes 166 tests in 40 suites, including the hand-authored
v3 interchange fixture and original V1/v2 compatibility evidence. Three
AppIntentsTesting journeys pass after the root URL handling change, including
foreground Item opening. Repository rules, catalog coverage, and app metadata
extraction also pass.

Native Files opening shows the normal two-Item preview before mutation. Merge
changes the synthetic collection from 8 Items / 2 archived / 23 Marks to
10 / 3 / 24; repeating it adds zero Items and zero Marks. The imported archived
Item appears in Archive. Version 999 remains blocked with a visible validation
reason. Picker cancellation preserves the collection.

Save to Files and Share Data both deliver actual 63,193-byte v3 files to local
Files storage. Readback confirms all 10 Items, 3 archived Items, 24 Marks,
year/month/day start precision, Mark policy, and photo bytes. Their Item
payloads match completely; each separately prepared export has its own
`exportedAt`. Framework file-provider/view-service diagnostics occur during
native presentation, but both saves complete and read back successfully.
This evidence does not establish production CloudKit, physical-device Siri,
or every third-party receiving app.

Controlled synthetic captures show the [export options][export-capture],
[opened-file preview][import-capture], and [repeated merge][repeat-capture].
The captures contain no real collection or account data.
The latest build also shows the [complete replacement warning][replace-capture]
before destructive approval; dismissing it leaves the collection unchanged.

[file-transfer]: https://developer.apple.com/documentation/coretransferable/filerepresentation
[share-link]: https://developer.apple.com/documentation/swiftui/sharelink
[opened-url]: https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)
[export-capture]: ui-preview-screenshots/data-transfer/export-options.png
[import-capture]: ui-preview-screenshots/data-transfer/opened-file-preview.png
[repeat-capture]: ui-preview-screenshots/data-transfer/repeated-merge.png
[replace-capture]: ui-preview-screenshots/data-transfer/replace-confirmation.png
