# Item Context Implementation

## Scope

The October 31, 2026 implementation follows the accepted
[product behavior](product-behavior-design.md) and
[prerelease replacement direction](rebuild-implementation-direction.md#october-31-prerelease-replacement-authority).
This is an implementation unit for Item context, not completion of the full
first-release feature set.

## Current Baseline

- `StallySchema` 1.0.0 owns Item, ItemMark, ItemPeriod, ItemPhoto, and Tag.
  Item includes one optional `representativeURL` string. Boolean favorites,
  date precision, identities, relationship ownership, and independent state
  retain their accepted meanings.
- Development V1/V2/V3 declarations and the empty migration plan are removed.
  The factory no longer searches old development locations or blocks startup
  because they exist. No development migration or rescue path is added.
- App Group, CloudKit identity, and explicit DEBUG local-store selection remain
  unchanged. Opening errors still surface normally; the app does not silently
  substitute an empty store or erase data. Incompatible test copies can be
  reinstalled under the owner's instruction.
- `schemaVersion` is now `1.0.0`; `formatVersion` 1 remains reserved for the
  unimplemented package codec. Earlier development fixtures and format examples
  are historical evidence, not supported import formats for this baseline.

## Item Save Behavior

`ItemOperations.draft(for:)` captures independent editing values.
`ItemOperations.save(_:context:)` validates and saves the submitted metadata,
Tag changes, and prepared photos as one operation. New Item creation requires
only a nonblank name. Neither creation nor editing adds Marks or periods.
The operation owns a separate write context so a failed compound save cannot
expose rolled-back relationship snapshots to the editor. The caller's context
must have no unrelated pending changes. Successful saves resolve the returned
Item into the caller's context.

Drafts retain the original values so unedited metadata, state, Tag assignments,
and photo captions are not reset by a stale editor. Explicit changes operate
on identities; equal Item or Tag names never merge records. New Tags are part
of the same save, so canceling the Item draft does not leave them behind.
Existing attachments retain identity when reordered or captioned. Explicit
photo removal deletes only that attachment; newly arriving unrelated photos
are not interpreted as removals.

An empty link clears it. A nonempty link must be an absolute website or app URL;
relative input and file/data/script URLs are rejected before mutation. Opening
uses SwiftUI's native URL action, with visible failure when the system declines.
It does not promise destination availability or installed app handling.

## Photo Behavior

The native Photos picker supplies ordered selections using its current encoding.
File transfer is bounded before pixel decoding and consumed while the provider
file is valid. Preparation runs off the main actor, checks cancellation between
images, and updates the draft only after the selected batch succeeds.

The library's ImageIO pipeline implements the selected
[photo policy](photo-storage-design.md): JPEG/HEIC/HEIF/PNG still images, 64-MiB
input and dimension guards, byte-identical retention within the 3,072-pixel and
8-MiB saved limits, and one transformation when required. Transformed images
retain supported descriptive metadata while normalizing geometry. A separate
512-pixel preview and bounded disposable decode cache support presentation.
Invalid images and oversized transformed results fail without saving an Item.

The editor supports multiple photos, captions, explicit ordering, and removal.
Details open the retained attachment rather than magnifying its small preview.
These controls are an initial implementation, not a frozen layout contract.

## Verification

On October 31, the library's 52 tests in 12 suites passed on iOS 27.2 Simulator,
and the Stally app built successfully. Repository SwiftLint/boundary checks,
English/Japanese catalog completeness, and whitespace checks passed.

New behavior tests cover disk reopening, atomic metadata/Tag/photo save failure,
unrelated edits, distinct identities on repeated creation, invalid URL retry,
photo removal/order, supported image formats, byte preservation, transformation,
orientation, and descriptive metadata retention. Read-only stores and malformed
images deliberately produce native diagnostics in negative tests.

Manual Simulator interaction in English and Japanese verified registration,
validation feedback and correction, canceling unsaved Item/Tag creation, photo
selection/captions/reordering/removal/detail viewing, relaunch persistence, and
retention of existing favorites, Marks, and periods. The session also verified
the corrected 44-point photo and Tag action targets. Cancellation during photo
preparation and actual external-URL handoff were not manually exercised.

## Remaining Work

Package export/import, redesigned App Intent coverage, period readings, and
organization capabilities are now implemented in the subsequent
[shared Operations work](remaining-capabilities-implementation.md). In particular,
export/import must carry the representative link and saved image bytes without
recompression when implemented. No CloudKit production schema is deployed by
this change.

Simulator unit tests and targeted app interaction qualify the changed paths;
physical-device photo providers, HDR source coverage, resource measurements,
and multi-device CloudKit convergence remain release qualification work.
