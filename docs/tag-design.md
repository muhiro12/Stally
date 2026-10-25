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
schema changed. The owner wants an explicit consolidation feature. The October
25 recommendation below is a bounded, user-reviewed reassignment and source
deletion, not a permanent identity alias or globally lossless merge. This
recommendation awaits acceptance; cloud behavior is not qualified.

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
| Explicitly consolidate selected Tags | Perform a separate deliberate operation with a chosen destination; see the bounded operation below |

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

## Explicit Consolidation: Recommended Bounded Operation

Recommend a one-time operation that replaces selected source Tag assignments
with one user-selected existing destination Tag, then deletes the selected
source Tags. This follows the accepted proportionate-cost and recovery policy:
perform an ordinary domain mutation, qualify its concrete consequences, and do
not build a permanent synchronization protocol merely to prevent every conflict.

This is not a native SwiftData merge API. Stally owns the small business
operation; SwiftData supplies relationships, deletion, local saving, and
rollback. Apple Reminders [documents user-facing tag merging][reminders], but
that does not reveal or endorse any particular SwiftData implementation.
Stally's explicit UUID-based selection remains different from rename-to-merge.

### Alternatives

| Approach | Advantage | Cost or limitation | Recommendation |
| --- | --- | --- | --- |
| Reassign the reviewed relationships and delete source Tags | One surviving Tag, ordinary relationships, unchanged three-field schema | Old source references stop resolving; unseen remote assignments may be lost | Recommend as an explicitly bounded operation, not a global preservation promise |
| Reassign but keep source Tags | Source UUIDs still exist; later source assignments remain inspectable | Does not finish combining Tags; empty source Tags remain separate and future use can diverge | Prefer if stronger retention is required; label it reassignment rather than completed consolidation |
| Retire sources and continuously transfer later assignments | Can preserve more delayed relationships | Requires persistent retirement state, ongoing processing, concurrent-target rules, and eventual cleanup policy | Not justified for 1.0 by current requirements |
| Keep permanent source-to-destination aliases | Old references can follow the decision | Resolver logic affects search, links, imports, cycles, destination deletion, and concurrent merges | Not recommended |

The first option's cost is real: deletion can remove source relationships that
this device never saw. It is accepted as a proposed bounded-operation tradeoff,
not reclassified as Apple's fault or cured by a confirmation dialog. If the
product instead promises that every source assignment on every device survives,
this implementation is insufficient. Reduce scope to reassignment or revisit
retention then; do not claim that waiting a fixed time proves completeness.

### User-visible Result

For source A and destination B:

- Keep B's UUID and name. The user chooses B; no most-used or lowest-UUID rule.
- Replace A with B on each reviewed Item. An Item already using both ends with
  B once. Preserve unrelated Tag memberships.
- Preserve the Item itself, its name/note/states, Marks, periods, and photos.
- Delete A. Source names are not kept as synonyms and old A links do not redirect.
- Rename B separately if desired; consolidation does not silently choose a name.

Support several sources into one existing destination with these same rules.
A source/destination label need not look similar; user selection establishes the
intent. An unassigned source can be deliberately removed through the operation,
but an empty inverse is not evidence that the cloud has no other assignments.

The review identifies selected sources, the surviving destination, and the
currently affected Item set/count, and states that source Tags will be deleted.
Do not describe this as an all-device snapshot. Keep the normal action concise;
place consequences and the export option in this destructive-operation review,
not repetitive warnings during ordinary tagging. Preserve the established
ability to create or rename distinct same-name Tags without automatic merging.

### Applying the Operation

1. Resolve the selected UUIDs in the current store. Reject ambiguous UUIDs,
   missing destinations, or changed source selection rather than matching names.
2. Fetch current affected Item relationships and capture a review snapshot of
   relevant Tag identities/names and memberships. Include Items already using
   the destination; their assignment should not be duplicated.
3. Before applying, use fresh reads to check that the locally visible affected
   set and values still match the review. If changed, refresh the review. This
   guards stale local decisions, not concurrent changes on unknown peers.
4. In an operation-owned context with autosave disabled, replace only source
   assignments, retain other memberships, and delete only selected source Tags.
   Complete the mutation without suspension and save once. A save failure must
   not be presented as completion; discard this operation's pending changes.
5. Refresh selection/navigation after successful save. The initiating screen
   can select B explicitly; that does not create a permanent A-to-B redirect.

