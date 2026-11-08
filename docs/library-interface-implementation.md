# Library Interface Implementation

## Direction

The app adapts the [accepted product behavior](product-behavior-design.md)
through shared Operations. Screen composition, labels and controls can evolve
without changing the stored records or published App Intent contracts.

One `NavigationSplitView` owns collection selection, the Item list and detail.
Compact layouts collapse the same hierarchy into native navigation.

## Implemented Surface

- Collections: Library, Favorites, Mark Recording, Archive and individual Tags.
  Library, Favorites, Mark Recording and Tags initially exclude archived Items;
  Archive initially includes archived Items. The list's Include control can
  select Library, Archive or All within the chosen collection. Sidebar badges
  describe each collection's initial scope, independently of list filters.
- Search and ordering: names, notes and Tag names; newest, oldest or name order.
  Changing collection resets search and archive scope. Returning from detail
  preserves filters. Creating or opening an Item resets filters to reveal it.
  Empty search results offer an explicit filter reset.
- Item editing: name, note, representative link, Tags and ordered photos with
  captions. Cancel discards the draft; save calls the compound Item operation.
- Detail: independent favorite/archive/recording states, notes, link and photos,
  current and cumulative period readings with their calculation basis, Mark
  history and period history. Record actions precede Mark history so they do
  not move farther away as history grows. Pausing prevents additions while
  keeping existing Marks editable.
- Periods: unknown/year/month/day boundaries, ongoing/ended state, correction,
  ending, genuine resumption and confirmed deletion.
- Tags: creation, rename, assignment, deletion and explicit reviewed consolidation.
  Similar names never merge identities automatically.
- Transfer: a native package with optional photos, a separate media-free JSON
  export, file selection and reviewed import. The photo toggle belongs only
  to package export. A new transfer clears previous completion feedback.
- Settings: optional paid iCloud sync, MHPlatform purchase/restore UI, support,
  privacy, terms and licenses. Sync changes apply on the next app launch.
- Diagnostics: the visible Debug entry opens inspection; development-store and
  sample controls remain DEBUG-only.

Selection uses store-local identity for live rows; external links use UUID and
reject ambiguity. No saved navigation preference or public route is added.
Draft dates use Gregorian civil components without inventing missing parts.

## MHUI Presentation Ownership

MHUI owns shared typography, semantic colors, row insets, section hierarchy and
spacing. Stally owns record meaning, navigation, drafts and Operations.
Native sidebar chrome, content List/Form chrome and `MHContainerContent` keep
platform containers responsible for navigation and interaction. `LibraryLayout`
contains app-specific column allocation and text-preview limits.

## Verification Boundary

The [Operations record](remaining-capabilities-implementation.md) retains prior
behavior and Simulator evidence. Later builds do not repeat that runtime proof.
The November 8 flow refinements require targeted navigation, empty-state and
transfer presentation review when deferred UI verification resumes. Physical
CloudKit, provider and distribution checks remain in
[release readiness](release-readiness.md).

### November 8 implementation checks

The settings Preview initially failed because its fixture was missing a library
import; that import is now explicit. The next Preview exposed a Google Mobile
Ads initialization exception after removing the sample app ID. Stally now links
MHPlatform's runtime/defaults/licenses products without its ads bundle, rather
than keeping an unused ad ID. Japanese and English Settings Previews then rendered
on iPhone 18 Pro / iOS 27.2 with visible sync guidance and support/legal/license
entries. This covers those first viewports, not purchase, restore or sync.

The Library preview remains a development-data surface. Navigation, record
editing, transfer dialogs, Dark Mode and Dynamic Type interaction remain part of
the deferred UI pass. The changed entrypoints retain their existing Operations.
