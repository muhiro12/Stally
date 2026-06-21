# Domain Concepts

## Item

An item is a personal possession the user may choose repeatedly.

The legacy product examples are intentionally ordinary and tactile:

- Black Wool Coat.
- White Everyday Sneakers.
- Canvas Tote.
- Daily Field Notes.
- Travel Weekender.

This suggests Stally is about personal pieces that carry usage history, not
abstract tasks.

The sample notes also preserve tone:

- "The one I reach for on cold mornings."
- "Easy pair for short walks and errands."
- "Usually comes with me when I need one extra layer."
- "Still waiting for its first stretch of regular use."
- "Archived because it only comes out a few times a year."

These are examples of product language, not a requirement to ship the same
sample dataset.

## Category

The preserved categories are:

- Clothing.
- Shoes.
- Bags.
- Notebooks.
- Other.

The empty-state copy says these categories are enough to begin. A future
rebuild should not expand the taxonomy merely because new categories are easy
to add.

## Note

A note adds context to an item.

Legacy guidance says a short note makes history easier to read later. Notes
are optional, but Insights may suggest adding context to frequent items that
lack notes.

## Photo

A photo is optional visual context for an item. It helps identify or remember
the item, but the product does not require every item to have one.

## Mark

A mark is the central signal in Stally.

One filled day means the user chose that item on that date. The product copy
uses "One mark is enough for today" to keep capture lightweight.

Preserve these mark rules:

- A user can mark an item for today.
- A user can undo today's mark.
- A user can add or remove a mark on another selected day.
- A mark belongs to one item and one calendar day.
- The same item should not need multiple marks on the same day.
- Mark history accumulates one day at a time.
- Archived items keep history but should be moved back to Library before
  history is changed.

## Library

Library is the active collection.

It should help the user see active items, mark today's choices, search and
filter items, and notice what still has room to accumulate.

Important filters and sort concepts are:

- All.
- All Categories.
- Open Today.
- Marked Today.
- Marked on Day.
- Open on Day.
- Never Marked.
- With History.
- Without History.
- Default Order.
- Recently Marked.
- Most Marked.
- Name.
- Category.

Item detail should also preserve a compact reading of one item's history:

- Total marks.
- Last marked.
- Marks in the last 30 days.
- Marks in the last 90 days.
- Months used.
- Days since last mark.
- Quiet History as a calendar-like record of marked days.

## Archive

Archive is a preserved collection of items that should stay nearby without
crowding the active Library.

Archive is not deletion. Archived items keep notes, photos, and marks.

An archived item with meaningful history may later become a Recovery Candidate.
An archived item without history is preserved but does not need active review.

## Review

Review is the attention system.

It is organized around three product lanes:

- Needs First Mark: items waiting quietly without a first mark.
- Dormant: items whose last mark feels far enough away to revisit.
- Recovery Candidates: archived items whose history suggests they may deserve
  another turn.

The legacy defaults treated unmarked items as review candidates after about two
weeks, and previously marked active items as dormant after about one month.
Those values were also user-adjustable, so the enduring concept is thresholded
review rather than hard-coded time.

## Insights

Insights converts marks into collection readings.

Preserved insight concepts include:

- Total marks.
- Active days.
- Unique marked items.
- Unique marked categories.
- Average marks per active day.
- Busiest day.
- Current streak.
- Best streak.
- Idle gap.
- Average marks per week.
- Active weeks.
- Weekend share.
- Category share of marks.
- Top Items.
- Quiet Items.
- Weekday rhythm.
- Monthly rhythm.
- History coverage.
- Note coverage.
- Photo coverage.
- Recently added items.
- Collection health.
- Report scope.
- Spotlight callouts for the top item and quiet item.

Insights ranges are:

- 30 Days.
- 90 Days.
- 365 Days.
- All Time.

The user can choose whether archived items are included in insight readings.

Legacy copy also hinted that Insights could later expand into longer-range
comparisons, saved reports, and trend views beyond one selected window. That
hint preserves a direction for product curiosity, but it does not define a
required feature or implementation.

## Recommendations

Recommendations are quiet next moves derived from the current collection
state.

Preserved recommendation concepts are:

- Start this range with one mark.
- Revisit quiet favorites.
- Add context to frequent items.
- Protect the current streak.

Recommendations should stay grounded in existing item history and should not
invent unrelated goals.

## Backup

Backup protects the user's collection history.

Preserve these concepts:

- Export a portable snapshot containing active items, archived items, notes,
  photos, and mark history.
- Preview an imported backup before applying it.
- Show counts for items, archived items, marks, existing items, new items,
  skipped items, and marks added.
- Surface validation issues before import.
- Merge import preserves local items where appropriate and adds missing data.
- Replace import removes the current library before restoring the selected
  backup.
- Delete Everything intentionally creates an empty library.
- Backup files are for personal archive and transfer, not multi-device sync.

Backup validation concepts include unsupported schema version, duplicate item
ID, duplicate mark ID, and unknown category.

## Shareable Links

The product can copy or share links to major app destinations and individual
items.

Preserved destinations are:

- Library.
- Archive.
- Backup Center.
- Insights.
- Review.
- Create Item.
- Settings.
- Item-specific links.

Unsupported links should produce a user-visible unsupported-link message.
