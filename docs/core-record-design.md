# Core Record Design

## Status and Scope

Recorded on October 22, 2026; updated on October 24, 2026. The owner confirmed
three base model names for version 1.0: `Item`, `ItemMark`, and `ItemPeriod`.
The October 24 discussion also accepts application UUIDs, registration times,
multiple user-defined classifications, and multiple photos with captions.
The owner delegated naming and state representation to the stated evidence
priorities. Selected engineering decisions below exercise that delegation;
they are not an implemented or CloudKit-promoted schema. Other proposals and
prototype validation remain explicitly distinguished.

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
  not. An Item can have multiple classifications; classification is optional.
- Keep application-owned UUIDs and Item registration times. Attribute naming
  and state representation are delegated engineering decisions.
- Support multiple photos per Item and a caption for each photo. Cookle is
  useful evidence, not an architecture that must be copied or presumed best.
- Multiple Marks on the same day must be supported. Stored history and the
  calendar's visual intensity are separate. People can choose how to see it;
  recording once per day must not look like inadequate participation.
- Support backdated Marks, correcting a Mark's assigned day, and correcting
  a day's count upward or downward. These are ordinary editing operations.
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
  Build within the public platform capabilities and the no-custom-backend
  constraint. If an interaction needs extensive persistence workarounds,
  reconsider the interaction before designing a replacement sync mechanism.
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

The selected representation separates four concerns because their valid
combinations matter, not because four switches must appear in the interface:

| Concern | Selected representation | Does not imply |
| --- | --- | --- |
| Everyday organization | `Item.isArchived` | Disposal or the end of a period |
| Personal preference | `Item.isFavorite` | Visibility or current possession |
| New Mark capture | `Item.isMarkRecordingEnabled` | Whether history exists |
| Relationship periods | Owned `ItemPeriod` records | Visibility or Mark count |

`isArchived` means put aside from ordinary lists and proactive Review
suggestions while retaining the record. It is not a security or privacy
boundary. An explicit archive view and direct identity resolution retain
access. A favorite can be archived; favorite filtering still respects the
selected archive scope. Unarchiving does not alter the favorite flag,
recording preference, or periods.

Favoriting records personal preference, not a calculated usage rank or a pinned
position. There is no speculative favorite timestamp or ordering column.
The UI may offer a convenient combined action, but it must say which facts it
changes. No single `active/archived/disposed/favorite` enum can express these
combinations. Select Archive/Unarchive as the action concepts; final localized
labels remain a UI decision. Archiving never asserts that ownership ended.

## Mark Facts and Calendar Presentation

Use the confirmed `ItemMark` model for each deliberate recording action.
Keep the established domain noun rather than introducing a generic
activity/event framework.
Each Mark stores identity, its chosen local day with optional clock time,
its registration instant, and its owning Item. The chosen day survives travel.
Registration time does
not claim to be the instant the subject was used, especially for backdating.

Counts and active-day counts are different readings. Three Marks on one day
mean three recordings and one active day. The stored model has no daily total,
streak, intensity, rank, target, or inferred duration. Reconstruct these from
Marks. Correcting a day preserves that Mark's identity and registration time.
Undo targets a particular Mark. Deleting all Marks on a day is a separate
action.

### Date Meaning, Corrections, and Future Time Precision

The owner confirmed backdating, date correction, and count correction.
Apply these meanings independently of their eventual editing controls:

- Adding yesterday's Mark today assigns yesterday as its day and today as
  its registration instant.
- Moving a Mark from yesterday to the day before changes its assigned day,
  preserving its UUID and registration instant.
- Correcting three Marks to four adds one Mark; correcting three to two
  removes one existing Mark. A simple count editor can express these actions
  without exposing record identifiers. Do not replace history with a stored
  daily counter or promise an absolute total across concurrent offline edits.

The owner clarified that occurrence time is not unwanted or automatically
deferred. Replace the earlier day-only 1.0 recommendation with a design that
admits a required day and optional occurrence time. Supporting optional time
in 1.0 is a reasonable candidate, not inherently overengineering; exact stored
fields and the shipping interaction remain to be selected. Time-of-day
patterns, within-day ordering, and hours-since-use are possible benefits,
not confirmed requirements that justify an elaborate temporal subsystem.

