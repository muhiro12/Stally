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
| One visible classification, permitting several same-name backing records | Same name selects all relevant Items; rename can combine classifications | Shared grouping, multi-record editing, and consumer identity resolution; no automatic record deletion | Recommended |

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

The follow-up review replaces folding followed by Swift equality with direct
Foundation comparison. The owner prefers the equivalences supplied by standard
APIs rather than extra rules to keep hiragana and katakana separate. This is
not a request for translation, synonym inference, or a custom normalizer.

The owner accepted this direct-comparison policy in the subsequent review.
Their description of multiple stored Tags appearing as one classification was
a request to confirm understanding, not approval of the entire grouping design.

Trim boundary whitespace, then compare complete names with caseInsensitive and
widthInsensitive under a fixed en_US_POSIX locale. Preserve the cleaned user
spelling. This is a Stally choice of standard comparison options, not an Apple
prescription for tag identity. A fixed locale avoids changing classification
merely because a device changes language; it does not freeze Unicode behavior
across future OS versions or provide culturally tailored matching everywhere.

```swift
import Foundation

func tagNamesMatch(_ first: String, _ second: String) -> Bool {
    first.trimmingCharacters(in: .whitespacesAndNewlines).compare(
        second.trimmingCharacters(in: .whitespacesAndNewlines),
        options: [.caseInsensitive, .widthInsensitive],
        locale: Locale(identifier: "en_US_POSIX")
    ) == .orderedSame
}
```

Do not manufacture a hash key assumed to be equivalent to this comparator:
Foundation folding and comparison differed in the verified kana cases. Group
fetched Tags using the same comparator, for example by sorting then collecting
adjacent equivalent names, with UUID as the within-group tie-breaker. Localized
user-visible sorting is a separate step. No comparison key is persisted.

| Names | Same classification in the verified runtime? |
| --- | --- |
| Shoes / shoes / full-width SHOES | Yes |
| くつ / クツ / half-width katakana equivalent | Yes |
| cafe / cafe-with-acute | No |
| はな / ばな | No |
| 靴 / くつ; 靴 / Shoes | No |
| 革 靴 / 革靴; one internal space / two internal spaces | No |
| 靴01 / 靴1; circled digit one / plain digit one | No |
| Straße / STRASSE | Yes |

A follow-up isolated four option sets across five pairs. Under en_US_POSIX,
Shoes/shoes required caseInsensitive; shoes/full-width uppercase SHOES required
both caseInsensitive and widthInsensitive. The tested hiragana/katakana and
full-width/half-width kana pairs compared equal even with no options. Their
equivalence comes from the native localized collation in this configuration,
not a Stally kana conversion or an assertion that kana has uppercase/lowercase.
These are runtime observations on macOS 27.2, not a promise for every locale or
comparison/search API.

Adding diacriticInsensitive also equated はな and ばな in the experiment.
Do not enable every permissive option merely to maximize grouping. It is
reasonable for search to offer approximate candidates without automatically
making them one editable classification. The recommendation retains accent
and voiced-kana differences without special language-specific exclusions.

There is no single standard API whose equality, substring search, and sort
ordering all agree. In the tested ja_JP environment, localizedStandardCompare
ordered variants separately, and localizedStandardContains did not match
くつ against クツ even though the selected whole-name comparison did. Its
[documented purpose][search] is user-facing, locale-aware, case- and
diacritic-insensitive search, with options allowed to evolve over time.

Use localizedStandardContains for candidate search over all member names,
supplemented by the same whole-name equivalence used for classification. This
ensures a recognized equivalent full tag name finds its classification. It
adds one shared matching rule, not transliteration or a synonym dictionary.
Do not promise arbitrary kana-substring equivalence beyond the standard search
API. Search hits do not themselves trigger grouping or rename.

Trim whitespacesAndNewlines at the edges for local input; reject an empty
result, internal control characters, line separators, and paragraph separators.
Retain ordinary internal spaces, case, width, accents, and emoji sequences.
Do not strip format characters such as emoji joiners. Missing/invalid incoming
names remain explicit incomplete data, never silently grouped into a valid
empty-name classification or deleted.

The existing model permits adding semantic search later without rewriting Tag
identity: expand search candidates while preserving names and UUIDs. Automatic
semantic merging would be a separate, consequential contract, not an equally
trivial extension. The owner can already explicitly combine 靴 and Shoes by
renaming one into the other; Foundation does not infer that they mean the same.

