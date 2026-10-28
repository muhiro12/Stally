# Library Interface Implementation

## Direction

The October 28, 2026 interface work follows the owner's request to build a usable
interface for the new record design before completing each subsystem. The
accepted storage and identity contracts remain the foundation. Navigation,
composition, and controls can change based on experience with the running app;
the earlier proposal to complete photo ingestion first is not the current
sequencing decision.

One `NavigationSplitView` owns collection selection, the Item list, and the
selected Item. This uses the familiar sidebar/list/detail structure of native
Apple apps. Compact layouts collapse the same hierarchy into navigation rather
than introducing a separate tab-based interface.

## Implemented Surface

- Sidebar: Library, Favorites, Mark Recording, Archive, and individual Tags.
  Library excludes archived Items; Favorites, Mark Recording, and Tag views
  include matching archived Items. Archive never changes those independent
  facts. Counts describe the respective collections, not mutually exclusive
  categories.
- Item list: search names, notes, and assigned tag names; sort by registration
  time or name; select a record; create an Item and open its detail.
- Detail: notes, state, Tags, individual Marks, and period history. Edit the
  Item, favorite/archive it, pause recording, or confirm deletion. All durable
  writes still pass through library Operations and remote-update policy.
- Tags: create, rename, delete with confirmation, and choose assignments. Similar
  names receive feedback; identical names remain distinct and display their UUID
  when necessary to identify the choice. Explicit consolidation remains pending.
- Mark editor: native date selection and an optional time control. Each Save
  adds a distinct occurrence; editing preserves the chosen record's identity.
- Period editor: unknown/year/month/day precision, explicit ongoing/ended state,
  dedicated end and resume flows, correction, and confirmed deletion. Resumption
  creates a new period. No duration or elapsed-time interpretation is introduced.
- English/Japanese interface strings, empty collections, empty search results,
  empty record sections, and visible operation errors.

Selection uses store-local model identity for live UI rows, including records
whose application UUIDs may conflict. External Item links still resolve by UUID
and reject ambiguity. No saved navigation key or new public route is introduced.
Draft date controls use a fixed Gregorian conversion calendar for civil values;
this does not turn stored dates into UTC events. Missing date parts stay missing
unless the person explicitly chooses finer precision. Invalid incoming date text
is shown for correction instead of silently replaced by today's date.

## Remaining Scope

This is a working interface for implemented core capabilities, not a claim of
first-release completeness. Photo ingestion/presentation, Tag consolidation,
`.stally` import/export, the full new Intent surface, Universal Links, settings,
and selected monetization surfaces remain separate work. Period readings remain
unaccepted. No inactive controls imply these features are already available.

The schema, shared store, CloudKit configuration, old-data guard, and existing
saved records were not changed by this interface work. UI validation does not
qualify physical-device signing, real CloudKit convergence, or production schema
compatibility.

## MHUI Presentation Ownership

