# First-Release Contract Summary

These are the contracts for developing Stally 1.0. Use the
[implementation record](remaining-capabilities-implementation.md) for the
current Operations and [release readiness](release-readiness.md) for outstanding
qualification. Changes to identifiers, stored facts, file semantics or destructive
effects require a compatibility decision. Screen layout and internal factoring
can evolve during development.

## Accepted Persistence and Domain Contracts

| Area | Selected contract | Detailed record |
| --- | --- | --- |
| Model set | `Item`, `ItemMark`, `ItemPeriod`, `ItemPhoto`, `Tag`; use the consolidated property names, types, relationships, and defaults | [Swift schema](model-schema-design.md) |
| Identity | Application-owned UUIDs survive correction and identity-preserving import; no identification by name, date, or SwiftData store identity | [Core meaning](core-record-design.md), [import](import-identity-design.md) |
| Item | User chooses what one Item represents, including a particular object or a continuing relationship; archive, favorite, and recording availability are independent | [Core meaning](core-record-design.md) |
| Mark | One record represents one occurrence; multiple occurrences on the same day are valid. Preserve date and optional minute knowledge in `localDateTime` | [Temporal comparison](mark-temporal-schema-comparison.md) |
| Period | Multiple periods belong to one Item; preserve unknown/year/month/day boundaries. Ending updates a period; genuine resumption creates another without overwriting prior periods | [Period lifecycle](period-schema-validation.md) |
| Registration metadata | `createdAt` on Item, Mark, Period, and photo; not a replacement for occurrence, period boundary, shooting time, or edit ordering | [Swift schema](model-schema-design.md) |
| Ownership/deletion | Item owns Marks, periods, and photos with cascade deletion; Tags are shared and deletion removes assignments without deleting the other records | [Relationships](model-schema-design.md#relationships-and-naming) |
| Tag identity | Different UUIDs remain separate even with identical or similar names; preserve confirmed spelling, offer suggestions, and never merge by comparison alone | [Tag design](tag-design.md) |
| Tag consolidation | User selects source/destination Tags; reassign reviewed relationships and delete sources in one local save, without permanent aliases or a promise to transfer unseen remote assignments | [Tag consolidation](tag-design.md#explicit-consolidation-recommended-bounded-operation) |

Mark values use Gregorian `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm`. Period boundaries
use nil, `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`. These denote civil-date knowledge,
not UTC instants. Unknown components remain unknown. `isOngoing` distinguishes
an ongoing period from an ended period whose end date is unknown. Operations
apply the selected local validity rules; concurrent incoming conflicts are not
silently rewritten to fit them.

A new Item receives no implicit Mark or Period. Archive and recording pause
preserve history and do not end a period. Recording can resume with prior Marks
intact. Counts, durations, calendar intensity, and current relationship status
are derived rather than separately stored assertions.

The exact Swift schema remains in one linked document instead of copying a
second implementation-shaped declaration into this summary.

### Text values

Required Item/Tag names and Mark dates cannot be empty when saved. Optional
note, caption, representative URL and period boundaries use nil for absence;
empty input is normalized to nil before persistence. No stored Stally field
assigns separate meaning to empty text. Nonempty free text retains whitespace
and newlines; required names and structured URL/date input keep their validation.

Forms may hold empty Strings while editing. Partial updates distinguish an
omitted field (keep) from supplied empty input or an explicit clear (remove).
Export writes explicit null for absent optional fields; import normalizes empty
strings before review and still rejects missing required keys. This revises the
unreleased schema-1 baseline, not a supported historical schema. No prerelease
store migration or production CloudKit compatibility is claimed by this change.

### Item context

The owner subsequently accepted one optional, user-chosen representative URL
per Item, providing direct access to its selected external destination. It is
not the Item's own Stally deep link and is not inferred from note contents.
The URL must be retained across storage, sync, and portable transfer. Older
Items may have no link; an older import's absent field must not clear one.
Favorites remain Bool, with no graded rating selected. Other unstructured
context remains in notes until a concrete feature justifies dedicated fields.
See [the accepted behavior](product-behavior-design.md#accepted-context-and-favorite-decisions).
The current `StallySchema` stores this optional URL. Both file representations preserve it.

## Accepted Photo Contract

The [photo design](photo-storage-design.md) is selected. Stally owns its saved
attachment independently of the source library/provider. It preserves useful
visual records without promising to archive every original camera resource.

- Keep one authoritative `imageData` payload in SwiftData external storage,
  with caption, explicit order, and an optional persisted `thumbnailData`.
  Thumbnail/cache data is derived and can be rebuilt.
- Preserve supported, valid delivered bytes already within saved limits.
  Transform only over-limit inputs; do not uniformly recompress qualifying files.
- The selected 1.0 saved limits are a 3,072-pixel longest edge and 8 MiB, with
  ImageIO quality 0.90 when lossy transformation is needed. Retain supported
  delivered descriptive metadata; normalize geometry only as needed by a
  pixel transformation. The source document specifies formats and input guards.
- Use a separate preview, initially 512 pixels with JPEG quality 0.70 for opaque
  images and PNG for transparency. This does not replace the attachment.
- Export the saved attachment. Omission or explicit output metadata filtering
  must not rewrite the saved source. User-supplied validation photos stay out
  of Git history and are not fixtures to copy into implementation work.

The numerical budgets and cache hints are selected engineering settings, not
immutable platform IDs or proof of a universal optimum. Future tuning must not
retroactively delete/rewrite existing photos or misrepresent lost original data.

## Accepted Export and Import Contract

Export primarily supports external use; import supplements it for timely device
transfer. The [data portability policy](data-portability-policy.md) defines
support boundaries, user explanations, and the separate DB maintenance stance.
There is no per-file expiry or promise to retain every historical reader forever.

Use one `.stally` document package, identified by
`com.muhiro12.Stally.data`, with JSON records and optional separate image files.
Records-only and records-with-images use that same physical container. Auxiliary
JSON sharing serves external tools without making `.stally` sometimes a plain
JSON file. See the [file specification](export-file-format-design.md).

Ordinary import preserves record identity and reviews additions/differences.
Same identity and same contents do not create another occurrence; different
identities do not collapse because they look alike. Conflicting content is not
automatically considered newer from creation or export timestamps. Retain
current facts unless a change is explicitly chosen. File omission does not
mean local deletion, and omitted images do not erase stored attachments.

No whole-library replacement or Import as Copy is selected for 1.0. Restoration
into an empty collection uses ordinary import. Absent historical fields and
explicit clearing retain their distinct meanings. For optional text, supplied
empty strings and null both mean absence; neither is an omitted field.
Invalid/unsupported files must not become partial success or silent data loss. The
[import design](import-identity-design.md) records detailed reconciliation and
review recommendations that implementation must qualify.

The export's `schemaVersion` aligns with the actual SwiftData schema version;
`formatVersion` versions its container/envelope/encoding separately. App release
numbers are not decoder selectors. Store migration and historical import share
preservation semantics, without requiring the same execution path or code.
Support the declared published pairs under the data portability policy. The
first pair is `(1, "1.0.0")`. Each package contains `manifest.json`
and, when it carries image bytes, `assets/<lowercase-photo-uuid>.<extension>`.

## Accepted Platform and Interface Direction

Readable Item content can be copied/shared separately from Item links and
portable files. It includes name, note, and representative URL without version
metadata or an import grammar. Manual creation, optional on-device text input
assistance, and reviewed file import are the first-release input paths. The
dedicated Markdown template workflow is retired, including prompt copying,
blank templates, and template parsing/review.
Foundation Models assistance prepares a reviewable name, note, and link from one
description, fills only empty draft fields, and uses the ordinary explicit save.
It creates no Marks or periods. Photo recognition and OCR remain separate future
work. See the [input-assistance boundary](item-input-assistance.md) and the
[selected input and sharing behavior](product-behavior-design.md#copy-and-share-one-item).

The [native transfer journeys](product-behavior-design.md#native-transfer-journeys)
add Item-link and readable-text dragging, dated Time Together reports, and
single-file drops into the existing import review. URL, String, and the supported
portable files remain independent representations; no new Item format is added.

- **Native synchronization:** optional iCloud sync is a subscription benefit
  from the first release under the November 8 policy. Follow
  native account/mirroring behavior and proportional recovery. No custom shadow
  library, account-independent retention guarantee, or distributed exactly-once
  engine is selected. Do not erase records or silently switch stores when
  entitlement state changes. Preserve the person's sync choice through a
  subscription lapse; apply it together with subscription access at next launch.
  See [sync lifecycle](sync-lifecycle-design.md).
- **Shared local storage:** begin with App Group-first storage, using the
  selected `group.com.muhiro12.Stally`, for the planned app/extension family.
  Widget/Watch support is anticipated; App Groups themselves are device-local,
  so Watch transport and exact target topology remain implementation design.
- **Links:** Universal Links are in the first release, alongside the existing
  custom-scheme direction. UUID references retain their meaning; a missing
  record is not replaced by a same-name record. Share `https://muhiro12.github.io/Stally/item/<UUID>`;
  installed-device handoff is a release check.
- **App Intents:** UI and Shortcuts call the same Operations. The
  [publication inventory](app-intents-publication-review.md) records the 40
  actions, their inputs and results, required authentication and destructive
  confirmations. Saved workflows depend on those identifiers and meanings.
- **App Shortcuts:** promotion, phrases, and composed workflows are later
  experience design and may follow 1.0. Their deferral does not remove Intent
  coverage or make discoverable actions unavailable to users' own workflows.
- **Preferences:** use descriptive fixed `stally.*` keys with typed access and
  explicit ownership. Never reuse a published key for incompatible meaning.
  No historical user-preference migration is needed for the first release
  starting with App Group storage. Unknown-key cleanup is a separate policy;
  reuse MHPlatform if needed rather than inventing another lifecycle engine.

The [identifier inventory](saved-key-and-identifier-design.md) retains the
current bundle ID, CloudKit container, configured App Store ID and monthly
product ID, and remote-update endpoint. It distinguishes selected identities
from account-registration evidence. Registry read-back remains release work.
