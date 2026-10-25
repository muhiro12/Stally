# Export and Import Identity Contract

## Status and Recommendation

The owner accepted conservative omission handling, review of absent identities,
and a 1.0 workflow without whole-library replacement or Import as Copy. The
record-level resolution details remain the engineering recommendation below.
The owner also accepted aligned store/export schema versions, a separate file
format version, and shared semantic conversion rules without mandatory reuse
of SwiftData migration execution. These decisions apply
protection of recorded facts and user intent to the five planned models.
No production importer, store, or cloud schema was changed.
The [portable data contract](portable-data-contract.md) still describes the
implemented development v2/v3 codec, not this new design.

Recommend one ordinary, identity-preserving import workflow: review additions
and differences, retain current values by default, and apply file values only
for records the person explicitly chooses. Import is a deliberate transfer of
facts, not a second synchronization system, automatic restore of all old state,
or inference of which account/device/file is authoritative.

## Alternatives

| Approach | Benefit | Cost or unacceptable inference | Recommendation |
| --- | --- | --- | --- |
| Always insert new UUIDs | Simple duplication | Re-import multiplies Items, Marks, periods, photos, and Tags | Not ordinary import |
| Automatically pick the newest version | Little interaction | createdAt and exportedAt do not establish edit order; no common baseline exists | Reject |
| Insert missing UUIDs and silently ignore every existing UUID | Protects current values | Conceals conflicts and cannot deliberately recover or apply corrected file values | Keep its conservative default, but expose conflicts and choices |
| Replace the whole collection | Exact local snapshot replacement | Deletes unrelated or newer records; omitted content becomes destructive; sync adds complexity | Do not carry forward as an ordinary 1.0 import mode |
| Match UUIDs and review differences | Stable repeated import and explicit corrections | A bounded review/apply operation and per-record decisions | Recommended |

Restoring into an empty collection works through ordinary identity-preserving
import. Whole-library replacement and deliberate duplication are separate
features, not necessary for that restoration. This is a recommendation to
simplify the new workflow, not a change to the existing production code.

## UUID and Record Matching

| Available facts | Proposed result |
| --- | --- |
| File UUID is absent locally | Offer addition using the original UUID and registration metadata |
| Same UUID, same authoritative content | No assignment or save for that record |
| Same UUID, different authoritative content | Show the difference; keep current values unless file values are explicitly selected |
| Different UUIDs, identical-looking content | Separate records; do not match by names, dates, counts, or image similarity |
| Record exists locally but is absent from the file | Leave it unchanged; absence is not a deletion command |
| Duplicate UUID entries or cross-type identity collision in the file | Reject ambiguous input before mutation |
| Multiple local rows claim an imported UUID | Block ambiguous application; do not choose the first or silently deduplicate |
| Same owned-child UUID claims a different Item | Treat as a structural identity conflict; ordinary import does not reparent it |
| Required relationship cannot resolve in the approved file/local graph | Block the invalid plan; do not guess a parent or Tag |

The one-record-per-UUID expectation is checked by this operation, not enforced
with a CloudKit-incompatible unique attribute. Parse UUIDs as Foundation UUID
values; casing of their textual representation does not create a new identity.
Retain distinct Tag UUIDs even for identical names. Retain distinct Mark UUIDs
even when localDateTime and Item match; multiple occurrences per day are valid.

An absent UUID is only known to be absent. It may represent new information or
something deleted since the file was exported. Without retained deletion history,
these cannot be distinguished. Show additions for review and allow exclusion;
state that older files can restore previously removed records. Do not introduce
permanent tombstones or an import ledger merely to guess that intent.

Repeated import adds no duplicates once those identities are present locally.
A conflict kept unchanged may appear again on the next import; no hidden
permanent dismissal or historical winner is stored. If the person later deletes
a record, re-import can offer it again. This is intentional and must not be
marketed as globally exactly-once delivery.

## Meaning of Content and Conflict Choices

