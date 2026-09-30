# Product Language

## Current Combined Product Glossary

The first-release vocabulary follows `first-release-data-model.md`. One Item
can carry daily choices, start knowledge, both, or neither. Its identity and
context do not depend on which readings the person wants to keep.

| English | Japanese | Meaning |
| --- | --- | --- |
| Item | アイテム | One personally meaningful thing or place |
| Mark | マーク | A recorded choice on one local calendar day |
| Record Marks | マークを記録する | Enable daily choice recording |
| Start | 開始時期 | Entered year, month, or day; creation is separate |
| Not Set | 未設定 | No start knowledge has been entered |
| Time Together | 一緒に過ごした時間 | A reading at the entered start precision |
| Milestone | 節目 | A derived yearly reflection, never a new event |
| Library | ライブラリ | The active collection, with either recording policy |
| Archive | アーカイブ | Put an Item aside; time and history continue |
| Review | 見直し | Revisit Mark-enabled Items that may need attention |
| Insights | 振り返り | Read choice patterns and collection context |
| History | 履歴 | Recorded choice days, separate from elapsed time |
| Import & Export | 読み込みと書き出し | Take the full collection out or bring data in |
| Stally Data | Stallyデータ | A portable collection file |
| Backup | バックアップ | A retained export for later recovery |
| Merge | 統合 | Keep local details and add missing compatible history |
| Replace | 置き換え | Restore the file's collection after confirmation |

Item is the canonical interface noun; thing/place explains its scope. A
relationship describes the person's time with that Item, not another record
or a social connection. Do not expose `recordsMarks`, schema names, or
"non-Mark state" in ordinary copy. Say that an Item does not record Marks.
An Item with no Marks yet may still have recording enabled; keep that distinct.

Start never implies an exact day when only a year or month is known. Japanese
uses 開始時期 for the general concept; exact-day controls may still say 日.
Archive never means ending the relationship. Milestones, counts, and time
together remain readings rather than inferred actions or history.

### Action Vocabulary

Use the same verbs in visible controls, accessibility labels, App Intents,
entity descriptions, and transfer prompts:

- Add Item / アイテムを追加; Edit Item / アイテムを編集.
- Mark Today / 今日マーク; Undo Today's Mark / 今日のマークを取り消す.
- Archive Item / アイテムをアーカイブ.
- Move Back to Library / ライブラリに戻す.
- Check Time Together / 一緒に過ごした時間を確認.
- Share Time Together / 一緒に過ごした時間を共有.
- Export Data / データを書き出す; Import Data / データを読み込む.
- Choose Data File / データファイルを選択.
- Merge Into Library / ライブラリに統合.
- Replace Library / ライブラリを置き換え.

Siri/Shortcuts name the same Item and actions. Stable route/UUID identifiers
and internal `Backup*` implementation types do not become interface language.
The `.stallybackup` extension and versioned development files retain their
documented meaning; a neutral display name does not relabel their schema.

### Public and Store Copy

Use this combined-product meaning in repository, support, and future Store
descriptions. Store publication and the public website deployment remain
separate release actions; this glossary is their copy source.

English:

> Keep a quiet record of the things and places that matter to you. Record
> everyday choices with Marks, look back on time together, or keep both.
> Enter only the start year, month, or day you know. Archive keeps an Item
> nearby without ending your time together. Your collection can be exported
> with its notes, photos, and history and previewed before importing it again.

Japanese:

> 大切なものや場所を、静かに記録するアプリです。日々の選択をマークしたり、
> 一緒に過ごした時間を振り返ったり、どちらも同じアイテムに残せます。
> 開始時期は、わかる年・月・日だけを入力できます。アーカイブしても時間は進み、
> 情報や履歴は残ります。メモ・写真・履歴を含むコレクションを書き出せます。
> データを読み込む前に内容を確認できます。

## Preserved Language Reference

The following sections retain the original Mark-centered language as product
intent evidence. Historical names such as Backup Center are superseded by the
current glossary; these examples do not restrict Items to daily choices.

## Voice

Stally's voice is calm, direct, and personal.

Use language that observes the user's collection without judgment. Prefer
phrases that suggest quiet accumulation, personal choice, and readable
history.

## Core Positioning Lines

Preserve these lines or their close meaning:

- "A quiet record of the things you keep choosing."
- "An app for marking your own actions and quietly building up counts."
- "Read the collection as a pattern, not just a list."
- "Past favorites can stay nearby without crowding the main list."
- "One mark is enough for today."

Sample item notes show the preferred scale and texture of item context:

- "The one I reach for on cold mornings."
- "Easy pair for short walks and errands."
- "Usually comes with me when I need one extra layer."
- "Still waiting for its first stretch of regular use."
- "Archived because it only comes out a few times a year."

## Canonical Nouns

Use these nouns consistently:

- Stally.
- Item.
- Category.
- Note.
- Photo.
- Mark.
- History.
- Library.
- Archive.
- Review.
- Insights.
- Backup Center.
- Settings.
- Deep Links.
- Backup.
- Snapshot.
- Report.
- Needs Review.
- Collection Snapshot.
- Archive Snapshot.
- Review Snapshot.
- Backup Snapshot.
- Collection Health.
- Spotlight.
- Scope.

## Category Names

Preserve these category labels:

