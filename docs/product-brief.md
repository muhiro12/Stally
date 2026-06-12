# Product Brief

## Summary

Stally is an unfinished iPhone app for quietly tracking the personal items a
user keeps choosing over time.

The product centers on a small personal collection: clothing, shoes, bags,
notebooks, and other everyday pieces. A user adds items they genuinely reach
for, marks an item on the days they choose it, and lets those marks accumulate
into a calm record of use.

Stally is not defined by its legacy implementation. The essential product is a
low-pressure way to remember what still feels current, what has gone quiet, and
what deserves to stay nearby without crowding the active list.

## Core Promise

Stally helps a user build a quiet record of personal choices with minimal daily
effort.

One mark on one day is enough. Over time, those marks become useful signals:
which items are active, which items have not earned a first mark, which
previous favorites have become dormant, and which archived items may deserve
another turn.

## Intended User Value

- Remember the personal items the user actually keeps choosing.
- Keep lightweight context on meaningful items through notes and photos.
- Separate active items from preserved past favorites without losing history.
- Notice neglected items before they drift too far out of mind.
- Read the whole collection as a pattern rather than only as a list.
- Keep a portable backup before risky restore or reset actions.

## Product Surface

The product evidence points to these user-facing areas:

- Library: the active collection of items.
- Item detail and editing: the place to inspect, mark, correct, and describe
  one item.
- Review: attention lanes for items that need a first mark, feel dormant, or
  may deserve a return from Archive.
- Archive: preserved items that stay nearby without crowding the main list.
- Insights: collection-wide patterns, metrics, rankings, rhythm, and next
  moves.
- Backup Center: export, import preview, merge, replace, and reset safety
  tools.
- Settings: quiet app details, review preferences, insights defaults, guidance
  reset, backup access, and shareable routes.

These areas are product concepts. They must not be treated as a requirement to
preserve the old navigation hierarchy, source folders, or screen composition.

## Product Tone

The legacy copy consistently describes Stally as quiet, personal, and
non-judgmental.

Important phrases include:

- "A quiet record of the things you keep choosing."
- "An app for marking your own actions and quietly building up counts."
- "Start with a few pieces you actually reach for."
- "One mark is enough for today."
- "Read the collection as a pattern, not just a list."
- "Past favorites can stay nearby without crowding the main list."

The emotional tone should stay calm and observant. The product should help the
user notice patterns, not pressure them to optimize behavior.

## Essential Concepts

The rebuild must preserve these concepts:

- Item.
- Category.
- Note.
- Photo.
- Mark.
- Mark history.
- Active Library.
- Archive.
- Review lanes.
- Needs First Mark.
- Dormant.
- Recovery Candidates.
- Insights range.
- Activity.
- Consistency.
- Category share.
- Rankings.
- Rhythm.
- Recommendations or next moves.
- Backup export.
- Backup import preview.
- Merge import.
- Replace import.
- Delete everything or reset.
- Shareable links to product destinations and items.

## Deliberately Discarded Evidence

The following legacy details are not product knowledge and should not be
preserved as rebuild requirements:

- Xcode project structure.
- SwiftUI view hierarchy.
- Swift type names, property names, and function names.
- Source folder and module boundaries.
- SwiftData storage model.
- JSON backup schema shape.
- Routing implementation.
- TipKit, package, or framework choices.
- Workarounds, technical debt, and pre-release compatibility choices.

Only the user-facing meaning behind those details should survive.