Compare decoded authoritative values, not whole-file bytes, exportedAt, JSON
key order, incidental array order, or SwiftData internal identifiers. Preserve
names and user text; no case, width, space, or semantic normalization decides
identity. Sort order and complete Tag-membership sets are meaningful where the
model explicitly assigns them meaning. Derived thumbnails, caches, and computed
counts are not authoritative record differences. The public timestamp codec
must settle precision and round-trip behavior before release so an export of
unchanged data does not manufacture createdAt conflicts through formatting
loss. The temporary probe uses Foundation Date Codable values and does not
verify the proposed human-readable timestamp codec.

Use a record as the smallest ordinary choice: keep current or use file. Show
field differences, but do not invent an automatic field-by-field mixture or
three-way merge without a baseline. For an Item, this means its own fields and
explicit Tag assignment set, not replacing every child in its inverse arrays.
Each Mark, period, photo, and shared Tag has its own UUID and decision.

- An existing Item can retain its current note while new Mark UUIDs from the
  file are added, if the review shows and approves those separate effects.
- Applying a Mark correction keeps its UUID; it does not add another occurrence.
- Applying a period uses its boundaries and isOngoing together. Validate the
  resulting graph for multiple ongoing periods and the selected interval rules.
  Do not silently end an existing period to make an incoming one fit.
- Item-to-Tag assignments are compared as a set. Applying the file's explicit
  set can detach assignments, so show that difference. It does not delete Tags.
  Do not automatically union assignments and undo a deliberate removal.
- Applying a shared Tag's name affects every local Item using that UUID,
  including Items not in the file. Show this impact. Keeping its local name
  also means newly imported Items referring to it use that local Tag/name.
- Registration timestamps are retained, not reset to import time. If two
  versions disagree about createdAt, expose the conflict rather than using it
  to pick a winner. Choosing file content is an explicit correction/restoration.

createdAt is creation metadata, not last-modified evidence. exportedAt says
when the snapshot was made, not whether every contained record is newer.
Adding updatedAt alone would not solve clock skew, concurrent edits, missing
baselines, or the question of what the person wants. No new timestamp, revision,
source-device, or conflict-history column is recommended solely for import.

Invalid file structure is not a partially successful import. A valid file may
still conflict with the current graph; revise the selection or skip the affected
incoming records explicitly, then validate the complete approved result. Do not
silently drop children or references. Selecting additions must include or resolve
their required dependencies; skipping a parent cannot leave orphaned additions.

## Omitted Content, Images, and Deletion

File coverage must distinguish content actually supplied from deliberate
omission or unavailability. Missing required fields are invalid, not an invitation
to use model initializer defaults. Optional temporal values may explicitly be
unknown; applying such a value is a visible conflict choice, not omission.

An absent child row never deletes a locally stored Mark, period, or photo.
An omitted image never means erase its saved bytes. The public media representation
must distinguish an included authoritative image, an omitted image, and unavailable
source content. A redacted outward derivative must also be identifiable as such;
it is not automatically an authoritative replacement for the preserved attachment.
Exact wire keys and packaging remain the next format decision.

For a photo UUID already present, retain local image data when the file omits it,
even if caption or order changes are explicitly accepted. If the file supplies
original attachment bytes missing locally, show filling them as a proposed change.
If both provide different image bytes, treat it as a substantive conflict, never
as a reason to recompress or silently replace the local image. An explicitly
chosen authoritative file version can restore that image as part of the reviewed
record; ordinary image replacement outside import still uses a new ItemPhoto.

A new attachment whose media was deliberately omitted can preserve its UUID,
caption, order, and missing-media state after review; it must not claim to contain
a recoverable full image. Thumbnails are optional, rebuildable, and do not satisfy
that claim. Restored images are validated but not passed through the normal
resize/re-encode ingestion pipeline.

Deletion is outside ordinary snapshot import. Clearing a field or an explicit
Tag assignment set through a chosen conflicting record is different from inferring
record deletion from its absence. Whole-library replacement, deletion commands,
and durable trash/restore behavior need separate explicit contracts if added.

## Deliberate Copies Are a Separate Intent

Do not use automatic duplication as conflict resolution: it can double counted
Marks while appearing to preserve data. Recommend leaving an Import as Copy mode
out of the initial workflow unless a concrete use case requires it.

