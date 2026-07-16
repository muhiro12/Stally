# UI Preview Report

## Purpose

This report records the current SwiftUI preview and screenshot coverage for
the rebuilt Stally core surfaces. It covers the current Library browsing,
photo, history, Review, Insights, Backup Center, Settings, CloudKit,
App Intents, monetization, and English/Japanese localization baseline.

## HIG And MHUI Style Policy

Apple Human Interface Guidelines and platform-native iOS behavior are the
foundation for Stally's app UI. Adaptive split-view navigation, lists, forms,
sharing, sheets, dialogs, alerts, and standard controls should keep their
native SwiftUI semantics unless a concrete product need justifies a custom
treatment.

App views should also consume semantic colors. The app accent resolves through
the Asset Catalog to the system Mint color instead of being specified directly
in feature code. Explicit colors remain appropriate only when they carry a
specific meaning, such as destructive or contrast-critical treatment.

MHUI and MHDesign are the shared app-family style layer on top of that
foundation. In Stally, they should be used more actively than in Incomes where
they improve spacing, hierarchy, typography rhythm, row rhythm, section
treatment, metadata, badges, empty states, summary surfaces, action emphasis,
destructive or safety treatment, feedback, and app-wide visual consistency.

MHUI should not make Stally feel louder, more dashboard-like, or less familiar
as an iPhone app. The desired result is a quiet Apple-native app that still
visibly belongs to the MHUI family.

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
- Edit Item.
- Adjust History.
- Item photo selection and detail presentation.
- Responsive iPhone and iPad navigation structure.

## Audit Findings

Current MHUI usage:

- App root and previews apply `MHTheme.standard` and `MHGlassPolicy.automatic`.
- Native controls and semantic accent styling resolve through the Asset Catalog
  to the system Mint color.
- Existing `List` and `Form` surfaces use Stally-local wrappers around
  `mhListChrome`, `mhFormChrome`, and `MHKeyValueLabeledContentStyle`.
- Rows, metadata, badges, empty states, action emphasis, destructive actions,
  and section support text use MHUI treatment across Library, Archive, Review,
  Insights, Backup Center, Settings, Add Item, and Item Detail.

Common UI kept outside MHUI:

- `NavigationSplitView`, detail-column `NavigationStack`, `NavigationLink`,
  toolbar buttons, sheets, alerts, file import/export, confirmation dialogs,
  and `ShareLink` remain standard SwiftUI because they already carry the
  correct platform behavior.
- Quiet History's dot grid remains a small app-specific data visualization.
  MHUI provides text rhythm around it, but the marked/unmarked dot state is
  product-specific.
- Preview and screenshot launch routing stays DEBUG-only app support, not a
  reusable style-system concern.

Improvements represented by the current surface:

- Backup Center Safety changed from four equal supporting rows into one quiet
  MHUI row summary. This better matches the product principle that safety
  belongs near risk, gives the most important instruction clearer hierarchy,
  and avoids a heavier card or custom surface.
- Empty Library offers clear add, sample-data, and restore paths.
- Library and Archive provide native search and compact category, history,
  date, and sort refinement without turning the first viewport into a filter
  dashboard.
- Add Item and Edit Item use a native Photos picker, while Item Detail presents
  the chosen photo as a header and Library rows stay text-first.
- Review supports both per-item actions and native multi-selection batch
  actions while keeping durable lane rules in `ReviewOperations`.
- Insights includes shareable reports and weekday/monthly rhythm readings.
- Settings exposes Review thresholds, completed-section visibility, Insights
  defaults, and iCloud sync independently from the ad-removal subscription.
- The five bottom tabs were replaced with four sidebar destinations. Library
  and Archive remain collection tasks, while Review and Insights remain
  reflection tasks.
- Backup Center moved out of the peer navigation level. It remains available
  from Settings, the empty-Library restore action, and supported deep links.
- Sidebar selection, primary actions, controls, badges, and preview photo
  fixtures share the Mint accent without feature-level color constants.

Overuse risks intentionally avoided:

- No `mhScreen`, `mhSection`, `mhSurface`, `mhGroupedRows`, `mhInputChrome`, or
  custom theme was added. Those would replace natural native structure or add
  card weight before Stally has a real screen-specific need.
- Item Detail's `Mark Today` remains the single primary action for now because
  it is the central workflow. Its full-width emphasis should be revisited only
  after real usage confirms whether it feels too strong.

Family assessment:

- The app now reads closer to the MHUI family through shared chrome, typography
  rhythm, row treatment, badges, empty states, action styles, and safety
  treatment.
- It still preserves Stally's quiet product tone because the pass avoids
  decorative cards, charts, dense dashboards, and custom replacements for
  familiar iOS controls.

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
- `Edit Item - Existing Values`.
- `Adjust History - Marked Day`.
- `Adjust History - Unmarked Day`.
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
- Backup snapshot, safety summary, and import validation issues.
- Add Item empty form validation state.
- Edit Item with existing text and photo data.
- Marked and unmarked history adjustment states.
- Dark mode for a dense Library state.
- Large Dynamic Type for Item Detail.

## Screenshot Artifacts

After screenshots are stored at the root of
`docs/ui-preview-screenshots/`. Before screenshots from the pre-MHUI state are
preserved under `docs/ui-preview-screenshots/before/`.

The phone images are 368 by 800 JPEG files captured on an iPhone 17 Pro
simulator through the DEBUG screenshot launch routes.
The iPad images are 827 by 1200 JPEG files showing the regular-width layout.
The current set was refreshed after the app adopted split-view navigation.

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
- English localization smoke:
  `docs/ui-preview-screenshots/localization-library-empty-en.jpg`
- Japanese localization smoke:
  `docs/ui-preview-screenshots/localization-library-empty-ja.jpg`
- Japanese package-local localization smoke:
  `docs/ui-preview-screenshots/localization-review-ja.jpg`
- iPad split-view Library:
  `docs/ui-preview-screenshots/ipad-library.jpg`
- iPad split-view Item Detail:
  `docs/ui-preview-screenshots/ipad-item-detail.jpg`

The Library empty-state localization screenshots exercise navigation, sidebar
labels, empty-state copy, and a primary action. The Japanese Review screenshot
also proves that package-owned category, Review lane, summary, empty-state, and
mark-count resources resolve from the `StallyLibrary` bundle. Preview item
names and notes remain deterministic fixture data rather than localized
product copy.

## Localization Baseline

String Catalog coverage added for this baseline:

- `Stally/Resources/Localizable.xcstrings`
- `Stally/Resources/AppIntents.xcstrings`
- `Stally/Resources/AppShortcuts.xcstrings`
- `StallyLibrary/Sources/Resources/Localizable.xcstrings`
- `StallyLibrary/Sources/Resources/SampleData.xcstrings`

English remains the source language. Japanese is the required additional
baseline language.

The app build processed the app catalogs into English and Japanese localized
resources, copied the `StallyLibrary_StallyLibrary.bundle`, and extracted
`Metadata.appintents`. Package-owned `LocalizedStringResource` values explicitly
carry the package bundle so they continue to resolve after crossing into app
views.

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
- A grouped Backup Center safety summary using `mhRow`, `mhRowTitle`, and
  `mhRowSupporting` instead of four equal supporting rows.

## APIs Not Adopted

Not adopted:

- `mhScreen`: the current app already uses native split-view and detail-stack
  titles. Adding an MHUI title block would duplicate navigation meaning and
  reduce native behavior.
- `mhSection`: native `Section` remains a better fit inside `List` and `Form`
  for these screens. Full MHUI section containers can be revisited if a future
  non-list screen needs grouped surfaces.
- `mhSurface` and `mhSurfaceInset`: the goal was calmer native list/form
  chrome, not card-heavy treatment. Backup Safety gained a stronger summary
  hierarchy inside a native row instead of becoming a separate card surface.
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
  quiet neutral direction. The app's Mint identity comes from the Asset Catalog,
  so feature views can continue to use semantic accent styling without a custom
  theme or app-specific color constants.

## SwiftUI Standard Behavior Preserved

Kept as standard SwiftUI:

- `NavigationSplitView` for adaptive sidebar and detail presentation.
- `NavigationStack` inside the detail column and focused sheets.
- `List` and `Form` as base containers.
- `ContentUnavailableView` for empty states.
- `ShareLink` for app and item links.
- `fileImporter` and `fileExporter` for Backup Center.
- `confirmationDialog` for merge, replace, and delete confirmations.
- `alert` for unsupported links and save/backup errors.
- Sheet presentation for Add Item, Settings, and contextual Backup Center
  routes. Item Detail uses the detail navigation path.

