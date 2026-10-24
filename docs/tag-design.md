# Tag Classification and Naming Design

## Status and Recommendation

This is the revised recommendation requested after the first Tag review.
The previous recommendation to expose same-name records separately and block
renaming to an existing label is superseded. The owner asked for a natural
Stally design using public Apple capabilities, not similarity to or difference
from Incomes or Cookle. The detailed revised recommendation awaits acceptance.
No production model, Operations implementation, actual store, or cloud schema
was changed by this review.

Recommend one user-visible classification for names considered equivalent by
the documented comparison rule. An Item can have several classifications, but
showing two indistinguishable labels to represent different sets of Items has
no selected Stally purpose. Different meanings should use different names.

Keep the current Tag model: uuid, name, and optional items. UUID identifies a
stored record. Normally one record represents a classification; native sync
may produce several. Compute the user-visible classification from all matching
records. A classification is not another persisted model, a permanent name
identifier, or an alias/redirect record.

## Alternatives Reconsidered

| Alternative | Product fit | Persistence cost or limitation | Judgment |
| --- | --- | --- | --- |
| Different UUIDs always mean separately selectable classifications | Useful if users need same-name categories with different meanings | Simple individual rename, but exposes storage duplicates and makes filtering ambiguous | No current Stally requirement justifies this behavior |
| Require exactly one physical Tag for every name | Clean record count and a familiar single-row model | Cross-device uniqueness needs deduplication and careful treatment of separately arriving relationships | Do not make physical uniqueness a 1.0 requirement |
| Store independent name values directly on every Item | Natural for independent labels without shared editing | Collection-wide rename updates many Items; abandons the selected shared-reference model without solving offline rename semantics | Valid alternative, but weaker fit for shared management |
| One visible classification, permitting several same-name backing records | Same name selects all relevant Items; rename can combine classifications | A small derived grouping and ordinary name updates; no automatic record deletion | Recommended |

The previous review treated successful implementation of collision rejection
as evidence that rejection was the best product rule. It also conflated
user-initiated grouping with automatic destructive deduplication. These are
separate decisions. A portable UUID does not require users to distinguish two
otherwise identical classifications.

## Apple Evidence and Its Boundary

Apple Notes on Mac permits renaming a tag to a name already in use to bring
similarly tagged notes together. Its [user guide][notes-mac] supports that
interaction, not an assertion about Notes' private model or sync algorithms.
Adopt the ability to combine through rename rather than mechanically copying
Notes' single-word hashtag syntax or automatic removal of unused tags.

[Public SwiftData/CloudKit guidance][cloudkit] does not support unique
constraints and
warns that relationships may synchronize separately. Apple's
[Core Data sharing sample][sharing-sample] specifically explains how deleting
a duplicate before all related objects arrive can lose relationships. Its
solution includes history processing, a deduplication date, deterministic
record selection, and delayed removal around import/export events.

The locally cached sample's PersistenceController+Deduplicate.swift and
related Tag/History source were inspected; its documented hazard and strategy
match the current Apple article. It is Core Data sharing code, not a SwiftData
API recipe. Do not reach into SwiftData's underlying Core Data container or
copy that machinery merely to ensure one physical row. This review uses the
sample to identify the cost of destructive deduplication, not as proof that
Apple prescribes Stally's derived grouping.

## Meaning of Same Name

Keep the independently justified native comparison from the first review:
trim boundary whitespace; fold case and width using Foundation under a fixed
en_US_POSIX locale; compare the resulting Swift Strings. Save the cleaned
user spelling, not the folded text. No comparison key is persisted.

This makes common input variants one classification, while keeping accents,
kana script, and meaningful interior spacing distinct in the tested cases.
It is a Stally policy over [Foundation folding][folding], not a universal
Apple tag rule. A fixed
locale avoids redefining classification when the device language changes.
Localized searching and sorting can still use the person's locale.

```swift
import Foundation

func tagComparisonKey(_ name: String) -> String {
    name
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(
            options: [.caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
}
```

[Swift String equality][swift-equal] recognizes canonical equivalence, so a
second NFC
normalization pass is unnecessary. The key is a temporary comparison value,
not a portable identity. Unicode/Foundation behavior may change across OS
versions; retaining source names and references avoids turning a new comparison
result into destructive cleanup.

| Names | Same classification? |
| --- | --- |
| Shoes / shoes / full-width SHOES | Yes |
| Half-width voiced katakana / the full-width equivalent | Yes |
| Composed accented letter or voiced kana / equivalent combining form | Yes |
| cafe / cafe-with-acute | No |
| はな / ばな; くつ / クツ | No |
| 革 靴 / 革靴; one internal space / two internal spaces | No |
| 靴01 / 靴1; circled digit one / plain digit one | No |
| Straße / STRASSE; ff ligature / ff | Yes, following native case folding |

The first comparison found that Foundation compare with the same case/width
options also equated hiragana and katakana under the tested locale, while
folding then Swift equality retained the distinction. Lowercasing alone missed
width/case-fold behavior; broad diacritic folding or compatibility normalization
collapsed additional distinctions. Keep the chosen folding for these reasons,
not because a sibling app does the same.

Trim whitespacesAndNewlines at the edges for local input; reject an empty
result, internal control characters, line separators, and paragraph separators.
Retain ordinary internal spaces, case, width, accents, and emoji sequences.
Do not strip format characters such as emoji joiners. Missing/invalid incoming
names remain explicit incomplete data, never silently grouped into a valid
empty-name classification or deleted.

## User Operations

