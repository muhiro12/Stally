# App Intents first-publication review

## Release decision

The first-publication inventory incorporates the four corrections identified in
the November 2 review. Saved workflow replay and locked-device authentication
remain release checks.

| Action | First-release behavior |
| --- | --- |
| Correct Period | Omitting a boundary preserves it. A clear switch explicitly makes that boundary unknown. Continuation defaults to unchanged. The resulting combination must be valid before saving. Correcting only the start of an ended 2018–2020 period preserves 2020 and its ended state. |
| End Period | Only ongoing periods can end. Repetition on an ended period reports that it has already ended and preserves the original end. Use Correct Period to revise it. |
| Edit Photo Caption | An omitted or empty caption preserves the current text. Clear Caption removes it. Supplying both a replacement and a clear request for the same field fails without saving, as for period boundaries. |
| Get Item Photos | Return attachments in the app's saved order, using UUID to break position ties. Moving a photo to position 1 makes it the first result on the next read. |

## Inventory

The November 2 iOS Release build extracted the corrected input definitions in
`Metadata.appintents/extract.actionsdata` (SHA-256
`5703bc41459328a9cb9d012f19a202af3877d9a98780ef995240c9da407e0610`).
All 38 Stally actions are discoverable and explicitly require authentication.
Review Import runs in the foreground. The other 37 declare background execution,
including the two Open actions that return an instruction to open a URL.
The app has no promoted App Shortcuts. Five delete actions and tag
consolidation request confirmation before mutation. All writes go through
the session's guarded write operation. This inventory covers extracted metadata and source behavior.

Parameter names are identifiers. Types, optionality, declared defaults and
results are part of the workflow interface. A question mark denotes an optional
value. An em dash in the result column means no returned value.

| Action identifier | Inputs | Result | Effect |
| --- | --- | --- | --- |
| `AddMarkIntent` | `item: ItemEntity`, `localDateTime: String` | MarkEntity | Write |
| `AddPeriodIntent` | `item: ItemEntity`, `start: String?`, `end: String?`, `ongoing: Bool = true` | PeriodEntity | Write |
| `AssignTagsIntent` | `item: ItemEntity`, `tags: [TagEntity]` | — | Write |
| `AttachPhotoIntent` | `item: ItemEntity`, `file: IntentFile`, `caption: String = ""` | — | Write |
| `ConsolidateTagsIntent` | `source: TagEntity`, `survivor: TagEntity` | — | Confirm + write |
| `CorrectMarkIntent` | `mark: MarkEntity`, `localDateTime: String` | — | Write |
| `CorrectPeriodIntent` | `period: PeriodEntity`, `start: String?`, `end: String?`, `clearStart: Bool = false`, `clearEnd: Bool = false`, `continuation: PeriodContinuationChange = .unchanged` | — | Write |
| `CreateItemIntent` | `name: String`, `note: String = ""`, `link: String = ""` | ItemEntity | Write |
| `CreateTagIntent` | `name: String` | TagEntity | Write |
| `DeleteItemIntent` | `item: ItemEntity` | — | Confirm + write |
| `DeleteMarkIntent` | `mark: MarkEntity` | — | Confirm + write |
| `DeletePeriodIntent` | `period: PeriodEntity` | — | Confirm + write |
| `DeletePhotoIntent` | `photo: PhotoEntity` | — | Confirm + write |
| `DeleteTagIntent` | `tag: TagEntity` | — | Confirm + write |
| `EditItemIntent` | `item: ItemEntity`, `name: String?`, `note: String?`, `link: String?` | ItemEntity | Write |
| `EditPhotoCaptionIntent` | `photo: PhotoEntity`, `caption: String?`, `clearCaption: Bool = false` | — | Write |
| `EndPeriodIntent` | `period: PeriodEntity`, `end: String?` | — | Write |
| `ExportLibraryIntent` | `includingImages: Bool = true` | IntentFile | Read |
| `ExportRecordsIntent` | — | IntentFile | Read |
| `FindItemsIntent` | `text: String = ""`, `scope: ItemArchiveScope = .library`, `favoritesOnly: Bool = false`, `tag: TagEntity?` | [ItemEntity] | Read |
| `GetItemDetailsIntent` | `item: ItemEntity` | ItemEntity | Read |
| `GetItemMarksIntent` | `item: ItemEntity` | [MarkEntity] | Read |
| `GetItemPeriodsIntent` | `item: ItemEntity` | [PeriodEntity] | Read |
| `GetItemPhotosIntent` | `item: ItemEntity` | [PhotoEntity] | Read |
| `GetItemTagsIntent` | `item: ItemEntity` | [TagEntity] | Read |
| `GetPeriodReadingsIntent` | `item: ItemEntity` | String | Read |
| `GetPhotoFileIntent` | `photo: PhotoEntity` | IntentFile | Read |
| `MovePhotoIntent` | `photo: PhotoEntity`, `position: Int` | — | Write |
| `OpenItemIntent` | `item: ItemEntity` | Open URL | Open |
| `OpenItemLinkIntent` | `item: ItemEntity` | Open URL | Open |
| `RecordNowIntent` | `item: ItemEntity` | MarkEntity | Write |
| `RecordTodayIntent` | `item: ItemEntity` | MarkEntity | Write |
| `RenameTagIntent` | `tag: TagEntity`, `name: String` | — | Write |
| `ResumePeriodIntent` | `period: PeriodEntity`, `start: String?` | PeriodEntity | Write |
| `ReviewImportIntent` | `file: IntentFile` | Review dialog | Foreground review |
| `SetItemArchiveIntent` | `item: ItemEntity`, `archived: Bool` | — | Write |
| `SetItemFavoriteIntent` | `item: ItemEntity`, `favorite: Bool` | — | Write |
| `SetItemRecordingIntent` | `item: ItemEntity`, `enabled: Bool` | — | Write |

