# Domain Operations

## Selected Boundary

The combined model in `first-release-data-model.md` has one Item identity,
independent Mark policy and start knowledge, and Archive as collection
placement. Operations follow those capabilities rather than the product that
originally introduced them. No aggregate rewrite is needed.

`ItemOperations` owns record creation, configuration, choice-history changes,
identity resolution, and placement. Its `+Tracking` file is an implementation
extension of that facade: creation and editing accept the same independent
Mark policy and start input. It is not another domain service or model. The
default creation overload remains a deliberate convenience for a Mark-enabled
Item with unknown start. Metadata-only updates preserve tracking knowledge.

`ItemTimeOperations` remains a separate, read-only capability. It applies to
either recording policy and to either collection placement. Milestones use
the same precision-aware start reading and remain derived yearly reflections.
They do not warrant a broader event or reflection subsystem.

Review selects actionable choice-history lanes. Insights reads patterns and
collection coverage. Their meanings and transaction/read lifetimes differ;
combining them would obscure their contracts. Future relationship-ending
behavior would require its own product decision, durable fact, and time
reading rules. It must not overload Archive.

## Public Use-Case Inventory

| Family | Role | Decision |
| --- | --- | --- |
| Item | Identity, configuration, history, placement | Core; retain |
| Item time | Precision-aware readings and milestones | Read-only; retain |
| Collection browsing | Search, filters, stable sorts | Product scope; retain |
| Photo | Bounded normalization and validation | Portable contract; retain |
| Review | Attention lanes and bulk placement | Core; retain |
| Insights | Choice patterns and whole-scope coverage | Read-only; retain |
| Import/export | Full-data transfer and recovery | Core; retain |
| Links | Destination and UUID transport | Adapter contract; retain |
| Sample data | Owned synthetic examples | Retain; unification in #20 |
| Subscription | Entitlement reading | Independent from iCloud; retain |
| Persistence | Factory and migration plan | Infrastructure; retain |

Public entry points by owner:

- Item: `create`, `update`, `delete`, `archive`, `moveBackToLibrary`, `items`,
  `item`, batch identity resolution, name matching, `suggestedItems`,
  `activeItems`, `archivedItems`,
  `itemsEligibleForHistoryChanges`, `mark`, `undoMark`, `isMarked`,
  `historySnapshot`, `trackingInput`, `capabilities`, and the history-change,
  conflict, and disable helpers.
- Time: `snapshot`, `milestone`, `elapsedText`, `startText`, `report`.
- Browsing: `ItemCollectionOperations.items`.
- Photo: `prepare`, `validate`, and size constants.
- Review: `snapshot`, `identifiersSnapshot`, `performPrimaryAction(s)`.
- Insights: `snapshot`, `InsightsReportOperations.report`.
- Import/export: `snapshot`, `exportData`, `preview`, `review`, `importReviewed`,
  `mergeIntoLibrary`, `replaceLibrary`, `deleteEverything`, and oversized-preview
  helper.
- Links: `url`, `parse`, and scheme.
- Sample data: empty-library creation, summary, and removal.
- Subscription: `calculate`.

Core writes retain validation and rollback. UUID resolution uses a predicate
and a single-result limit. Action guards and suggestions share capability
readings; compatibility helpers delegate to them. Time values remain separate
from localized report formatting. Review retains atomic bulk placement, and
import/export retains explicit preview and recovery transactions. Reviewed app
imports bind the file, method, and complete current-data baseline; changes
require a new visible review before writing.

No public facade is obsolete merely because it was added later. Localized
presentation belongs beside reusable domain readings; SwiftUI, sheets, and
framework-specific entities stay in the app. Browsing operates on a supplied
scope so it does not decide navigation or invent another stored collection.

## First-Release Task Map

