# Initial release repository review

## Scope and result

The November 14, 2026 review covered the full local `develop` candidate for
PR #35, starting at `214cf30a1badca4e1104f1324161df3b9c9cd9fb`.
`main` at `709e2935ac021d9534998ce6cde43c7e990e3290` is a provisional baseline,
not a previously released version. The review followed the
[first-release contracts](first-release-contract-summary.md) and checked their
implementation, including paths analogous to the recent Mark and Tag fixes.

The repository blockers found below are fixed. No change to the accepted model
schema, file-format pair, public identifiers, date meaning, or ownership policy
was needed. This is repository and Simulator evidence, not distribution approval
or proof of real-device synchronization. External services were not changed.

The verified implementation ends at `2a42419`. Corrections were committed on
`develop` as `5533754` (mutation isolation), `89c4598` (privacy declarations),
`6e49cf3` (Intent review preparation) and `2a42419` (delayed edit validation).
The review record follows those commits. No push or merge into `main` was made.

## Findings and corrections

All findings were present at the starting candidate. They are not regressions
introduced by `214cf30`; there is no shipped version against which to claim a
release regression.

| Priority | Trigger and impact | Correction |
| --- | --- | --- |
| Before publication: saved-data correctness | Another writer saves while a retained Item, Mark, Period, or Tag is still displayed. A later state, relationship, or record mutation can restore unedited scalar fields, including Item metadata and registration timestamps; Mark addition can ignore a saved recording pause. | Resolve unique saved identities and mutate an owned fresh context. Re-fetch affected observed models after saving. Apply this across additions, corrections, deletions, Item states and Tag assignments. |
| Before publication: delayed editing | An open Tag name editor submits its old name after another rename, even without a user change. | Retain the original name and reject a changed saved name before mutation. Immediate Rename Tag commands retain explicit replacement semantics. |
| Before publication: photo order | A stale Item editor adds, removes or reorders photos after another writer reordered the original attachments. Position rewriting can restore the old order. | Recheck the original attachments' relative order before any list change. Reject the entire stale save. Caption-only edits retain the newer order; unrelated arriving photos are preserved. |
| Before publication: bounded deletion | Duplicate Item UUIDs appear after tag consolidation was reviewed. Set comparison hides duplicate membership and permits an unreviewed reassignment/source deletion. | Recheck membership cardinality and unique resolution of affected Item identities before mutation, including a duplicate outside those relationships. |
| Before publication: distribution declaration | Transfer code uses file attributes and available disk space, and preferences use the App Group; the app manifest declared only app-local UserDefaults. | Declare the matching required reasons and verify the built app contains the source manifest. See the [privacy declaration mapping](release-readiness.md#repository-privacy-declarations). |
| Implementation follow-up, completed | Review Import's foreground Intent performed full snapshot preparation synchronously on the main actor, unlike the ordinary transfer UI. Duration depends on library size; a runtime hang was not demonstrated. | Use the existing asynchronous preparation worker, then recheck cancellation, account session and pending import review before presentation. No automatic import or new public interface. |

The write-context fix does not serialize CloudKit delivery or writes from other
processes with a local transaction. Stale-editor checks protect a reviewed local
submission; they do not promise distributed conflict resolution.

## Contract and implementation coverage

| Boundary | Evidence and assessment |
| --- | --- |
| Persistence and identity | Compared the five SwiftData models, defaults, optional relationships, cascade/nullify rules, UUID lookup and consolidated schema with the accepted model design. Checked shared-store location, same-store sync choice and visible open failure without fallback. |
| Records and editing | Reviewed all Item/Mark/Period/Tag mutations and Item drafts. Tested multiple same-day Marks, pause/archive independence, retained dates and registration metadata, end/resume, stale submissions, rollback, deletion scope and reopen. |
| Period meaning | Checked unknown/year/month/day civil dates, conservative overlap checks, gradual conflict repair and qualified readings. Unknown or invalid histories do not become invented numeric totals. No redesign was needed. |
| Transfer | Checked the exact `(1, "1.0.0")` pair, required versus null fields, UUID/kind/owner checks, no deletion from absence, explicit conflict selection, omitted media preservation, all-or-nothing save and stale review. Inspected staged file validation, resource checks and asynchronous preparation. |
| Photos and input assistance | Checked owned image data, byte preservation versus transformation, native supported formats, metadata and preview handling, atomic draft application, source-grounded text suggestions, cancellation and explicit review/save. Actual model quality remains hardware qualification. |
| Published interfaces | Compared all 40 action identifiers and parameter names/types/optionality, source defaults, results, five entities and two enums with the App Intents inventory. Checked required authentication, five delete confirmations plus consolidation, guarded writes, query identity resolution and shared ordering. |
| Platform wiring | Checked fixed bundle/App Group/CloudKit/UTI/preferences/product identifiers, package and JSON adapters, route parsing and app navigation, saved sync choice versus entitlement, update guard, no-ads runtime composition and source entitlements. Registry/signature truth is a separate qualification. |
| Localization and documentation | Audited all five catalogs for English/Japanese coverage and stale keys. Proper names and placeholder-only entries explain the source-copy notices. Static unused candidates were not deleted. Checked local documentation file links. |

## Verification

- Xcode selected by `xcode-select`: Xcode 27.2, build 27B52.
- Full library contract: **160 tests in 39 suites passed** on the dedicated
  iPhone 18 Pro / iOS 27.2 Simulator after the final implementation changes.
  New regression tests first failed on the affected implementations. The suite
  covers same-container and separate-container saves, disk reopening, related
  mutation paths and the pre-existing stale Mark/Tag/Period guards.
- New coverage is in `RecordAdditionTests`, `RecordMutationIsolationTests`,
  `TagEditingTests`, `PhotoEditingTests` and `OrganizationTests`.
- Formatter, repository SwiftLint/boundary checks and `git diff --check` passed.
- Native Stally Simulator build passed with no reported build diagnostics.
  Metadata extraction produced 40 authenticated discoverable actions, five
  entities and two enums. The built privacy manifest matches the source.
- Japanese Simulator UI: Today and Now add two Marks; Undo removes only the
  acknowledged addition; date correction updates immediately; Period resume,
  ending and scoped deletion work; pause disables addition while retaining
  history; favorite, archive and Tag assignment update immediately. Review-created
  records were removed without deleting existing records.
- Targeted Tag name UI: create, rename, reopen and verify the saved name, then
  delete only the review-created Tag. Existing Tags and their Item counts remain
  unchanged. The run explicitly selected the isolated DEBUG development store.
- Both interaction sessions and verification runs were ended. Xcode was restored
  to its original `Stally` scheme and `My Mac` destination.

Expected negative tests emit diagnostics for read-only saves, a corrupt
development store and invalid images. Passing those tests is not a claim of an
empty runtime log. The interactive mutation pass showed no persistence failure
or crash; Simulator/framework warnings were not associated with failed actions.

## Remaining work outside this repository review

No known repository blocker from this review remains. Before distribution,
complete the separate [release qualification](release-readiness.md): signed
archive and toolchain acceptance, production CloudKit/account transitions,
purchase/restore/lapse behavior, installed Universal Links, saved Shortcuts and
locked-device execution, representative device file/photo providers, eligible
Apple Intelligence hardware, and Store metadata/disclosures. This review did
not repeat a full language, device-size, accessibility or release-flow matrix.

Optional future improvements are narrower import-review invalidation after
unrelated saved changes, more selective entity-query fetches for large libraries,
and clearer recovery navigation after a stale-editor refusal. The current
whole-library import check and explicit dismiss/reopen behavior preserve data;
these improvements do not require changing the first-release contracts.