A per-user or per-tag exception to grouping is not recommended for 1.0. Use
meaningfully different labels when separate classifications are wanted. A
setting that changes editable classification identity also changes rename and
removal scope and is more than a display preference. This remains a product
recommendation, not an accepted owner requirement.

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

Implement grouping as a derived read using the native Foundation comparator
and Swift collections. Use UUID-based sets when combining Item results so Items that
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

## Application Work and Framework Boundary

This design does add application logic. SwiftData does not provide an automatic
name-based classification spanning several model identities. The previous
review understated that cost by describing only a small grouping operation.
Using Foundation does not make the entire behavior platform-provided.

| Surface | Framework capability | Stally responsibility |
| --- | --- | --- |
| Tag list and Item chips | Fetch/observe models and compare strings | Derive groups, choose a display spelling, show one chip per group |
| Candidate search | localizedStandardContains | Search all member spellings and include whole-name equivalent groups |
| Item filtering and count | Persistent relationship predicate over member UUIDs | Resolve the group first; count each matching Item once |
| Rename and combine | Edit names and save | Update all currently known source members; explain combination scope |
| Detach and delete | Change relationships or use nullify deletion | Apply the operation to all currently known matching members |
| Saved selection and external references | Resolve a stored Tag UUID | Use that record's current name to resolve its current group |
| Export/import | Codable and ordinary model insertion/assignment | Preserve raw Tag UUIDs, names, and Item references; do not invent a group ID |

Centralize these rules in the shared library. A representative UUID is a record
identifier, not a newly promised permanent classification identity. A saved
reference may use any surviving member UUID and resolve its current group;
choosing a different display representative must not invalidate that reference.
Handling actual deletion remains an ordinary missing-reference case.

Grouping requires reading the Tag collection, but does not require loading all
Items or photos. Resolve matching member UUIDs, then use a native relationship
predicate for the Item results. The probe executed that predicate against a
persistent SwiftData store; an arbitrary Foundation comparison is not inserted
into a database predicate. Live observation, pagination, and realistic collection
size still need verification during integration.

The recommendation is framework-compatible application behavior, not a
zero-cost standard feature or a proven universal best practice. For Stally's
selected desire to present one equivalent-name classification, it avoids the
larger obligation of destructive cross-device deduplication. If even this
shared projection is too costly, the simpler honest alternative is to expose
separate UUID-backed tags and accept visible duplicates. There is no demonstrated
public switch that supplies clean grouping, global rename, and cross-device
uniqueness together. Do not build a custom sync engine to hide that tradeoff.

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

## Latest Verification Evidence

The follow-up compared 14 name pairs with five native approaches on macOS 27.2
using Xcode 27.2. Five additional pairs were checked with whole-name comparison
and range search under en_US_POSIX, ja_JP, en_US, and tr_TR. The observations
above are runtime evidence, not guarantees for every OS version or language.

A new throwaway full-five-model SwiftData probe passed 22 assertions across
four processes: source creation/export, fresh-store import, unchanged replay,
and reopen. It exercised kana/width grouping, union counts, standard candidate
search plus whole-name equality, explicit rename into an existing group,
retained member UUID lookup, a persistent Item predicate using matching Tag
UUIDs, and a Codable Tag/Item graph round trip. All nine Tag records and four
Items retained their identities and assignments; replay did not multiply rows.

This was an isolated identity/relationship export probe, not the final Stally
file format or a complete import implementation. It did not resolve edited-UUID
conflicts, restore photos, test malicious input, or prove partial-import recovery.
The standard macOS store-change notification registration emitted sandbox
warnings while the persistence assertions passed; observation is not verified.
The same source compiled for iOS Simulator without warnings. No iOS runtime,
real CloudKit sync, UI refresh, App Intents lifecycle, or scale benchmark is
claimed. Sources and artifacts remain under /private/tmp/stally-tag-native-review.

## Previous Verification Evidence

The first review's Foundation comparison records the superseded folding policy:
seven approaches across 23 pairs and 61 name-rule assertions on macOS 27.2 / Xcode 27.2. Its
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

[search]: https://developer.apple.com/documentation/swift/stringprotocol/localizedstandardcontains(_:)
[cloudkit]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
