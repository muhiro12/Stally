# Core Record Design

## Status and Scope

Recorded on October 22, 2026. Product decisions below come from the owner's
current design discussion. The owner confirmed the three base models and their
exact names for version 1.0: `Item`, `ItemMark`, and `ItemPeriod`. The property
tables remain engineering recommendations, not an implemented schema or owner
approval of attribute names, types, relationships, or deletion rules.

Stally has no released or beta users. Breaking development-model and file-format
changes are acceptable. Preserve actual development data until an explicit
implementation chooses its transfer or retirement; this document performs no
reset, migration, CloudKit deployment, or entitlement change.

This is the current direction for the core redesign. Where it differs from
older documents, those documents describe the implemented baseline or earlier
intent. In particular, one-Mark-per-day, history-free disabled recording, and
mandatory retention of development formats are not constraints on this design.

## Confirmed Product Decisions

- Version 1.0 uses three base persisted models: `Item`, `ItemMark`, and
  `ItemPeriod`. These type names are decided, not naming candidates. `ItemMark`
  and `ItemPeriod` represent history belonging to an Item; their model status
  does not introduce a generic event or period system for unrelated domains.
- An Item is a subject the person chooses to treat as one continuing record.
  It can represent an individual object, a repeatedly purchased product, or a
  place. Categories do not decide identity or ownership semantics.
- Classification is user-defined. App-provided examples or starter samples
  are acceptable; a fixed vocabulary or mandatory built-in category picker is
  not. Single classification versus multiple tags remains undecided.
- Multiple Marks on the same day must be supported. Stored history and the
  calendar's visual intensity are separate. People can choose how to see it;
  recording once per day must not look like inadequate participation.
- Stopping new Marks preserves earlier history. Resuming continues that history.
- Putting a record out of everyday view and no longer having or using its
  subject are different intentions. Neither the word Archive nor a fixed
  number of state axes is prescribed.
- Favorites belong in the design comparison. The exact stored representation
  and first-release control are recommendations below, not an earlier decision.
- Relationship start knowledge can be unknown, a year, a month, or an exact
  day. Creation time and the first Mark must not fabricate that knowledge.
- Consider foreseeable evolution now, especially facts that cannot be recovered
  later. Empty speculative fields are not a substitute for that analysis.
- Export primarily enables use of the collection outside Stally, including AI
  analysis. Import complements it; an export may also serve as a backup.
  Ordinary users do not need an AI tutorial to use these actions.
- Prefer native Apple persistence and proportionate synchronization effort.
  The owner currently intends cloud integration to be paid; the existing app
  implements free sync. The monetization boundary needs separate resolution
  against App Review guidance before an entitlement gate is implemented.
- Record consequential decisions as they are made. Distinguish confirmed
  product intent, engineering recommendations, and completed implementation.

## Identity and Independent State

Keep `Item`. `Possession` implies ownership and `Product` implies a commercial
product; neither covers the chosen meaning. A generic `Entity` loses useful
domain language. A UUID identifies the person's record, not a SKU or a physical
object whose identity the app claims to verify.

A replacement pair of shoes can become another Item or continue the same Item.
No required individual-versus-series selector, automatic category rule, or
replacement graph is needed. A future explicit link between Items can add
context without changing existing identities.

The recommended representation separates four concerns because their valid
combinations matter, not because four switches must appear in the interface:

| Concern | Recommended representation | Does not imply |
| --- | --- | --- |
| Everyday visibility | `Item.isHidden` | Disposal or the end of a period |
| Personal preference | `Item.isFavorite` | Visibility or current possession |
| New Mark capture | `Item.isMarkRecordingEnabled` | Whether history exists |
| Relationship periods | Owned `ItemPeriod` records | Visibility or Mark count |

`isHidden` means excluded from ordinary lists and proactive Review suggestions.
It is not a security or privacy boundary. A deliberate hidden-items view and
direct identity resolution retain access. A favorite can be hidden; favorite
filtering must still respect the selected visibility scope. Showing an Item
again does not alter its favorite flag, recording preference, or periods.

