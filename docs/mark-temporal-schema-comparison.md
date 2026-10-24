# Mark Temporal Schema Comparison

## Decision

On October 24, 2026, select one canonical, timezone-free local date/time string
for the redesigned ItemMark occurrence value, named `localDateTime`.
The owner subsequently accepted this recommendation for the 1.0 design.
Use Gregorian `YYYY-MM-DD` for day-only records and
`YYYY-MM-DDTHH:mm` for records with an entered clock time. Initial time capture
has minute precision. No time zone, occurrence timestamp, separate time flag,
or minutes-since-midnight attribute is required by this selected meaning.

This selects a storage representation, not a new calendar algorithm. Use
Foundation Calendar, DateComponents, and fixed-format parsing/formatting for
validation and UI conversion. Keep `createdAt: Date` as separate automatic
record-creation metadata. This replaces the earlier `dayKey`/`recordedAt`
proposal and the chat-only day-string/minute-of-day candidate.

The owner requested an actual comparison and delegated the choice. The
selection prioritizes stable recorded days, optional clock times, ordinary
SwiftData queries, and modest maintenance cost. It does not claim that text
is best for applications whose primary fact is an absolute occurrence instant.

## Candidates

Identity, creation metadata, and Item ownership are common to all candidates
and omitted from these abbreviated property declarations.

| Candidate | Occurrence attributes | Observation | Decision |
| --- | --- | --- | --- |
| Date plus original zone, proposed by the owner | `date: Date`, `timeZoneIdentifier: String`, `hasTime: Bool` | Saved and reopened; original local readings were reconstructed. An ordinary UTC day-range predicate did not select the original civil day across mixed zones. | Valid for instant-centered records; extra precision and zone semantics are not needed for the selected Stally meaning. |
| Canonical zone-free text, proposed by the owner | `localDateTime: String` | Saved, reopened, queried by day/month, sorted, edited, and exported without changing precision. | Selected. One occurrence attribute and standard String predicates. |
| Day text plus optional minutes | `day: String`, `minuteOfDay: Int?` | Saved, reopened, queried by day; nil and 870 were preserved. | Valid, but two occurrence attributes and an additional clock encoding have no demonstrated benefit here. |
| Native DateComponents, direct persistence | `components: DateComponents?` | Compiled; container setup failed at runtime on both tested platforms. | Not selected for persistence; still useful in memory. |
| Native DateComponents, Codable persistence | `@Attribute(.codable) var components: DateComponents?` | Saved and reopened; the predicate inspecting `components.day` failed at runtime. | Not selected for the primary queried occurrence value. |

### Date Plus Zone Is a Different, Valid Tradeoff

The tested Date-plus-zone model also stored `hasTime` so that an arbitrary
anchor for a day-only value was not confused with a known midnight occurrence.
A fixed UTC offset can replace a zone identifier when the requirement is to
retain the original offset; it does not remove the need to represent whether
an occurrence time was known. It also does not carry a region's calendar rules.

This candidate can answer absolute elapsed-time questions when the occurrence
instant is known. Original local-day queries can be implemented by grouping
zones, fetching a broader range and filtering, or storing a civil-day key.
It is not impossible to query correctly; those additions are unnecessary for
Stally's selected civil-day-centered contract.

For backdated records, the zone must describe the occurrence interpretation,
not automatically the location where the record was entered. Creating a Date
for a day-only value requires an anchor policy. These are normal design choices,
but they retain more concepts than the current product needs.

### Text Interpretation and Date Conversion

The selected string is a civil reading, not an RFC 3339 timestamp. Never append
`Z` to make it appear to identify an instant. Never re-interpret it in a new
zone
and write the converted date back as a correction to the recorded history.

Use DateComponents as the in-memory bridge. When a consumer requires Date,
choose a calendar and zone explicitly for that consumer. A Date generated in
the current zone is a contextual interpretation, not recovery of the historical
instant. The same civil reading can produce different instants in two zones.
Some readings have no matching instant in a particular zone, and some have two.
Do not silently normalize an invalid match or claim uniqueness where none
exists.

The probe used a fixed Gregorian/UTC reference solely to validate the civil
syntax and obtain components with Foundation. That reference was never stored
as an occurrence timestamp. It used `en_US_POSIX`, a fixed `yyyy-MM-dd` format
with optional `HH:mm`, `isLenient = false`, and an exact format/parse round
trip.
This rejects malformed strings and invalid calendar dates without implementing
leap-year or timezone arithmetic. Uppercase `YYYY` in the format description
means a year placeholder; the DateFormatter pattern is lowercase `yyyy`.

Date-only values sort before timed values on the same date lexically. This is
a presentation order, not evidence that the day-only occurrence happened first
or at midnight. The UI should distinguish records without a recorded time.

The experiment also accepted and round-tripped a seconds-precision spelling
(`YYYY-MM-DDTHH:mm:ss`) as an extension check. It is not part of the selected
initial input contract. Adding it later would need decoder and export-version
review even though it would not require another persisted attribute.