The reason is deliberate: these APIs already carry the platform semantics
Stally needs. MHUI is used as presentation chrome and hierarchy, not as a
replacement for native interaction behavior.

## Screen Changes

App shell:

- Replaced five bottom tabs with a two-column `NavigationSplitView`.
- Starts directly in Library at compact widths and exposes the four primary
  destinations through the standard sidebar affordance.
- Keeps the sidebar and selected detail visible together at regular widths.
- Routes item selection and item deep links through a UUID-backed detail path
  instead of presenting Item Detail as a sheet.
- Places Settings in the sidebar toolbar and Backup Center under Settings.

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

- Applied list chrome, key-value rows, semantic button styles, and a grouped
  safety summary row.
- Kept risky actions behind native confirmation dialogs.
- Used destructive styling only for replace and delete actions.

Settings:

- Applied list chrome and row rhythm to subscription, iCloud, Review,
  Insights, shareable links, and about sections.
- Kept controls native and persisted their product-level defaults through
  typed MHPlatform preference descriptors.

Add Item:

- Applied MHUI form chrome and footer typography.
- Kept native `Form`, `TextField`, `Picker`, `PhotosPicker`, toolbar
  cancellation, and confirmation actions.

Item Detail:

- Applied list chrome and key-value overview treatment.
- Used badges and semantic typography in the header.
- Presents the canonical item photo when one is stored, while list rows remain
  compact and text-first.
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
- Backup Center safety copy is grouped into a clearer safety summary, and
  action roles are clearer.
- Add Item is still a simple form, but it now matches the visual rhythm of the
  other screens.
- Empty states remain native, but their spacing and primary action style match
  the MHUI pass.
- Semantic accent styling now resolves to Mint across sidebar selection,
  actions, controls, badges, and the deterministic preview photo fixture.

## Runtime Capture Notes

Confirmed through after screenshots:

- Library empty state renders with the documented quiet start copy.
- Dense Library renders active items, notes, mark counts, and updated row
  hierarchy without a bottom tab bar.
- iPad renders the sidebar and selected detail together without duplicating
  toolbars or navigation titles.
- Item Detail renders header, Mark Today, Archive, overview, and Quiet History
  sections inside the detail navigation stack.
- Archive renders preserved items without deletion language.
- Review renders all three attention lanes with MHUI section headers.
- Insights renders scope controls and metric rows without heavier dashboard
  treatment.
- Backup Center renders the grouped safety summary, snapshot counts, and
  export/import/reset entry points.
- Settings renders shareable destination links.
- Add Item renders the empty form with disabled Add action.
- Mint resolves consistently from the Asset Catalog across the captured app
  surfaces without direct feature-level color selection.

Capture limits:

- Direct Preview rendering is available through the current Xcode-native tool
  surface, but the app-shell `ContentView` preview currently fails while Xcode
  generates its Preview thunk because action closures resolve with conflicting
  actor-isolation types. This is a Preview-only blocker; the app build and
  DEBUG launch routes remain available.
- Runtime screenshots were used as the faithful fallback where routes could
  reproduce the screen state.
- The Xcode device-interaction bridge could not connect to the booted
  simulators during this refresh. Xcode Run still launched successfully, so
  the existing DEBUG routes, `simctl` screenshots, and simulator logs were
  used without erasing simulator data.
- Archive, Review, Insights, Backup Center, Settings, and Add Item were
  reproduced through their DEBUG launch routes after the split-view shell
  stabilized.
- Backup import validation is covered by SwiftUI Preview, not runtime
  screenshot, because reproducing it requires file importer interaction.
- Destructive confirmation dialogs were outside this refresh because the saved
  artifact set covers stable first-viewport states.

## Future Improvement Candidates

- Consider a dedicated visual pass for action placement in Item Detail after
  real usage confirms whether Mark Today should stay as a full-width primary
  row.
- Add an editor-specific pass before adopting `mhInputChrome`; the current Add
  Item form is still intentionally simple.
- Revisit `mhSection` or `mhSurface` only if Stally gains non-list summary
  surfaces that need true grouped cards.
- Add empty-state runtime screenshots for Archive and Review if those surfaces
  become release-sensitive.
- Keep MHUI out of `StallyLibrary` and continue guarding the app/library
  boundary with repository rules.
