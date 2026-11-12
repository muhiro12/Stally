# SwiftData App Data Flow

## Live model ownership

The main app uses the five `StallySchema` models as its live object graph:
`Item`, `ItemMark`, `ItemPeriod`, `ItemPhoto`, and `Tag`. Their relationships,
identity, and ownership follow the [schema contract](model-schema-design.md).
There is no mirrored Item entity, copied query result in `@State`, or
`ResultsObserver` layer between SwiftData and SwiftUI.

Use `@Query` at the feature composition boundary that independently needs a
live store collection. Configure predicates and sorting at that boundary when
needed. Follow relationships for records already owned by a selected model;
do not add child queries merely because a relationship contains many records.
Use a bounded Operations lookup for a one-shot identity resolution when no
appropriate live collection is already available. `ResultsObserver` requires
a concrete non-view consumer; it is not a replacement for ordinary view queries.

## Current read inventory

| Boundary | Read and ownership |
| --- | --- |
| `StallyApp` | Opens the container and supplies it, the library session, and the write session to the app subtree. It does not query Items. |
| `LibraryView` | Owns the live Item and Tag queries used by the three-column Library feature. Resolves selected persistent IDs and incoming Item UUID links against those live results. Missing or duplicate UUID matches produce an error. |
| `LibrarySidebar`, `ItemListView` | Receive the Library feature's collections for counts, destination filtering, search, and sorting. These are live model references, not stored snapshots or independently fetched collections. |
| `ItemListRow`, `ItemDetailView` | Read their current Item from the typed environment. The list injects each row's Item; `LibraryView` injects the selected detail Item. |
| Detail sections and quick actions | Read the same Item from the environment. Summary, photos, Marks, periods, and readings traverse its relationships through the relevant Operations. They do not re-fetch the Item. |
| `ItemTagPicker`, `ItemDraftTagsSection` | Query all Tags because the available choices extend beyond the Item's assigned Tags. The picker obtains its target Item from the environment. |
| `TagManagerView`, `TagEditor`, `TagConsolidationView` | Own their independently presented Tag collections. Consolidation identifies two peer Tags and prepares a value review. |
| Transfer and diagnostics | Operations perform user-requested export, import review, or diagnostic reads. Their archives, reviews, and diagnostic counts are purpose-specific snapshots, not live collection substitutes. |

`LibraryView` deliberately remains the query owner for its coordinated sidebar,
list, and selection. Moving the query into each column would duplicate collection
reads and complicate selection and link resolution. A future independently
scoped or paged feature can own its own query when that boundary is useful.

## Selected Item propagation

```text
LibraryView @Query [Item]
  -> ItemListView -> each row .environment(item) -> ItemListRow
  -> selectedItemID -> selected Item
     -> ItemDetailView.environment(selectedItem).id(selectedItem.persistentModelID)
        -> summary / photos / readings / Marks / periods / quick actions
        -> RecordEditor and ItemTagPicker sheets
```

Views acting on the current Item declare `@Environment(Item.self)`. Do not
relay that Item through initializers or re-query it in descendants. The detail
identity resets presentation state when selection changes, including pending
record selections and quick-action undo state. Sheets inherit the selected
Item and the app's write session from their presenting subtree.

Required Item readers must have an ancestor that injects the live Item,
including standalone Previews. The Library add-Item sheet has no selected Item
requirement: it edits a new value draft.

Explicit parameters remain appropriate for bindings, actions, configuration,
drafts, snapshots, record-edit selection, and operations involving peer models.
`RecordEditor.Selection` describes the requested action and its Mark or Period
target; it does not relay the parent Item. Existing Tag editor/label inputs and
the Period row input remain separate from this selected-Item propagation change.
When changing those model-context boundaries, apply the same typed-environment
convention rather than adding another selected-model relay chain.

## Draft and mutation flow

`ItemDetailView` prepares `ItemOperations.draft(for:)` when presenting the Item
editor. `ItemEditor` accepts the draft, a localized title, and an optional save
callback. It does not need the live Item: the draft retains the original identity
and values needed by Operations. New Item creation supplies an empty draft.
SwiftUI `@State` preserves that draft for the editor's presentation lifetime;
ordinary view updates do not replace in-progress input.

`ItemTagPicker` similarly seeds local selection state from explicit Tag IDs,
while its save target is the environment Item. `RecordEditor` initializes date
drafts from its action selection and uses the environment Item for new records.
Canceling these forms discards local inputs without mutating stored records.

```text
user action or submitted draft
  -> RecordWriteSession.performMutation
  -> public StallyLibrary *Operations
  -> validated SwiftData write
  -> @Query / observed model properties and relationships
  -> rows, detail sections, and counts
```

The write session enforces update/account validity; Operations own validation,
mutation, save, and rollback. Views own presentation state and report errors.
The Item editor's save callback selects a newly created Item; it does not copy
saved fields into a shadow UI model. Item editing preserves the existing
[draft and save semantics](item-context-implementation.md#item-save-behavior),
including protection of unedited fields against intervening changes.

Photo drafts, period readings, import reviews, archives, App Intent entities,
and route IDs retain their distinct meanings and lifetimes. They are not
replacements for the live SwiftData graph.
