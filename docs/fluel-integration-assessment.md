# Fluel Integration Assessment

> Status: Stally-side evidence, September 13, 2026. Model integration remains
> undecided after reconciling the Fluel investigation with the decisions below.

## Scope

This assessment follows `AGENTS.md`, the near-term development brief, and the
preserved rebuild documents. It evaluates Stally as the potential delivery
host. It does not authorize a persisted schema, navigation, branding, or
data-transfer change.

Stally's current promise remains repeated choices and readable mark history.
Fluel's distinct value is an honestly known relationship start and the time
together derived from it. Similar names, notes, photos, and UUID fields do not
establish a shared domain or a transferable identity.

## Evidence Baseline

- Stally source baseline: `f8d24e5`, with backup export correction `0c131ec`
  described in [release-readiness.md](release-readiness.md).
- Fluel reference baseline: `d464de9`, inspected read-only. Relevant files are
  `FluelLibrary/Sources/Entry/EntryStart.swift`, `EntrySnapshot.swift`,
  `EntryOperations.swift`, and `EntryOperations+Milestones.swift`, plus
  `Fluel/Sources/Features/Entries/Entry.swift` and the app's versioned schema
  and container factory under `Fluel/Sources/Platform/`.
- Fluel's completed assessment is `Fluel@9492897`,
  `docs/stally-integration-assessment.md`; its reusable domain contract is
  `Fluel@19c858d`, `docs/domain-behavior-contract.md`. Both were read and
  reconciled with this host-side assessment. Distribution and real-data
  continuity remain unconfirmed. Repository descriptions of an unreleased
  product do not prove that no installed or distributed data needs protection.

## Semantic Conflicts

| Concern | Stally | Fluel |
| --- | --- | --- |
| Main signal | Choosing an Item on a day | Time since a relationship began |
| Date knowledge | Exact `LocalDay` marks | Day, month, or year precision |
| Creation date | Record insertion and Review age | Separate from the start |
| Archive | Preserve history outside Library | Stop elapsed time at archive |
| Deletion | Delete Item and its marks | Archive before permanent delete |
| History | Chosen calendar days | Added, updated, archived activity |
| Photo boundary | Canonical JPEG bytes | Snapshot exposes `hasPhoto` only |
| Identity | Item UUID, links and entities | Separate Entry UUID and entity |

Stally evidence lives in `StallyLibrary/Sources/Item/Item.swift`,
`ItemOperations.swift`, `LocalDay.swift`, `ItemPhotoOperations.swift`, and
`StallyLibrary/Sources/Review/ReviewOperations.swift`.

These conflicts have practical consequences:

- `Item.createdAt` cannot become a relationship start. It also drives default
  ordering and the Needs First Mark age. Backdating it would change Review
  behavior without any mark being added.
- A month or year start cannot be represented as an exact `LocalDay` alone.
  Fluel retains precision even when calculations use the earliest date in the
  range. Unknown start must also remain possible for existing Stally items.
- A start edit must not add a Mark. Importing an old relationship must not
  invent daily choices or make an elapsed-time reading an Insights count.
- Archive needs an explicit combined meaning. Fluel caps elapsed time at
  `archivedAt`; Stally uses Archive to put favorites aside and later restore
  them. Fluel resumes elapsed time from the original start after restoration;
  archived intervals are not subtracted. Stally has no interval history, and
  Fluel's activity records are separate from its elapsed-time calculation.
- `EntrySnapshot` is not a complete transfer format: it carries photo presence,
  not bytes, and does not contain persisted activity or presets.
- A shared UUID representation does not prove that two records represent the
  same object. Automatic name-based matching would require an explicit policy
  and reviewable conflict handling.

## Candidate Product Slice

The smallest candidate worth evaluating is optional start knowledge and a
time-together reading in Item Detail. It could complement Mark Today without
adding a second primary collection or making dates mandatory during creation.
This is a proposal for comparison with Fluel's findings, not approved UI scope.

Evaluate the following journeys before selecting an implementation:

1. An existing Stally Item with marks and no known start keeps all readings.
2. An Item known only since a particular year shows that uncertainty clearly.
3. Refining a start from year to month changes elapsed text, not mark history.
4. Archiving and restoring an Item has a stated, understandable time meaning.
5. A user can still add and mark an Item without learning Fluel terminology.

Milestones need a separate value decision after those journeys are understood.
Dashboard, Timeline, Presets, places, and a second app shell are outside the
  candidate slice. A separate Fluel domain model remains an alternative until
the evidence settles ownership. Physical package extraction can wait until
integrated behavior demonstrates a need.

## Persistence And Transfer Gate

Stally's rebuilt schema is version 1 with `Item` and `ItemMark`; its backup
wire format is version 2. Fluel's rebuilt schema is independently version 1
with `Entry`, `EntryActivity`, `Preset`, and `PresetDefaultSelection`. The
version numbers do not make the schemas compatible.

The configured CloudKit containers are also separate:
`iCloud.com.muhiro12.Stally` and `iCloud.com.muhiro12.Fluel`. A Stally migration
must not be assumed to discover or import Fluel's store automatically.

Before either persisted model changes, the combined decision must record:

- Which distributed versions and local or cloud stores contain real data.
- Which data must survive, including original identifiers, precision, photos,
  archive dates, activity, and custom presets where applicable.
- Whether the requirement is no transfer, explicit user import, or continuity
  with a distributed version, supported by evidence rather than inference.
- Conflict, duplicate, retry, partial-failure, and source-preservation rules.
- The next Stally schema and migration stage, backup compatibility, and
  fixtures proving existing Stally marks survive opening and restoring.

The removed legacy schemas remain outside the rebuilt migration baseline.
Do not delete or archive the Fluel repository as part of this evaluation.

## Routes, Intents, Language, And Release Identity

Keep Stally's current `stally` URL grammar and `StallyItemEntity` UUID
resolution stable. Fluel uses a separate `fluel` grammar and `EntryEntity`.
Neither is automatically an alias for a Stally Item. Existing shortcuts and
links need a documented compatibility requirement before any forwarding.

If accepted, start and time-together use cases should enter through a
Stally-owned Operations boundary; the app's feature adapters would expose
them. Do not copy Fluel's App Shortcuts catalog, runtime bootstrap, or app-wide
navigation. Preserve the meanings of Item, Mark, Library, Archive, Review,
and Insights in English and Japanese. Review candidate time-together language
alongside them before expanding the catalogs.

One delivery host could reuse Stally's settings, backup entry point, runtime,
licenses, and subscription integration. It would still incur date semantics,
migration, transfer, accessibility, localization, and real-device testing
costs. Two apps would retain two app shells, identities, CloudKit environments,
store/support surfaces, and release verification paths. Neither cost should be
estimated from overlapping field counts alone.

## Reconciled Findings And Decision Handoff

Both assessments agree that starts must preserve precision, marks and activity
are different histories, photo presence cannot stand in for photo bytes, and
one app shell would not eliminate domain or data-continuity maintenance.
Fluel reports 66 package tests and an iOS 27 Simulator build, with no runtime
or real-device transfer evidence; those are Fluel-side results, not Stally
verification.

Fluel also establishes why a home or other relationship without daily choices
cannot simply become an unmarked Stally Item: it could enter Needs First Mark
or affect collection readings with the wrong meaning. Its activity history and
custom presets remain preserved source knowledge even if a first host slice
defers them. A product omission is not permission to discard required data.

The host-side result is to keep model integration undecided. The remaining
inputs are the real-data/distribution confirmation, accepted combined journeys
(especially places without Marks), archive semantics, and a bounded cost
comparison for that scope. Source evidence does not settle those product and
continuity questions.

Stally owns the host-side conflict analysis and integration acceptance cases.
Use the completed Fluel assessment and domain contract as the other side of
the decision. Resolve the remaining inputs above before choosing whether or
how to combine models.

The resulting decision must name the accepted journeys, information
architecture, domain ownership, archive semantics, routes and App Intents,
product language, release identity, and transfer requirement. Until then,
continue Stally work that survives either outcome, including backup safety
and the release evidence gaps in [release-readiness.md](release-readiness.md).