## Runtime Evidence

The independent probes used Xcode 27.2 build 27B48 and Apple Swift 6.4.2.
They ran on macOS 27.2 build 26B118 and on a dedicated iPhone 17 Simulator with
iOS 27.2 build 24B114. Each store used an explicit temporary disk URL and
`cloudKitDatabase: .none`. Write, read, edit, and post-edit read were separate
process invocations; the reads did not reuse the writing ModelContext.

An initial Xcode-native snippet in the existing Stally workspace failed because
its active Mac destination compiled a dependency consumer for macOS 12 while
MHPlatformCore required macOS 15. The app settings were not changed. The probes
used the same Xcode compiler directly with explicit macOS/iOS targets. The
workspace's original Stally / My Mac selection was retained.

### Successful Checks

There were 47 successful assertions on each platform, grouped as follows:

| Group | Assertions | Boundary exercised |
| --- | ---: | --- |
| Foundation behavior | 22 | Canonical forms, leap day, invalid dates/times, travel, DST, skipped dates, JSON round trip |
| Initial disk write | 1 | All four persistable candidate shapes saved together |
| Separate-process read | 18 | Fidelity, ordinary predicates, sorting, zone restoration, civil/instant distinction |
| Edit transaction | 1 | Date correction, individual cancellation, day-only backdated addition |
| Separate-process post-edit read | 5 | UUID and creation-time preservation, corrected clock time, counts, absent time |

The synthetic dataset contained these civil readings:

| Label | Reading | Zone used for the Date-plus-zone candidate |
| --- | --- | --- |
| day | `2026-10-24` | Asia/Tokyo |
| tokyo-early | `2026-10-24T00:30` | Asia/Tokyo |
| tokyo-afternoon | `2026-10-24T14:30` | Asia/Tokyo |
| la-previous | `2026-10-23T23:30` | America/Los_Angeles |
| la-late | `2026-10-24T23:30` | America/Los_Angeles |
| tokyo-next | `2026-10-25T00:15` | Asia/Tokyo |

The text predicate below returned day, tokyo-early, tokyo-afternoon, and
la-late:

```swift
let lower = "2026-10-24"
let upper = "2026-10-25"
let predicate = #Predicate<TextMark> {
    $0.localDateTime >= lower && $0.localDateTime < upper
}
```

Sorting by `localDateTime` matched canonical civil ordering. The analogous
month-range predicate returned all six fixtures. An instant range spanning
October 24 in UTC instead returned la-previous, tokyo-afternoon, and tokyo-next.
That difference is expected semantic behavior, not a SwiftData query defect.

Foundation checks included a nonexistent New York `2026-03-08T02:30`, repeated
`2026-11-01T01:30`, and the skipped Apia date `2011-12-30`. Civil values
remained
representable. Explicit zone conversion rejected nonexistent matches, and
Calendar's first/last repeated-time policies produced instants one hour apart.

### Reproduced Candidate Limitations

Direct DateComponents persistence compiled but failed during schema creation:

```text
Unexpected property within Persisted Struct/Enum: _CalendarProtocol
```

Codable persistence preserved the values, including absent hours. A predicate
accessing `components?.day` then failed with a schema-validation fatal error
stating that the computed property was not a member of DateComponents. These
negative probes ran separately from the successful persistence comparisons.
The results were reproduced on both platforms; they are evidence about this
SDK/runtime and model shape, not a claim about every future SwiftData version.
Apple also documents that Codable attribute internals cannot be used for
filtering or sorting in [its SwiftData session][codable].

The sandboxed macOS writer emitted a Core Data notification-registration
warning; the explicitly saved data reopened successfully in a different
process. iOS runs did not emit that warning. Neither result proves cross-process
change notifications, which were not part of this comparison.

## Limits and Next Implementation Boundary

No Stally model, application source, entitlement, production schema, or actual
user data was changed. These were standalone local-store probes, not the app's
full test suite. No physical-device CloudKit propagation, merge behavior,
production schema, old-store migration, index performance, or UI acceptance
was verified. Optional relationships, defaults, UUID replay, and deletion rules
remain governed by the core design and need implementation-level verification.

Keep entry and editing validation in the existing Operations flow. Export/import
must preserve the civil spelling and identity without inventing a time or zone.
Do not add an occurrence Date, day key, time flag, or minute counter as
redundant
stored copies of the same value. A future requirement for actual elapsed hours
would justify new, explicitly optional instant information; historical instants
cannot be recovered from these civil readings alone.

[Foundation DateComponents][components] and [Calendar matching policies][calendar]
provide the native temporal building blocks. [SwiftData model storage][storage]
provides the ordinary String and Date attributes used by the recommendation.

[codable]: https://developer.apple.com/videos/play/wwdc2026/274/
[components]: https://developer.apple.com/documentation/foundation/datecomponents
[calendar]: https://developer.apple.com/documentation/foundation/calendar/matchingpolicy
[storage]: https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches
