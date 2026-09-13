# MHUI Adoption and UI Capture Report

## Purpose

This report preserves the major-screen captures from Stally's MHUI adoption
through version 1.17.0 and subsequent targeted runtime checks.

The initial review date is July 23, 2026. Later checks are dated separately.

The September 13 optional-start integration has a separate
[screen comparison and coverage ledger](item-tracking-verification.md), including
actual Simulator captures, native Preview/session failures, and adapter checks.
Its subsequent isolated interaction audit records one precision-Picker layout
correction, Dynamic Type/appearance comparisons, and explicit manual checks
where runtime operation or accessibility tools could not connect.

## Current MHUI 1.18 Adoption

The September 13 review confirms that the latest published
[MHUI 1.18 release][mhui-1-18] is already installed by `ea9b314`. The app's
lockfile and both verified build checkouts match the published revision
`5e9841f77b770184ea560cec4831adacc1e0fdb6`.

The release makes native `List` and `Form` composition complete adoption paths
alongside stack-based composition. Current Stally already follows that guidance:

- `3b5d353` composes Item Detail with native list sections. Its
  `scrollEdgeEffectStyle` and bottom `safeAreaBar` precede `mhListChrome`,
  keeping the reading surface and floating Mark/history actions in the same
  adaptive layout scope.
- `c337a60` preserves native item-editor fields and photo rows while keeping
  explicit destructive styling for Remove Photo. Native row treatment is
  selective; applying `mhRow` to every field is not required.
- Mark, history, and backup buttons use MHUI's semantic button styles. The
  release's capsule glass effect includes the padded label and disables glass
  interaction for disabled actions inside the package. Stally does not layer
  a competing glass effect or pressed-state workaround over those buttons.
- Insights retains its deliberate stack-based reading hierarchy. The release
  does not require moving every screen to one container style or changing
  app-owned theme tokens.

No further app-source migration is required for 1.18. The prior July 23 policy
and gallery below are historical; their stack-based Item Detail does not
describe the current native-list implementation.

The final Debug build and development-signed Release archive recorded in the
MHPlatform 1.13 check already included this exact MHUI revision and the current
app source. This review rechecked their resolved dependency state and found no
subsequent app, project, or library-source change. Builds and tests were not
repeated for this documentation-only reconciliation. The package release's
own visual validation does not substitute for Stally interaction evidence;
the capture and tool-access limits in the dated checks below still apply.

## July 23 Outcome

The package update and the adoption advice are implemented.

- Item Detail, Insights, and Backup Center now use MHUI signature composition.
- Library, Archive, Review, Settings, and item editors retain native
  `List` or `Form` bridges where platform behavior is part of the screen.
- Native navigation, sheets, file import and export, sharing, TipKit, alerts,
  and confirmation dialogs remain intact.
- Insights now leads with the complete MHUI hierarchy: screen title, editorial
  summary, semantic feature surfaces, then native scope and report controls.
- Enabled primary, secondary, and destructive actions remain visually distinct
  from disabled actions inside `MHActionGroup`.
- The host app still owns the Mint accent through `AccentColor`.
- English and Japanese localization remain complete for the changed surface.
- The main iPhone gallery, targeted accessibility variants, and regular-width
  iPad evidence were refreshed from the rebuilt app.

The current MHUI follow-through is split into these commits:

- `3567b88` updates MHUI to 1.16.0.
- `f2dc247` adopts the adaptive Insights feature hierarchy.
- `29acb19` makes that hierarchy visible as the primary Insights composition.
- `8b6a7dc` updates MHUI to 1.17.0 and adopts its action contrast restoration.

## Adoption policy

Stally chooses its MHUI integration by screen purpose instead of applying one
container style everywhere.

Signature composition is used for read-only detail, report, and focused tool
screens:

- `mhScreen` owns the scrolling canvas, readable width, margins, and vertical
  section rhythm.
- `MHSummary` provides an editorial lead when a screen has a representative
  state or metric.
- `MHFeatureGrid` preserves one primary feature and a concise supporting set
  across available widths and Dynamic Type sizes.
- `MHGroupedRows` presents compact related values without nesting a `List`.
- `MHActionGroup` makes primary, secondary, and destructive actions explicit.
- `mhSection` provides consistent section hierarchy and separation.

Native bridges remain the correct choice for interaction-heavy collection and
editor screens:

- Library and Archive retain search, row navigation, and collection behavior.
- Review retains native selection, editing, and multi-selection behavior.
- Settings retains native controls and preferences.
- Add Item, Edit Item, and Adjust History retain native form semantics.

This preserves the behavior expected from Apple lists and forms while using
MHUI for the screens where custom composition adds meaningful hierarchy.

## Implemented changes

### Item Detail

- Replaced the list container with `mhScreen`.
- Kept the item name as the native navigation title.
- Changed the summary lead to item status so it does not duplicate the title.
- Promoted the item photo to a dedicated `mhSection`.
- Grouped Mark Today, Undo, and Adjust History in `MHActionGroup`.
- Converted History, Quiet History, Overview, Archive, and Delete areas to
  MHUI sections and grouped rows.
- Kept edit, share, TipKit, sheets, and confirmation dialogs native.

### Insights

- Replaced the list container with `mhScreen`.
- Moved Insights into the MHUI screen title and subtitle hierarchy instead of
  repeating a native navigation title.
- Made the selected range the `MHSummary` context and total marks an accent
  badge.
- Added app-owned Activity, Consistency, and Collection Health feature tiles
  using MHUI typography, insets, key-value rows, and semantic surface roles.
- Positioned the feature hierarchy before controls so the first viewport
  communicates the screen's purpose.
- Converted scope controls and report sharing to compact MHUI groups.
- Promoted Activity as the primary reading and grouped Consistency with
  Collection Health as concise supporting readings through `MHFeatureGrid`.
- Converted Activity, Consistency, Rhythm, Categories, rankings, collection
  health, and recommendations to signature sections.
- Kept item navigation and `ShareLink` native.
- Kept the advertisement as product-owned content outside MHUI abstractions.

### Backup Center

- Replaced the list container with `mhScreen`.
- Made the current backup snapshot a leading key-value group.
- Separated Export and Import into focused action sections.
- Promoted Export Backup as the safe primary action.
- Moved a loaded backup into an independent Backup Preview section.
- Shows validation results before merge and replace actions.
- Keeps Delete Every Item as the final destructive section.
- Kept file import, file export, TipKit, alerts, and destructive confirmation
  dialogs native.

## Adopted MHUI surface

The changed screens now use:

- `MHTheme.standard` and `MHGlassPolicy.automatic` at the app root.
- `mhScreen` for Item Detail, Insights, and Backup Center.
- `MHSummary` for Item Detail and Insights.
- `MHFeatureGrid` for the adaptive Insights reading hierarchy.
- `MHGroupedRows` for details, metrics, history, validation, and status.
- `MHActionGroup` for focused safe and destructive action clusters.
- `mhSection` for signature section hierarchy.
- `MHKeyValueLabeledContentStyle.mhKeyValue` for compact value reading.
- Existing MHUI typography, badge, empty-state, row, and button styles.

Stally does not add a custom theme, fixed RGB palette, separate MHDesign link,
or MHUI dependency to `StallyLibrary`.

## Root-first styling and asset ownership follow-up

The July 23 package review confirms that Stally already has the preferred
root shape:

```swift
rootContent
    .stallyPlatformEnvironment(platformEnvironment)
    .mhTheme(.standard)
    .mhGlassPolicy(.automatic)
```

`mhTheme(_:)` is the canonical root-first styling entry point. It propagates
the complete theme, synchronizes the underlying MHDesign metrics, and carries
the app-owned `AccentColor` into the ordinary native tint path. Stally should
not add a blanket root button, font, foreground, list, or form style; those
styles would cross toolbar, menu, and system-presentation boundaries where the
root cannot infer semantic intent.

The current captures show that this is not a conservative, theme-only
adoption. Item Detail, Insights, and Backup Center visibly use the MHUI
signature through editorial rules, section cues, outlined grouped rows, and
measured whitespace. Library, Archive, Review, Settings, and editors remain
native routes for concrete collection, selection, preference, and input
behavior. Their native containers are deliberate exceptions rather than the
dominant design direction.

MHUI 1.17 is now resolved. It preserves the semantic color adoption and
adaptive feature hierarchy from 1.16 while restoring enabled label and symbol
contrast inside Liquid Glass action groups. Stally does not add a local
foreground override or disable Glass for these controls; the package-owned
action styles remain the presentation authority. Stally continues to use the
package's semantic color modifiers for the remaining product-source color
exceptions:

1. `View+StallyPresentationChrome.swift` applies
   `.mhTint(.primaryText)` where toolbar actions intentionally use a neutral
   theme color.
2. `ItemPhotoFeedback.swift` applies
   `.mhForegroundStyle(.destructive)` and
   `.mhForegroundStyle(.secondaryText)` to feedback content.
3. `ItemCollectionRefinementSection.swift` resolves its secondary count
   through the MHUI secondary text role.
4. `QuietHistoryDayCell.swift` resolves marked and unmarked circles through
   `.accent` and `.secondaryText`, keeping opacity as a code-derived treatment.

These changes keep concrete color values in MHUI or app asset catalogs while
letting source express semantic intent. The `CGColor(red:...)` values in
`StallyLibrary` test photo fixtures are generated image-processing inputs, not
shipping presentation colors. The screenshot JPEGs under `docs` are review
artifacts, not runtime app resources.

## Capture environment

- App configuration: Debug.
- Xcode: 27.0 beta, build `27A5228h`.
- iPhone: iPhone 17 Pro for Stally, iOS 27 Simulator.
- iPad: iPad Pro 11-inch (M5) for Stally, iOS 27 Simulator.
- Main gallery locale: Japanese app localization with deterministic preview
  item data.
- Phone artifacts: 368 by 800 JPEG.
- iPad artifacts: 827 by 1200 JPEG.
- Source: DEBUG preview scenarios and launch routes.
- Simulator application data was not erased.

## Major iPhone screens

### Library

Empty state:

![Library empty](ui-preview-screenshots/library-empty.jpg)

Dense collection:

![Library dense](ui-preview-screenshots/library-dense.jpg)

### Item Detail

![Item Detail](ui-preview-screenshots/item-detail.jpg)

### Archive

![Archive](ui-preview-screenshots/archive.jpg)

### Review

![Review](ui-preview-screenshots/review.jpg)

### Insights

![Insights](ui-preview-screenshots/insights.jpg)

### Backup Center

![Backup Center](ui-preview-screenshots/backup-center.jpg)

### Settings

![Settings](ui-preview-screenshots/settings.jpg)

### Add Item

![Add Item](ui-preview-screenshots/add-item.jpg)

## Regular-width iPad screens

The iPad captures confirm that the split-view sidebar remains native while
signature screens use a constrained readable content width. Insights uses the
regular-width `MHFeatureGrid` split: the elevated Activity feature leads, with
the two muted supporting features beneath it.

### Library

![iPad Library](ui-preview-screenshots/ipad-library.jpg)

### Item Detail

![iPad Item Detail](ui-preview-screenshots/ipad-item-detail.jpg)

### Insights

![iPad Insights](ui-preview-screenshots/ipad-insights.jpg)

## Targeted adaptive evidence

### Insights feature hierarchy

The regular-width capture isolates the app-owned feature content that MHUI
arranges. Activity remains primary, while Consistency and Collection Health
form a concise supporting pair and stay readable in Japanese.

![Insights feature hierarchy](ui-preview-screenshots/insights-supporting.jpg)

### Insights in Dark Mode

Semantic text, group borders, controls, and the Mint accent remain legible.