Favoriting records personal preference, not a calculated usage rank or a pinned
position. There is no speculative favorite timestamp or ordering column.
The UI may offer a convenient combined action, but it must say which facts it
changes. No single `active/archived/disposed/favorite` enum can express these
combinations. Hide/Show and Archive/Unarchive remain wording candidates;
neither the user-facing term nor the persisted visibility name is confirmed.

## Mark Facts and Calendar Presentation

Use the confirmed `ItemMark` model for each deliberate recording action.
Keep the established domain noun rather than introducing a generic
activity/event framework.
Each Mark stores identity, its chosen local day, its registration instant,
and its owning Item. The chosen day survives travel. Registration time does
not claim to be the instant the subject was used, especially for backdating.

Counts and active-day counts are different readings. Three Marks on one day
mean three recordings and one active day. The stored model has no daily total,
streak, intensity, rank, target, or inferred duration. Reconstruct these from
Marks. Correcting a day preserves that Mark's identity and registration time.
Undo targets a particular Mark. Deleting all Marks on a day is a separate
action.

Prefer two presentation modes, with the final settings surface designed later:

- Presence: zero versus one-or-more, using one positive intensity. Recommended
  initial default; every recorded day receives the same visual recognition.
- Frequency: intensity reflects the count within a clearly stated scale and
  scope. A collection whose positive days all contain one Mark should still
  have a useful positive color. Show counts and a legend; do not imply that
  lighter cells represent failure or that differently scaled charts compare.

Changing presentation never rewrites history or disables multiple recording.
An ordinary device preference is sufficient initially; no palette, threshold,
or heatmap mode needs a field on every Item. Item-specific overrides can be
added later without reconstructing missing historical facts.

Pausing new capture preserves readable, exportable, countable history and
explicit corrections to that history. Resuming does not create catch-up Marks.
Hidden Items do not receive routine capture prompts, but hiding does not rewrite
the independent recording preference. App Intents must use the same eligibility
rules and deliberate correction paths as the app.

## Periods: Keep Reopening History Without Splitting Identity

The selected structure uses owned `ItemPeriod` models, rather than one
overwritten start/end pair or requiring a new Item on every return.
A person may still choose a new Item.
This preserves their choice of identity while retaining a closed period when
the same subject returns. A single pair cannot retain both periods; requiring
separate Items fragments Marks, favorites, links, and the continuous record.

Use a SwiftData relationship, not a Codable array stored in one attribute.
Periods have separate identities and can be queried and edited independently.
An array-valued relationship does not promise ordering; derive display order
from date knowledge, with a deterministic tie-breaker for presentation only.

A period has optional partial start/end knowledge and an explicit `isOngoing`
flag. An ended period with an unknown end is representable: nil end must not
mean ongoing. No periods means the relationship has not been described; it
must not mean the person never had the subject. Do not create an implicit
purchase, start date, or period when an Item is created.

Recommended operation semantics:

- End a period: retain its start and identity; set it ended and record only
  the end knowledge the person supplies. Ending today is an explicit action.
- Resume a relationship: retain ended periods and add an ongoing period.
  Correcting an accidental end edits the existing period instead.
- Hide/show, favorite/unfavorite, or pause/resume Marks: change no periods.
- Delete a period: explicitly remove that period knowledge, not its Item or
  Marks. Marks are owned by the Item, not assigned to periods.

Normally allow at most one ongoing period through local Operations. Reject
definitely reversed boundaries and definitely overlapping entered periods;
partial-date uncertainty must remain visible instead of acquiring invented
days. Preserve conflicting or incompletely synchronized periods for review;
do not silently choose a winner or sum overlapping intervals twice.

Elapsed readings must distinguish time since an initial start from time within
recorded periods. Exclude known gaps from the latter. Unknown boundaries or
overlap may prevent an exact duration; retain precision and show an approximate
or unavailable reading. Do not turn missing dates into zero duration. The
calculation and display specification belongs in the period implementation.

