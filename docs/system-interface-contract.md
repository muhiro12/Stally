# System Interface Contract

## Selected Journeys

The canonical system entity is an Item: a meaningful thing or place, with its
own stable identity, collection placement, independent Mark policy, and optional
start knowledge. It is neither a calendar event nor a reminder or a journal
entry. The selected first-release journeys are:

1. Create a non-Mark Item with a year/month/day start, pass its returned entity
   into Check Time Together, and open the same Item in the app.
2. Mark or undo an eligible Item today, with a repeated request becoming a
   no-op. Archive and move back preserve identity, history, and passing time.

Review and Insights retain direct app-opening intents. A scalar time report and
localized dialog give a useful read-only system result with its reference day
and original precision. Interactive snippets would add a second layout/action
lifecycle without improving this atomic reading, so they are not adopted now.
Rendering and querying never create Marks.

## Complete Intent Inventory

This inventory covers all 15 pre-existing intents and the new canonical Open
adapter. Revise keeps the named type unless explicitly stated.

| Intent type | Decision | Responsibility |
| --- | --- | --- |
| OpenStallyLibraryIntent | Revise | Foreground Library |
| OpenStallyArchiveIntent | Revise | Foreground Archive |
| OpenStallyReviewIntent | Revise | Foreground Review |
| OpenStallyInsightsIntent | Revise | Foreground Insights |
| OpenStallySettingsIntent | Revise | Foreground Settings |
| OpenStallyBackupCenterIntent | Revise | Foreground Import & Export |
| CreateStallyItemIntent | Revise | Combined input; return Item |
| MarkStallyItemTodayIntent | Revise | Guarded choice; return change flag |
| UndoStallyItemTodayIntent | Revise | Guarded undo; return change flag |
| ArchiveStallyItemIntent | Revise | Placement; return change flag |
| MoveStallyItemBackToLibraryIntent | Revise | Placement; return change flag |
| CheckStallyTimeTogetherIntent | Keep | Read-only report and dialog |
| OpenStallyItemIntent | Keep | Hidden existing item-parameter adapter |
| OpenStallyDestinationIntent | Revise | Hidden generic destination adapter |
| OpenStallyRouteIntent | Revise | Hidden URL adapter |
| OpenStallyItemEntityIntent | Add | Canonical schema Open action |

All user tasks are discoverable in Shortcuts; three routing/compatibility
adapters stay hidden. Six existing App Shortcuts and their English/Japanese
phrases retain their meaning. Opening uses current `supportedModes` foreground
execution. SwiftData work uses main-actor perform witnesses and the registered
ModelContainer dependency; the Item entity carries no dependency or
live model. No existing intent type, enum raw value, or phrase is removed.

## Canonical Entity and Queries

`StallyItemEntity` is a Sendable value snapshot. Its identifier remains the
Item UUID's string, independent of name, Archive, category, device, or start.
System properties are name, category enum, archived state, Record Marks, and
nullable canonical partial-start text. Start remains `YYYY`, `YYYY-MM`, or
`YYYY-MM-DD`; missing components never become an inferred date. A malformed
stored string is not silently repaired by entity materialization.

Private note, photo, and full history are not entity properties. The entity's
fields describe the value at resolution time; actions fetch the current Item
by UUID and run Operations guards again. A saved value cannot authorize an
invalid history change after policy or placement changes.

Identity resolution batches UUIDs in a bounded predicate and omits missing
identities. Name search covers active and archived Items, including non-Mark
Items. Generic suggestions return at most 40 recent active Items. Mark-specific
suggestions filter that recent subset through Operations eligibility; this
never narrows generic identity resolution. There is no unbounded enumerable
entity query or extra app-side SwiftData observer.

## App Schema and Spotlight Decisions

The current [system Open schema][open-schema] genuinely matches opening an
Item, so `OpenStallyItemEntityIntent` adopts it with the standard `target`
parameter. Its local-device authentication is required by schema validation.
The older hidden `OpenStallyItemIntent` deliberately retains its `item`
parameter as an existing configured-action bridge; it is not the canonical
first-release discovery surface.

Calendar, reminders, notes, journal, and health domains do not describe choice
Marks or partially known starts accurately. Their schemas are not adopted.
The custom Item and atomic Mark/time actions remain valid App Intents.

[IndexedEntity and IndexedEntityQuery][indexing] could provide a searchable
name/category projection and system-driven reindexing. They also require
ownership of updates, deletions, restore, and Cloud-originated changes in a
second store. The selected journey already uses live entity search and stable
identity; a broad Spotlight content index is not adopted for the first release.
This is an explicit scope/value decision, not a claim that App Entity metadata
alone indexes every Item. Private notes/photos are not indexed. Computed or
deferred properties are unnecessary for these small resolved snapshots.

## Widget and Watch Decisions

Widget: do not add a target in this release. A pinned Item time glance could be
useful, but there is no selected-item configuration contract yet. Recent-choice
ranking risks reducing the combined collection to a score. Widget timeline
refresh, shared-container ownership, and guarded interactive writes add a
lifecycle beyond the selected atomic Shortcuts journey.

