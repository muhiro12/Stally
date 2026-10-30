# Sample and Fixture Architecture

## Current Development Setup

Issue [#34](https://github.com/muhiro12/Stally/issues/34) applies to the new
five-model foundation. A normal `DEBUG` launch opens an explicitly local store
in the app sandbox at `Application Support/StallyDevelopment/Development.store`.
CloudKit is disabled for this store. Release continues to open the App Group
store with its existing CloudKit configuration. The October 31 replacement
removed the legacy-store guard and old schema definitions. Incompatible
prerelease installations may be reinstalled; no recovery adapter is provided.

Only initial creation of the development directory automatically seeds records. Reopening an
empty store, deleting all records, changing a preference, or updating the seed
definition does not seed it again. An existing directory is conservatively
considered already initialized, even if empty or left by a failed setup. A
failed open/save is surfaced by the existing startup error screen; the directory
and database are retained for diagnosis, never deleted or replaced by a fallback.
This is a single-app development setup, not a multi-process seed coordinator.

Existing shared and older development stores are neither moved nor deleted.
They are not shown by the default DEBUG route. This is explicit store selection,
not recovery from an error or a migration of earlier records.

### Developer Controls

Open **Debug** from the Library sidebar in any build. DEBUG adds the
development controls described below. See [diagnostics access](diagnostics-access.md)
for the distributed read-only surface. The same
screen is available from the startup-error screen so a failed shared-store open
does not prevent changing the next-launch choice. It uses native Form controls
with MHUI presentation and has English/Japanese strings.

The screen separates the actual open container from next-launch preferences:

- Current storage: disk/in-memory configuration, local store locations, and
  configured CloudKit status. This is not a claim of completed synchronization.
- Record counts: read-only Item, Mark, Period, Photo, and Tag counts, with an
  explicit refresh action. Fetching diagnostics never saves pending edits and
  does not load image payloads.
- Development samples: explicitly add the representative graph now, only when
  every record type in the isolated local store is empty. Automatic-seeding
  preferences do not affect this action; restarting is unnecessary.
- Next launch: select the shared store or initial-only sample creation. Selecting
  the shared store requires confirmation explaining that writes may sync with
  iCloud. Changing the choice does not replace the currently open container.
- App: current version/build and domain schema version. No entitlement overrides,
  database reset, arbitrary mutations, or log export controls are provided.

The preferences below are read only inside `#if DEBUG`, from standard local
UserDefaults rather than shared production settings. No custom Scheme is needed
for ordinary development. Native UserDefaults launch overrides can opt out for
an individual run; overridden controls are disabled with an explanation:

- `-development.automaticallySeedRecords NO`: create an initially empty local
  development store. Setting this after initial setup preserves existing records.
  Removing the override later does not backfill the opted-out store.
- `-development.useSharedStore YES`: explicitly open the existing App Group /
  CloudKit store for integration verification. This path never injects developer
  records. It does not copy local
  developer data into the shared store. Normal shared-store writes can sync.

Use a fresh, dedicated Simulator for initial-empty launch checks, or a temporary
URL through the library test API. Do not erase existing Simulator or device data
to repeat initial setup. There is no automatic reset or reseed control.

### Manual Sample Insertion

The [owner clarification on Issue #34](https://github.com/muhiro12/Stally/issues/34#issuecomment-6465665557)
adds a manual DEBUG action after initial opt-out or deliberate deletion. It does
not change the initial-only automatic policy. Existing next-launch preferences
remain useful and need no replacement with a new configuration system.

`DevelopmentSampleOperations` validates the actual open container before
inserting anything: exactly one writable on-disk configuration, the app-local
development URL without directory/file redirection, no App Group or CloudKit
container, the main context with no pending changes, and zero Items, Marks,
Periods, Photos, and Tags. An orphan or remaining Tag therefore prevents a
second graph from being inserted. Validation and insertion run synchronously
on the main actor and save through the existing rollback-on-failure boundary.
Neither an empty shared store nor a Preview container is a manual insertion
target. Unit tests substitute a disposable directory through internal helpers;
the public app entry cannot supply another target directory.

The existing seed definition still serves initial setup and Previews. The
manual action adds no persisted flag, schema change, reset, replacement, or
developer mode. The DEBUG shared-store option remains a specialized inspection
tool, not the ordinary development default. Deliberately prepared Release runs
remain suitable for normal-store verification; neither route allows manual
developer samples in a shared store. Release/TestFlight never include the manual
insertion Operations or button.

### Representative Data and Reuse

`StallyDevelopmentSeed` owns one synthetic graph: five Items, five Marks, five
Periods, and three Tags. It covers two Marks on one day with different time
precision; unknown/year/month/day period precision; an ended and resumed
relationship; archived favorites; paused recording with retained history;
shared Tags and distinct same-name Tag identities; and an Item with no history.
Names, notes, and Tags resolve through the English/Japanese `DevelopmentSamples`
string catalog when each graph is created, using the current app locale. Initial
setup, manual insertion, and Previews share this localized definition. Saved
records retain their text after a language change, including any edits; existing
English development records are not rewritten or automatically reseeded.
Photos remain absent until photo ingestion has its own representative fixtures.

The localization follow-up passes all 65 native Library test cases on iOS 27.2,
including English/Japanese text and disk-reopen checks. The app consumer build,
strict repository rules, and all 11 sample catalog entries pass verification.
Direct `LibraryPreview` captures show localized names and notes in both languages;
archived content and Tags are checked by the Library tests.

The library builds the graph in one owned context and saves once. It is not a
public insertion operation on arbitrary user contexts. The DEBUG-only
`StallyDevelopmentStore.preview()` returns a fresh in-memory, CloudKit-disabled
container using the same graph. `LibraryPreview` supplies the existing MHUI theme
and isolated remote-update environment. Unit tests reuse that entry point while
keeping independent behavioral assertions. UUIDs are newly generated for each
new graph and survive reopening the same store; they are not exported contracts.

### Diagnostics Boundary

Release provides the visible read-only Debug screen and ordinary
startup-failure presentation. Existing warning/error logging uses error
type/domain/code rather than record contents in diagnostic metadata. Developer
storage, seed construction, Preview wiring, and preference routing remain
compiled only for DEBUG. The current all-build boundary is documented in
[diagnostics access](diagnostics-access.md). Neither the development route nor the Preview adds
entitlement bypasses, user-facing example-content controls, export, or database
reset actions. DEBUG manual insertion is restricted as described above.

### Current Verification

Before the manual-action follow-up, all 35 library tests in nine suites passed
on Xcode 27.2 / iOS 27.2, including
six development-store tests and three diagnostic/preference tests. Disposable disk stores verify graph reload,
identity/precision retention, preserving edits while seeding is disabled,
no reseeding after deliberate deletion, permanent initial opt-out, conservative
handling of an existing directory, and retaining an unreadable store without
fallback. Independent in-memory graphs verify Preview isolation and ordinary
Operations. Diagnostic tests also verify that counts refresh, unsaved edits
remain unsaved, and default registration preserves explicit preferences and
launch overrides. Expected diagnostics from the read-only save test and malformed
SQLite fixture were reviewed against their passing tests. The package test
runner also reports skipped App Intents metadata extraction because that test
product has no AppIntents framework dependency.

Strict SwiftLint and repository boundary checks pass. The historical counts
and screenshots in the next section are not evidence for this implementation.

The DEBUG consumer builds through Xcode MCP. A separate Release Simulator build
passes without warnings or errors. Symbol and literal inspection finds the
development store/seed/Preview types, preference keys, seed name, and local store
filename in DEBUG and absent from the Release executable. This is not an Archive
or distribution-signing qualification.

The assigned iPhone Simulator shows four Library Items, one archived Item, two
favorites, three recording-enabled Items, and three Tags. The backpack detail
shows the same-day Marks and ended/ongoing periods. Stopping and relaunching with
automatic seeding disabled retains the collection without duplication. No
app-owned persistence, CloudKit, or crash error appeared; Simulator framework
noise was reviewed separately. The shared store was not opened in this pass.

During the initial store work, direct rendering of the single `LibraryPreview` was attempted but timed out in
the Preview renderer without returning an image. Its source compiles and the
in-memory graph is unit-tested; direct Preview appearance remains unverified.
Live-app captures verify the same representative content in the persistent
development route, not the Preview renderer. Owned runs/sessions were stopped
and the original Xcode destination restored. Actual CloudKit synchronization and
initial-empty app launch remain outside this runtime pass; initial opt-out is
covered by disk tests.

The subsequent Developer Tools pass covers Japanese and English on iPhone and
Japanese on iPad Simulators. It verifies the sidebar entry, actual local-store
configuration and counts, sample-preference persistence across relaunch,
shared-store confirmation/cancellation, and the distinction between the current
store and next-launch choice. Shared-store selection was restored to off before
relaunch; that store was never opened during the pass. A launch override disables
the affected control and explains why. Removing it restores the saved choice.
All modified preferences were restored to their initial values.

The first pass exposed missing text when multiple MHUI footers were supplied to
one Section. One footer now contains all explanatory paragraphs, confirmed in
Japanese, English, and the iPad layout. No record edits or deletions were needed.
At that DEBUG-only stage, the Release build passed without warnings/errors and
omitted the development view, diagnostic Operations, preference type, and
preference-key literals. The later all-build diagnostics change supersedes that
view/Operations exclusion; development preferences remain DEBUG-only. Localized resource strings
are not a runtime entry point and may remain in the shared string catalog.
Startup-error entry, dark appearance, Dynamic Type, and VoiceOver interaction
remain unverified by this UI pass. Verification runs and sessions were stopped
and the original Xcode selection restored.

### Manual Insertion Follow-up

All 42 Library tests in ten suites pass, including seven new manual-insertion
tests. They cover initial automatic opt-out, disk reload, duplicate rejection,
manual reinsertion after deliberate deletion without reopening the container,
pending edits and other contexts, unrelated local stores and Previews, cloud/
shared/read-only/multiple configurations, each of the five existing record
types independently, and a redirected development directory. Cloud configuration
refusal is tested before opening a container; no cloud account or schema is
modified. The first redirection test exposed an incomplete path check; the
corrected check passes the full suite. Existing negative-test diagnostics remain
expected, and the package runner reports its unrelated App Intents metadata
extraction warning. Strict repository rules and English/Japanese catalog checks
also pass.

On a dedicated initially empty iPhone Simulator, a per-run automatic-seeding
opt-out produces an empty Library and an enabled manual button. One tap inserts
5 Items, 5 Marks, 5 Periods, no Photos, and 3 Tags without relaunch, disables the
button with an explanation, and updates the Library to four active Items plus
one archived Item. An English relaunch with the same opt-out retains those
records and the disabled action. Japanese and English labels and the footer
that limits the read-only promise to diagnostic refresh were inspected.

The existing shared-store Simulator retains its 2/3/4/0/1 counts and rejects
the manual action with the local-development-only explanation. It reports the
known CloudKit no-account code 134400; this is not synchronization evidence.
No existing records or saved preferences were changed. The only UI mutation
was one sample insertion into the newly provisioned local development store.
All verification runs and sessions were stopped, and Simulator data retained.
The current-source native Release iOS Simulator build succeeds without warnings
or errors. Its executable retains diagnostics but excludes
`DevelopmentSampleOperations`, the manual action, seed/preferences types, and
development preference-key literals. The temporary Release launch configuration
was restored byte-for-byte, and Xcode returned to Stally / My Mac. This pass
does not qualify TestFlight installation, physical devices, production CloudKit
schema, or real synchronization.

## Historical Architecture

The October 27 five-model implementation supersedes the older implementation
and evidence described here. See [foundation implementation](first-release-foundation-implementation.md)
for current Operations, storage, UI, verification, and unfinished capabilities.
Retain the details below as historical evidence, not as the new schema contract.

### Roles and Ownership

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

### Profile Vocabulary

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

### Reproducible Use

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
`--stally-preview-text-size xxxLarge`, `accessibility3`, or `accessibility5`
affects only a synthetic launch. Use the platform's ordinary language/appearance launch
configuration for localized capture; no system setting override is persisted.
Maximum-type UI tests also supply UIKit's preferred content-size category as a
per-process launch argument so sheets and native controls use the same size.

For lifecycle checks, `--stally-preview-advance-day-after 45` starts the synthetic
clock one second before midnight UTC and advances it to one second after
midnight after 45 elapsed seconds, including time spent in the background.
The delay accepts finite positive seconds up to 3,600; invalid values retain
the fixed reference clock. Add `--stally-preview-send-time-change` to post
`UIApplication.significantTimeChangeNotification` at that transition while
the app is running. Without that flag, returning to the foreground exercises
the normal scene-activation refresh. These options require a recognized
synthetic profile, route, or tracking screen and never change the system clock.

An explicit route without a profile uses `typical`; a tracking screen uses
`integration`. No recognized synthetic profile/route/screen means normal
persistent startup, the system clock, and the system timezone. The profile API,
launch parser, and synthetic hosts are compiled out of Release. Shared sample
creation stays available as a deliberate product action in Release.
Ordinary UI actions read the current execution instant, rather than reusing an
older display reading as a mutation/export timestamp. Only explicit synthetic
launches control that instant. System intents retain their real current-day
contract.

Migration stores retain their original schema, bytes, external photos, and
checksums. Tests copy them before opening with CloudKit disabled. The v3 golden
interchange JSON and malformed validation cases stay independent of the current
seed builder, so changing a seed cannot silently bless migration/wire behavior.

### Historical Implementation Evidence

The following observations record the original fixture implementation. The
current automated gate uses unit tests, the app build, and repository rules;
the former UI testing bundle is no longer maintained.

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
