# Tag Identity, Suggestions, and Explicit Consolidation

## Status and Governing Principle

The owner selected protection of recorded facts and user intent as the governing
principle. The app supports decisions; it does not infer that similarly named
records represent one classification. This supersedes the previous recommendation
to present all equivalent names as one classification with several backing Tags.
The earlier acceptance of Foundation comparison now applies to suggestions, not
record identity, assignment, or automatic grouping.

Use the existing Tag shape: uuid, name, and optional items. Distinct UUIDs mean
distinct Tags, including records with identical names. Preserve existing names
and relationships until the user edits, deletes, or explicitly consolidates
selected Tags. Preserving facts does not require an immutable event log or
prohibit deliberate correction and removal.

This document records the owner's product direction and bounded engineering
recommendations. No production model, Operations code, actual store, or cloud
schema changed. The owner wants an explicit consolidation feature; its synced
persistence algorithm and source-record lifecycle are not yet finalized.

## Identity and User Operations

| Action or condition | Contract |
| --- | --- |
| Two different UUIDs have the same name | Keep and present two Tags; do not automatically group or delete either |
| Similar spelling, case, width, kana, or spaces | Offer candidates without changing identity or the entered spelling |
| Select an existing suggestion | Assign that specific Tag UUID; preserve its stored name |
| Explicitly create using the entered name | Create a new Tag with that name, including when another name is identical |
| Assign a Tag already assigned to this Item | Do not add the same UUID twice |
| Tap a Tag on an Item | Show Items related to that Tag UUID only |
| Open a Tag deep link | Resolve the specified UUID, not all Tags sharing its name |
| Rename a Tag | Change only that Tag's name; retain its UUID and assignments |
| Rename to a name already in use | Inform the user of the existing name and show the relevant Tag; rename alone neither consolidates nor fails solely because of the collision |
| Detach or delete a Tag | Affect only the selected UUID; preserve other Tags and Items |
| Receive another Tag through sync/import | Retain its identity and references; no name-based reassignment |
| Explicitly consolidate selected Tags | Perform a separate deliberate operation with a chosen destination; see the open persistence boundary below |

A typed name alone is not authority to choose an existing UUID. Make selecting
an existing suggestion and creating a new Tag distinct actions. Default focus,
return-key behavior, and labels need UI verification so a suggestion does not
silently become a decision. Do not add repetitive confirmation dialogs merely
because a suggestion exists.

The owner requires feedback when a proposed rename duplicates an existing
name. Similar-name suggestions should be distinguished from exact-name
collisions. The UI may offer reuse or explicit consolidation when applicable,
but must not silently merge, rewrite, or block an intentional separate name.
Placement, wording, and presentation will be designed later; the requirement
to inform the user is selected now. This does not require a modal confirmation.

The proposal to choose a representative by UUID order or usage count is retired.
If A has 99 related Items and B has one, selecting B assigns B. Popularity may
inform suggestion presentation later, but must not silently substitute A.

## Names and Suggestions

Preserve user-confirmed spelling, including leading, trailing, and interior
spaces. In particular, くつ, クツ, く つ, and a leading-space version of くつ
can coexist as independently named Tags. Do not silently trim a stored name or
render a trimmed replacement as if it were the saved value.

For local input, recommend requiring at least one non-whitespace character and
rejecting control characters and line/paragraph separators rather than silently
rewriting them. This validation does not require trimming accepted names. Keep
emoji format characters such as joiners. These are input-validity rules, not
a name-uniqueness constraint. Preserve invalid incoming records for explicit
handling rather than deleting them or grouping them into an empty-name Tag.

The previously verified Foundation comparison can suggest an existing Tag:

```swift
import Foundation

func tagNamesSuggestReuse(_ first: String, _ second: String) -> Bool {
    first.trimmingCharacters(in: .whitespacesAndNewlines).compare(
        second.trimmingCharacters(in: .whitespacesAndNewlines),
        options: [.caseInsensitive, .widthInsensitive],
        locale: Locale(identifier: "en_US_POSIX")
    ) == .orderedSame
}
```

Trimming here affects only candidate discovery; it never changes saved input.
Under the verified runtime this suggests Shoes for case/width variants and
くつ for kana-script/width variants. It does not infer that 靴, くつ, and Shoes
mean the same thing. Interior-space variants need not all match. Do not build
custom transliteration, whitespace removal, translation, or synonym rules just
to ensure every potentially related Tag is suggested.

The fixed locale is the previously tested engineering choice for candidate
comparison, not an identity contract. Locale-aware localizedStandardContains
remains suitable for broader user-facing searches. Matching behavior can evolve
without changing stored Tag identity, unlike the retired grouping proposal.
The Foundation method and its options are not a complete suggestion UI.

## Search, Display, and References

Text search may find several Tags. Present them as separate results even when
their names look identical. Selecting one result filters by that UUID only.
A general Item text search may match through several Tag names and return each
Item once; deduplicating Item results is not consolidating the matching Tags.
If a future UI permits explicitly selecting several Tags, it must state its
union/intersection semantics rather than infer a multi-Tag selection from a name.