If later offered, it must explicitly remap UUIDs for the copied graph, including
owned children and references. Preserve sharing within the copied graph through
one old-to-new map, rather than duplicating a shared Tag for each Item. Do not
reuse local Tags by name. Define scope, metadata/provenance, external references,
and the expected multiplication on repeated copies before shipping that mode.
This is not a migration-free promise or an implemented feature.

## Public File Evolution and Older Exports

The accepted policy aligns the file's data schemaVersion with the
SwiftData version that wrote it, while keeping file decoding independent of
SchemaMigrationPlan execution. The previous recommendation for a wholly
independent single portable revision conflated two choices: version alignment
and implementation reuse. External usability does not itself require separate
data-schema numbering. The owner accepted this revised policy on October 24,
2026; the concrete wire format and its implementation remain pending.

| Version | Responsibility |
| --- | --- |
| App release version | Product release identity; not a decoder selector |
| Shared schemaVersion | SwiftData model version and the data-schema version declared by exports from that model |
| File formatVersion | File container, envelope, and encoding conventions, including representation-only changes |

Use the actual current VersionedSchema.versionIdentifier as the source of the
exported schemaVersion, not a second manually maintained copy of the number.
Do not make import create a temporary database solely to reuse migration stages.
For each published schema transition, specify the preservation rules once:
identities, meaning of missing data, precision, units, ownership, and any new
record mapping. Both the store migration and the file adapter implement those
rules with appropriate mechanisms.

Share pure value-conversion functions when they contain real common logic.
For straightforward renames or optional additions, SwiftData may already handle
the store change, while the historical Decodable type and mapping handle the
file. Do not force common model types, duplicate native migration machinery,
or build a generic migration framework just to avoid a small explicit adapter.
Test the common semantic results as well as each path's distinct behavior.

The two file fields distinguish different changes:

- A real storage/model version change also changes exported schemaVersion,
  even if the exported values happen to be identical. Register support for that
  new exported version; reuse an existing decoder where the representation
  really is unchanged. Older apps may reject it. Accept this coupling cost.
- A representation-only change, such as JSON key encoding or package layout,
  changes formatVersion without manufacturing a SwiftData model revision.
- A change to stored data meaning and file representation may change both.
  Never alter a published version pair's interpretation in place.

Read support is defined for actually published (formatVersion, schemaVersion)
pairs, not every possible Cartesian combination. Every exported model version
must have an explicit file reader and coverage of the schema transitions to the
current import candidate. This detects a missing file adapter when store schemas
evolve; it does not promise support for schemas that never exported a file.
The concrete first revisions, extension, and package layout remain to be chosen;
examples called F1/F2 do not renumber the existing development v2/v3 files.

The October 25 [concrete file-format proposal](export-file-format-design.md)
now recommends the first version pair, a consistent `.stally` package with
auxiliary JSON sharing, explicit media states and integrity metadata,
millisecond registration precision, and development-file retirement.
These are engineering recommendations awaiting owner review, not changes to
the accepted identity policy or the implemented codecs.

An app 2.0 using storage schema S2 can read an export declaring schema S1:

1. Validate the format identifier and supported format/schema version pair.
2. Decode the historical representation into ordinary Foundation value types.
3. Apply the S1-to-current semantic mapping, preserving field availability.
4. Validate identities and relationships, then use the same UUID conflict review.
5. Save only approved differences into the already-current SwiftData store.

Do not rewrite the original file, swap the live store for an old store, or
assume SwiftData migrations automatically decode JSON. Apple's
[ModelContainer migrationPlan][migration-plan] describes store-schema evolution.
An explicit file reader is a separate application responsibility.

Recommend keeping a reader for every publicly released Stally format as the app
evolves. Export writes the current format; newer apps retain older readers,
including skipped-version paths. Frozen means historical field meanings, date
units, requiredness, and defaults are not silently changed to match today's
model initializer. Correct bugs with regression evidence without reinterpreting
past facts. Current development v2/v3 compatibility remains an explicit pre-release
transition choice; it is not erased or promised by the new versioning proposal.

Unknown future file revisions must fail before mutation with a clear update
message. An older unsupported format and a malformed file should not be described
as the same error. Do not partially decode known fields from an unknown revision
and report a successful import after discarding facts. No downgrade writer or
arbitrary future-format forward compatibility is promised.