- Clothing.
- Shoes.
- Bags.
- Notebooks.
- Other.

## Library Language

Preserve these Library and Archive refinement labels:

- All.
- All Categories.
- Search items.
- Search archive.
- Clear.
- Open Today.
- Marked Today.
- Marked on Day.
- Open on Day.
- Never Marked.
- With History.
- Without History.
- Default Order.
- Recently Marked.
- Most Marked.
- Name.
- Category.
- Items shown.

`Open Today` and `Marked Today` belong to the lightweight daily Library scan.
`Open on Day` and `Marked on Day` are the selected-day versions of the same
marking idea.

Preserve these item-level reading labels:

- Overview.
- Actions.
- Quiet History.
- Total marks.
- Last marked.
- Not yet.
- Marks (30d).
- Marks (90d).
- Months Used.
- Days Since Last.

## Review Language

Preserve these review lane names:

- Needs First Mark.
- Dormant.
- Recovery Candidates.

Supporting language:

- "Find the items that deserve attention before they drift too far out of
  mind."
- "Items that have been waiting quietly without a first mark."
- "Items whose last mark feels far enough away to revisit."
- "Archived items whose history suggests they may deserve another turn."

## Insight Language

Preserve these section and metric names:

- Activity.
- Consistency.
- Categories.
- Rankings.
- Rhythm.
- Recommendations.
- Next Moves.
- Collection Health.
- Spotlight.
- Scope.
- Marks.
- Active Days.
- Best Streak.
- Current Streak.
- Idle Gap.
- Longest idle gap.
- Avg Marks / Week.
- Active Weeks.
- Weekend Share.
- Unique Items.
- Avg / Active Day.
- Busiest Day.
- With History.
- Note coverage.
- Photo coverage.
- Top Items.
- Top item.
- Quiet Items.
- Quiet item.
- Weekdays.
- Months.
- Current State.
- Latest Change.

Preserve these range labels:

- 30 Days.
- 90 Days.
- 365 Days.
- All Time.

Preserve these scope and preference labels:

- Active items only.
- All items.
- Include archived items.
- Include archived items by default.
- Default range.
- Needs First Mark after N days.
- Dormant after N days.
- Show completed review sections.

## Recommendation Language

Preserve these recommendation names:

- Start this range with one mark.
- Revisit quiet favorites.
- Add context to your frequent items.
- Protect the current streak.

Supporting language should stay grounded in the user's data:

- No marks in the selected range.
- Items with history but no marks in the selected range.
- Frequent active items without notes.
- An active streak already in motion.

## Action Language

Use these action labels when the matching concept appears:

- Add Item.
- Edit Item.
- Delete Item.
- Mark Today.
- Undo Today's Mark.
- Add Mark.
- Remove Mark.
- Adjust History.
- Danger Zone.
- Archive Item.
- Archive Selected.
- Move Back to Library.
- Copy Item Link.
- Share Item Link.
- Copy Report.
- Open Review.
- Open Archive.
- Open Insights.
- Open Backup Center.
- Export Backup.
- Choose Backup File.
- Merge Into Library.
- Replace Library.
- Delete Every Item.
- Delete Everything.
- Restore From Backup.
- Show Tips Again.

## Backup Language

Preserve the distinction between:

- Export.
- Import.
- Merge.
- Replace.
- Reset.

Important safety phrases:

- "Export before higher-risk changes."
- "Keep one recent export before you try any replace-style restore."
- "Merge import will preserve local items; replace import will overwrite
  them."
- "Backup files are meant for your own archive and transfer workflow, not for
  syncing between multiple devices at once."

Preserve these backup grouping, preview, result, and status labels:

- Backup Snapshot.
- Export Tools.
- Import Tools.
- Reset Tools.
- Safety.
- Existing.
- New.
- Skipped.
- Marks Added.
- Last Merge Result.
- Last Replace Result.
- Backup saved.
- Merged into the current library.
- Replaced the current library.
- Deleted every item from the current library.

## Error And Empty-State Language

Preserve these concepts:

- Name is required.
- This item no longer exists.
- This link is not supported by this version of Stally.
- Unsupported Schema Version.
- Duplicate Item ID.
- Duplicate Mark ID.
- Unknown Category.
- No Matching Items.
- No Archived Items.
- No Matching Archived Items.
- Nothing Needs Review.
- Nothing in this lane right now.
- Nothing currently looks dormant.
- Nothing is asking to come back right now.
- No activity in this window yet.
- No category activity in this window yet.
- No weekday pattern yet.
- No monthly trend available.
- No follow-up suggestions right now.
- All review lanes are clear right now.

## Preferred Verbs

Prefer:

- Choose.
- Reach for.
- Mark.
- Adjust.
- Revisit.
- Archive.
- Move back.
- Preserve.
- Read.
- Export.
- Preview.
- Merge.
- Replace.
- Restore.

Use "use" only when it reads naturally in supporting copy, such as "last used."
The primary product metaphor is choosing and marking.

## Language To Avoid

Avoid replacing the legacy tone with language that makes Stally feel like:

- A productivity tracker.
- A compliance system.
- A shopping tool.
- A social product.
- A technical analytics console.
- An inventory database.

Avoid shaming labels such as "failed," "bad," or "inactive user" for ordinary
quiet periods. The legacy language uses neutral terms such as "Dormant" and
"Quiet Items."