## Identity and behavior to preserve

- Entity identifiers are the app-owned record UUID. A missing or ambiguous
  identity cannot be replaced by a different record with the same display name.
  The published properties of ItemEntity are name, details (the note), link,
  archived, favorite and recordingEnabled. MarkEntity, PeriodEntity, TagEntity
  and PhotoEntity expose name and details. Entity queries resolve requested
  IDs in caller order, omitting missing records. Changes to labels need not
  change these identifiers.
- ItemArchiveScope has three serialized values, `library`, `archived` and
  `all`. Find Items defaults to the active library. Set actions assign their
  requested state. Set Item Tags replaces membership, including clearing the
  selection when passed an empty list.
- Creating an Item requires a name and creates no Mark or period. For Edit
  Item, omitted name, note or link preserves the current field. An explicit
  empty note or link clears that field. A blank name is invalid.
- Each Record Today, Record Now or Add Mark invocation adds a new occurrence.
  Today records the local day, Now records local minute precision. Add and
  Correct Mark accept `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm`. Correction keeps
  the Mark identity. Delete Mark can target the exact returned Mark.
- Period inputs preserve the precision supplied in `YYYY`, `YYYY-MM` or
  `YYYY-MM-DD`. Adding an ongoing period with unknown start is distinct from
  recording no period. Resuming creates a new identity. Get Time Together
  returns localized text explaining current and cumulative time, precision,
  and applicable subtotal or overlap qualifications. It has no numeric result
  contract. PeriodContinuationChange has the serialized values `unchanged`,
  `ongoing` and `ended`. Reopening a period with a known end requires an
  explicit end clear along with the ongoing state.
- Open Item resolves an existing Item and opens its canonical HTTPS address.
  Open Item Link opens its representative URL. Neither changes a record.
- Export Library returns a native package and includes saved photo bytes by
  default, including embedded metadata. Export Records always returns JSON
  without image bytes. Get Photo File returns the saved bytes in their native
  format. Review Import presents a review and returns a dialog. Only the
  in-app apply operation may write the reviewed selection.
- Retain shipped action, entity and parameter identifiers, enum raw values,
  result types and omission semantics when changing implementation. If a
  future operation needs incompatible meaning, provide a distinct action or
  a verified compatibility path for saved workflows.

See the [implementation and release checks](remaining-capabilities-implementation.md)
and [product behavior](product-behavior-design.md) for the source of these rules.