The owner's follow-up requires visible MHUI adoption, beyond a root theme.
Stally uses the pinned MHUI 2.4.0
[adoption guide](https://github.com/muhiro12/MHUI/blob/2.4.0/Designs/Guides/ADOPTION_GUIDE.md)
as the presentation baseline. The package owns shared typography, semantic
colors, row insets, section hierarchy, and spacing. Stally owns its record
meaning, navigation, collection choices, editor drafts, and Operations.

- Root: the standard theme and one-time iOS native appearance configuration.
- Navigation source list: native sidebar presentation through
  `mhListChrome(.native)`; system column backgrounds and dividers remain native.
- Item list, detail, and Tag lists: `MHContainerContent` inside native `List`,
  with `mhListChrome(.content)` and the default native content-list background.
  Detail retains list behavior for its open-ended Mark and Period history.
- Item, Mark, Period, and Tag editors: `MHContainerContent` inside native `Form`
  with `mhFormChrome(.content)`. Fields, focus, sheets, and controls remain native.
- Content: semantic row typography, section headers/footers, neutral status
  badges, and environment-derived theme spacing. Shared row insets are not
  supplemented with duplicate app padding.

The remaining `LibraryLayout` values describe app-specific column allocation
and text-preview limits, not a second spacing or color system. This adoption
keeps the single split-view information architecture and does not change stored
records, external identifiers, or the package itself.

## Verification

The app builds through Xcode MCP on Xcode 27.2 for iOS 27.2. Strict SwiftLint
and repository boundary checks pass. The English/Japanese catalog audit has
no incomplete entries. A standalone native execution of the actual date-draft
source passed 19 scenarios in each of three timezone configurations: Tokyo,
Los Angeles, and Kiritimati. Scenarios include precision-preserving round trips,
leap day, civil times within DST gaps/overlaps, explicit precision changes,
optional-time removal/restoration, preserving malformed saved text, and showing
today as the initial day candidate when explicitly increasing unknown precision.
This is supplemental app-helper evidence, not an additional library test suite.

The iPhone 17 Simulator pass used newly created synthetic records and left the
existing foundation record unchanged. It verified Item creation and opening,
Tag creation/assignment, favorite and archive independence, two same-day Marks
with and without time, a year-precision start, month-precision ending, and
resumption with unknown start while retaining the ended period. A missing locale
on the draft calendar caused month labels such as `M10`; the integration pass
identified it and the implementation now supplies the current locale. Explicit
menus were also moved out of the secondary-action overflow to remove a redundant
menu level.

The refreshed iPhone run confirmed localized month names, single-level menus,
matching/no-result search and clearing the query, the name-sort menu choice,
Tag filtering, and retained records after reinstall/relaunch. Selection from
Favorites continued to show an archived favorite with its archive badge, as
intended. The existing foundation record was not edited. The last iPhone pass
preceded the final plain-button text styling, which is covered on iPad below.
Actual multi-row sort ordering, deletion, and selection immediately after
archiving from Library were not exercised in this pass.

The iPad Pro 13-inch Simulator pass confirmed the Japanese three-column empty
and populated layouts without overlap. Two synthetic Items, a Mark, and an
ongoing period were created. Portrait/landscape changes retained selection and
an unsaved Item-note draft; Cancel discarded that draft. The pass caught the
plain-style record buttons excluding blank label space from hit testing. Explicit
content shapes now make both Mark and Period labels editable from their centers,
confirmed after rebuilding. The same pass confirmed that selecting day precision
from unknown proposes today and that the saved period reopens with that date.
The unavailable Tag-management symbol was replaced with the standard Tag symbol
and visually checked.

An English relaunch confirmed the same three-column surface and retained records.
The accessibility hierarchy exposed an English singular-count issue; the final
catalog now supplies singular/plural variants for Item and Mark counts. Foundation
formatting against the built English resources confirmed counts zero, one, and
two for both nouns. This does not substitute for a full VoiceOver usability pass.
The final app build had no warnings or errors. Verification runs and interaction
sessions were stopped, and Xcode's original `Stally` / `My Mac` selection was
restored.

The app's assigned Simulators retain their data; validation does not modify
user-supplied photos, existing cloud records, or production schema settings.

### MHUI Follow-up

The MHUI adoption passed the app build, strict repository rules, and the
English/Japanese catalog audit. On iPad, the light appearance pass covered
selection, detail, Item/Mark/Period editors and cancellation, Tag assignment
and management presentation. Dark appearance covered detail and the Item form;
the original light appearance was restored afterward. iPhone light appearance
covered compact navigation, detail, and the Item editor with cancellation.
The iPhone pass exposed an icon-only favorite badge; an explicit title-and-icon
label style now preserves its meaning, confirmed in a rebuilt app. The final
build completed without warnings or errors, and the original Xcode destination
was restored.
Existing records were retained and no save or deletion was needed for this pass.

These checks qualify presentation and adapter interaction. They do not add
CloudKit, full VoiceOver, Dynamic Type, or iPhone dark-appearance evidence.
