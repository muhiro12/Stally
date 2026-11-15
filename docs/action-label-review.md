# Shared Action Labels

## Scope and ownership

This implements the focused review in [Issue #33](https://github.com/muhiro12/Stally/issues/33).
`StallyActionLabel` retains each action's localized title and SF Symbol in a
native SwiftUI `Label`. `StallyActionButton` wraps a native `Button` and forwards
the caller's action and role. Neither component imposes a label style, tint,
layout, enabled state, or confirmation policy.

The existing English and Japanese titles remain unchanged. In particular,
"Record Now with Time" distinguishes timestamp precision, and "Resume with a
new period" distinguishes resumption from reopening an ended period. Shortening
those titles would lose useful meaning. App Intent names are outside this review.

## Placement inventory

| Actions | Placements | Decision |
| --- | --- | --- |
| Add Item | List toolbar and list/detail empty states | Shared label; native adaptation |
| Edit Item | Detail toolbar | Shared label; retain pencil symbol |
| Record Today, Record Now, undo | Detail Mark section | Shared labels; retain distinct checkmark, clock, and undo symbols |
| Add Mark, Add Period | Detail history sections | Shared labels with distinct object/addition symbols |
| End Period, resume | Period rows | Add native completion/resumption symbols |
| Favorite, archive, return to Library | Detail overflow menu | Share state-specific labels; retain existing symbols and callbacks |
| Delete Item, record, Tag | Menus, editor sections, confirmation dialogs | Shared labels; retain destructive roles and confirmation boundaries |
| Add/choose/remove Tag | Tag manager, picker, Item draft | Shared labels; preserve assignment versus deletion meaning |
| Consolidate Tags | Tag manager | Add native merge symbol; keep reviewed consolidation |
| Add/reorder/remove photos | Item draft and native PhotosPicker | Shared labels; preserve ordering, draft ownership, and loading state |
| Share Item Link | Native ShareLink | Shared label; retain native share behavior |
| Export library/JSON, choose file, import selected | Transfer form and review toolbar | Shared labels; retain existing distinct symbols and wording |
| Save, Cancel, Done | Item/record/Tag/import editors, settings, photo viewer, transfer | Shared labels; keep placement and disabled conditions at each caller |

Single-use navigation, filter reset, review/retry prompts, alert acknowledgements,
and development diagnostics keep their current native controls. They do not
need a new shared action definition in this bounded change. Data rows, state
badges, and collection labels are content rather than action definitions.

### Placement-specific presentation

The Item draft's existing inline Tag controls and photo ordering/removal row
retain `.iconOnly` locally: the Tag field/name and photo already identify the
target, and the adjacent controls need compact, separate hit areas. Their full
localized labels and minimum control sizes remain intact. This does not change
the default presentation of the shared components.

Favorite/archive status badges retain their explicit title-and-icon treatment;
they describe state and are not buttons. Toolbars, menus, and other action rows
inherit the container's native presentation.

## Symbol choices and availability

The changed symbols were compared using actual native system glyphs. No glyph
overlays, custom badges, or composites are introduced.

| Action | Previous | Selected | First iOS / macOS / visionOS |
| --- | --- | --- | --- |
| Add Item | `plus` | `rectangle.stack.badge.plus` | 13 / 10.15 / 1 |
| Add Mark | `plus` | `checkmark.circle.badge.plus` | 26 / 26 / 26 |
| Add Period | `plus` | `calendar.badge.plus` | 13 / 10.15 / 1 |
| End Period | Text only | `calendar.badge.checkmark` | 17 / 14 / 1 |
| Resume with a new period | Text only | `arrow.clockwise` | 13 / 10.15 / 1 |
| Consolidate Tags | Text only | `arrow.triangle.merge` | 14 / 11 / 1 |
| Delete Tag / Delete Record | Text only | `trash` | 13 / 10.15 / 1 |

Item creation uses the native stacked-card addition symbol, consistent with the
stacked-card Item imagery. Mark creation extends its checkmark-circle identity;
Period creation extends its calendar identity. These remain distinct beside each
other and from the quick Record Today/Record Now actions.

The native catalog has no `tag.badge.plus`, so Add Tag retains its established
`plus` fallback. Only this creation family uses the generic addition icon.
Archive, return to Library, undo, and deletion retain `archivebox`,
`tray.and.arrow.up`, `arrow.uturn.backward`, and `trash`, respectively. The
favorite slash continues to mean removing favorite status, never deletion.

Availability was checked against the installed SF Symbols application's
`name_availability.plist` and its release mapping on November 12, 2026. Every
symbol in the shared label definition predates or matches the app's 27.2
deployment targets, so no availability branch or older-system fallback is
needed. Recheck this contract if deployment targets are lowered or symbols change.

The native presentation and availability constraints follow Apple's
[Label documentation](https://developer.apple.com/documentation/swiftui/label)
and [SF Symbols guidance](https://developer.apple.com/design/human-interface-guidelines/sf-symbols).

## Verification boundary

The November 12 implementation retains all action callbacks, draft mutations,
roles, confirmation prompts, loading/disabled conditions, and keyboard shortcuts.
No shared-library, persistence, or App Intent behavior changes. The focused
verification therefore uses the app build and native UI evidence rather than
adding tests that repeat a title-to-symbol mapping.

- Swift formatting, strict repository SwiftLint, architecture checks, and
  whitespace checks passed.
- The catalog audit found no incomplete English/Japanese keys. All 32 shared
  labels reuse existing translated Japanese entries; no catalog edits were needed.
- Native English iPhone Simulator captures confirmed the Item creation toolbar
  symbol with its full accessibility label, editor presentation/cancellation,
  disabled Save for an empty Item, and draft Tag/photo action labels. The empty
  Tag field continued to disable its inline Add Tag action.
- Japanese detail captures confirmed distinct Mark/Period creation and Period
  completion symbols alongside the existing quick recording actions. The
  overflow menu retained localized action names, and Delete Item still opened
  native confirmation. No clipping or overlap was observed in these captures.
- Japanese Tag management and Transfer captures confirmed their action labels
  and native symbols. Delete confirmation was dismissed without deleting data;
  no save, import, export, or destructive operation was executed.
- The final app build on iPhone 18 Pro / iOS 27.2 succeeded with zero build
  warnings or errors. The verification run/session ended, and Xcode's original
  `Stally / My Mac` selection was restored.

Runtime logs contained Simulator accessibility-class/traversal diagnostics,
UIKit animation assertions, and an image-provider timeout. No corresponding
persistent visual failure or crash was observed; this is not a claim of clean
runtime logs. Existing DEBUG local data was preserved.

Actual VoiceOver speech, Dynamic Type, iPad, photo reordering with attachments,
and the dynamic undo/return-to-Library/resumption states were not exercised in
this pass. Their source labels and callbacks were reviewed, which does not
replace runtime verification of those states.