Day-only records remain valid even after time capture is introduced. Precision
belongs to each Mark, so the same person or Item can mix records with and
without time. Capture preferences can supply defaults without rewriting old
Marks. Not retaining a time and hiding a retained time are different choices;
changing display must not erase data or claim that an unrecorded time exists.
An explicit "used now" action could capture the current time without manual
entry. An ordinary day-only or backdated action must not silently claim that
its registration instant was the occurrence instant.

Keep the selected day and registration instant semantically separate now.
If a later feature needs an occurrence instant, an optional attribute can
extend each independently identified Mark. Existing records retain unknown
occurrence time; neither midnight nor registration time supplies missing
evidence. This remains a viable extension path if time capture is deferred;
it is not a reason to exclude time from 1.0. It cannot recover historical times
that were never recorded. Before choosing fields, distinguish a local clock
reading from an absolute occurrence instant. An instant alone does not retain
the original time zone or local clock reading; choose the required meaning
before adding zone metadata or promising cross-zone elapsed-time analysis.

If time is supported, date correction must edit the occurrence consistently,
not leave a timestamp on the old day. A local date/time correction may retain
the entered clock time, subject to explicit zone interpretation and native
calendar validation. Count increases without supplied times add day-only
Marks. Count reductions must make the affected record clear when retained
times distinguish the records; do not silently discard an arbitrary timed
Mark. Registration identity and time survive these corrections.

Keep registration time as automatically captured record metadata, useful for
recent-entry ordering and understanding backdated imports or records. It is
not a required user-facing fact or an Apple-mandated field, nor a reliable
cross-device causal clock or a replacement for native synchronization.
Preserve it through edits and identity-preserving export/import. Select
`createdAt` for this creation meaning, replacing the earlier `recordedAt`
proposal and aligning the name with Item and ItemPhoto.

An additive field still changes the schema and export contract. Follow native
[SwiftData schema evolution][schema], verify saved-store migration, and check
CloudKit compatibility and older-file import behavior. This is a bounded
extension proposal, not a claim that an untested migration is automatic.

Foundation's [Date][absolute-date] represents an absolute instant, whereas
[DateComponents][date-components] expresses calendar components. For Stally,
the selected Mark day is a civil date, not an instant at local midnight.
Keep its Gregorian year, month, and day stable when the viewing time zone or
preferred calendar changes. Derive the default for a new Mark from the
device's current local day; a later time-zone change must not rebucket history.
Use native Calendar and DateComponents for conversion and calendar arithmetic,
with an explicit storage calendar. Do not calculate yesterday by subtracting
86,400 seconds or implement time-zone offset arithmetic by hand.

Select one `localDateTime: String` occurrence attribute following the
[October 24 runtime comparison](mark-temporal-schema-comparison.md).
Use Gregorian `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm`, with no stored time zone.
DateComponents remains an in-memory representation; native Calendar and
fixed-format parsing/formatting perform validation and conversion.
The earlier integer day key and day-string/minute-of-day candidates are
superseded. Do not add redundant Date, time-presence, or minute attributes.
This is a civil reading and does not identify a historical absolute instant.
A current-zone Date conversion is only contextual; it must not rewrite history
or silently normalize nonexistent local times. Initial time precision is
minutes. The comparison's seconds-form experiment is a possible extension,
not an initial accepted form.

A bounded probe verified disk reopen, queries, sorting, corrections, and native
calendar edge cases on macOS and iOS 27.2. CloudKit propagation, migration,
and app UI integration were not exercised. This decision does not establish
that a sibling app's use of Date is wrong without examining its intended
semantics and conversion paths.

