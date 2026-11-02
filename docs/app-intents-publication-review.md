# App Intents first-publication review

## Release decision

Use the identifiers and types in the inventory below as the proposed 1.0 baseline.
Four behaviors need correction before freezing it. The findings come from the
existing iOS Release extraction and source inspection. Saved workflow replay,
locked-device authentication, and delivery of omitted versus explicitly empty
values through Shortcuts remain release checks.

| Action | Why the present behavior matters | Recommended first-release behavior |
| --- | --- | --- |
| Correct Period | With an ended 2018–2020 period, setting only the start to 2019 supplies a missing end and the default ongoing state. If validation succeeds, this loses 2020 and reopens the period. | Treat omitted fields as unchanged, including continuation state. Changes to unknown boundaries or a mistaken ending must be deliberate. Validate the resulting combination before saving. Distinguish an explicit clear from an omitted parameter in Shortcuts. |
| End Period | Calling it again on an already ended period can overwrite the recorded end with an unknown or different date. | Only end an ongoing period. A repeated call on an ended period must preserve its end and report that it is already ended. Correct Period is the operation for revising it. |
| Edit Photo Caption | The default empty string is assigned unconditionally. A workflow that only selects a photo can erase an existing caption. | Require a deliberate replacement or clear. An omitted caption must preserve the saved caption. If the editor cannot express an explicit empty value reliably, provide an explicit clear choice. |
| Get Item Photos | Move Photo writes an explicit position, but the reader returns relationship array order. The first returned photo can differ from the first photo in the app. | Return saved position order, breaking ties by UUID as in the app. Shortcuts can then rely on a move to position 1 being reflected by the next read. |

These are proposed corrections. The inventory records the parameters extracted
**before** the corrections. Update it from the candidate build after implementation.

## Inventory

The November 2 review compared the source at `d984300` with the retained
iOS device Release `Metadata.appintents/extract.actionsdata` (SHA-256
`d83475e393692b85b9c1f227173fe8fdc35f2ff8f18eb86f834a908ab11d1418`).
All 38 Stally actions are discoverable and explicitly require authentication.
Review Import runs in the foreground. The other 37 declare background execution,
including the two Open actions that return an instruction to open a URL.
The package has no promoted App Shortcuts. Five delete actions and tag
consolidation request confirmation before mutation. All writes go through
the session's guarded write operation. The review used the existing build
artifact and did not run tests or install the app.

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
| `CorrectPeriodIntent` | `period: PeriodEntity`, `start: String?`, `end: String?`, `ongoing: Bool = true` | — | Write |
| `CreateItemIntent` | `name: String`, `note: String = ""`, `link: String = ""` | ItemEntity | Write |
| `CreateTagIntent` | `name: String` | TagEntity | Write |
| `DeleteItemIntent` | `item: ItemEntity` | — | Confirm + write |
| `DeleteMarkIntent` | `mark: MarkEntity` | — | Confirm + write |
| `DeletePeriodIntent` | `period: PeriodEntity` | — | Confirm + write |
| `DeletePhotoIntent` | `photo: PhotoEntity` | — | Confirm + write |
| `DeleteTagIntent` | `tag: TagEntity` | — | Confirm + write |
| `EditItemIntent` | `item: ItemEntity`, `name: String?`, `note: String?`, `link: String?` | ItemEntity | Write |
| `EditPhotoCaptionIntent` | `photo: PhotoEntity`, `caption: String = ""` | — | Write |
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
  contract. Correct and End require the changes above.
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
