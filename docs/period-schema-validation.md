# Period Schema Validation

## Selected Schema

On October 24, 2026, select the following ItemPeriod attributes for the 1.0
redesign. This is a design decision with standalone runtime evidence, not an
application-schema deployment or an old-store migration.

```swift
@Model
final class ItemPeriod {
    var uuid: UUID = UUID()
    var startLocalDate: String?
    var endLocalDate: String?
    var isOngoing: Bool = true
    var createdAt: Date = Date()
    var item: Item?

    init(
        item: Item?,
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
```

The probe used this storage shape, with validation in PeriodOperations before
normal mutations. A normal creation requires a real owning Item; the optional
stored relationship also represents an incompletely available graph. Inverse
relationships are declared on Item with cascade deletion for owned periods
and Marks. The child-to-parent relationship uses the default nullify rule.

### Naming and Metadata

- Replace `startDateRawValue` and `endDateRawValue` with `startLocalDate` and
  `endLocalDate`. They are canonical civil-date text, consistent with the
  accepted `ItemMark.localDateTime`. The properties express domain meaning
  without a RawValue suffix. They do not denote absolute Date instants.
- Keep `uuid`, `item`, and `isOngoing`. The latter reads as an assertion about
  the period and describes its two-state continuation fact. An enum or a
  separate ended flag is not needed for the current states.
- Add `createdAt: Date`, consistent with Item and ItemMark. It supports entry
  ordering when period dates are unknown and records when a historical period
  was entered. It is never a fallback start/end date or proof of chronological
  relationship order. Keep it unchanged during corrections and preserve it
  during identity-preserving export/import.
- Do not add stored duration, precision flags, normalized endpoint Dates,
  timezone identifiers, current-period pointers, or modification timestamps.

These are Stally naming decisions guided by [Swift API conventions][naming],
not names prescribed by Apple.

## States and Precision

Both boundaries independently support nil, `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`.
The calendar is Gregorian. Nil means unknown; an empty string is invalid.
Initial period boundaries do not include times or zones. Precision is encoded
by the canonical spelling and does not require a second stored attribute.

| Continuation | End boundary | Ordinary local edit |
| --- | --- | --- |
| Ongoing | Unknown | Valid |
| Ongoing | Entered year, month, or day | Reject as inconsistent |
| Ended | Unknown | Valid: known to have ended, date unknown |
| Ended | Entered year, month, or day | Valid if boundaries are not definitely reversed |

Start precision is independent of this table. No periods means the person has
not described the relationship history; it does not mean an ended relationship.
A new Item does not automatically receive a period or a purchase/start date.

### Native Partial-Date Comparison

The probe validates fixed Gregorian date text with Foundation DateFormatter
using `en_US_POSIX`, `isLenient = false`, and an exact format/parse round trip.
Its actual format patterns use lowercase `yyyy`. It obtains comparison ranges
with Calendar's year, month, and day intervals in a fixed UTC reference zone.
DateComponents retains only the supplied components for in-memory use.
There is no custom leap-year calculation or timezone-offset arithmetic.

A range is temporary comparison information, not a stored assertion that an
unknown month or day was January or the first day. For example, `2024` permits
any date within that year; it does not assert January 1 as the relationship
start. Durations must not treat these comparison bounds as measured endpoints.

Reject reversed boundaries only when the earliest possible start is after the
latest possible end. Consequently:

- `2024` to `2023` is rejected.
- `2024-06` to `2024-05` is rejected.
- `2024-05-13` to `2024-05-12` is rejected.
- `2024-05` to `2024` is accepted as uncertain.
- `2024-05-31` to `2024-05` is accepted as uncertain.
- `2024` to `2024-01-01` is accepted as possible.
- The same exact start and end date is accepted.

Raw String ordering is therefore useful for fixed-prefix year searches but
must not substitute for semantic boundary validation across mixed precision.
A native SwiftData year-range predicate included year-only, month, and day
start values and excluded unknown starts in the disk-store check.

## Ending, Resuming, and Correcting

PeriodOperations validates the proposed value and its relevant siblings before
mutating or inserting a model. A rejected end or overlap does not leave a
partially changed record. The probe explicitly saved each successful operation.

- End: retain the start, UUID, and createdAt; set isOngoing false. Keep the end
  nil unless the person supplies date knowledge. Ending today is explicit.
- Resume: retain the ended record and create a new ongoing ItemPeriod with a
  new UUID and creation instant. Accept an unknown new start if appropriate.