This follows general date modeling rather than an Apple-specific exception.
For example, [PostgreSQL][sql-date-types] distinguishes date-only values,
local date/time values, and instants. Use a database's date-only type when
available and appropriate. Where the storage layer lacks that semantic type,
validated Gregorian `YYYY-MM-DD` text is an ordinary encoding option;
[SQLite documents date text][sqlite-dates]. Avoid ambiguous display strings
such as `10/24`. Text is not inherently immune to later incorrect conversion:
all readers must preserve the date-only meaning. Foundation Date does not
retain the original time zone, date-only precision, or selected calendar.
Native Calendar and DateComponents support the necessary conversions; they
do not make an instant interchangeable with a civil date or establish the
best SwiftData attribute layout. Do not access SwiftData's backing SQL store
directly to obtain date semantics.

### Calendar Presentation and Recording Availability

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
Archived Items do not receive routine capture prompts, but archiving does not
rewrite the independent recording preference. App Intents must use the same
eligibility rules and deliberate correction paths as the app.

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
- Archive/unarchive, favorite/unfavorite, or pause/resume Marks: change no
  periods.
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

The three base model names are confirmed. `uuid`, `createdAt`, `isArchived`,
and the independent Bool representation are selected below. `ItemPhoto` and
`Tag` extend the design for the clarified photo and classification needs; the
base-model decision was not a cap of three entities. Their field tables and
relationships are the selected engineering direction, subject to generated
schema, disk-store, and synchronization validation. Other existing field
proposals remain under review. No existing physical schema changes here.

### Item

| Stored property | Type / initial value | Meaning |
| --- | --- | --- |
| `uuid` | `UUID`, generated once | Portable record identity |
| `name` | `String`, empty storage default | Required nonblank user name |
| `tags` | `[Tag]?` | Optional multiple user-defined classifications |
| `note` | `String`, empty | Optional user context |
| `photos` | `[ItemPhoto]?` | Owned photos with individual captions and order |
| `createdAt` | `Date`, creation instant | Registration, not relationship start |
| `isArchived` | `Bool`, false | Put aside while retaining the record |
| `isFavorite` | `Bool`, false | Explicit personal preference |
| `isMarkRecordingEnabled` | `Bool`, true | Permit new deliberate recordings |
| `marks` | `[ItemMark]?` | Owned recording facts |
| `periods` | `[ItemPeriod]?` | Owned relationship knowledge |

The existing `categoryRawValue` and fixed category values are an implemented
baseline that does not match the confirmed direction. Tags and photo records
replace the fixed category and single-photo proposals. The archive intent does
not itself require an `archivedAt` timestamp. Recording is a mutable preference,
not a record kind that determines whether history may exist.

#### Item Attribute Review

The following definitions refine the field table. The status above distinguishes
accepted product facts, delegated selections, and remaining proposals. None
changes application behavior until implemented and verified.

- `uuid`: generate once when creating a new record, preserve it through edits,
  archive/unarchive, export, and restoration. Duplicating an Item creates a new
  UUID. Equal names do not establish identity. Keep the name distinct from the
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
- `photos`: own multiple `ItemPhoto` records, each with its image and caption.
  Use explicit ordering rather than the relationship array's incidental order.
- `tags`: share user-defined classifications with other Items. Removing a tag
  assignment changes neither the Item nor the Tag's other assignments.
- `isArchived`: a synced Item-level organization choice, default false. Exclude
  it from routine lists and proactive suggestions; retain deliberate access.
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
concise registration instant, consistently across Items, Marks, and photos. The
fact supports registration ordering and cannot be recovered reliably from
relationship dates or Marks. Select `createdAt` for the Item registration
instant. This is a Stally naming decision, not an Apple-mandated spelling.

Photos use app-owned image bytes. Deleting the source after successful
ingestion does not remove that copy. External storage delegates the binary
representation to SwiftData; it is not a reference to iCloud Photos or a
user-managed path. Cookle's Photo assets and ordered PhotoObject relationships
support shared image reuse. Stally selects one owned `ItemPhoto` per attachment:
the image, caption, and order have the same lifetime. It does not need shared
asset deletion or deduplication semantics to meet the current requirements.

