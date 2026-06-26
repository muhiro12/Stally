# UI Preview Report

## Purpose

This report records the current SwiftUI preview and screenshot coverage for
the rebuilt Stally core surfaces after the MHUI and MHDesign presentation pass.

The pass intentionally improves the existing UI only. It does not add product
features, change the SwiftData schema, add Operations, or change the
StallyLibrary package boundary.

## Target Screens

Reviewed as current Stally surfaces:

- Library empty state.
- Library with items.
- Item detail.
- Archive.
- Review.
- Insights.
- Backup Center.
- Settings.
- Add Item.

Not included as implemented screens:

- Edit Item: no dedicated edit surface exists yet.
- Photo-specific item UI: preview data includes placeholder photo data, but
  the current UI does not render item photos.

## Preview Coverage

Preview support lives under `Stally/Sources/PreviewSupport/`.

- `StallyPreviewData` creates Product Language aligned representative data.
- `StallyPreviewContainer` injects an in-memory SwiftData container, applies
  `MHTheme.standard`, and uses `MHGlassPolicy.automatic`.
- `StallyPreviewLaunchConfiguration` enables DEBUG-only screenshot routes.
- `StallyScreenPreviews` contains screen-level previews.

Added or retained SwiftUI previews:

- `Stally - Empty Library`.
- `Stally - Typical Collection`.
- `Library - Empty`.
- `Library - Typical`.
- `Library - Dense Dark`.
- `Item Detail - Long Text Large Type`.
- `Add Item - Empty Form`.
- `Archive - Preserved Items`.
- `Archive - Empty`.
- `Review - Attention Lanes`.
- `Review - Empty`.
- `Insights - Typical`.
- `Backup Center - Snapshot`.
- `Backup Center - Import Preview`.
- `Settings - Shareable Links`.

Preview states covered:

- Empty Library.
- Typical Library data.
- Dense Library data.
- Long item name and long note.
- Archived items.
- Empty Archive.
- Review lanes with Needs First Mark, Dormant, and Recovery Candidates.
- Empty Review.
- Insights with active marks and category variety.
- Backup snapshot and import validation issues.
- Add Item empty form validation state.
- Dark mode for a dense Library state.
- Large Dynamic Type for Item Detail.

## Screenshot Artifacts

After screenshots are stored at the root of
`docs/ui-preview-screenshots/`. Before screenshots from the pre-MHUI state are
preserved under `docs/ui-preview-screenshots/before/`.

All saved images are 368 by 800 JPEG files captured on an iPhone 17 Pro
simulator through the DEBUG screenshot launch routes.

- Library empty:
  `docs/ui-preview-screenshots/library-empty.jpg`
- Library dense:
  `docs/ui-preview-screenshots/library-dense.jpg`
- Item detail:
  `docs/ui-preview-screenshots/item-detail.jpg`
- Archive:
  `docs/ui-preview-screenshots/archive.jpg`
- Review:
  `docs/ui-preview-screenshots/review.jpg`
- Insights:
  `docs/ui-preview-screenshots/insights.jpg`
- Backup Center:
  `docs/ui-preview-screenshots/backup-center.jpg`
- Settings:
  `docs/ui-preview-screenshots/settings.jpg`
- Add Item:
  `docs/ui-preview-screenshots/add-item.jpg`

## Adopted MHUI And MHDesign APIs

Adopted:

- `MHUI` product linked into the app target.
- `MHUI` re-exported `MHDesign`; no separate `MHDesign` product link was
  needed.
- `MHTheme.standard` and `MHGlassPolicy.automatic` at the app root and preview
  container.
- `mhListChrome` for existing `List` surfaces: Library, Archive, Review,
  Insights, Backup Center, Settings, and Item Detail.
- `mhFormChrome` for Add Item.
- `MHKeyValueLabeledContentStyle.mhKeyValue` for overview, metric, backup,
  and coverage rows.
- `mhRow`, `mhRowTitle`, `mhRowSupporting`, `mhRowOverline`, and
  `mhTextStyle` for list rows, item metadata, detail copy, recommendations,
  validation issues, and Quiet History date labels.
- `mhBadge` for item category and marked-today state.
- `mhEmptyStateLayout` for native empty states.
- `mhPrimary`, `mhSecondary`, `mhQuiet`, and `mhDestructive` button styles for
  existing action hierarchy.
- `mhSectionHeader`, `mhSectionHeaderTitle`, `mhSectionHeaderSupporting`, and
  `mhSectionFooterText` where native section structure needed quieter support
  text.

## APIs Not Adopted

Not adopted:

- `mhScreen`: the current app already uses native `NavigationStack` titles and
  tab surfaces. Adding an MHUI title block would duplicate navigation meaning
  and reduce native behavior.
- `mhSection`: native `Section` remains a better fit inside `List` and `Form`
  for these screens. Full MHUI section containers can be revisited if a future
  non-list screen needs grouped surfaces.
- `mhSurface` and `mhSurfaceInset`: the goal was calmer native list/form
  chrome, not card-heavy treatment.
- `mhGroupedRows`: native List rows already provide the right platform
  affordance. Grouped rows should wait until Stally has custom stack content
  that is not naturally a List.