Watch: do not add a target in this release. Wrist Mark/undo could reduce friction
for frequent choices, but no established wrist-specific task, offline identity
resolution, or cross-device write contract justifies the additional target and
sync/presentation maintenance. Neither no-go changes the library boundary or
prevents later adoption when a concrete task warrants it.

## Authentication, Confirmation, and Replay

All record read/write and opening intents require authentication. Canonical
schema Open requires local-device authentication. An unlocked synthetic
Simulator does not prove locked-device or physical Siri authorization.

Mark/Undo recheck Mark policy, Archive, and local day through ItemOperations.
They return whether history changed; repeated Mark/Undo, Archive, and move-back
are no-ops after the intended state is reached. Archive never ends elapsed time.
No delete, reset, replacement, or automatic file-import write intent is added.

Create validates every parameter before saving and returns the created entity.
Category defaults to Other; Record Marks defaults to true for existing action
compatibility; omitted start remains unknown. Blank start is unknown, while
malformed or future start fails before mutation. An explicitly repeated Create
means another Item, including duplicate names; it does not silently deduplicate
identity. No prompting or restart-producing operation follows its commit.

These reversible atomic actions need no extra confirmation beyond selecting
the Item and action. Irreversible reset/replacement remains a reviewed app flow.
The separate system undo lifecycle is not adopted: today's undo already has an
explicit domain action, and a historical-day undo must not guess which day the
person intended after midnight.

## Links and Incoming Data

Existing `stally://` destination and `stally://item/<UUID>` links retain their
wire identifiers, including `backup-center` for the visible Import & Export
surface. Links carry identity/routes, never private Item content or a Mark
command. Missing identities display a safe missing-item state. External routes
select the intended tab and establish a fresh path; ordinary tab switching
preserves each path. Canonical Open resolves identity before routing.

There is no universal-link host or remote publication promise. Opened/shared
collection files belong to the separately reviewed import contract, never to a
navigation URL's automatic mutation. Context menus and onscreen entity
annotations are the separate #15 slice of this system surface.

## Verification Contract

`StallySystemTests` is a focused UI testing bundle using the iOS 27
[AppIntentsTesting framework][testing]. Apple requires that bundle because calls
run out of process through the installed app's real App Intents infrastructure.
The tests import neither app implementation nor library models. Durable business
tests stay in StallyLibrary. No Widget, Watch, or new runtime package is added.

Tests launch only the DEBUG synthetic empty collection, then use real intents
and queries. They verify partial start round trips, creation/entity chaining,
non-Mark rejection, Archive/time/restore semantics, repeated Mark/Undo change
flags, archived-item rejection, missing identity, and schema Open navigation.
No reset/seed intent or ordinary-data mutation is required.

Use a discovered dedicated iOS 27 Simulator and the `StallySystemTests` scheme
through the available Xcode test capability. The repository compatibility
entrypoint is `bash ci_scripts/tasks/test_stally_intents.sh`, with
`CI_IOS_SIMULATOR_DESTINATION` set explicitly. Library tests, app metadata
extraction, catalog/formatter/rule checks, and this out-of-process evidence
remain distinct verification capabilities.

### Current Evidence

On September 30, 2026, Xcode 27.0 (27A266a) with iOS 27.0 Simulator (24A434)
builds the app and test bundle and exports App Intents metadata without errors
or warnings. Metadata includes the system Open schema, its required local-device
authentication, five canonical entity properties, and all Create parameters.

All three out-of-process tests pass with zero failures in 23.383 seconds.
StallyLibrary passes 161 tests in 39 suites, including bounded suggestions,
pending insert/archive changes, batched identities, archived/non-Mark identity,
and the existing migration/backup/Operations contracts. Formatter, SwiftLint and
architecture checks, six-catalog EN/JA audit, Markdown lint, project/script
syntax, and diff whitespace checks pass. Compiler-extracted new Intent and
summary keys have explicit English/Japanese translations; stale unreferenced
UI keys were removed after checking current sources.

A final [native Library capture][library-proof] retains Home's year-only start
and elapsed range, Canvas Tote's 3 Marks, and the four adaptive destinations.
The three test launches and one native capture launch all reach synthetic
startup ready, with no app-owned fatal/exception/persistence error in the scoped
logs. Owned runs and sessions are stopped; ordinary data and global settings
are unchanged.

Native project/scheme discovery remains unresponsive, so build/test use the
explicit Xcode 27.0 CLI and a discovered dedicated device. The original Xcode
selection is unchanged. Physical Siri speech, locked-device prompts, Spotlight
content indexing, real CloudKit sync, and release readiness require separate
evidence and are not claimed by these tests.

[open-schema]: https://developer.apple.com/documentation/appintents/appschema/systemintent/open
[indexing]: https://developer.apple.com/documentation/appintents/indexedentityquery
[testing]: https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code

[library-proof]: ui-preview-screenshots/system-interface/library-integration.png