![Insights Dark Mode](ui-preview-screenshots/insights-dark.jpg)

### Item Detail with accessibility text

The summary and section hierarchy reflow at
`accessibility-extra-large` without truncating the first viewport.

![Item Detail accessibility text](ui-preview-screenshots/item-detail-accessibility.jpg)

### Backup Center with increased contrast

Grouped boundaries and action hierarchy remain visible with Increase Contrast
enabled.

![Backup Center increased contrast](ui-preview-screenshots/backup-center-contrast.jpg)

### Library in forced right-to-left layout

Navigation controls and leading alignment mirror correctly. English is
expected here because Arabic is not a supported Stally localization.

![Library right-to-left](ui-preview-screenshots/library-empty-rtl.jpg)

The iPhone Simulator was restored to Light appearance, standard Large content
size, and normal contrast after these captures.

## Review findings

No blocking visual issue was found in the captured first viewports.

- Signature screens have one clear navigation heading and do not repeat it in
  `MHSummary`.
- Grouped rows read as one related surface without nested list chrome.
- Item Detail keeps its photo and Mark Today action prominent without turning
  the screen into a dashboard.
- Enabled Mark, history, archive, export, and destructive actions no longer
  resemble disabled controls when composed inside `MHActionGroup`.
- Insights presents its purpose, range summary, primary readings, scope, and
  report in a stable editorial order. Activity stays primary while
  Consistency and Collection Health reflow as supporting content.
- Backup Center separates safe, import, and destructive tasks clearly.
- Native collection, selection, editor, and system-presentation behavior is
  unchanged.
- iPad uses a readable detail width while preserving the system split view.
- Dark Mode, accessibility text, increased contrast, and forced RTL do not
  introduce clipping or misplaced controls in the captured states.

## Verification boundary

Runtime captures verify layout and presentation of the stable first viewport.
They do not by themselves prove:

- destructive confirmation completion;
- runtime file importer interaction with an external backup document;
- real-device CloudKit synchronization;
- production StoreKit resolution;
- production AdMob serving.

Backup import validation remains represented by the dedicated
`Backup Center - Import Preview` SwiftUI preview and by the compiled
`BackupImportPreviewSection`. Destructive actions remain behind native
confirmation dialogs and were not executed for this visual audit.

The updated action surfaces were captured from live iPhone and iPad Simulator
launches. MHUI's dedicated action contrast regression Preview was also rendered
in Light and Dark appearances. Xcode Device Interaction did not establish a
workspace-backed session, so the already-built app was installed directly and
verified through a bounded non-workspace session instead. That session captured
the Item Detail hierarchy before and after scrolling, confirmed enabled
44.3-point action controls without truncation or overlap, and was then stopped.

The repository build, library tests, repository rules, string-catalog audit,
and runtime-log review are recorded in the task handoff alongside this report.

## September 13 Backup Export Verification

This targeted check uses the existing `typical` in-memory launch fixture on
iPhone 18 Pro, iOS 27.0, built with Xcode 27.0 (`27A266a`). It records current
runtime evidence for backup validation hardening, not a new visual baseline
or acceptance of a broader redesign. Product copy and MHUI composition were
preserved.

The Japanese Backup Center showed 5 items, 1 archived item, and 23 marks.
Export opened the native Files exporter with the Stally backup filename.
Dismissing that sheet without saving returned to the same collection counts.

![Backup Center before export][release-backup]
![Native Files exporter][release-exporter]
![Backup Center after dismissing the exporter][release-dismissed]

The same fixture also verified navigation from Library to Item Detail and
from the root to Insights and Settings. No overlapping or unreadably clipped
text was observed in the captured viewports. Fixture item names and notes are
intentionally English; the current captures verify Japanese interface chrome.

![Library][release-library]
![Item Detail][release-detail]
![Insights][release-insights]
![Settings][release-settings]