Use existing Operations boundaries. Do not modify model defaults, add an
operation log, or route all future reads through a resolver. Do not reconstruct
or silently recreate a source/destination deleted since review. A later retry
with absent source UUIDs requires refreshed state, not inference that another
actor already completed the same merge.

### Concurrent Arrival and Deletion

Apple's [sharing sample][sharing-sample] documents a concrete relationship-loss
case when a duplicate Tag is deleted before its associated records arrive. Its
history queue and delayed cleanup solve a broader automatic deduplication task;
Stally does not copy that machinery. The example still applies as a warning
about the scope of explicit source deletion.

A single local save does not make cloud relationship transfer and source deletion
atomic. A late source assignment may be removed without being transferred;
independent source recreation may remain a separate Tag; a concurrent destination
deletion or competing A-to-B/A-to-C operation is resolved through native sync.
No deterministic global winner or complete relationship preservation is promised.
There is no app-owned background replay after the operation.

The implementation must preserve every locally reviewed relationship and refuse
known stale inputs. Representative two-device checks should exercise late
assignments and competing deletion to establish actual UI behavior. They do
not need to prove that every distributed interleaving is prevented.

### Recovery and Old References

- Cancellation before applying writes nothing. Failure before a successful save
  rolls back only this operation's pending changes.
- Offer access to the existing export feature before the destructive operation.
  Do not introduce mandatory automatic backups or a new file format for merging.
- Restoration from a prior export needs the source Tags **and their Item
  assignments**, through normal import conflict review. Recreating an empty
  source Tag alone does not restore the old grouping. An export cannot restore
  unseen remote assignments or changes absent from that file.
- A historical export containing deleted A can offer A and its assignments again
  through the accepted absent-UUID and existing-Item conflict rules. Do not
  reinterpret A as B; the file does not contain this consolidation decision.
- Old A links report an unavailable Tag. They must not search by name and select
  B or a newly created lookalike. Shared destination B links continue to work.
- Immediate native Undo is desirable only if the full operation and subsequent
  edits are verified. It is not part of the guaranteed recovery contract yet;
  the standalone experiment below did not restore the full saved graph.

The initial recovery proposal therefore uses cancellation, bounded rollback,
ordinary editing, and existing export/import. It does not promise undo after
relaunch, cross-device rollback, or recovery without a surviving copy.

### Schema Impact and Decision Status

Keep Tag as uuid, name, and optional items. No mergedInto, retiredAt, deletedAt,
alias array, or persistent merge model is recommended. The cost is deliberately
finite source lifetime and no memory of the old merge for future imports.
This is an engineering recommendation awaiting owner acceptance, not a change
to the currently implemented app or proof of synced safety.

## October 25 Local Consolidation Probe

A disposable five-model disk store was exercised with two source Tags, one
destination, one unrelated Tag, and five Items covering source-only,
destination-only, overlapping source/destination, and unrelated assignments.
Each Item also had a Mark, Period, and photo payload. Probe files are outside Git.

The final seed/rollback/apply/reopen sequence ran as separate macOS 27.2
processes with Xcode 27.2 / Swift 6.4.2 and CloudKit disabled. All four stages
passed: seed 2 checks, rollback 3, apply 3, and final reopen 25, totaling 33.
The final stage logs contained no warning/error diagnostics. It verifies the
relationship union without duplicate assignments, preservation of unrelated
memberships and owned records, source removal, and the absence of old source IDs.
The injected failure occurs before save; it is not a disk-full or cloud failure.

Two separate Undo experiments registered an UndoManager and a group, with save
outside and inside the group respectively. Both reported an available undo but
failed the exact UUID/name/membership restoration assertion after undo and save.
The inspected snapshots still showed the merged graph. This establishes a
failure of these standalone attempts, not a universal SwiftData Undo defect or
proof that a correct UI-integrated implementation is impossible. Do not claim
an immediate Undo feature from API availability alone. The final merge/rollback
sequence excludes Undo and does not disguise those failed experiments as passes.

No new iOS runtime, actual cloud synchronization, complete export/import
round trip, or UI recovery verification was performed in this probe. These
limits are separate from the earlier iOS graph tests in the lifecycle review.

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

Those earlier revisions updated design records without new runtime evidence.
The October 25 probe above adds bounded local consolidation evidence, not
production implementation, real multi-device CloudKit verification, or a full
import/export round trip. The bounded operation and recovery proposal await
acceptance; immediate Undo remains unqualified.

[sharing-sample]: https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users
[cloudkit]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices

[reminders]: https://support.apple.com/en-asia/guide/reminders/remn45640f4f/mac