Version changes are driven by meaning, not just whether JSON still decodes.
Changes to ownership, date interpretation, record identity, field units, image
coverage, or authoritative user fields require a new appropriate schema or format revision unless
the existing contract already defines their interpretation. Only explicitly
ignorable non-authoritative metadata can evolve without forcing a new reader.
Keep this simple rather than introducing a capability-negotiation framework.

### Old Missing Fields Are Not New Empty Values

A hypothetical future model could add an optional rating. An older export has
no rating field because the concept did not exist in its contract. That is not
an instruction to clear a rating already entered in the new app.

- For an existing record, retain current values for fields the old file cannot
  express, even when the person selects Use File for its supplied fields.
- For a new record, use a documented compatibility default or an explicit unknown
  state. Do not invent a rating, date, source, or registration event as a fact.
- Explicit null in a format that defines that field is different from absence
  in a historical format. Applying explicit null may be a reviewed change.
- When no faithful representation exists, do not silently drop or fabricate
  information. Design a preservation path or explain the unsupported conversion
  before applying anything.

Carry this availability in the transient decoded candidate or revision adapter;
it does not require per-field provenance columns in the live model. A version
adapter must not fill absent fields with current defaults and then present the
result as a complete old record. Similarly, absence of a record kind from an
old format cannot authorize deletion of that kind from the current store.

Preserve existing UUIDs, names, registration metadata, date precision, and
relationships while adapting versions. If a future schema split needs newly
represented child identities, design stable repeat-import mapping as part of
that change; never create random child UUIDs on every decode of the same old
file. Preserve available source facts rather than inferring new user choices.
Share a pure semantic conversion with store migration where useful, without
coupling portable decoding to a temporary database merely to reuse machinery.

### Sibling Comparison and Chosen Tradeoff

Read-only source and design review found two different approaches:

- Incomes' Designs/Architecture/data-import-export.md and IncomesFileCodec keep
  portable versions independent of storage. Frozen V2/V3 payload readers route
  older values into the current representation. IncomesFileVersionTests reads
  a committed V2 fixture and verifies the V3 conversion. Its direct value-type decoding is useful independently of its choice to
  number files separately from storage.
- Cookle's ADR 0012 binds schemaVersion to the SwiftData schema and separately
  versions the package envelope. Its documented future V2 path constructs a
  temporary V1 store, migrates it, and extracts a current archive so migration
  stages own reshaping. The inspected implementation currently reads schema V1;
  its tests check that declared readers cover migration-plan schemas. The future
  V1-to-V2 temporary-store path is documented, not demonstrated by this review.

Cookle's version alignment and its proposed temporary-store execution are
separable decisions. Stally can adopt aligned data-schema numbering while using
Foundation value adapters, preserving one shared semantic evolution policy
without the temporary-store cost. Incomes demonstrates the latter decoding
style. The recommendation combines these independently justified choices;
neither sibling's complete implementation is authoritative and Apple does not
mandate this numbering policy.

The inspected checkout revisions were Incomes
b05ff045a2e590e2ff98a76738bebde576db2d5e and Cookle
3a880c2f604de1596aec18c6aa46c7b410316964. Their code, tests, and design files were
read, not modified or executed. Existing sibling format-identifier exceptions
are app-specific history, not precedent to break Stally's future public files.

### Release Acceptance for Compatibility

Retain synthetic fixtures produced by each actual public writer and do not
regenerate old fixtures with the newest encoder. Before a new release, verify
all published format/schema pairs against the new app, not only the newest
file version. Include UUID continuity, explicit/absent values, old files applied to
already-edited current records, repeated import, relationships, media omission,
and unsupported-version rejection without mutation. Keep actual historical
store migration tests separate; passing one path does not prove the other.

A small Foundation-only experiment compared illustrative F1/F2 payloads, including
a hypothetical newly introduced nullable rating. Fifteen assertions passed on
macOS: preserved UUID and leading-space spelling, deterministic conversion,
old-field absence retaining an existing value, explicit null remaining distinct,
and rejection of unsupported/malformed headers and missing required F2 data.
It resides at /private/tmp/stally-file-version-review. This validates the narrow
Decodable/availability technique; its illustrative single revision is not a
test of the newly proposed two-field header. It is not a frozen Stally format,
a SwiftData migration, an iOS runtime check, or an implementation of future
model changes.

## Apple-Native Implementation Boundary

Use native fileImporter/fileExporter and a typed portable representation with
Foundation Codable; keep file representation separate from SwiftData models.
Apple's [file importer][file-importer] documents security-scoped access. The current
Stally file adapter already coordinates a bounded read into immutable bytes;
retain that capability while reviewing format limits separately.

The application still owns the meaning of conflicts. SwiftData does not know
whether an older file is a recovery source or stale information. The recommended
implementation is a finite reviewed operation, not custom continuous reconciliation:

1. Read a bounded immutable request, release provider access, decode, and validate.
2. Compare with local facts and build an immutable preview of additions,
   unchanged records, conflicts, omissions, and affected relationships.
3. Let the person exclude additions and choose file values for specific conflicts;
   the default keeps current values and must be visible in the summary.
4. Re-fetch and revalidate the affected records/dependencies immediately before
   applying the exact approved choices. Observed relevant changes invalidate
   stale approval. Do not apply newly discovered conflicts under old approval.
5. Apply only differences in an operation-owned ModelContext with autosave off.
   Validate the resulting graph and perform one explicit save for the bounded
   operation; discard pending changes on failure or cancellation.

Apple documents [save][save] and [rollback][rollback] for pending context changes.
Use a context without unrelated editor work. Do not interpret rollback as undoing
an earlier save, an external file change, or a cloud transfer. The complete import
must fit the eventual validated limits; do not silently switch to partially saved
batches for an oversized request. Those limits need representative media testing.

The check-and-save sequence is not a cross-context or distributed transaction.
Serialize in-app import operations, account for other editors, and refresh review
when relevant changes are observed. Native sync can still race or arrive later.
Two offline devices importing the same absent UUID can create duplicate physical
rows because [native CloudKit uniqueness is not guaranteed][sync]. Local replay
checks do not prove multi-device deduplication. Do not add a custom sync engine
to claim otherwise; test and define that remaining lifecycle boundary separately.

## Verification and Limits

The current code was inspected independently of sibling implementations. Its
review-before-apply approach and failure handling are useful. Its same-day Mark
deduplication, silent retention of conflicting metadata, and destructive replace
mode are not adopted as the new product contract. Existing v2/v3 files and codecs
are unchanged; their development compatibility remains a separate transition
choice before release.

An isolated probe on macOS 27.2 / Swift 6.4.2 used the complete five-model schema
with CloudKit disabled and exercised Item/ItemMark values and relationships. It
passed 26 assertions across five fresh processes: seed, policy/application,
replay, rollback, and final reopen. It covered:

- UUID/creation-metadata preservation through a Codable round trip.
- Unchanged replay, conservative conflict choices, and explicit file corrections.
- Separate same-name Item UUIDs and separate same-day Mark UUIDs.
- No deletion inferred from absence, and restoring an absent identity.
- Duplicate-file-ID, unresolved-parent, changed-owner, and stale-review rejection.
- Read-only review, persisted approved changes, and rollback of unsaved updates
  and insertions followed by a clean reopen.

The first replay probe found that unconditionally assigning equal values left
pending SwiftData changes. After applying only differences, replay left no
pending changes. The final probe also compiled for iOS Simulator. Source and logs
are outside the repository at /private/tmp/stally-import-contract.

This is a small design probe, not the production importer or full portable codec.
It does not exercise every stored Item field, Tag-assignment conflicts, period
validation, omitted/redacted images, save-failure injection, limits, Files UI,
iOS runtime, or real CloudKit concurrency. Those remain implementation acceptance
checks. No personal photos were used. No new stored fields are needed for the
proposed ordinary identity-preserving workflow; consolidation may still reveal
separate requirements before the final schema freeze.

[file-importer]: https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)
[save]: https://developer.apple.com/documentation/swiftdata/modelcontext/save()
[rollback]: https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()
[sync]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices

[migration-plan]: https://developer.apple.com/documentation/swiftdata/modelcontainer/migrationplan
