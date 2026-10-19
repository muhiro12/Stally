# Item Spotlight Index

The first-release search surface indexes Item names, categories, and Library or
Archive placement. The existing `StallyItemEntity` now adopts `IndexedEntity`;
its type, UUID-string ID, query and existing action contracts remain intact.
SwiftData models, migration plans and backup formats do not change.

## Projection and Platform Boundary

`attributeSet` supplies title, category/placement description and keywords, and
the canonical Item link. Notes, photo bytes, Marks and history are absent from
this projection. Existing start/policy properties remain available through the
live entity query; they are not added as searchable attribute keys.

The app converts these typed values with public `CSSearchableItem(appEntity:)`,
assigns owned item/domain identifiers, then calls CoreSpotlight's ordinary
index/update/delete APIs. Explicit item identifiers are namespaced independently
of the canonical AppEntity UUID. A named index alone is a client-state handle,
so it is not treated as an isolation boundary.

`ItemSearchIndexOperations` owns captured projections and identity policy in
StallyLibrary. `ItemSearchIndexSynchronizer` serializes platform-sink writes.
The app adapter owns CoreSpotlight, persistence observation and navigation.
No shared platform package or extra app target is added.

## Lifecycle and Recovery

- App root startup and foreground activation force reconciliation.
- Successful ModelContext saves schedule reconciliation for UI, intents and
  imports. A root Query also observes the complete projection, including changes
  imported by CloudKit. Reads use a fresh context after checking for unsaved
  main-context edits.
- Every reconciliation covers all Items, including Archive, rather than the
  entity query's bounded suggestions. Archive placement changes the metadata;
  it does not make a Mark or move an Item back to Library.
- The sink verifies that its freshly resolved models still match the queued
  projection before writing. A changed or deleted source cannot be recorded as
  successfully indexed under an older snapshot.
- Merge/Replace and deletion reconcile the current saved UUID set against an
  owned tracking ledger. Failed source fetches or unsaved edits do not prune.
- The ledger contains only attempted UUIDs. It is written atomically before OS
  additions, and finalized after upserts and removals. A failed attempt clears
  the successful-snapshot cache so returning to an earlier source state still
  cleans up interrupted additions.
- Missing or malformed ledger state rebuilds only the owned domain. It never
  calls a global delete-all API or deletes source Items.
- Index failures are logged and retried by later saves, activation or reindex
  requests. They do not roll back a successful domain save.
- CSSearchableIndexDelegate's partial/full callbacks force the same full
  reconciliation, then acknowledge the request. The delegate is retained with
  the sink. IndexedEntityQuery is not adopted because this adapter writes
  ordinary searchable items rather than using indexAppEntities. This follows
  [Apple's reindexing contract](https://developer.apple.com/documentation/appintents/indexedentityquery).
  Cloud updates are reflected after the app imports/observes them or next
  startup/activation; immediate background Cloud indexing is not promised.

## Preview and Synthetic Data

Canvas Preview and in-memory/temporary stores have indexing disabled by default.
The actual ModelConfiguration is checked: preview launch data previously reports
its persistence status as local, so that label alone is insufficient.

Only a Debug in-memory launch may explicitly enable a UUID-based synthetic
namespace using `--stally-search-index-test-namespace <UUID>`. Its ledger, item
IDs and domain are separate from production, and its entity values request
`hideInSpotlight`. Ordinary preview/test launches cannot clear the real index.

## Result Opening

CoreSpotlight continuation activities resolve an owned namespaced identifier,
or the production entity's standard EntityIdentifier, to a UUID. The existing
`openItemLink` fetches the current Item and chooses Library or Archive detail.
A deleted UUID cannot silently resolve to an equal display name. The standard
OpenIntent continues to use the same live model resolver.

## Verification Boundary

Library tests cover the selected fields, duplicate names, Archive/edit snapshots,
actual Replace import, deletion, stale revisions, interrupted writes, retry and
ledger recovery. Run the repository's full StallyLibrary unit-test plan and build
the Stally consumer using a discovered iOS 27 destination. The consumer build
checks App Intents adapter compilation and metadata extraction.

Library tests and an app build do not prove OS index delivery. Verify actual
index writes, result visibility/opening, reindex callbacks and Cloud-originated
changes separately. Use a dedicated synthetic namespace for automated index
checks; never reset the production domain to prepare a test. Spoken Siri and
physical-device Spotlight checks require their own evidence.
