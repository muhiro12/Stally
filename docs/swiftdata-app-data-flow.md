# SwiftData App Data Flow

## Live Model Rule

The main app uses the selected `Item` / `ItemMark` SwiftData graph as its live
model. Durable changes enter through StallyLibrary Operations. SwiftData
observation and `@Query` bring those changes back to the views; there is no
second Item-shaped UI graph, query bridge, or manual model-copy refresh.

An independently reading screen owns its `@Query`. Configure store predicates
and sort descriptors at that boundary, through an initializer when they depend
on inputs. Do not copy query results into `@State`.

A selected Item establishes one subtree context. Supply `.environment(item)`
at each selection/destination boundary and read `@Environment(Item.self)` in
its row, detail, editor, history editor, and action descendants. Do not relay
that same live Item through view initializers. This required environment has
no constructed default; a missing injection is a composition error.

Values, bindings, callbacks, configurations, captured readings, and form inputs
remain explicit parameters. A future view comparing multiple peer Items may
take those peers explicitly; it has no single current Item context.

## Read Inventory

| Surface | Read role | Ownership |
| --- | --- | --- |
| Navigation shell | Route and presentation state | No collection query |
| Library | Live active scope and sample eligibility | Screen `@Query` |
| Archive | Live archived scope | Filtered screen `@Query` |
| Review | Live collection and derived lanes | Screen `@Query` + Operations |
| Insights | Live collection and scope readings | `@Query` + Operations |
| Import & Export | Live summary and workflow preview | Screen `@Query` |
| Settings | Live sample-data ownership summary | Screen `@Query` |
| Item route destination | UUID resolution | Bounded Operations fetch |
| Item row/detail/summary | Current live Item | Typed environment |
| Item editors | Live Item and draft values | Typed environment |
| Insights ranking row | Item and range metrics | Environment + values |
| Item history | Related Marks | Item relationship |
| DEBUG hosts | Synthetic graph selection | In-memory environment |

Library deliberately queries the whole collection: it displays active Items
but also needs live collection-wide emptiness to decide whether adding sample
Items is available. Archive has an independent `archivedAt != nil` predicate
and newest-archived sort. Review, Insights, and transfer summaries require
their own whole-collection scopes. Their arrays are live references supplied
to composition helpers and Operations, never stored mirrors.

Navigation paths and links carry UUIDs. `ContentView` and
`StallyItemDestinationView` resolve them through `ItemOperations.item`, using
a predicate and one-result fetch limit. The destination then supplies that
same live model to its children. A missing identity shows the existing
unsupported-link state; a fetch failure exposes its error rather than becoming
an empty collection. DEBUG initial-detail selection is a one-shot read of
already seeded preview data.

## Relationships and Inputs

Mark history belongs to the selected Item's optional SwiftData relationship.
History and time Operations derive their readings from that graph. Detail and
history editing do not issue another Item or ItemMark query.

Cookle's read-only Diary/Recipe reference demonstrates the same pattern:
select a live object, supply its typed environment, traverse existing
relationships, and supply each related object's environment at its row or
destination boundary. A collection derived from a relationship is not another
independent store read. A dedicated query needs a concrete filtering, paging,
sorting, or measured performance reason.

`EditItemView` reads the current Item and supplies semantic form values to
`EditItemForm`. The form initializes its own draft state once per Item identity
and keeps unsaved edits when its live parent changes. Saving targets the same
environment Item through `ItemOperations.update`, which rechecks current
history/policy constraints. There is no write-to-model/copy-back-to-UI step.

Snapshots and transfer records remain valid where their lifetime differs from
the live graph: history/time readings, Review lanes, Insights range metrics,
import previews, reports, stable route IDs, and external App Entities. They do
not become a general replacement for live model propagation. Cross-isolation
consumers follow `domain-operations.md` and use Sendable values/identifiers.

## ResultsObserver Decision

No current non-view consumer needs a continuously observed query.
`ResultsObserver` is therefore not adopted. Ordinary SwiftUI screen reads
continue to use `@Query`; a future non-view observable consumer must establish
its need and isolation before introducing another observer.

The native SDK documentation and implementation use Apple's
[Query](https://developer.apple.com/documentation/swiftdata/query),
[Environment](https://developer.apple.com/documentation/swiftui/environment),
and [ResultsObserver](https://developer.apple.com/documentation/swiftdata/resultsobserver)
contracts. No custom environment key or model default is needed for Item.

## Verification Boundary

The app build compiles all actual destinations and DEBUG preview hosts with
the required model injection. Repository rules and a source inventory check
that selected-model view initializers and root collection relay are removed.
Targeted synthetic runtime interactions verify that Operations writes update
detail and consuming collection screens through the same live model.

On Xcode 27.0 (27A266a), iOS Simulator 27.0 (24A434), a single DEBUG in-memory
integration run demonstrates:

- Canvas Tote's Mark count changes from 3 to 4 to 3 with Mark Today and Undo.
  Detail status, recent-history readings, and the Library badge/count follow.
- Saving Home's edited name updates its detail title and Library row. Its
  year-only 2020 start and disabled Mark policy remain intact.
- Moving focus while editing preserves the unsaved name draft.
- Archive moves the active/archived counts from 6/2 to 5/3; moving back
  restores 6/2. The selected Item retains its year precision and time reading.
- Import & Export then reports 8 Items, 2 archived, and 23 Marks.
- Independent year/month editor launches inject 2020 and September 2020
  respectively, both with Mark recording disabled.

| Reading | Evidence |
| --- | --- |
| Mark state | [Before][mark-before], [after][mark-after], [Undo][mark-undo] |
| Live edit | [Before][edit-before], [saved][edit-after] |
| Draft lifetime | [Refocused draft][draft] |
| Archive and time | [Archived detail][archived], [restored][restored] |
| Cross-surface reading | [Transfer summary][transfer] |
| Precision injection | [Year][year], [month][month] |

[mark-before]: ui-preview-screenshots/data-flow/mark-item-before.png
[mark-after]: ui-preview-screenshots/data-flow/mark-item-after.png
[mark-undo]: ui-preview-screenshots/data-flow/mark-item-after-undo.png
[edit-before]: ui-preview-screenshots/data-flow/nonmark-detail-before-edit.png
[edit-after]: ui-preview-screenshots/data-flow/nonmark-detail-after-edit.png
[draft]: ui-preview-screenshots/data-flow/nonmark-edit-draft-refocus.png
[archived]: ui-preview-screenshots/data-flow/nonmark-detail-archived.png
[restored]: ui-preview-screenshots/data-flow/nonmark-detail-restored.png
[transfer]: ui-preview-screenshots/data-flow/import-export-after-roundtrip.png
[year]: ui-preview-screenshots/data-flow/edit-year-injection.png
[month]: ui-preview-screenshots/data-flow/edit-month-injection.png

This change does not alter persisted fields, schema versions, backup records,
App Entity identity, or navigation destination identifiers.

Native device interaction and process-scoped runtime logs show no fatal app,
SwiftData, ModelContainer, or CloudKit error. Xcode-native scheme/destination
discovery was unavailable; the build uses official `xcodebuild` with an explicit
Xcode 27.0 developer directory and a dedicated discovered iOS 27 Simulator.
No Xcode selection was changed.

These checks use synthetic in-memory data. External model updates during an
open draft, the Quiet History calendar grid, physical-device sync, and production
services are outside this verification.
