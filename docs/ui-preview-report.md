# UI Preview Report

## Purpose

This report records the current SwiftUI preview and screenshot coverage for
the rebuilt Stally core surfaces. It is a preparation artifact for a later
MHUI and MHDesign adoption phase, not a new product feature plan.

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

Preview support now lives under `Stally/Sources/PreviewSupport/`.

- `StallyPreviewData` creates Product Language aligned representative data.
- `StallyPreviewContainer` injects an in-memory SwiftData container.
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
- `Review - Attention Lanes`.
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
- Review lanes with Needs First Mark, Dormant, and Recovery Candidates.
- Insights with active marks and category variety.
- Backup snapshot and import validation issues.
- Add Item empty form validation state.
- Dark mode for a dense Library state.
- Large Dynamic Type for Item Detail.

## Screenshot Artifacts

Screenshots were captured through XcodeBuildMCP runtime launch fallback on an
iPhone 17 Pro simulator. All saved images are 368 by 800 JPEG files.

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

## Runtime Capture Notes

Confirmed through screenshots:

- Library empty state renders with the documented quiet start copy.
- Dense Library renders active items, notes, mark counts, and marked-today
  indicators.
- Item Detail renders header, Mark Today, Archive, and overview sections.
- Archive renders preserved items without adding deletion language.
- Review renders all three attention lanes.
- Insights renders scope controls and early metric sections.
- Backup Center renders safety copy, snapshot counts, and export entry point.
- Settings renders shareable destination links.
- Add Item renders the empty form with disabled Add action.

Capture limits:

- Direct Preview capture was not available through the current MCP tool
  surface.
- `snapshot_ui` failed because the local Xcode beta is missing
  `SimulatorKit.framework` at the expected private-framework path.
- Runtime screenshots were used as the faithful fallback where routes could
  reproduce the screen state.
- Item Detail screenshot capture works for a normal detail sheet. The long
  text and large Dynamic Type detail state is covered by SwiftUI Preview.
- Backup import validation is covered by SwiftUI Preview, not runtime
  screenshot, because reproducing it requires file importer interaction.
- Destructive confirmation dialogs were not captured because semantic UI
  automation was unavailable.
- The Item Detail runtime screenshot includes an iOS previous-app breadcrumb
  in the status area. The Stally sheet content itself is still visible.

## UI State Observations

The current UI tone is close to the documented quiet, personal,
non-judgmental direction. The strongest matches are the Library empty state,
Archive copy, Review lane copy, and Backup safety copy.

Areas to watch:

- Review can feel crowded in the first viewport when all lanes have content.
  The first Recovery Candidates row sits close to the tab bar in the captured
  state.
- Insights is functionally readable, but its metric density can start to feel
  like a dashboard if hierarchy is not softened in the next visual pass.
- Backup Center has clear safety copy, but its repeated list sections would
  benefit from a calmer shared section treatment.
- Settings is intentionally minimal and reads as a rebuild placeholder.
- Photo placeholder state is not visible because photos are not currently
  rendered by Library or Item Detail.

## MHUI And MHDesign Candidates

Prioritize MHUI and MHDesign adoption where repeated visual structure already
exists:

- Shared List and Form chrome for Library, Review, Insights, Backup Center,
  Settings, and Add Item.
- Section spacing, section headers, and grouped surface treatment.
- Empty states and quiet guidance surfaces.
- Backup safety, status, and destructive-action treatment.
- Toolbar/share actions and icon sizing.
- Item row metadata hierarchy and marked-today indicator treatment.

Keep SwiftUI standard behavior where it is already appropriate:

- `NavigationStack`.
- `TabView`.
- `List` and `Form` as the base containers.
- `ContentUnavailableView`.
- `ShareLink`.
- `fileImporter` and `fileExporter`.
- `confirmationDialog` for destructive backup actions.

## Next MHUI Adoption Goal Candidates

The next MHUI adoption Goal should not add new product surfaces. It should:

- Compare these screenshots against current MHUI and MHDesign capabilities.
- Choose one shared list/form visual treatment and apply it across existing
  screens.
- Keep Product Language unchanged unless UI fit requires small copy tightening.
- Preserve the app/library boundary and avoid MHUI dependencies in
  `StallyLibrary`.
- Re-capture the same screenshot set after adoption for before-and-after
  comparison.

Avoid in the next Goal:

- Adding App Intents, Widgets, Watch, CloudKit, or broader settings.
- Reworking navigation hierarchy before visual system fit is understood.
- Replacing native SwiftUI containers with custom equivalents.
- Turning Insights into a heavier analytics dashboard.