## Recommended Persisted Names and Types

The three model type names are confirmed. The proposed attribute names, types,
defaults, relationships, and deletion rules below still need design review
and validation in a bounded implementation prototype. This decision does not
promote a CloudKit schema or change the existing physical schema.

### Item

| Stored property | Type / initial value | Meaning |
| --- | --- | --- |
| `uuid` | `UUID`, generated once | Portable record identity |
| `name` | `String`, empty storage default | Required nonblank user name |
| Classification | Representation pending | User-defined, never a fixed vocabulary |
| `note` | `String`, empty | Optional user context |
| `photoData` | `Data?`, nil, external storage | Existing single-photo scope |
| `createdAt` | `Date`, creation instant | Registration, not relationship start |
| `isHidden` | `Bool`, false | Exclude from everyday presentation |
| `isFavorite` | `Bool`, false | Explicit personal preference |
| `isMarkRecordingEnabled` | `Bool`, true | Permit new deliberate recordings |
| `marks` | `[ItemMark]?` | Owned recording facts |
| `periods` | `[ItemPeriod]?` | Owned relationship knowledge |

The existing `categoryRawValue` and fixed category values are an implemented
baseline that does not match the confirmed direction. Select the intended
single-category or multiple-tag workflow before choosing its representation.
Do not expand photos solely to make this table more general.
The visibility intent does not itself require an `archivedAt` timestamp.
The `isHidden` name remains provisional. Prefer a recording preference over a
record kind: enabled/disabled is a mutable preference, not whether history may
exist.

#### Item Attribute Review

The following recommendations refine the field table. Only the model names
have been confirmed; this review does not mark the attributes as approved or
change application behavior.

- `uuid`: generate once when creating a new record, preserve it through edits,
  hide/show, export, and restoration. Duplicating an Item creates a new UUID.
  Equal names do not establish identity. Keep the name distinct from the
  framework's store-scoped `persistentModelID`; declaring an application-owned
  `id` is not inherently wrong, but `uuid` makes the two roles clear here.
- `name`: use a nonoptional String. Require a nonblank value at creation/edit
  boundaries and allow duplicate names. A schema default is not a valid
  user-confirmed name; temporarily incomplete synced content must not be
  deleted or assigned a fabricated name. A display placeholder is not stored.
- `note`: use a nonoptional String with an empty default. No note and an empty
  note have the same domain meaning. Keep ordinary text and intentional line
  breaks; do not add rich-text serialization without a selected workflow.
- `createdAt`: the instant this Item was first registered, never purchase,
  relationship start, first Mark, or last import time. Preserve it during
  restoration. It supports registration ordering and collection-age readings.
- `photoData`: retain an optional single representative photo, with nil meaning
  no photo. Store prepared bytes with SwiftData external storage, not a Photos
  library identifier or a temporary file URL. External storage remains part of
  the persistent store's recovery boundary. A representative photo is not a
  photo timeline; multiple-photo history needs a separate product decision.
- `isHidden`: a synced Item-level visibility choice, default false. Exclude it
  from routine lists and proactive suggestions; retain deliberate access.
  This does not change recording preference, favorites, or relationship facts.
- `isFavorite`: a synced Item-level preference, default false. Do not derive it
  from Mark counts. It is neither a pinned position nor a ranking score.
- `isMarkRecordingEnabled`: default true; controls new deliberate capture from
  app and system surfaces. Existing Marks remain readable and included in
  historical readings for the selected Item scope. Explicit corrections and
  restoration of earlier facts remain possible while capture is paused.
- `marks` and `periods`: optional stored to-many relationships with explicit
  inverses and Item-to-child cascade deletion. Their Swift array shape does not
  promise ordered storage. Read interfaces may expose empty collections where
  appropriate, but must tolerate partial synchronization without deleting data
  or claiming the remote history is complete.

Do not persist `totalMarks`, active-day count, last marked day, elapsed time,
heatmap intensity, or current ownership as additional Item truth. Derive the
first five from history and display settings; relationship knowledge belongs
to periods and may be incomplete. Do not keep Item-level start/end copies.