Both app runs logged preview-container creation and startup readiness. No app
crash, fatal error, or SwiftData, ModelContainer, or CloudKit failure was
observed. Simulator logs did contain CoreTelephony XPC, PointerUI, duplicate
accessibility-class, and Files symbol-lookup diagnostics; the log stream was
not warning-free.

The Files remote accessibility hierarchy did not match its Cancel hit point.
The sheet was dismissed with a downward swipe, so the Cancel button itself
was not verified. No file was saved or imported, and no destructive action or
settings mutation was performed. Malformed-export alerts remain covered at
the library validation boundary and by the compiled alert adapter; no existing
safe launch fixture exercised that alert on screen. Real-device CloudKit,
StoreKit purchase resolution, and production advertising remain separate.

The verification runs and device session were stopped. The original Stally
scheme and My Mac destination were restored and confirmed.

[release-backup]: ui-preview-screenshots/release-2026-09-13/backup-center.png
[release-exporter]: ui-preview-screenshots/release-2026-09-13/backup-exporter.png
[release-dismissed]: ui-preview-screenshots/release-2026-09-13/backup-export-cancelled.png
[release-library]: ui-preview-screenshots/release-2026-09-13/library.png
[release-detail]: ui-preview-screenshots/release-2026-09-13/item-detail.png
[release-insights]: ui-preview-screenshots/release-2026-09-13/insights.png
[release-settings]: ui-preview-screenshots/release-2026-09-13/settings.png

## September 13 MHPlatform 1.13 Verification

This check uses MHPlatform 1.13.0, MHUI 1.18.0, and Google Mobile Ads SDK
13.9.0 on a dedicated iPhone 18 Pro Simulator running iOS 27.0. Each route
uses the existing `typical` in-memory fixture. It checks the app's correction
from a runtime-only bootstrap to MHPlatform's standard runtime adapters.

| Surface | Observed result | Remaining boundary |
| --- | --- | --- |
| Library | Small test ad loaded | Spacing after scrolling |
| Insights | Initial viewport | Medium ad loading and layout |
| Settings | Empty subscription card | Product resolution and transactions |

![Library with the loaded small test ad][platform-library]
![Insights initial viewport][platform-insights]
![Settings with the unresolved subscription card][platform-settings]

The small ad shows the test-mode title, Ad label, icon, and CTA. Its
description is ellipsized and its Japanese CTA wraps within the compact layout.
The initial capture shows the ad near the floating search bar; it does not
establish the full scrolling layout. No ad was clicked.

All three launches logged `model_container.preview_created` and
`startup.ready`. The scoped runtime review found no app crash, fatal
SwiftData or CloudKit error, or unsatisfiable layout-constraint diagnostic.
The logs were not warning-free: Simulator service and rendering diagnostics
were present, and StoreKit reported a missing auto-renewable subscription and
a subscription-status timeout. The empty Settings card remains an observed
release issue until the intended product environment is verified; a sample
StoreKit catalog was not substituted for it.

The Xcode-native build passed before the bootstrap correction. When the native
transport closed, the final corrected app was built with official `xcodebuild`
and installed with `simctl`. The existing shared Simulator was left to the
other active app. A new official bridge required Xcode agent authorization,
and computer interaction was unavailable while the Mac was locked. These
limits prevented scrolling, opening Licenses, and confirming restoration of
the original Stally / My Mac selection. The last confirmed native selection
was Stally / iPhone 18 Pro.

The dedicated Simulator was shut down after the captures. Fixtures remained
in memory. No persistent domain or cloud data was changed, and no purchase,
ad interaction, or manual settings change was performed.
Detailed build, console, and OSLog evidence is retained in the ignored
`.build/ci/mhplatform-1.13-adoption/` directory.

[platform-library]: ui-preview-screenshots/mhplatform-1.13/library.png
[platform-insights]: ui-preview-screenshots/mhplatform-1.13/insights.png
[platform-settings]: ui-preview-screenshots/mhplatform-1.13/settings.png

[mhui-1-18]: https://github.com/muhiro12/MHUI/releases/tag/1.18
