# Preserved Concepts

## Preservation Rule

Preserve product meaning, not implementation shape.

The old repository is archaeological evidence of intent. A future rebuild may
delete every source file and create a new project, but the product concepts in
this document must survive unless a later explicit product decision changes
them.

## Product Concepts To Preserve

### Stally

The product name is Stally.

The legacy concept line is:

> An app for marking your own actions and quietly building up counts.

The strongest product summary is:

> A quiet record of the things you keep choosing.

### Item

An item is a personal object the user can repeatedly mark as chosen on a day.
Evidence strongly centers on clothing, shoes, bags, notebooks, and a small
other category.

Items can have:

- A name.
- A category.
- An optional note.
- An optional photo.
- A mark history.
- Active or archived state.

### Mark

A mark records that the user chose an item on a specific day.

The product language treats a filled day as meaning the user chose the item on
that date. One mark per item per day is enough.

### Library

Library is the active collection. It is where current items live and where
today's marks are balanced against items that still need room to accumulate.

### Archive

Archive keeps past favorites nearby without crowding the main list.

Archived items preserve their marks and context. Legacy copy treats archived
items as read-only for mark changes until they are moved back to Library.

### Review

Review gathers items needing attention before they drift too far out of mind.
It contains three core lanes:

- Needs First Mark.
- Dormant.
- Recovery Candidates.

Review actions include archiving items that remain untouched or dormant, and
moving recovery candidates back to Library.

### Insights

Insights reads the collection as a pattern, not just a list.

Insights should preserve:

- Activity.
- Consistency.
- Categories.
- Rankings.
- Rhythm.
- Recommendations or next moves.
- Range controls for 30 Days, 90 Days, 365 Days, and All Time.
- Optional inclusion of archived items.
- Shareable or copyable insight reports.

### Backup Center

Backup Center groups higher-risk data actions.

It should preserve:

- Export of the full collection.
- Import preview before restore.
- Merge into Library.
- Replace Library.
- Delete Everything or reset.
- Clear safety copy around destructive actions.
- The `.stallybackup` product-facing file extension unless later changed by an
  explicit product decision.

### Deep Links And Sharing

The product includes shareable links to major app destinations and individual
items. Unsupported links should be handled as unsupported rather than silently
ignored.

## Product Language To Preserve

Preserve these nouns:

- Stally.
- Item.
- Mark.
- Library.
- Archive.
- Review.
- Insights.
- Backup Center.
- Needs First Mark.
- Dormant.
- Recovery Candidates.
- Quiet Items.
- Top Items.
- Next Moves.
- Quiet History.

Preserve these verbs:

- Add.
- Mark.
- Undo.
- Adjust.
- Archive.
- Move Back to Library.
- Export.
- Import.
- Merge.
- Replace.
- Restore.
- Copy.
- Share.

## Workflow Concepts To Preserve

- Start empty by adding the first item, trying sample items, or restoring from
  backup.
- Add a real item the user reaches for.
- Mark an item for today.
- Adjust a mark on a past day carefully.
- Search, filter, and sort active and archived lists.
- Review untouched, dormant, and recovery-candidate items.
- Archive and restore items one at a time or in lane groups.
- Read insights by selected time range.
- Include or exclude archived items from insight readings.
- Export before replace-style restore or reset.
- Preview backup import results before merge or replace.

## Discarded Implementation Details

The following must not be preserved as rebuild requirements:

- Legacy source tree layout.
- Legacy app target and library target boundaries.
- Swift type, property, parameter, or file names.
- SwiftUI hierarchy and navigation implementation.
- SwiftData schema details and relationship rules.
- Package choices and platform helper abstractions.
- Tip implementation.
- Ad and diagnostics implementation.
- Test file structure.
- Backup codec internals and schema fields.
- CI script structure.
- Architecture decisions written for the legacy implementation.

The user-facing concepts that happened to be expressed through those details
are preserved elsewhere in `docs/`.
