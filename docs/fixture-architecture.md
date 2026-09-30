# Sample and Fixture Architecture

## Roles and Ownership

| Role | Source |
| --- | --- |
| User samples | `SampleDataOperations`, `SampleDataSeed` |
| Canonical builder | Internal `ItemSeedBuilder` |
| Developer records | DEBUG `StallyFixtureOperations` |
| Preview adapter | `StallyPreviewData`, `StallyPreviewContainer` |
| Agent/capture launch | `StallyPreviewLaunchConfiguration` |
| Behavior tests | `StallyLibrary/Tests/Default/` |
| Historical migration | Frozen `Fixtures/V1/` |
| Interchange golden | Hand-authored `Fixtures/Interchange/` |
| Deliberately invalid data | Local validation test cases |

The five representative sample records are defined once. Developer profiles
reuse their localized form input, creation offsets, Mark-day offsets, and
Archive offsets through the same builder. User samples retain their existing
stable Item IDs and explicit add/remove lifecycle. Their Mark IDs may be new
when samples are recreated. Developer Item and Mark IDs are deterministic and
disjoint from sample IDs, so Remove Samples cannot delete development records.
Neither role supplies data automatically to an ordinary app launch.

The earlier app-owned `StallyPreviewItemSeed` and tracking builder are removed.
Tracking records now share the profile catalog and select screens by semantic
UUID, rather than localized names. The app adapter supplies only its UIKit
placeholder image and native presentation environment. There is no second
domain model, fixture database, general generator framework, or package.

## Profile Vocabulary

| Profile | Items / Archive / Marks | Purpose |
| --- | --- | --- |
| `empty` | 0 / 0 / 0 | Empty surfaces, explicit sample creation, system tests |
| `typical` | 5 / 1 / 23 | Canonical samples and transfer |
| `dense` | 10 / 2 / 40 | Long text, photos, accessibility |
| `integration` | 8 / 2 / 23 | Mixed policy; every start precision |
| `timeTogether` | 3 / 1 / 0 | Non-Mark starts and Archive |
| `history` | 5 / 3 / 450 | Longer histories and Archive readings |
| `stress` | 500 / 100 / 6,250 | Optional bounded personal collection scale |

All profiles use September 30, 2026 at noon UTC as their reference date.
Creation, Archive, Mark-day, Mark creation date, and identifiers repeat across
fresh containers. The app's synthetic reading clock and timezone match that
reference for elapsed time, Review, Insights, history, and day filters. Native
status bars, platform rendering, image encoding, and JSON object-key ordering
are not promised to be byte-identical across SDKs. Tests compare complete
domain/wire values rather than treating screenshot pixels as a model contract.

Names and notes resolve through the package's English/Japanese SampleData
catalog; the same semantic UUID selects an Item in either locale. Stress names
are technical numbered fixture labels. The app produces a placeholder image
for ordinary visual profiles; stress deliberately excludes large photos so it
measures collection/history scale independently of the validated photo limits.

## Reproducible Use

For library tests or an explicit debug seed, create an in-memory container and
call `StallyFixtureOperations.seed(.integration, in: context)`. The facade
refuses persistent or nonempty containers before inserting anything. The batch
saves once and rolls back failures. Do not use it on historical migration
stores or real data.

For the Debug app, launch with `--stally-preview-scenario integration`.
Optional `--stally-preview-route` values remain `library`, `archive`, `review`,
`insights`, `backup`, `settings`, `addItem`, and `itemDetail`. Use
`--stally-preview-tracking-screen monthDetail` (or `yearDetail`,
`archivedDetail`, `editYear`, `editMonth`) to host the actual selected screen.
Tracking hosts resolve the same UUID across English/Japanese launches. Existing
`--stally-preview-text-size xxxLarge` or `accessibility3` affects only a
synthetic launch. Use the platform's ordinary language/appearance launch
configuration for localized capture; no system setting override is persisted.

An explicit route without a profile uses `typical`; a tracking screen uses
`integration`. No recognized synthetic profile/route/screen means normal
persistent startup, the system clock, and the system timezone. The profile API,
launch parser, and synthetic hosts are compiled out of Release. Shared sample
creation stays available as a deliberate product action in Release.
Ordinary UI actions read the current execution instant, rather than reusing an
older display reading as a mutation/export timestamp. Only explicit synthetic
launches freeze that instant. System intents retain their real current-day
contract.

Migration stores retain their original schema, bytes, external photos, and
checksums. Tests copy them before opening with CloudKit disabled. The v3 golden
interchange JSON and malformed validation cases stay independent of the current
seed builder, so changing a seed cannot silently bless migration/wire behavior.

## Current Evidence

Xcode 27.0 (27A266a) / iOS 27.0 (24A434) passes 171 library tests in 41 suites.
New checks compare complete repeated snapshots, validate/restore every small
profile, confirm mixed start/policy/Archive values, resolve Japanese identity,
preserve sample removal boundaries, and refuse persistent/nonempty injection.
Original migration and interchange compatibility tests remain included.

The bounded stress run contains 500 Items, 100 archived Items, and 6,250 Marks.
One final Debug run records 3.552 seconds for one-time seeding, 32ms for saved
Item fetching, 0.954 seconds for combined collection/Review/Insights readings,
and 0.941 seconds for validated export (635,994 bytes). These are cold synthetic
Simulator measurements without timing assertions. They are a model/query sanity
check, not a production latency guarantee or a reason to add broader scale
infrastructure. Seeding is developer-only; normal app startup does not pay it.

Debug and Release app builds pass. Release binary/symbol inspection finds no
fixture API or preview scenario/tracking/text-size argument entrypoints. The
three existing AppIntentsTesting journeys also pass after the clock adapters
change (21.983 seconds, zero failures). The eight original V1 checksum entries still match. The six EN/JA catalogs have
zero incomplete or stale keys; the manual multiline developer note remains
referenced through the localized seed helper rather than a literal-only scan.

Native synthetic captures show [mixed Library][mixed-capture],
[Japanese month detail][month-capture], and [stress Library][stress-capture].
Restarting `integration` repeats all 51 observed display labels and six active
Items in order. Semantic UUID selection opens the Japanese month Item without
name matching; its September 2020 precision and approximately 72 months remain
visible. Stress renders 400 active Items and 100 archived Items. Five owned
launches report preview-container creation and ready startup, with no app-owned
error/fault or fatal persistence/crash match. Framework diagnostics are retained
separately. These captures use no real data, account changes, or CloudKit proof.

[mixed-capture]: ui-preview-screenshots/fixtures/mixed-library.png
[month-capture]: ui-preview-screenshots/fixtures/month-detail-ja.png
[stress-capture]: ui-preview-screenshots/fixtures/stress-library.png