Do not add `updatedAt` solely as a conventional audit field. Cookle currently
updates recipe modification timestamps, but that does not define which Stally
actions should count as an Item edit. Add it if a selected edit-history,
recency, or interchange use requires a precisely defined last-edit instant.
Starting to capture it later cannot recover earlier edit times; that is the
explicit tradeoff, and one timestamp would not preserve a full edit history.
It would not be a substitute for CloudKit conflict handling.

The current source review also identifies consumers that must change with the
proposed schema: Insights filters out `recordsMarks == false` Items, so merely
relaxing the write guard would still hide paused history. Review uses
`archivedAt` for recovery ordering; replacing it with visibility requires an
explicit Review behavior change, not a mechanical field rename. Names, photos,
creation dates, and category values also cross the portable-file boundary.

Apple distinguishes a model's [store identity][persistent-id] from application
identity and documents [external storage][external-storage] as binary data
adjacent to the model store. These support the representation choices; the
field meanings and defaults above are Stally-specific recommendations.

#### Attribute Alternatives and Sibling-App Evidence

The October 22 source comparison found no record-specific UUID on Incomes Item
or Cookle Recipe. Incomes `repeatID` identifies a repeat series instead. Both
apps use SwiftData identifiers in their persistence-facing APIs. Cookle's
archive code maps those identifiers to file references and reconstructs
relationships during restoration. Those designs do not establish a universal
requirement to add UUIDs to every SwiftData model.

Stally's reason to keep application-owned UUIDs is continuity across exports
and imports, including identifying individual Marks without matching names or
days. Apple's [history guidance][history-identity] distinguishes local store
identity from an attribute usable across devices or services. Native CloudKit
mirroring does not itself require an app UUID. UUIDs also do not resolve merge
conflicts or prevent duplicate imports without defined operation semantics.

`createdAt`, `createdTimestamp` (used by Cookle), and `creationDate` are viable
names. Apple does not prescribe `createdAt`. The recommendation uses it for a
concise registration instant, consistently with `recordedAt` on a Mark. The
fact supports registration ordering and cannot be recovered reliably from
relationship dates or Marks. Its meaning matters more than its spelling;
the spelling is still under review.

For photos, the proposed single-image field stores an app-owned copy of image
bytes. Deleting the source photo after successful ingestion does not remove
that copy. External storage delegates the binary representation to SwiftData;
it is not a reference to iCloud Photos or a user-managed file path. Cookle
instead has a Photo asset model and ordered PhotoObject relationships for
multiple, reusable photos. A representative image and a photo history are
different requirements; the latter would justify a separate photo model.

Current Stally prepares orientation-normalized, metadata-stripped JPEGs with a
1,600-pixel longest side and a 2 MiB encoded-size ceiling. It flattens alpha
onto white and does not preserve the original. These are existing policies,
not newly approved 1.0 requirements. Decide single versus multiple images,
original retention, transparency, and quality before freezing photo storage.
Export packaging remains a separate contract choice.

`isHidden` emphasizes presentation; `isArchived` emphasizes putting a record
aside while retaining it. `isVisible` expresses the inverse, and a `visibility`
enum can make the presentation scope explicit. None automatically defines
ownership or period ending. Choose the name with the intended action wording.

Independent two-state facts can be separate Bools: hidden, favorite, and
recording-enabled have eight meaningful combinations. Mutually exclusive
states of one concern should instead use an enum when that clarifies the
domain. A domain enum does not require a different physical representation:
current Stally already wraps its persisted `recordsMarks` Bool in an
`ItemMarkPolicy` enum. Keep one stored source of truth, not an independently
editable Bool and enum for the same fact. If a selected workflow needs a
third recording policy, compare explicit raw-value storage then; do not add
speculative states solely to avoid Bools.

### ItemMark

| Stored property | Type / initial value | Meaning |
| --- | --- | --- |
| `uuid` | `UUID`, generated once per action | Mark and retry identity |
| `dayKey` | `Int`, valid storage default | Existing Gregorian YYYYMMDD encoding |
| `recordedAt` | `Date`, registration instant | When this fact entered Stally |
| `item` | `Item?` | Owning subject |

Use validated `LocalDay` at public operation boundaries; the storage default
never supplies a missing day during import. `recordedAt` deliberately avoids
claiming an exact occurrence time. Do not store an incrementing per-day counter
that two offline devices must reconcile. No unique constraint on UUID or day.

### ItemPeriod

| Stored property | Type / initial value | Meaning |
| --- | --- | --- |
| `uuid` | `UUID`, generated once | Period identity through corrections |
| `startDateRawValue` | `String?`, nil | Partial Gregorian start knowledge |
| `endDateRawValue` | `String?`, nil | Partial Gregorian end knowledge |
| `isOngoing` | `Bool`, true | Known continuation versus known ending |
| `item` | `Item?` | Owning subject |

Use `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`, with a shared validated partial-date
value type at operation boundaries. Ongoing implies no entered end. Ended
with nil end means the end date is unknown. The flag is needed for that case,
not as a second independently editable copy of a known end date.

For both child models, declare an explicit inverse from the Item relationship.
Item deletion cascades to its Marks and periods; deleting a child must never
delete the Item (use the child-to-parent nullify rule). CloudKit requires
optional relationships and compatible
defaults. A missing parent during sync is not immediate proof of an orphan to
delete. No `.unique`, `.deny`, polymorphic subject hierarchy, or opaque period
blob is proposed.

## Native Synchronization and Cost Boundary

Use one local SwiftData schema and Apple's automatic private CloudKit mirroring
when enabled. The domain remains useful offline. Avoid a custom synchronization
engine, distributed counter, general operation log, or background reconciliation
service without a reproduced need that the standard stack cannot address.

Independent Marks are separate inserts. Locally retrying a still-known action
reuses its UUID and checks its saved result; a second user action creates a new
UUID. Repeated import matches UUIDs, never day alone. A UUID and a fetch check
do not guarantee distributed exactly-once execution. Do not invent such a
promise for App Intents or two independent taps that happen to describe the
same real-world use. Native sync may be delayed and relationships may arrive
separately. Preserve facts and avoid premature cleanup during partial arrival.

Metadata edits and concurrent period changes remain subject to native conflict
handling and need bounded device tests. Prefer tolerating incomplete readings
over an elaborate automatic repair protocol. Initial evidence must cover two
offline additions, replay/import, cancellation, delete-versus-add, and two
simultaneous resumes. These tests have not been run for this proposal.

The owner's paid-cloud intent changes the earlier product direction, but not
the existing implementation. Apple's App Review Guideline 4.10 prohibits
monetizing built-in capabilities and names iCloud storage. This does not by
itself settle every paid app feature using CloudKit. Define the app-owned paid
value and review that boundary before gating sync. A subscription change must
not delete local records or silently select a different empty store.

## Export and Import Direction

Use simple Export and Import wording; explain scope or replacement consequences
where needed. No mandatory AI explanation, provider integration, or embedded
prompt is part of this design.

Design an explicit public representation independently of SwiftData/Codable
defaults. Prefer readable JSON keys such as `category`, `day`, `recordedAt`,
`start`, and `end`. Use RFC 3339 UTC timestamps for instants and the explicit
partial-date grammar for date knowledge. Specify fractional precision and
round-trip expectations before freezing the codec; do not claim arbitrary
binary Date values survive an unspecified string formatter exactly.

Export individual Marks and periods so outside tools can derive different
readings. Include favorite, visibility, and recording state in a full collection
export. Presentation preferences are not historical facts. A lighter export
may omit photos, but must identify its scope; importing it must not silently
erase existing photos. Select media packaging and full-versus-light export
behavior in the portable-contract slice. Do not finalize a new extension or
file version here. Development v2/v3 support is a deliberate decision, not
proof of published compatibility obligations.

