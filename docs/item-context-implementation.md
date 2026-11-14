# Item Context Implementation

## Scope

Shared Item Operations implement the [accepted product behavior](product-behavior-design.md).
The [app data flow](swiftdata-app-data-flow.md) defines live query ownership,
selected Item propagation, and the boundary between models and editor drafts.

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
- The portable format uses the supported pair `(1, "1.0.0")`.

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

Mark editors retain their original date/minute, and the Tag picker retains its
original assignment UUIDs for the editing session. Before either saves, Operations
uses a fresh context to check those facts against the saved record. Changed
facts reject the entire submission before mutation, including an unchanged form
submitted after another writer's save. Unrelated writes do not invalidate the
edit. The picker resolves every selected Tag UUID instead of silently dropping
selections that disappeared from its live query. Missing or ambiguous selected
identities also reject the save. The editor remains open with its draft and the
existing review-again error; dismiss and reopen it to review current facts.
Tag selections save through the fresh context so relationship updates cannot
write back unrelated stale Item fields; live reads follow native save merging.
These guards do not change the explicit replacement semantics of immediate
Operations or App Intent commands, or provide a cross-device transaction.

Period editors retain their original boundaries and continuation state for the
editing session. If any of those facts changed before saving, the shared
correction operation resolves the UUID in a fresh write context and compares
the saved facts, rather than trusting the editor's retained model. Missing or
ambiguous identities are rejected, and sibling-period validation uses that same
fresh context. A stale submission is refused before mutation. After validation,
the operation saves in that context and re-fetches the caller's model so observed
values update without waiting for a cross-context merge. The editor
keeps its input and displays the existing review-again error; dismiss and reopen
it to review current facts. Unrelated Item or Mark writes do not invalidate the
period edit. This is a local stale-edit guard, not a cross-device transaction.

Ending a period uses the same saved-fact check before applying its end date.
An intervening correction, ending, deletion, or ambiguous UUID rejects the
operation without overwriting history. Reopening the record permits a new
ending against its current start; unrelated writes do not invalidate it.

Adding or resuming also validates the saved Item and its period history in a
fresh context. Resumption first resolves the selected period uniquely and
requires that it is still ended. Missing or ambiguous identities and newly
saved sibling conflicts reject the operation before insertion. Successful
insertion uses that fresh context, while the previous period retains its identity
and ending. These checks do not serialize CloudKit delivery or writes from other
processes with the local save.

Record additions, corrections, deletions, Item state changes, and Tag assignments
or deletions save through an owned fresh context. Saving a retained model can
write back unrelated scalar values when a relationship changes; reading fresh
facts only for validation is insufficient. Mark additions also check the saved
recording choice and resolve the owner uniquely before insertion. Corrections
preserve registration metadata accepted by an intervening import. Item deletion
cascades through the saved graph without restoring stale shared Tag names.
After successful writes, bounded reads refresh affected caller models for
immediate observed values. Failed saves leave the caller's graph and the saved
store unchanged. These are implementation safeguards, not a schema change or a
distributed transaction guarantee.

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
[shared Operations work](remaining-capabilities-implementation.md).

Simulator unit tests and targeted app interaction qualify the changed paths;
physical-device photo providers, HDR source coverage, resource measurements,
and multi-device CloudKit convergence remain release qualification work.