- `mhInputChrome`: Add Item currently uses native `TextField`, `Picker`, and
  `Form` behavior. Custom input chrome would be premature without a dedicated
  editor design pass.
- `MHActionGroup`: existing actions are ordinary row buttons, toolbar buttons,
  or confirmation actions. Grouping them visually would make the first UI pass
  heavier than the current product tone needs.
- Custom `MHDesignMetrics` or custom `MHTheme`: `MHTheme.standard` fits the
  quiet neutral direction. Base color or metric customization should remain a
  later owner-directed design-system decision.

## SwiftUI Standard Behavior Preserved

Kept as standard SwiftUI:

- `NavigationStack` and navigation titles.
- `TabView`.
- `List` and `Form` as base containers.
- `ContentUnavailableView` for empty states.
- `ShareLink` for app and item links.
- `fileImporter` and `fileExporter` for Backup Center.
- `confirmationDialog` for merge, replace, and delete confirmations.
- `alert` for unsupported links and save/backup errors.
- Sheet presentation for Add Item, Settings, and Item Detail launch routes.

The reason is deliberate: these APIs already carry the platform semantics
Stally needs. MHUI is used as presentation chrome and hierarchy, not as a
replacement for native interaction behavior.

## Screen Changes

Library:

- Added MHUI list chrome and row rhythm.
- Changed the marked-today indicator from a lone tint icon to a restrained
  `Marked` badge with an accessibility label.
- Kept native navigation, toolbar buttons, and `NavigationLink` behavior.

Archive:

- Shares the improved item row and list chrome with Library.
- Empty Archive remains a native `ContentUnavailableView` with MHUI spacing.

Review:

- Moved lane summaries from body rows into section headers.
- This reduces first-viewport crowding while preserving the documented lane
  copy.
- Item rows use the same Library row treatment.

Insights:

- Kept metrics as native `LabeledContent`.
- Applied MHUI key-value treatment and restrained row typography.
- Avoided charts, cards, or heavier dashboard styling.

Backup Center:

- Applied list chrome, key-value rows, and semantic button styles.
- Kept risky actions behind native confirmation dialogs.
- Used destructive styling only for replace and delete actions.

Settings:

- Applied list chrome and row rhythm to the existing shareable-link list.
- Kept the screen minimal because broader settings are outside this goal.

Add Item:

- Applied MHUI form chrome and footer typography.
- Kept native `Form`, `TextField`, `Picker`, toolbar cancellation, and
  confirmation actions.

Item Detail:

- Applied list chrome and key-value overview treatment.
- Used badges and semantic typography in the header.
- Kept Mark Today as the single primary action and Archive/Undo as quiet
  actions.

## Before And After Notes

Compared with `docs/ui-preview-screenshots/before/`:

- Lists now use calmer full-screen MHUI chrome instead of default grouped list
  density.
- Item rows have a more consistent metadata hierarchy across Library, Archive,
  Review, and Insights.
- Review has less repeated body text because lane explanation is in the
  header.
- Insights reads more like a collection summary than a dashboard because the
  pass avoided new chart or card treatments.
- Backup Center safety copy is softer and action roles are clearer.
- Add Item is still a simple form, but it now matches the visual rhythm of the
  other screens.
- Empty states remain native, but their spacing and primary action style match
  the MHUI pass.

## Runtime Capture Notes

Confirmed through after screenshots:

- Library empty state renders with the documented quiet start copy.
- Dense Library renders active items, notes, mark counts, and updated row
  hierarchy.
- Item Detail renders header, Mark Today, Archive, overview, and Quiet History
  sections.
- Archive renders preserved items without deletion language.
- Review renders all three attention lanes with MHUI section headers.
- Insights renders scope controls and metric rows without heavier dashboard
  treatment.
- Backup Center renders safety copy, snapshot counts, and export/import/reset
  entry points.
- Settings renders shareable destination links.
- Add Item renders the empty form with disabled Add action.

Capture limits:

- Direct Preview capture was not available through the current MCP tool
  surface.
- Earlier `snapshot_ui` attempts failed because the local Xcode beta is
  missing `SimulatorKit.framework` at the expected private-framework path.
- Runtime screenshots were used as the faithful fallback where routes could
  reproduce the screen state.
- Backup import validation is covered by SwiftUI Preview, not runtime
  screenshot, because reproducing it requires file importer interaction.
- Destructive confirmation dialogs were not captured because semantic UI
  automation was unavailable.
- Some screenshots may include an iOS previous-app breadcrumb in the status
  area. The Stally content itself is still visible.

## Future Improvement Candidates

- Consider a dedicated visual pass for action placement in Item Detail after
  real usage confirms whether Mark Today should stay as a full-width primary
  row.
- Add an editor-specific pass before adopting `mhInputChrome`; the current Add
  Item form is still intentionally simple.
- Revisit `mhSection` only if Stally gains non-list summary surfaces that need
  true grouped cards.
- Add empty-state runtime screenshots for Archive and Review if those surfaces
  become release-sensitive.
- Consider owner-directed accent color and metrics tuning later; this pass
  intentionally used `MHTheme.standard`.
- Keep MHUI out of `StallyLibrary` and continue guarding the app/library
  boundary with repository rules.