## Evidence and Alternatives

The owner's weighting is approximately Apple guidance/samples 40%, Incomes and
Cookle 20%, engineering judgment 20%, iOS practitioner experience 10%, and
general software principles 10%. These are judgment priorities, not a numerical
vote or a claim that the proposed product model is prescribed by Apple.

- [Apple's schema session][schema] demonstrates model, relationship, deletion,
  and versioned migration choices. Its SampleTrips excerpts were reviewed;
  no downloaded sample project or new model prototype was executed here.
- [Apple's sync requirements][sync] establish optional relationships, the lack
  of uniqueness guarantees, and asynchronous related changes. The period and
  Mark recommendations are Stally-specific conclusions within those limits.
- [CloudKit schema evolution][cloud-schema] separates local migrations from
  production field identity. [Swift naming guidance][naming] prioritizes
  clarity at use sites, not the shortest possible names.
- Current local Incomes and Cookle architecture guides retain tested domain
  Operations in their libraries and platform/UI adapters in app targets.
  Stally can retain that boundary without copying their domain schemas.
- [Fatbobman's practitioner investigation][practitioner] is supplementary
  experience about CloudKit relationship constraints. It is not an Apple
  guarantee or a reason to adopt a custom synchronization stack.
- [RFC 3339][timestamps] supplies an interoperable instant representation.
  Separating source facts from derived views and retaining periods instead of
  overwriting them are engineering judgments applied to the chosen workflows.

The recommended extra period entity has a concrete benefit: preserving
multiple relationships under user-selected Item identity. A one-pair model is
smaller but loses that history. A generic event store could express everything
but adds reconstruction, correction, and sync complexity with no selected need.
Multiple Mark rows cost more storage than a daily counter, but avoid shared
counter updates and preserve individual undo, import identity, and future
readings. Confirm useful scale before publication; do not optimize by losing
facts without an explicit product tradeoff.

## Implementation Order and Required Evidence

1. Prototype the three models, generated schema, validated date values, and
   Operations on synthetic stores. Verify all state combinations and deletion
   directions. Keep actual production promotion out of this step.
2. Implement multiple Marks, capture pause/resume, corrections, counts, and
   stable replay/import identity. Test both presentation modes against the same
   unchanged history, including all-positive-counts-equal-to-one collections.
3. Implement period end/resume/correction and uncertain readings. Test unknown
   ends, approximate boundaries, gaps, overlaps, and hide/favorite independence.
4. Select the development-store transition and public export/import contract.
   Verify disk reopen, external photos, round trips, rejected imports, and
   source preservation after failures. Update the current baseline documents
   when the behavior actually changes.
5. Build the app adapters and perform bounded real-device CloudKit tests before
   freezing/publishing identifiers. Confirm the live production-schema state;
   an unreleased app alone does not prove that no schema was promoted.

Outstanding choices include the proposed attributes, types, relationships,
deletion rules, export media/precision, heatmap scale and settings placement,
localized action wording, the paid-feature boundary, and results of the native
schema/sync prototype. Future decisions should update this document rather
than treating chat proposals as completed implementation.

[schema]: https://developer.apple.com/videos/play/wwdc2023/10195/
[sync]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
[cloud-schema]: https://developer.apple.com/videos/play/wwdc2022/10120/
[naming]: https://www.swift.org/documentation/api-design-guidelines/
[practitioner]: https://fatbobman.com/en/posts/coredatawithcloudkit-2/
[timestamps]: https://www.rfc-editor.org/info/rfc3339/

The paid-feature boundary references [App Review Guideline 4.10][review].

[review]: https://developer.apple.com/app-store/review/guidelines/#monetizing-built-in-capabilities
[persistent-id]: https://developer.apple.com/documentation/swiftdata/persistentidentifier
[external-storage]: https://developer.apple.com/documentation/swiftdata/schema/attribute/option/externalstorage
[history-identity]: https://developer.apple.com/documentation/swiftdata/fetching-and-filtering-time-based-model-changes
