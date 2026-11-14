# Export File Format Design

The first-release file format pairs envelope version 1 with `StallySchema`
1.0.0. The [Operations record](remaining-capabilities-implementation.md#portable-file-and-import-boundary)
describes the implemented limits and the [import contract](import-identity-design.md)
explains UUID matching and preservation.
The [data portability policy](data-portability-policy.md) defines external use
as the primary purpose and timely re-import as a supplementary capability.

## One Native Package, Optional Photos

Use UTF-8 JSON for record values inside a `.stally` document package. The two
ordinary export choices use the same physical container and document type:

| Choice | Delivery | Intended use |
| --- | --- | --- |
| Records | `Stally-Export-<timestamp>.stally` document package | Contains manifest.json alone, including photo captions and identities but not image bytes |
| Records and photos | `Stally-Export-<timestamp>.stally` document package | Carry records and available authoritative attachment images together for external use or device transfer |

Both use the same JSON schema and UUID-based import pipeline. The difference is
the image availability declaration. Neither is a database copy, deletion log,
sync checkpoint, or guarantee that every device has finished uploading.
Export includes the current local saved collection, including archived Items,
all their children, and unused Tags. Selection-only export can be added later
without changing the rule that absence never deletes a local record.

The package layout is:

```text
Stally-Export-<timestamp>.stally/
  manifest.json
  assets/
    <photo-uuid>.jpg
    <photo-uuid>.heic
    <photo-uuid>.heif
    <photo-uuid>.png
```

The manifest is the entry point for the format, records, and attachment references.
The optional `assets/` directory holds the files those records reference. These
names describe roles reusable across package formats. Stally currently writes
only photo files, named for their attachment UUIDs.

The app and export App Intents suggest the same local-time stem for package and
standalone JSON exports: `Stally-Export-YYYY-MM-DD_HH-mm-ss+HHMM`, for example
`Stally-Export-2026-11-11_20-15-30+0900.stally`. Use Gregorian date components,
24-hour time and the signed numeric UTC offset at the export instant, including
daylight-saving changes. The filename is user-renamable display metadata;
timestamps inside the manifest remain UTC. Second precision does not guarantee
unique names, and names with different offsets need not sort chronologically.
The JSON encoder indents and sorts keys; the reader does not depend on whitespace
or the suggested filename. The writer omits `assets/` when there are no image files. Names
use lowercase UUID strings, never Item names, captions, or source file paths.
Each included photo references its own file even when another photo happens to
have identical bytes. No content-addressed blob registry or deduplication store
is needed. The extension must match the decoded image container.

Use Foundation FileWrapper and the platform document export/import surfaces.
On the current iOS 27 baseline, use WritableDocument/DocumentWriter for new
export adapters, with a FileWrapper writer for a bounded snapshot or a URL-based
writer when the measured workload requires incremental resource processing.
Do not convert the main application into a DocumentGroup app; these are portable
snapshots around the existing Operations boundary and SwiftData store.

The registered package UTI is `com.muhiro12.Stally.data`, conforming to
`com.apple.package` and `public.content`, with extension `stally`. Do not also emit a regular JSON
file with that extension or declare the package itself as public.json/public.data.
An application can branch on physical file kind, but that leaves external type
inference, provider behavior, and document handling with two different container
contracts for one extension. Apple distinguishes regular-data documents from
packaged directories; using one kind avoids this unnecessary ambiguity.

Preserve the external-use purpose through an auxiliary "Share JSON" operation
that supplies records-only JSON as `.json`/public.json or text. It uses the same
schema and omitted-media rules, not a second backup format. The app and the Export Records as JSON action offer this output; it does not replace the ordinary `.stally` export or quietly give
a package a `.json` extension. A standalone records-only JSON remains readable
by the common import reader after header validation. Its content header
establishes that it is Stally data.
Stally does not claim every `.json` file. The old flat development declaration
has no compatibility commitment; installed provider behavior still needs qualification.

### Alternatives

| Alternative | Assessment |
| --- | --- |
| One JSON file with Base64 photos | Foundation supports it, but binary data grows by about one third before JSON overhead, obscures readable records, and couples text decoding to media volume |
| ZIP containing JSON and photos | Widely portable; Foundation can create an upload ZIP snapshot, but that does not provide a matching general ZIP import reader. A native package avoids adding that archive-reading layer |
| Native package for every ordinary export | Recommended: consistent `.stally` document handling, with optional media; external tools may need manifest.json separately |
| JSON and package both called `.stally` | Avoid: an app can inspect the physical kind, but the same extension has inconsistent container semantics for other consumers |
| Separate `.json` and `.stally` ordinary exports | Previous proposal; technically coherent, superseded by the owner's preference for a consistent `.stally` export |

A `.stally` package is a directory, not ZIP bytes with another extension.
On other systems it may appear as a folder. Do not promise universal package
sharing or require an AI tool to open it; auxiliary JSON sharing addresses that
use case. Files/provider/share-sheet behavior still needs runtime qualification.
Foundation's `NSFileCoordinator.ReadingOptions.forUploading` can produce a ZIP
snapshot of a directory. Therefore ZIP creation is not itself a missing Apple
capability. This review did not find a matching high-level ZIP extraction API in
the inspected Foundation headers or AppleArchive documentation; it does not claim that all Apple
platforms lack every lower-level archive facility. The Files app's ability to
unzip is a user workflow, not a programmatic Stally importer.

## Header and Version Pair

All files contain these required fields:

| Key | Value |
| --- | --- |
| `format` | Literal string `com.muhiro12.Stally.data` |
| `formatVersion` | Positive integer; first revision `1` |
| `schemaVersion` | Three-component string from the actual VersionedSchema version, such as `1.0.0` |
| `exportedAt` | UTC registration-style timestamp described below |
| `items`, `itemMarks`, `itemPeriods`, `itemPhotos`, `tags` | Arrays, including empty arrays |

Recommend starting the redesigned, pre-release five-model baseline at schema
`1.0.0`, yielding the first published pair `(1, "1.0.0")`. This is not app-version
numbering and must not be emitted while the current development schema remains
in use. Physical schema integration must implement the selected baseline and
provide its version directly; do not maintain an independent export constant.

Only registered format/schema pairs are readable. Reject future, unsupported,
or malformed versions before changes. Preserve historical readers and semantic
adapters for the supported pairs under the data portability policy and import
identity contract; support does not depend solely on the file's age.
Do not infer a file version from its filename or parse it as today's DTO merely
because its keys look familiar.

## Record Fields and Relationships

The October 28 [representative-link decision](product-behavior-design.md#accepted-context-and-favorite-decisions)
is included in the first public schema and codec. `note`, `representativeURL`,
`caption`, `startLocalDate` and `endLocalDate` are required nullable keys:
null explicitly clears that selected field.
There are no supported development-file readers in this prerelease baseline.

| Record | Required fields |
| --- | --- |
| Item | `uuid`, `name`, `note`, `representativeURL`, `createdAt`, `isArchived`, `isFavorite`, `isMarkRecordingEnabled`, `tagUUIDs` |
| ItemMark | `uuid`, `itemUUID`, `localDateTime`, `createdAt` |
| ItemPeriod | `uuid`, `itemUUID`, `startLocalDate`, `endLocalDate`, `isOngoing`, `createdAt` |
| ItemPhoto | `uuid`, `itemUUID`, `caption`, `sortOrder`, `createdAt`, `image` |
| Tag | `uuid`, `name` |

UUIDs are standard hyphenated UUID strings. Export lowercase; decode hexadecimal
case without changing identity. Different UUIDs never collapse by name.
Item tag membership is an explicit complete set, encoded as an array without
duplicates. Every referenced Tag and parent Item must exist in this export.
This makes both deliveries self-contained for record interpretation.

Nonempty user text is retained exactly, including whitespace, newlines, and spelling.
Apply the existing domain validation rules, not new filename or tag-normalizing
rules. Export booleans as JSON booleans and sortOrder as a nonnegative integer.
Records sort by UUID for reproducible output; tagUUIDs sort by UUID. Array order
does not define record meaning. Photo order is sortOrder, then UUID, as in the
model contract. Object-key order is irrelevant; pretty printing and sorted keys
make ordinary exports easier to inspect and compare.

Do not export thumbnails, caches, derived counts, CloudKit metadata, persistent
model identifiers, source paths, account identifiers, or subscription state.
Do not silently drop orphan records to manufacture a self-contained snapshot.
If ownership or references are incomplete, stop that export with an actionable
message; retain the database unchanged. This is export validation, not an orphan
repair job or a requirement to prove global sync completion. Multiple ongoing
Periods may be represented faithfully; import still applies the existing
review/correction policy before approving a resulting graph.

### Missing, Null, and Empty

- All schema-1 fields listed above must be present. Missing is invalid, even if
  a Swift initializer has a default. Historical absence is handled by the
  explicitly selected older schema reader.
- Optional note, caption, representative URL and Period boundaries export as
  `null` when absent. On import, an explicit empty string is normalized to nil
  before validation and conflict review, exactly like explicit `null`. Applying
  that selected row clears the field; an empty string is never stored.
- Unknown Period dates do not infer January 1 or the registration date.
  Required names and Mark dates reject empty or null values.
- Empty tag sets are actual supplied values. Applying an empty tag set after
  conflict review clears assignments; it does not delete the Tags themselves.
- Omitted rows are never deletion instructions. There are no merge redirects,
  tombstones, or automatic name-based lookup instructions in the file.
- Unknown extra keys may be ignored within a supported version pair, but are
  not preserved on re-export. Unknown versions and unknown image states are
  rejected; ignoring extra keys is not future-schema support.

Synthesized Swift Codable omits nil optionals by default. A writer must
encode every nullable key explicitly; a reader must check key presence separately
from decodeIfPresent. This distinction belongs to the codec, not the model.

## Dates and Precision

Business dates retain the accepted string forms without timezone conversion:

- Mark: `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm`.
- Period: `null`, `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`.

Validate these with the existing strict Gregorian rules. Never fill unknown
precision, append `Z` to a Mark, or use the importing device's timezone to move
an occurrence to another day.

For createdAt and exportedAt, recommend a UTC RFC 3339 string with exactly three
fractional digits, for example `2026-10-25T05:00:00.123Z`. Define the portable
registration-time precision as milliseconds, rounded to the nearest millisecond,
with half values away from zero. Validate the exact form and calendar values;
accept years 0001 through 9999. Business-date limits remain their own contract.

Compare creation instants at that same millisecond precision during import.
Keep the local Date unchanged when all portable values agree. An exported and
reimported record must not conflict merely because its local Date had additional
submillisecond precision. This is an intentional, less-than-one-millisecond
registration precision tradeoff, not exact binary64 Date preservation. It does
not round Mark or Period facts and does not make createdAt a conflict winner.

A simple implementation uses an integer millisecond comparison value, derived
with `(date.timeIntervalSince1970 * 1000).rounded()`, and a fixed Gregorian,
en_US_POSIX, UTC DateFormatter with `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`. Quantize before
formatting and reject out-of-range/non-finite values before conversion. Do not
add another persisted epoch field or a second timestamp to the JSON solely to
retain unused binary precision.

The unconfigured JSONEncoder date strategies and a naive ISO8601FormatStyle
round trip do not establish this contract. Keep a dedicated, validated wire
timestamp codec; do not expose selectable encoder date strategies to callers.

## Attachment Availability

Every ItemPhoto has one of these image objects:

```json
{
  "state": "included",
  "path": "assets/20000000-0000-4000-8000-000000000001.jpg",
  "byteCount": 123456,
  "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
}
```

The included example illustrates the fields; its count and digest are
placeholders, not a valid image fixture.

```json
{ "state": "omitted" }
```

```json
{ "state": "unavailable" }
```

| State | Meaning | Import behavior |
| --- | --- | --- |
| included | Package contains authoritative saved attachment bytes | Validate without recompression, then include the bytes in ordinary conflict review |
| omitted | Export deliberately leaves out available attachment bytes | Preserve existing local bytes; a new photo can retain its identity/caption/order with no recoverable image |
| unavailable | Snapshot has no available authoritative bytes | Preserve existing local bytes; do not interpret as erase or substitute a thumbnail |

Only included has a path, byteCount, and sha256; all three are required for that
state and forbidden for omitted/unavailable. Only packages can contain included entries; importing
an extracted manifest.json with included references must request the package,
not reinterpret missing files as deliberate omissions or search neighboring
arbitrary folders. A records-only package or auxiliary JSON share writes omitted
for available images and unavailable for genuinely missing images.

### Image Integrity

Adopt Cookle's explicit per-image byte count and SHA-256 verification. ImageIO
decodability alone cannot detect a substituted, otherwise valid image. These
fields are derived wire metadata, not new SwiftData columns or new identities.

- byteCount is the actual nonnegative integer byte length, within the saved
  image limit; a zero-length value still fails image validation.
- sha256 is exactly 64 lowercase ASCII hexadecimal characters, computed from
  the complete saved bytes with CryptoKit SHA256, including embedded metadata.
- Before review, check the actual bounded read length and digest against the
  declaration, then validate image format and dimensions. A filename extension
  or an untrusted declared size is not sufficient validation.
- Hash the bytes actually written during export and apply the same reader-side
  checks to the staged output before reporting success. Do not hash an earlier
  mutable source and then copy different bytes.
- Review and apply use the same validated staged bytes. The existing conflict
  policy still compares authoritative content; a digest is not a Tag/Item match
  key or a reason to merge separate photo identities.

This detects accidental corruption or substitution relative to the manifest.
It is not a signature, proof of authorship, or protection against a person who
rewrites both an image and its digest. No encryption or signing system is added.

Export saved bytes unchanged. Preserve supported embedded metadata, including
GPS and capture information already retained by the accepted photo contract.
Explain this when the person chooses image-inclusive export. The records-only
option contains no image bytes or extracted EXIF, but still contains the user's
record text and is not an anonymized export.

Do not introduce metadata-redacted derivatives into the first format. A future
redaction feature needs an explicit derivative representation and format
revision; it must not masquerade as an authoritative replacement. This defers
a feature, not the ability to preserve original attachment metadata now.

The 8-MiB saved-image bound, supported image formats, 3,072-pixel edge bound,
decodability, and orientation handling follow the accepted photo contract.
Restoration validates the saved representation without rerunning its lossy
ingestion transformation. Missing included files or corrupt bytes invalidate
the proposed import before any database writes.

## Reading and Resource Boundaries

Resolve media through package child entries with the exact grammar
`assets/<photo-uuid>.<supported-extension>`. Reject symbolic links, directories
where regular files are expected, duplicate/ambiguous record UUIDs, invalid
parent references, and path escapes. Never fetch URLs declared in a file.
The writer emits no extra entries; the reader does not traverse or import
unreferenced entries. This avoids recursively expanding arbitrary folder trees.

The original 32-MiB JSON, 128-MiB media, and 50,000-record budgets were
implementation safeguards, not Apple limits or permanent semantic maxima.
The staged implementation removes those fixed aggregate ceilings without
changing format/schema versions. Keep the per-image 8-MiB saved representation
limit and all graph, path, type, and integrity validation.

One operation owns a private temporary directory. Provider bytes are copied
through coordinated, descriptor-relative, no-symlink reads; only manifest
references are visited. Read chunks and per-image native temporary objects are
released in autorelease pools. Native URL writers prepare a replacement before
publishing it, preserving an existing destination on preparation failure.
The in-memory-only MHFilePackage snapshot API cannot provide this staging
lifetime; Stally keeps its narrower format-specific reader with the same
openat/O_NOFOLLOW resolution boundary.

iOS and visionOS declare copy-based document opening. macOS requires opening
original documents; its platform-specific declaration permits that access, while
the reader still stages a private copy and never edits the source document.

Images use private copy-on-write mappings whose Data deallocator retains the staging
owner. A failed mmap throws instead of silently allocating all pending images.
This keeps the saved SwiftData model and single-save contract unchanged. The
normal app and Intent paths do not assemble an aggregate FileWrapper/Data graph.
The legacy FileWrapper adapter remains available for bounded callers.

Typed Codable fields preserve required nulls, UUID spelling, timestamp precision,
and additive-key behavior without an additional JSONSerialization object graph.
Metadata still consumes memory proportional to record values and counts.
Admission uses the lesser of one quarter of physical memory and one half of
current app dirty-memory headroom on devices; Simulator/macOS use the physical
estimate because the iOS process-limit API does not apply to their test hosts.
JSON reserves an eightfold decoding budget and records an 8-KiB pending-record
estimate. These are conservative workload-based estimates, not hard memory
bounds. Export and import share the checks; available resources can differ
between devices or between preparation and apply. Preflight disk requirements
and propagate actual allocation/write/save failures. Do not claim unlimited
capacity, silently truncate records, or switch to partially committed batches.

Do not claim that FileWrapper alone bounds aggregate memory. Capture a coherent
saved-value snapshot and stage the relevant immutable bytes before presenting
import review. Later apply from that same validated snapshot, not from mutable
provider files. Coordinate external file access and release security-scoped
access normally. Temporary staging belongs to the operation, never to a second
permanent attachment store. Remove it after completion/cancellation and clean up
abandoned temporary work using normal temporary-file lifecycle handling.

Writing, validation, and review failures make no database changes. Approved
imports use the previously selected operation-owned context and one local save;
none of the file mechanics add distributed transaction guarantees.

### Safeguards Retained from the Sibling Review

Incomes' symmetric export/import limits and historical value readers, and
Cookle's reviewed-content binding, stale-review rejection, and save-failure
preservation are already part of the Stally proposal. Preserve them as explicit
implementation acceptance criteria. They are independent of UUID matching;
having UUIDs does not replace them. The concrete new addition in this revision
is per-image integrity metadata. Aggregate resource qualification is made
explicit rather than treated as solved by the smaller per-image limit.

## Bounded Verification and Remaining Qualification

The revised container/integrity recommendation passed 14 additional standalone
Foundation/CryptoKit assertions on the same host: both a records-only and a
media-bearing `.stally` are directories and reopen without changing bytes;
SHA-256 matches the published `abc` test vector; incremental hashing agrees;
same-length substitution, truncation, incorrect length, and incorrect digest
are detected; and integrity fields survive Codable round trip. Synthetic binary
data was used, not user photos. This is not installed UTI/Files/provider testing
or qualification of the production image/import validator.

On Xcode 27.2 / Swift 6.4.2 / macOS 27.2, a standalone Foundation probe passed
16 package/JSON transport assertions: a FileWrapper package written and reopened
from disk, unchanged JSON and binary payload bytes, separate same-name Tag UUIDs,
two same-day Marks, explicit Period null, preserved user whitespace, membership
sets, and a standalone JSON variant retaining photo identity with omitted media.
The binary fixture was synthetic; it was not an image-validation test. The first
restricted run failed with a Launch Services access error; the run with normal
host access passed. No user images were used or added to Git.

A separate timestamp probe passed 40,505 millisecond comparison and stable-text
round trips across fractional-second sweeps near Unix epoch, 2001, 2026, and
2100. The initial naive ISO8601FormatStyle experiment exposed precision loss and
unstable reformatting near second boundaries, motivating explicit quantization.
These probes are outside the repository and do not constitute a production
codec, all-year calendar proof, iOS UI test, or full application import test.

Before implementation is considered qualified, verify the actual strict Codable
readers/writers, invalid input and limit cases, historical field availability,
five-model import conflicts, image restoration, provider changes during review,
installed UTI/Files/export/share behavior, and representative device memory/disk
workloads. Runtime admission estimates do not establish an absolute memory guarantee.

## Sources

- [Apple: Defining file and data types](https://developer.apple.com/documentation/uniformtypeidentifiers/defining-file-and-data-types-for-your-app)
  distinguishes regular data and package document conformance.
- [Apple: CryptoKit](https://developer.apple.com/documentation/cryptokit)
  provides SHA-256 without a third-party crypto implementation.
- [Apple: JSONEncoder](https://developer.apple.com/documentation/foundation/jsonencoder)
  supplies standard JSON coding and formatting; Stally selects the wire meaning.
- [Apple: UTType.package](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct/package)
  identifies the native package abstraction.
- [Apple: Date.ISO8601FormatStyle](https://developer.apple.com/documentation/foundation/date/iso8601formatstyle)
  supplies ISO formatting; probe results qualify the chosen precision handling.
- [Apple: forUploading](https://developer.apple.com/documentation/foundation/nsfilecoordinator/readingoptions/foruploading)
  documents directory-to-ZIP snapshots, separately from archive import.
- Apple's Xcode 27 document-app guidance, consulted locally, covers
  WritableDocument, FileWrapperDocumentWriter, direct-URL readers/writers,
  package declarations, fileExporter, and coordinated file access. It establishes
  platform composition, not Stally's version numbers, image policy, or limits.
