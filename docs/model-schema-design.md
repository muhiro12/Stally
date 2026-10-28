# Consolidated Model Schema

For the integrated October 27 implementation, current evidence, and remaining
work, see [foundation implementation](first-release-foundation-implementation.md).
The design-session and standalone-probe statements below retain their original
scope; they are not claims about the later application state.

## Status

On October 24, 2026, the owner accepted the ItemPeriod proposal after its
standalone validation. This document consolidates that decision with the
accepted ItemMark representation and the selected Item, photo, and tag design.
It is a Swift illustration of the intended five-model schema, not the
application's current implementation or a promoted CloudKit schema.

See [core record design](core-record-design.md) for field meanings and
alternatives, [Mark comparison](mark-temporal-schema-comparison.md) for temporal
evidence, and [Period validation](period-schema-validation.md) for lifecycle
rules. The existing application models and stores are unchanged.

### October 28 Accepted Addition

The owner accepted one optional representative URL per Item and reaffirmed
Bool favorites. See [the behavior decision](product-behavior-design.md#accepted-context-and-favorite-decisions).
The Swift illustration below retains the earlier five-model baseline; the
implemented `StallySchemaV3` does not yet contain the URL. Integrate the new
fact through a successor schema rather than silently changing that historical
snapshot. Decide the physical property representation and matching export key
with the implementation, preserving identity, notes, and an absent-link state.
This addition does not select a separate link entity or a collection of URLs.

## Swift Representation

The initializers below describe ordinary creation. Operations validate input
before insertion or mutation and own persistence. Stored relationships remain
optional to accommodate the native synchronization model. Requiring an Item
in a child initializer does not make its stored relationship nonoptional.

```swift
import Foundation
import SwiftData

@Model
final class Item {
    var uuid: UUID = UUID()
    var name: String = ""
    var note: String = ""
    var createdAt: Date = Date()

    var isArchived: Bool = false
    var isFavorite: Bool = false
    var isMarkRecordingEnabled: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \ItemMark.item)
    var marks: [ItemMark]? = []

    @Relationship(deleteRule: .cascade, inverse: \ItemPeriod.item)
    var periods: [ItemPeriod]? = []

    @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.item)
    var photos: [ItemPhoto]? = []

    @Relationship(deleteRule: .nullify, inverse: \Tag.items)
    var tags: [Tag]? = []

    init(name: String, note: String = "") {
        self.name = name
        self.note = note
    }
}

@Model
final class ItemMark {
    var uuid: UUID = UUID()
    var localDateTime: String = ""
    var createdAt: Date = Date()
    var item: Item?

    init(item: Item, localDateTime: String) {
        self.item = item
        self.localDateTime = localDateTime
    }
}

@Model
final class ItemPeriod {
    var uuid: UUID = UUID()
    var startLocalDate: String?
    var endLocalDate: String?
    var isOngoing: Bool = true
    var createdAt: Date = Date()
    var item: Item?

    init(
        item: Item,
        startLocalDate: String? = nil,
        endLocalDate: String? = nil,
        isOngoing: Bool = true
    ) {
        self.item = item
        self.startLocalDate = startLocalDate
        self.endLocalDate = endLocalDate
        self.isOngoing = isOngoing
    }
}

@Model
final class ItemPhoto {
    var uuid: UUID = UUID()

    @Attribute(.externalStorage)
    var imageData: Data?

    var thumbnailData: Data?
    var caption: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var item: Item?

    init(
        item: Item,
        imageData: Data,
        thumbnailData: Data? = nil,
        caption: String = "",
        sortOrder: Int = 0
    ) {
        self.item = item
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.caption = caption
        self.sortOrder = sortOrder
    }
}

@Model
final class Tag {
    var uuid: UUID = UUID()
    var name: String = ""

    @Relationship(deleteRule: .nullify)
    var items: [Item]? = []

    init(name: String) {
        self.name = name
    }
}
```

## Relationships and Naming

| Relationship | Ownership | Deleting either end |
| --- | --- | --- |
| Item to ItemMark | One Item owns many Marks | Item cascades; Mark preserves Item |
| Item to ItemPeriod | One Item owns many periods | Item cascades; period preserves Item |
| Item to ItemPhoto | One Item owns many photos | Item cascades; photo preserves Item |
| Item to Tag | Many Items share many Tags | Remove assignments; preserve the other records |

Each inverse is declared once on Item. The unannotated child-to-parent
relationships use the default nullify rule. Tag explicitly shows that rule
because its shared lifetime differs from the three owned child types. These
are ordinary [SwiftData relationships][relationships], not a custom join or
ownership engine.

- Keep the accepted `Item`, `ItemMark`, and `ItemPeriod` names. `ItemPhoto`
  describes an attachment owned by one Item. `Tag` describes shared identity;
  it is not an Item-owned assignment entity.
- Keep `uuid` distinct from SwiftData's store identity. There is no uniqueness
  attribute, implicit same-name merge, or unique day constraint.
- Use `localDateTime` for a Mark's day with optional minute precision;
  `startLocalDate` and `endLocalDate` describe partial period boundaries.
  None is an absolute instant. Their canonical Gregorian text preserves the
  supplied precision without separate flags, zones, or duplicate Date fields.
- Keep `createdAt` for Item, Mark, Period, and photo registration metadata.
  Do not add it to Tag merely for symmetry: the selected tag interactions
  require identity, a label, and assignments, not registration chronology.
- Shooting dates and other supported source-image facts remain embedded in
  ItemPhoto.imageData; they do not require duplicate model properties or change
  the meanings of Mark/Period dates.
  See the [photo policy](photo-storage-design.md).
- `imageData` uses [external storage][external-storage]. SwiftData manages
  its storage location; no app-managed path, Photos library reference, or
  separate reusable image-asset model is required by this design. Qualifying
  delivered image bytes are preserved; only over-limit inputs are transformed.
  Neither path requires a stored normalization flag or a second original.

## Rules Outside the Stored Schema

- Operations require nonblank Item/Tag names, valid canonical dates, and
  decodable image data for ordinary photo creation. Storage defaults and
  optionals do not make incomplete user input valid. This code is a schema
  illustration, not a complete validated creation API.
- Mark text is `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm`. Period boundaries are nil,
  `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`. These are shape descriptions; Foundation
  formatter patterns use calendar-year `yyyy`, not week-year `YYYY`.
- An ongoing period has no end value. An ended period may have an unknown
  end. Ending edits the existing period; resuming creates another. Correcting
  a mistaken ending edits the same period. Apply the validated conservative
  partial-date and overlap rules in Period Operations.
- A new Item does not automatically receive a period or Mark. Neither
  archive nor recording pause ends periods. Favoriting changes neither.
- Corrections preserve UUID and creation metadata. Identity-preserving import
  restores them rather than using initializer-generated replacements.
- Relationship arrays are not an ordering contract. Photos sort by
  `sortOrder`, then UUID, with the first photo serving as cover. Reordering
  assigns positions through Operations; simultaneous remote edits may tie.
- Counts, active days, calendar intensity, elapsed readings, current period,
  and relationship status are derived. Do not duplicate them on Item.
  Calendar presentation settings are separate from the occurrence records.
- Preserve incomplete or contradictory incoming data for explicit handling;
  this design does not add automatic orphan deletion or a sync repair engine.

The owner accepted the [photo storage policy](photo-storage-design.md),
including conditional byte preservation, ingestion limits, metadata handling,
and persistent previews. ItemPhoto now includes optional thumbnailData
as a rebuildable derivative alongside the authoritative imageData.
The [Tag report](tag-design.md) records the owner's selected direction:
preserve distinct UUID identities, including identical names; suggest existing
Tags without automatically grouping, rewriting, or reassigning them. Selection,
filtering, links, and rename operate on the chosen UUID. Preserve confirmed
spelling, including spaces. The previous derived classification recommendation
is superseded. The October 25 consolidation recommendation reassigns reviewed
Item relationships to a selected Tag and deletes the source Tags in one local
save. It adds no fields or permanent aliases and does not guarantee transfer
of unseen cloud relationships. The owner accepted this bounded contract with appropriately timed explanation; local
merge/rollback verification does not qualify immediate Undo or cloud behavior.
The [export/import identity proposal](import-identity-design.md) recommends
UUID matching with explicit record-level conflict choices and no deletion by
omission. Its conservative omission handling, minimal 1.0 scope, and aligned
schema-version policy are accepted. The owner also accepted proceeding with the
[concrete file design](export-file-format-design.md): a consistent `.stally`
package and image integrity checks, with auxiliary JSON sharing. Resource
qualification and physical integration remain pending. It adds no stored fields
for ordinary import; image digests are derived file metadata.
The [native sync lifecycle review](sync-lifecycle-design.md) follows native
account lifecycle and proposes explicit handling of concurrent Period states,
without adding domain attributes. The earlier separate local/cloud library
recommendation is withdrawn; account-independent retention was not a product
requirement. Real CloudKit qualification and final reading/presentation behavior
remain to be settled.
Follow the [contract summary and handoff](first-release-contract-summary.md)
for the next development phase. Physical schema/shared-container integration
and release qualification remain pending; derived readings and presentation
belong to feature design. Native sync, explicit Tag consolidation, and the
export/import direction have already been discussed and selected.
This illustration does not add speculative stored fields for those concerns.

The [period readings proposal](period-readings-design.md) exercises elapsed and
total calculations and unknown/partial-date handling with the existing fields.
Its counting and presentation policy awaits owner review; no stored durations
or changes to export/import are proposed.

## Consolidated Graph Verification

The [photo policy review](photo-storage-design.md) separately verified the
added thumbnailData attribute with disk-store reads, metadata edits, missing
image/thumbnail cases, and cascade deletion. The earlier complete-graph checks
below apply to the version without that attribute.

Before adding thumbnailData, the five declarations above were extracted and
compiled together with
Apple Swift 6.4.2 in Xcode 27.2. On macOS 27.2, a disposable disk store passed
26 assertions across ten separate processes, with explicit saves and fresh
reopens after each mutation. CloudKit was disabled for this probe.

The checks covered independent Item flags and notes, the absence of an
automatic period, owned inverses, shared Tag assignments and rename, individual
photo captions, explicit photo ordering, and reopened binary payload equality.
Tag deletion retained its Items and their children. Photo deletion retained
its Item and other photos. Item deletion cascaded only to its own children,
preserving another Item and an unused Tag. Mark and Period fields and creation
metadata survived the complete-graph round trip.

The external-storage attribute was exercised with a deterministic two-million-
byte binary fixture; this verifies byte recovery, not image decoding, image
quality, or a specific on-disk placement decision by SwiftData. All ten stages
exited successfully without logged diagnostics. Probe source and logs were
retained under `/private/tmp/stally-model-schema.JHrUkt` for this local review;
that temporary path is not a repository or application dependency.

This is macOS local persistence evidence. It does not establish device or
multi-device synchronization, incoming conflict handling, image ingestion,
old-store migration, or integration into the application. The separate Mark
and Period reports retain their own iOS evidence; it must not be generalized
to this complete graph without an iOS run.

[relationships]: https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes
[external-storage]: https://developer.apple.com/documentation/swiftdata/schema/attribute/option/externalstorage
