# Period Readings Design

## Status

The accepted product provides current ongoing period length and cumulative
length across recorded periods. The current reading starts at the ongoing
period's own start, not the earliest historical start. Ended periods remain
part of the cumulative reading when calculable.

Approximate readings supplement exact-date readings. Unknown components remain
unknown in storage; estimates expose their assumptions and calculable subtotals.
The [current implementation](remaining-capabilities-implementation.md#recorded-time-together)
defines mixed precision, aggregation, uncertainty and initial presentation.
The superseded October 25 proposal is not an implementation specification.

## Accepted Approximation Behavior

In the subsequent October 30 discussion, the owner accepted differences at
the recorded precision as the basis for understandable estimates:

- For year-only boundaries, use the difference between the recorded years.
  For example, 2020 to 2021 supports "about 1 year" even though the unknown
  months and days permit a much shorter or longer actual span.
- For year-and-month boundaries, use the difference between those calendar
  components. For example, April 2020 to October 2025 supports "about
  5 and a half years" without inventing either boundary's day.
- Make the calculation basis available in details. For the year-only example,
  explain that the estimate subtracts the start year from the end year and
  that unknown months and days can change the actual duration.
- An uncertainty range may supplement an estimate, but is not a prerequisite
  for showing it and need not replace the ordinary approximate reading.
  A midpoint or most-likely-date model is not required for this approach.
- Keep the original dates and precision unchanged. The estimate does not
  assert completed exact years or establish missing boundary dates.
- A wholly unknown boundary provides no subtraction basis. Distinguish a
  subtotal over calculable periods from the cumulative reading covering all
  recorded periods; do not force unknown periods to zero.

## Current Calculation and Presentation

Day-precision endpoints contribute exact Gregorian day differences. A pair
containing year precision contributes the difference in recorded years;
otherwise month precision contributes calendar month differences. Ongoing
periods use the current local day without modifying their saved endpoints.

Cumulative readings add calculable periods and exclude gaps. Unknown or future
ongoing starts are excluded and reported; an empty history is unavailable,
not zero. Definite contradictions fail visibly. Possible overlaps are disclosed
as an assumption rather than certified as non-overlapping history.

Results retain exact days, approximate months and years, included/excluded
counts and possible-overlap information. The current UI converts approximate
components using 365.2425 days per year and 12 months per year, rounds the
combined headline to one fractional year and exposes the contributing parts.
Rounding, units and layout remain reversible presentation choices. App Intents
return localized explanatory text, not an exact scalar total.

See [product behavior](product-behavior-design.md#revisit-and-understand-the-record)
and [period validity](period-schema-validation.md) for the domain boundaries.