Current Stally prepares orientation-normalized, metadata-stripped JPEGs with a
1,600-pixel longest side and a 2 MiB encoded-size ceiling. It flattens alpha
onto white and does not preserve the original. These are existing policies,
not approved 1.0 requirements. The new direction preserves the supported
representation supplied at ingestion and generates smaller display images
separately. This does not promise the Photos library's RAW original, edit
history, or Live Photo video. Supported formats, limits, metadata treatment,
and export packaging still need a media-contract decision and measurements;
do not silently inherit the JPEG-only, white-background conversion.

`isHidden` emphasizes presentation; `isArchived` emphasizes putting a record
aside while retaining it. `isVisible` expresses the inverse, and a `visibility`
enum can make the presentation scope explicit. None automatically defines
ownership or period ending. Select `isArchived`: the owner's intent is to put
a retained record aside, which is a durable collection-organizing action rather
than transient filtering. Keep `isFavorite` and `isMarkRecordingEnabled` as
independent Bools, along with the proposed period's `isOngoing`. Do not persist
an overlapping aggregate status enum.

Independent two-state facts can be separate Bools: archived, favorite, and
recording-enabled have eight meaningful combinations. Mutually exclusive
states of one concern should instead use an enum when that clarifies the
domain. A domain enum does not require a different physical representation:
current Stally already wraps its persisted `recordsMarks` Bool in an
`ItemMarkPolicy` enum. Keep one stored source of truth, not an independently
editable Bool and enum for the same fact. If a selected workflow needs a
third recording policy, compare explicit raw-value storage then; do not add
speculative states solely to avoid Bools.

### ItemPhoto

Use `ItemPhoto` for one photo attached to one Item. Like `ItemMark`, its name
expresses ownership rather than a reusable asset library. A caption describes
this photo in this Item's context; it does not belong to a globally shared
image asset. Ingesting the same image for another Item creates a separate
attachment with its own UUID and caption.

| Stored property | Type / initial value | Meaning |
| --- | --- | --- |
| `uuid` | `UUID`, generated once | Portable attachment identity |
| `imageData` | `Data?`, nil, external storage | App-owned image representation |
| `caption` | `String`, empty | Optional plain-text description |
| `sortOrder` | `Int`, zero | Explicit user-controlled display order |
| `createdAt` | `Date`, registration instant | When the attachment was created |
| `item` | `Item?` | Owning Item |

Item-to-photo deletion cascades; deleting a photo never deletes its Item.
Declare the inverse explicitly on one relationship end. Local confirmation
requires a decodable image, even though storage permits nil to tolerate
incomplete sync. Preserve captions and attachment identity while image data
is unavailable. A new import must distinguish deliberately omitted media from
invalid or missing required media; omission never silently erases saved bytes.

Sort by `sortOrder`, then UUID as a deterministic tie-breaker. Concurrent
reordering can produce ties; display every photo rather than dropping one or
running an automatic renumbering loop. Local reordering saves the intended
order together; native sync does not promise atomic remote arrival. Initially,
the first ordered photo is the cover, with no competing `isCover` flags.
Do not call attachment registration time the photo's shooting date or infer a
relationship start from it. A dated photo journal is a separate product scope.

Use image data from the selected source as the durable representation, with
derived thumbnails for lists and grids. Thumbnails are rebuildable caches,
not additional historical facts. Avoid decoding every full-sized image during
list rendering; choose cache placement and invalidation after a bounded
implementation measurement. Apple's [Wishlist code-along][wishlist] separates
image models and thumbnails from full-sized image data. This supports the
loading boundary, not a mandate for Stally's exact schema or image limits.

Splitting a shared Photo asset from each attachment could reduce repeated
bytes if cross-Item reuse becomes a significant workflow. It also introduces
shared lifetime, reference tracking, and edit propagation choices. Keep one
owned model now; an eventual asset layer can retain each ItemPhoto's UUID,
caption, and order while moving only its binary storage.

### Tag

Use `Tag` for a user-defined classification shared by multiple Items. Unlike
ItemPhoto, a Tag is not owned by one Item; `ItemTag` would suggest that it is
an assignment record. Direct many-to-many relationships are sufficient while
an assignment has no caption, date, or other independent facts.

