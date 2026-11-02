# Core Record Design

An Item is a subject the person chooses to remember. Items can be described
with a note, photos, Tags and a representative link. Mark and period history
are independent. The [contract summary](first-release-contract-summary.md)
records the durable choices; the [schema](model-schema-design.md) identifies
the records that implement them.

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

`isArchived` means put aside from the active Library while retaining the record. It is not a security or privacy
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
Undo targets a particular Mark. Deleting one Mark leaves other occurrences on the same day intact.

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

Selected operation semantics:

- End a period: retain its start and identity; set it ended and record only
  the end knowledge the person supplies. Ending today is an explicit action.
- Resume a relationship: retain ended periods and add an ongoing period.
  Correcting an accidental end edits the existing period instead.
- Archive/unarchive, favorite/unfavorite, or pause/resume Marks: change no
  periods.
- Delete a period: explicitly remove that period knowledge, not its Item or
  Marks. Marks are owned by the Item, not assigned to periods.

Normally allow at most one ongoing period through local Operations. Reject
definitely reversed boundaries and definite positive-day overlaps. Permit
ending and resuming on the same date without inventing clock times;
partial-date uncertainty must remain visible instead of acquiring invented
days. Preserve conflicting or incompletely synchronized periods for review;
do not silently choose a winner or sum overlapping intervals twice.

Elapsed readings must distinguish time since an initial start from time within
recorded periods. Exclude known gaps from the latter. Unknown boundaries or
overlap may prevent an exact duration; retain precision and show an approximate
or unavailable reading. Do not turn missing dates into zero duration. The
calculation and display specification belongs in the period implementation.

See [period readings](period-readings-design.md) for the current and cumulative
readings and the treatment of incomplete dates.