Identical-looking results need useful selection context. Related Item counts
and an Item preview are candidate UI aids; a count alone is not sufficient when
counts tie. Show saved names faithfully, and make edge whitespace inspectable
in editing or management without rewriting the stored value. Ordinary users
need not see UUIDs. Specific presentation needs screen-level verification.

No persistent logical-group identity, name-to-group resolver, or representative
Tag is required for ordinary navigation, filtering, counts, rename, or deletion.
All surfaces keep the familiar relationship between a selected Tag UUID and its
related Items. Preserve UUID references through export/import; never collapse
different UUIDs merely because names compare equal. Conflicting contents with
the same UUID remain a separate import-conflict question.

## Explicit Consolidation: Product Intent and Open Persistence Boundary

The owner wants a way to combine deliberately selected Tags, including exact
same-name duplicates and different labels such as 靴 and Shoes. The app does not
need to infer semantic equivalence when the person selects the sources.

The proposed interaction should make the following concrete:

1. Which Tag UUIDs are being combined.
2. Which destination Tag survives, and its resulting name.
3. Which Item assignments change; an Item assigned to both must not acquire a
   duplicate destination assignment.
4. What happens to the source Tags, existing links, and undo/recovery.

Choosing the destination is a user decision, not an implicit lowest-UUID or
highest-count policy. A suggested destination is allowed if the result is
visible and selectable. Renaming one Tag to the other's text is not a substitute
for consolidation now that identity is explicitly UUID-based.

For a complete local graph, changing source assignments to a destination and
removing the sources is conceptually straightforward. The earlier local probe
of this alternative passed five assertions; it did not establish safe behavior
with asynchronous CloudKit changes. Do not present that local check as a final
synced consolidation implementation.

User authorization resolves who decides to consolidate, but does not make
CloudKit relationship delivery atomic. A source Tag may have relationships on
another device that have not reached this device. Deleting it immediately after
moving only locally known assignments can remove relationships that were never
transferred. A currently empty inverse relationship or a recent successful local
save does not establish that all peers have finished.

Apple's [sharing sample][sharing-sample] explicitly documents this loss hazard
and delays duplicate deletion while transferring arriving relationships. It is
Core Data sample evidence, not a direct SwiftData implementation recipe and not
a mandate to adopt its history/deduplication machinery. The [SwiftData sync
contract][cloudkit] likewise does not guarantee atomic relationship updates.

The remaining consolidation decision is the source-record lifecycle and
concurrency contract for this explicit operation. It must consider late assignments,
concurrent consolidation, destination deletion, failure, and old UUID links.
Do not silently add permanent redirect records, automatic name grouping,
custom sync, or a claim of safe immediate deletion. If a complete merge requires
excessive machinery, simplify or bound the feature openly before implementation.
The presence of duplicates is acceptable in the meantime and is never a reason
for automatic data repair.

Keeping the current three Tag fields is sufficient for the accepted ordinary
operations. Whether explicit consolidation needs additional persisted state is
open; do not freeze that part of the physical schema prematurely.

## Sequencing Before the Physical Schema Is Frozen

Recommend settling export/import identity and the native synchronization and
deletion contract before choosing the consolidation mechanism. This changes the
previous ordering that made a completed merge design a prerequisite for the
next contract discussion. It does not cancel the requested feature or silently
move it to a post-1.0 release.

The information needed for future consolidation is already retained: each Tag's
UUID, original name, and Item assignments. No consolidation has happened in the
new design, so there is no past consolidation decision that must be captured
now. Do not add speculative redirect or history fields merely to reserve space.

Export/import must first preserve distinct UUIDs, handle same-UUID conflicts,
and distinguish restoration from new copies. Native sync review must establish
the scope of deletion and concurrently arriving changes. Then choose the merge
semantics, including source UUID references in old exports and links. Keeping
references UUID-based is settled; permanent resolution of removed source UUIDs
is not promised.

If consolidation ships in 1.0, finalize its persistence needs and verify its
sync behavior before freezing the production schema or public reference/file
contracts. Deferring that decision within the design process is not a claim
that adding it after release will be migration-free or trivial. If its cost
requires reducing scope, explain the concrete tradeoff to the owner first.

## Evidence and Superseded Experiments

The existing Foundation probes remain evidence for suggestions. They compared
seven approaches across 23 pairs, followed by 14 pairs across five approaches
and five pairs with isolated comparison options. Under the tested en_US_POSIX
locale, the kana pairs compared equal even without case/width options; this is
native collation behavior, not an app conversion. These observations on macOS
27.2 / Xcode 27.2 do not promise the same results for every OS, locale, or API.

Earlier SwiftData probes verified retained same-name records, shared rename,
nullify deletion, UUID-based Item filtering, and a limited Codable graph round
trip. The 32-assertion grouping probe and the 22-assertion grouping/export probe
also tested behavior that is now superseded. Their passing results do not mean
that the accepted UUID-specific UI has been implemented or tested end to end.
Sources and results remain in the previously recorded temporary directories;
no personal images were added to the repository.

This revision updates design records only. No new runtime test, production
implementation, real multi-device CloudKit verification, or full import/export
contract is claimed. The explicit consolidation feature remains the outstanding
Tag-specific technical decision.

[sharing-sample]: https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users
[cloudkit]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
