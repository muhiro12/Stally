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
The development sample graph contains no photo attachments.

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