| Action | Recommended result |
| --- | --- |
| Enter a new name | Create a Tag and assign it to the Item |
| Enter an existing equivalent name | Reuse the classification without creating another record or changing its display spelling |
| Choose a classification backed by several records | Present one choice; it covers all those records |
| Add it to an Item already carrying any member | No duplicate visible assignment or new relationship is needed |
| Rename to an unused name | Update all currently known members of the source classification; preserve UUIDs and assignments |
| Rename to an existing classification | Explain that the classifications will be combined; committing changes source members to the destination spelling |
| Correct case/width spelling within a classification | Update its known members to the entered spelling |
| Receive another same-name record through sync/import | Include it in the same read grouping; perform no cleanup write |
| Remove a classification from one Item | Remove all matching member references from that Item only |
| Explicitly delete a classification | Delete its currently known member records through standard nullify rules; retain Items and their history/photos |

A rename to an existing classification is supported in 1.0. Its commit action
must say that it combines classifications, rather than presenting an ordinary
rename and silently changing its scope. Keep editing as a draft until commit;
cancellation changes nothing. This is a domain action through Operations,
not a requirement for a new settings screen or repeated confirmation dialogs.

For a collision, retain the destination's existing display spelling. If several
records have equivalent but different spellings, choose the member with the
lowest UUID as a deterministic display/assignment representative. Trim boundary
whitespace for display without silently rewriting incoming records. Do not
rewrite other members merely to enforce that choice. A case-only spelling
correction updates the source classification's known members explicitly.
Localized sort order is independent of the representative rule.

## Non-Destructive Combination

For example, Items A and B use a record named Travel, and Items B and C use a
record named Trips. When the person renames Travel to Trips and commits the
combination:

1. Change the name of the Travel record to Trips.
2. Keep both record UUIDs and every existing Item relationship.
3. Present one Trips classification whose Items are the union A, B, and C.
4. Show one Trips chip on B and count B once in that classification's results.

There is no relationship transfer or redundant-record deletion in this action.
If another Item's reference to the former Travel record arrives later, that
record still exists and participates in Trips. This property addresses the
specific premature-deletion hazard without introducing a synchronization
repair engine.

Implement grouping as a derived read using the native Foundation key and Swift
collections. Use UUID-based sets when combining Item results so Items that
reference multiple member records appear once. Keep this logic in the shared
library's read/Operations boundary so lists, filters, counts, and system
surfaces agree; do not implement grouping only in the tag picker. Do not fetch
photos merely to compare Tag names.

New assignments can use the deterministic representative when the Item has no
member already. Read grouping must always consider every member, including
records temporarily lacking their inverse Item relationships. Do not use only
the representative's items. Unused tags remain until explicitly deleted, as
already selected. No global name uniqueness, normalizedName column, alias
chain, tombstone field, or background reconciliation task is added.

## Native Sync Limits and Export Implications

Names and relationships may arrive at different times. A multi-record rename
is not a distributed transaction: intermediate views can show old and new
classifications. Conflicting edits follow native sync behavior. The local
read grouping is deterministic for the records currently available; it does
not establish cross-device atomicity or convergence of arbitrary conflicts.

A wholly new old-name Tag created on another offline device can arrive after a
rename. It remains an old-name classification, with its information intact.
There is no permanent old-name redirect, and reusing an old name later is
allowed. Do not promise that a rename also rewrites unknown future records or
old export files. This is an explicit scope boundary rather than a hidden
claim of durable global merge semantics.

Retaining several small backing records is a chosen storage tradeoff. Physical
consolidation is not needed for the visible combination action. Revisit it only
if measured scale or a concrete contract requires it, including the relationship
arrival concerns demonstrated by Apple. Native sync integration still requires
bounded multi-device tests before release.

Export/import is the next contract discussion. Identity-preserving round trips
must retain backing UUIDs and memberships; a human-readable summary can present
one classification per name. Do not discard extra member identities merely
because the UI displays one row. Restoration can reintroduce historical names;
exact UUID conflict rules belong to that separate design. No stable logical
classification UUID or permanent alias mapping is promised by this proposal.

## Verification Evidence

The first review's Foundation comparison remains relevant: seven approaches
across 23 pairs and 61 name-rule assertions on macOS 27.2 / Xcode 27.2. Its
29 local persistence assertions demonstrated shared rename and retained
same-name records. Its five physical-merge assertions established only a local
alternative, not safe cleanup across asynchronous CloudKit arrivals.

The reconsidered design passed 32 assertions across nine fresh macOS processes
using the complete current five-model schema, including thumbnailData, in a
throwaway SwiftData store with CloudKit disabled. It covered:

- Same-name filtering as a union, including an Item assigned to both records.
- Draft rollback, reopen, and rename into an existing classification.
- Unchanged record UUIDs and Item memberships during combination and rename.
- A later Item assignment referencing the former source record.
- Renaming all known members of a combined classification.
- A later independent old-name record remaining visible without redirection.
- Removing every matching reference from one Item while preserving others.
- Explicit classification deletion preserving unrelated tags, all Items, and
  existing Mark history.

The same final source compiled for iOS Simulator. Local sources and results are
under /private/tmp/stally-tag-reconsidered. The late-arrival cases are
deliberately ordered local insertions, not actual CloudKit events. Rollback
verification is not disk-full or save-failure injection. No iOS runtime, UI,
cross-device sync, large-tag-set performance, or cross-OS Unicode guarantee is
claimed.

No sibling Tag implementation was read for this reconsideration. The relevant
Apple sample was inspected read-only in the external sample cache; its cached
check date was October 22, 2026, and the current official article was consulted.
No sample code was copied into Stally and no production code was changed.

[notes-mac]: https://support.apple.com/guide/notes/use-tags-apdc88ed7f1d/4.13/mac/27
[sharing-sample]: https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users

[folding]: https://developer.apple.com/documentation/foundation/nsstring/folding(options:locale:)
[swift-equal]: https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html
[cloudkit]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