| Stored property | Type / initial value | Meaning |
| --- | --- | --- |
| `uuid` | `UUID`, generated once | Portable classification identity |
| `name` | `String`, empty storage default | Required user-defined label |
| `items` | `[Item]?` | Items using this classification |

`Item.tags` and `Tag.items` have an explicit inverse and nullify deletion rules.
Deleting a Tag removes assignments but never Items. Deleting an Item never
deletes its Tags; an unused Tag remains available for reuse until explicitly
deleted. Renaming a Tag preserves its identity and updates the shared label.
An Item may have zero or many Tags. Tag assignment order has no domain meaning.

Reuse a selected existing Tag rather than copying its name into each Item.
Store neither a parallel string array nor a comma-separated label list.
Local creation should offer existing matching labels using a documented name
comparison rule. Do not impose a CloudKit-incompatible uniqueness constraint
or silently merge different UUIDs because their names match after sync.
Normalization, explicit duplicate consolidation, and matching rules remain
part of the Tag Operations design, without a custom synchronization engine.

Apple Notes demonstrates [multiple user-created tags][notes-tags] as a familiar
classification interaction. This is UX evidence, not evidence of its private
database schema. Incomes' Tag model is comparison material only. The independent
reason for a shared Tag entity is reusable identity and collection-wide rename
and removal, rather than separate label strings on every Item. Multiple labels
alone would not require an entity. Shared label management is a selected Stally
interaction, not an additional owner requirement or an Apple prescription.
Stally does not inherit finance-specific tag types or date tags.

### ItemMark

| Stored property | Type / initial value | Meaning |
| --- | --- | --- |
| `uuid` | `UUID`, generated once per action | Mark and retry identity |
| `localDateTime` | `String`, empty storage default | Gregorian day with optional local clock time |
| `createdAt` | `Date`, registration instant | When this fact entered Stally |
| `item` | `Item?` | Owning subject |

Use validated Gregorian date components at operation boundaries. Encode the
canonical day or minute-precision reading into `localDateTime`. The empty
storage default is not a valid Mark; do not use it to fabricate missing import
data. `createdAt` deliberately avoids claiming an occurrence instant. Do not
store an incrementing per-day counter
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

The owner clarified that library/Operations responsibilities and the shared
package strategy are deliberate architecture choices, not accidental sibling
precedent. Respect them unless a concrete correctness or platform-fit problem
is demonstrated. Independent technical validation does not require replacing
those boundaries or preferring different packages merely to be independent.

Treat the absence of an app-owned backend as a product constraint. Combine
supported OS capabilities to deliver the experience. If a requested guarantee
cannot be expressed naturally with SwiftData and CloudKit, first compare
simplifying the interaction, relaxing the guarantee with clear behavior, or
deferring the feature. Do not preserve every proposed feature by adding a
custom merge engine, repair daemon, distributed locking, or undocumented
store manipulation. Bounded validation and recoverable error handling remain
appropriate; an elaborate workaround requires a separate explicit decision.
Apple's apps are interaction references, not proof that their private internal
implementations are available through public third-party APIs.

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
defaults. Prefer readable JSON keys such as `tags`, `localDateTime`,
`createdAt`,
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

The owner clarified on October 24 that the Incomes/Cookle share primarily
represents system-wide architecture and operating philosophy: responsibility
boundaries, maintainability, and how the apps are developed and operated.
Their existing database schemas, persistence contracts, and uses of Apple APIs
are comparison material, not correctness authorities. They may reflect an
incomplete understanding at the time they were designed.

For technical foundations, establish correctness independently through current
official API documentation, relevant Apple samples, and verification against
the supported runtimes. A documented platform constraint is not subject to a
weighted vote. Where Apple leaves a design choice open, evaluate Stally's
requirements and tradeoffs; do not prefer a sibling-app pattern simply to meet
the nominal 20% share. Existing selected designs remain accountable to these
criteria and may be revised when stronger evidence warrants it. This
clarification does not itself establish a defect in either sibling app or
invalidate an independently supported Stally decision.

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

### October 24 Sibling-Influence Review