- Correct an accidental end: clear the end and restore ongoing on the same
  record. Do not create another period or overwrite its creation metadata.
- Change archive, favorite, or Mark-recording preferences: do not change period
  history. These are independent Item facts.
- Delete one period: remove that knowledge only; keep its Item, the other
  periods, and the Item's Marks. Marks do not belong to a period.
- Delete an Item: cascade to its owned periods and Marks; preserve unrelated
  Items and their histories.

### Local Validation Versus Incoming Conflicts

Ordinary local operations allow at most one ongoing period per Item. They also
reject a positive-day overlap that is definite even at the entered precision.
The check is conservative: unknown bounds and merely possible overlaps do not
justify inventing dates or silently rejecting valid uncertain history.
For ongoing periods, the comparison uses the current local Gregorian day,
converted to the common reference calendar for comparison only.

Ending and resuming on the same calendar date is permitted. With day-only
boundaries, Stally cannot infer within-day ordering or invent an unused day
between the periods. A shared boundary date is not automatically an error;
any future duration aggregation must avoid double-counting it.

The probe also inserted conflicting ongoing periods, an ongoing record with an
end, and an unattached period directly into a synthetic store to represent
possible incoming data shapes. They survived reopen without deletion or
silent repair. Normal operations detected the conflict/inconsistency before
adding a new ongoing period. This is bounded local validation and preservation,
not a distributed uniqueness guarantee or a CloudKit conflict simulation.

## Verification Evidence

Toolchain: Xcode 27.2 build 27B48, Apple Swift 6.4.2. Runtime targets: macOS
27.2
and a dedicated iPhone 17 Simulator running iOS 27.2 build 24B114.
Each store used an explicit temporary disk URL and `cloudKitDatabase: .none`.
Each write/read or operation/reopen pair used separate process invocations.

The independent compiler/Simulator route retained the same scope as the earlier
[Mark comparison](mark-temporal-schema-comparison.md). The observed Xcode-native
snippet dependency/deployment-target mismatch was not repaired by changing the
app. Stally's original scheme and My Mac destination remained unchanged.

There were 125 successful assertions on each runtime across 15 process stages:

| Group | Assertions | Coverage |
| --- | ---: | --- |
| Semantic/date checks | 67 | 32 state/precision combinations, valid and invalid text, leap month, reversed and uncertain boundaries, overlap, local-day conversion |
| Initial write and independent read | 32 | All 20 valid representative state combinations, precision, inverse relationships, state/year predicates, incoming conflict preservation |
| End and reopen | 6 | Rejected reverse edit leaves data unchanged; unknown end and original identity/creation time survive |
| Resume and reopen | 7 | New period identity, old history preservation, single ongoing local rule, independent Item flags and Marks |
| Correct accidental end and reopen | 2 | Reuse of the current record without another period |
| Delete child and reopen | 2 | Item, Mark, and sibling period preserved |
| Delete parent and reopen | 5 | Owned cascade, unrelated history and unattached data preserved |
| Same-day boundary operations and reopen | 4 | Definite overlap rejected before insert; same-day close/reopen accepted |

All final stage processes exited successfully on both platforms. Captured final
logs contained no warning, error, or fatal diagnostics. The 32-case matrix used
four start representations, four end representations, and two continuation
states. The 20 valid combinations were also written and reopened with exact
field comparison; the other combinations were rejected before ordinary writes.

## Evidence Limits

This does not establish physical-device CloudKit propagation, concurrent merge
behavior, production-schema compatibility, migration of an existing app store,
app UI flows, or duration-display semantics. Native mirroring's optional
relationship/default requirements remain applicable. The local guards are not
server constraints, and incoming conflicts must remain recoverable.

The application implementation is unchanged. The selected schema and operation
semantics are ready to guide that later implementation. The public export
contract must preserve partial-date precision, UUIDs, continuation state, and
creation metadata without inventing unknown dates.

Apple's [DateComponents][components] and [Calendar intervals][intervals] supply
native building blocks for partial knowledge and comparison. Its
[relationship guidance][relationships] supplies the inverse and cascade
behavior exercised here.

[naming]: https://www.swift.org/documentation/api-design-guidelines/
[components]: https://developer.apple.com/documentation/foundation/datecomponents
[intervals]: https://developer.apple.com/documentation/foundation/calendar/dateinterval(of:for:)
[relationships]: https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes
