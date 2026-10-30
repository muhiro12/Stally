# Period Readings Design

## Status

On October 30, the owner selected **current ongoing period length** and
**cumulative length across recorded periods**, personally favoring the latter.
See [the accepted product scope](product-behavior-design.md#revisit-and-understand-the-record).
The current-period reading replaces this earlier proposal's "since first
start" candidate for the selected pair. It starts at the current ongoing
period, not at the earliest historical start. If no period is ongoing, there
is no current-period length; retained ended periods still contribute to the
cumulative reading when calculable.

The October 25 proposal below remains historical engineering material. Its
counting, precision, incomplete-total, and conflict policies are not accepted
by the October 30 feature selection. In particular, do not silently inherit
either its since-first-start definition or its all-or-nothing numeric-total
policy. Update the calculation specification after the remaining product
choices are made; the earlier probe does not verify that future specification.

This October 25, 2026 engineering recommendation builds on the accepted
[ItemPeriod schema and lifecycle](period-schema-validation.md). It awaits owner
review. No production calculator, UI, schema, migration, or export codec changes.
The existing fields suffice; readings are derived values.

Periods describe the relationship the person chose to track. Marks describe
separate occurrences. Neither supplies missing facts about the other. Do not
infer ownership, continuous use, or missing dates from registration metadata.

## Two Readings

| Reading | Meaning | End and resume behavior |
| --- | --- | --- |
| Since first start | Calendar difference from the earliest established start among recorded periods to today's local Gregorian date | Advances through gaps and after an end; resuming does not reset it |
| Total period duration | Sum of calendar-day differences within valid recorded periods; only an ongoing period uses today as its endpoint | Ended portions stay fixed; gaps contribute nothing; resuming adds another span |

The scope is the recorded history, not a claim that all lifetime history is
known. Do not label the first reading "continuously used for" or the second
"days used": a Mark-based count is a separate metric. Show ended relationship
status alongside a since-first-start reading so it does not imply continuation.

Archive, favorite, and Mark-recording preferences affect neither reading.
Deleting or correcting a period can legitimately change either reading. Do not
retain a hidden earliest-start value or freeze a previously calculated total.

## Counting Convention

Recommend calendar-date subtraction for both metrics: January 1 to January 2
is one elapsed calendar day; January 1 to January 1 is zero elapsed days. An
ongoing period starting today has zero elapsed days. A same-day ended period
still records a meaningful relationship; use "started today" or "started and
ended on the same date" where more helpful than a bare zero.

This is calendar progression at day precision, not completed 24-hour blocks or
measured physical time. Temporary endpoint Dates do not assert that the person
started or ended at midnight. Zero does not mean no relationship or no use.

| Convention | Assessment |
| --- | --- |
| Date difference | Recommended: coherent across both metrics; shared end/resume boundaries compose without adjustment |
| Count both boundary dates | Appropriate for a separate count of dates touched; adds one to isolated spans and needs deduplication at shared boundaries |
| Seconds divided by 86,400 | Not appropriate: Period has no instants, and local days need not have a fixed number of hours |

The convention is Stally's product choice, not a rule mandated by Apple.
Adding one would change the metric to inclusive date counting, not fix this
duration. A later "dates covered" feature needs its own name and definition.

For calculation, each precise span behaves as `[start, end)` on a calendar-day
axis. Do not use those reference bounds or DateInterval.contains to restrict
Marks; Marks do not belong to periods.

### Examples

Assume the local reference day is February 1, 2026.

| Recorded periods | Since first start | Total period duration |
| --- | --- | --- |
| January 1 to January 11; January 21 to ongoing | 31 days | 21 days: 10 plus 11 |
| January 1 to January 11; January 11 to January 21 | 31 days | 20 days, with no duplicated boundary |
| January 1 to January 11, ended | 31 days | 10 days, fixed after ending |
| February 1 to ongoing | Started today; zero elapsed days | Zero elapsed days |
| January 1 to January 1, ended | 31 days | Same-day period; zero elapsed days |
| January 1 to an unknown end, ended | 31 days | Unavailable: end date unknown |
| No periods | No period history | No period history, not zero |

## Unknown and Partial Dates

Keep the supplied precision in storage and presentation. The first release does
not choose January 1, a month's first/middle day, or an average year length to
turn partial knowledge into a point estimate.

| Knowledge | Presentation | Duration |
| --- | --- | --- |
| Exact start and exact end, or exact start and ongoing | Exact date range or ongoing status | Calculable at calendar-day precision |
| Start `2020` | Started in 2020 | No exact day total or anniversary counter |
| Start `2020-05` | Started in May 2020 | Do not treat it as May 1 |
| End known by year/month only | Ended in that year/month | No exact duration for this period |
| Start unknown | Start date unknown | No start-based duration |
| End unknown, ended | Ended; end date unknown | Never substitute today or createdAt |
| End unknown, ongoing | Ongoing | Today is the evaluation endpoint if start is exact |

"Since May 2020" or "May 2020 to 2022" remains useful information. Partial dates
are valid knowledge, not an error requiring the person to invent a day.

### Establishing the First Start

Do not order history by UUID, createdAt, array position, or mixed-precision raw
string ordering. An exact first-start reading is allowed when one exact start
is known and no other recorded period could start earlier. Reuse the existing
Foundation comparison ranges: that exact day must be no later than the earliest
possible day of every other start. An unknown start prevents that conclusion.

- Exact January 1, 2020 followed by a year-only 2025 start permits exact elapsed
  calculation from January 1, 2020, but does not permit an exact total.
- Year-only 2020 and exact June 1, 2020 do not establish an exact first day.
  Choosing the first precise value would discard the earlier uncertainty.
- Unknown start and exact 2020 start do not prove that history began in 2020.

For one period, display its supplied start at its own precision. When multiple
uncertain starts cannot be confidently ordered, show their individual records
without manufacturing one earliest date. Comparison bounds never become
duration endpoints just because they are available for validation.

### Total with Incomplete Knowledge

Show a numeric total only when every period supplies an exact, consistent
day-precision span. Otherwise show why the total is unavailable: unknown dates
or dates known only by year/month. Precise individual periods may still show
their own durations. Do not label their subtotal as the complete Item total.

Do not implement a tight minimum/maximum solver across uncertain boundaries,
possible overlaps, and uncertain ordering for 1.0. Calendar provides component
calculations and comparisons, not the domain uncertainty policy. Faithful date
statements provide useful output without that additional machinery.

An explicitly labeled estimate or a derived uncertainty range could be added
later without changing the stored facts. Estimates introduce assumptions; naive
sums of independent ranges can misrepresent overlaps. Neither alternative is
impossible, but neither is needed to preserve or display current date knowledge.

## Conflicts and Future Dates

Keep the accepted local rules: at most one ongoing period, no ongoing/end
contradiction, no definitely reversed boundaries, and no definite positive-day
overlap. Possible overlap caused only by partial precision remains uncertainty.

If inconsistent records arrive, retain them and indicate that the history needs
review. Withhold aggregate numeric headlines; do not select a winner, count
overlaps twice, or silently union them into a corrected history. The period list
and unrelated Item/Mark operations remain usable. Shared end/resume dates are
valid and compose naturally under date subtraction.

A start definitely after today, or an ended period whose end is definitely in
the future, cannot be presented as elapsed history under this 1.0 contract.
Show that the dates need checking, without deleting them or clamping them to
today/zero. A partial year/month containing today is not definitely future.
This is a reading state, not a new stored planned state or an independent change
to accepted write validation. Re-evaluate when the local day changes; travel or
clock changes must not permanently flag or modify records.

## Apple-Native Implementation Direction

1. Capture one evaluation instant and device timezone for the calculation pass.
   Extract today's Gregorian year, month, and day in that zone.
2. Map civil components into the fixed Gregorian/UTC comparison calendar used
   by Period validation. These Dates are temporary references, not new facts.
3. Use `Calendar.dateComponents([.day], from:to:)` for day differences. Do not
   divide local seconds by 86,400 or maintain a custom leap-year table.
4. For a single exact since-start span, use Calendar's year/month/day components
   and native localized formatting. Preserve Gregorian semantics and precision;
   the user's locale controls presentation, not stored date interpretation.
5. Keep sums of disconnected spans in days. Do not sum their year/month/day
   components or convert the total with 365/30 or an arbitrary anchor Date.
   Months and years have context-dependent lengths. A rounded approximation
   would need an explicit, separately labeled presentation contract.

For example, the host Calendar reports one month from January 31 to February
29, 2024, and 29 days when asked only for days. Both are meaningful for that
single span; neither defines a universal conversion for disconnected spans.

Stored civil dates do not move across timezones. Today does depend on the local
day, so travel can move an ongoing reading forward or backward by a day. Accept
that normal behavior; do not add persisted timezones or monotonic counters to
hide it. Closed-period totals do not depend on today or the current timezone.
Refresh on relevant local-day/timezone changes and foreground entry without
persisting a daily ticking value.

No schema or file fields are needed. In-memory results should distinguish exact,
partial-date, unknown-date, no-history, and needs-review. These are not new
persisted statuses. A nullable integer alone must not conflate zero and unknown.

## Bounded Verification

A standalone Foundation probe on Xcode 27.2 / Swift 6.4.2 / macOS 27.2 passed
43 assertions covering:

- Strict date parsing; leap/non-leap February; invalid text and dates.
- Same/next day, month ends, and 365/366-day year spans.
- Gaps, shared end/resume dates, ended totals, today's start, no-history/zero.
- Unknown/partial dates; exact earlier start before a later partial start;
  unknown earlier history; refusal to present a known subset as the total.
- Multiple ongoing periods, inconsistent/reversed boundaries, definite overlap,
  and future dates.
- Los Angeles spring/fall changes: 23/25 elapsed hours but one Calendar day.
- One instant giving October 25 in Tokyo and October 24 in Los Angeles, with
  unchanged stored civil dates and corresponding ongoing readings.

The probe is outside Git and did not mutate application data. It does not prove
iOS/device integration, localized UI quality, all historical calendar cases,
or CloudKit conflict delivery. Its pairwise overlap check is bounded semantic
evidence, not a selected production performance strategy. Reuse PeriodOperations
and qualify representative history sizes during implementation.

## Sources

- [Apple: Performing Calendar Calculations](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/DatesAndTimes/Articles/dtCalendricalCalculations.html)
  explains calendar arithmetic and choosing between elapsed units and calendar
  boundaries. Archived Objective-C guidance supplies semantics; current Swift
  Calendar was exercised locally.
- [Apple: Calendar](https://developer.apple.com/documentation/foundation/calendar)
  supplies date construction, components, and calendar differences.
- [Apple: dateInterval(of:for:)](https://developer.apple.com/documentation/foundation/calendar/dateinterval(of:for:))
  supplies temporary precision-aware comparison bounds.
- [Apple: DateComponentsFormatter allowedUnits](https://developer.apple.com/documentation/foundation/datecomponentsformatter/allowedunits)
  describes native unit formatting, not Stally's counting/uncertainty policy.