Scope: review the core design and its linked direction/contract documents,
using the owner's clarified reference policy. Recheck the relevant sibling
declarations and current official identity, relationship, CloudKit, storage,
and naming guidance. This is not a correctness audit of Incomes or Cookle and
does not supply new runtime evidence for Stally's unimplemented schema.

| Decision | Sibling influence found | Independent judgment and disposition |
| --- | --- | --- |
| Library and Operations boundaries | Deliberate architectural influence | Keep: the app and system surfaces need the same durable domain operations; do not mechanically duplicate helper layers. |
| Package selection | Older direction required following Incomes' package set | Correct that directive: choose capabilities for Stally independently, retaining explicit app-specific choices. |
| `Item`, `ItemMark`, `ItemPeriod` | `Item` also appears in Incomes; no requirement to reuse its meaning | Keep confirmed names: user-chosen subject identity, individual recording facts, and retained periods justify these concepts. |
| Application UUIDs | Sibling store identifiers were a comparison point | Keep: portable identity is a Stally requirement; native CloudKit does not require the added UUID. |
| `ItemPhoto` | Cookle's shared asset and attachment layers framed the initial comparison | Keep one owned attachment model for caption, order, and lifetime; shared assets are not required by current use cases. |
| `Tag` | Incomes' model was cited too readily as architectural support | Keep with independent justification: shared rename/reuse/removal. A string collection remains a valid simpler alternative for independent labels. |
| Creation and modification timestamps | Cookle supplied a familiar naming and audit-field precedent | Keep `createdAt` for an independently useful registration fact; do not add `updatedAt` merely to match Cookle. |
| Archive and independent Bools | No sibling-specific requirement identified | Keep: the owner's valid state combinations justify separate facts; the names are Stally choices, not official mandated spellings. |
| Optional relationships and deletion rules | Similar declarations exist in sibling apps | Keep based on native CloudKit requirements and owned versus shared lifetimes, not similarity to sibling declarations. |
| Export/import and old-format support | Sibling review/cancellation flows were references; old Stally formats were another source of inertia | Keep deliberate review and source preservation. No requirement to inherit a sibling codec or retain development formats forever. |

The review also distinguishes our own unverified assumptions from sibling
influence. The integer day-key proposal was subsequently replaced by the
[verified civil-text choice](mark-temporal-schema-comparison.md). Partial-date
period strings remain a separate representation decision; existing Stally
code alone does not establish their suitability. Photo `sortOrder` needs
saved-store and concurrent-reorder evidence;
the existence of Cookle's order field is not that evidence. Preserving ingested
image data with derived thumbnails remains the selected direction, but the
Apple example does not establish optimal image limits or metadata policy.
No evidence here establishes all of these choices as uniquely best.

The five-entity direction survives this review. Correct the overly broad
reference/package instructions and the rationale for shared Tags, without
renaming models or changing the schema simply to differ from sibling apps.
The existing baseline contract documents describe currently implemented
formats; their compatibility constraints do not override the newer pre-release
design scope. Actual development data still needs an explicit transition when
implementation begins, rather than deletion on failed store initialization.

## Implementation Order and Required Evidence

1. Prototype the base models, photos, tags, generated schema, date values, and
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

Photo and Tag checks must include individual caption edits, image omission on
import, explicit photo order after reopening, tied order after sync, deleting
one photo, deleting one Tag, deleting an Item, and concurrent same-name Tag
creation. Verify that unrelated Items and shared Tags survive the relevant
deletions. No new-model runtime or device-sync evidence is claimed here.

Outstanding choices include remaining base-model field proposals, media limits
and metadata policy, export media/precision, heatmap scale, settings placement,
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
[wishlist]: https://developer.apple.com/videos/play/wwdc2026/275/
[notes-tags]: https://support.apple.com/en-gb/guide/iphone/iphedddbfdf9/ios
[absolute-date]: https://developer.apple.com/documentation/foundation/date
[date-components]: https://developer.apple.com/documentation/foundation/datecomponents
[sql-date-types]: https://www.postgresql.org/docs/current/datatype-datetime.html
[sqlite-dates]: https://www.sqlite.org/lang_datefunc.html