| User task | Authoritative entry point |
| --- | --- |
| Add with either policy and start precision | Item `create` |
| Edit context, photo, policy, start | Item `update`, `trackingInput` |
| Mark, Undo, or adjust a local day | Item `mark`, `undoMark` |
| Browse Library or Archive | Query plus collection `items` |
| Read choice history | Item `historySnapshot` |
| Read/share time and milestones | Time `snapshot`, `report`, `milestone` |
| Put aside or return | Item `archive`, `moveBackToLibrary` |
| Inspect/apply a Review lane | Review `snapshot`, `performPrimaryAction(s)` |
| Read/share Insights | Insights `snapshot`, report `report` |
| Preview an import | Backup `review`; value `preview` |
| Merge or replace reviewed data | Backup `importReviewed` |
| Save/share full data | Backup `exportData` |
| Delete one or reset all | Item `delete`, Backup `deleteEverything` |
| Open/share links | Link `parse`, `url`; app routing |
| Add/remove sample Items | `SampleDataOperations` |

Form and tracking inputs retain their selected precision. Date selection is
presentation state. Import preview precedes the chosen mutation; destructive
actions require the app's existing confirmations.

## Capability Rules

`ItemOperations.capabilities(for:)` captures a Sendable `ItemCapabilities`
reading. It contains action eligibility rather than a mirrored Item. The
legacy eligibility helpers delegate to that same reading. Mark and Undo
re-evaluate it on the live model, and configuration edits use it to protect
existing history. A captured value never authorizes a later mutation.

| State | History writes | Disable recording | Placement | Time |
| --- | --- | --- | --- | --- |
| Active, enabled | Validate day | Empty history | Archive | Read |
| Archived, enabled | Return first | Empty history | Move back | Read |
| Active, disabled | Blocked | Already off | Archive | Read |
| Archived, disabled | Blocked | Already off | Move back | Read |
| Disabled, history conflict | Blocked | Keep history | Either | Read |

Every time reading respects entered precision and continues through Archive.
Conflicts preserve existing history and remain visible rather than being
silently repaired by a reading or placement action.

Review and choice-count Insights use recording-enabled Items. Collection note
and photo coverage use the whole selected scope. Inspecting retained history
is valid even when a conflict blocks further history changes. Generic Item
identity/name resolution includes both policies and both placements; action
suggestions may narrow to eligible Items without redefining entity identity.

## Isolation and Value Lifetimes

Live `Item`/`ItemMark`, `ModelContext`, `ReviewSnapshot`, Review action requests,
and Insights contribution lists remain inside the owning isolation domain.
The app uses their identity and SwiftData observation. Do not add unchecked
Sendable conformance or send them to another actor or process.

System adapters resolve UUIDs in their own context, call Operations there,
then return purpose-specific values:

- `ItemHistorySnapshot`, `ItemTimeSnapshot`, `ItemMilestone`, and
  `ItemCapabilities` are immutable Sendable readings.
- `ReviewIdentifiersSnapshot` captures ordered lane UUIDs without retaining
  models. Resolve them afresh and recheck live eligibility before writing.
- Insights and time reports are Strings. The app's model-bearing Insights
  reading remains local; it is not a cross-actor transport type.
- Form inputs, partial dates, route values, and backup records retain their
  distinct input/wire lifetimes. Never replace ordinary live UI reads with
  these captured values just to hide SwiftData.

This follows Swift's
[Sendable guidance](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
and [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
UUID lookup follows Apple's
[FetchDescriptor constraints](https://developer.apple.com/documentation/swiftdata/fetchdescriptor).

## Verification

Library tests cover capability policy/placement combinations, duplicate Mark
idempotency, conflict retention, stale captured permissions, bounded UUID
resolution including pending records and rollback, and value capture across
a detached task. Review identity readings match the live lane calculation and
retain their captured membership after later placement changes. Existing
tests cover precision-aware time, archive-independent elapsed time, Review
transactions, Insights scope, photos, portable round trips, and migrations.

The app build proves the public facade remains usable by existing adapters.
Visible UI restructuring, system entity redesign, and actual Siri execution
belong to the following issues.
