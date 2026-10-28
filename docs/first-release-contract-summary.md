# First-Release Contract Summary

For the integrated October 27 implementation, current evidence, and remaining
work, see [foundation implementation](first-release-foundation-implementation.md).
The design-session and standalone-probe statements below retain their original
scope; they are not claims about the later application state.

## Status and Scope

Consolidated on October 27, 2026 at the owner's request. This is the entry point
for the decisions reached in the first-release contract-design session. It
summarizes accepted direction without accepting previously unresolved proposals,
claiming completed implementation, or authorizing release.

On October 28, the owner clarified the next phase: derive product capabilities
and behavior from these foundations before designing concrete Operations and
App Intent adapters. Existing Operations and temporary UI are not accepted
feature specifications. See [product behavior design](product-behavior-design.md)
for contract consequences and explicitly unaccepted proposals.

A contract is a persisted or published identity, structure, or meaning whose
consumers can outlive the current implementation and leave material migration,
compatibility, recovery, or support responsibility. Fulfill that responsibility
within its applicable scope and lifetime; neither perpetual support nor an
arbitrary expiry is assumed. Replaceable screen presentation and internal
factoring are not automatically such contracts.

**Session conclusion:** the foundational preservation and interface policies
are established. Detailed feature/interface design, physical schema integration,
and publication qualification can proceed in a separate development session.
Some concrete external values still require selection before publication; they
are explicitly assigned below rather than silently treated as finalized.

No production model, preference store, entitlement, cloud schema, website, or
file codec was changed by this consolidation. Existing documentation contains
bounded standalone experiments; those are not an integrated app or a complete
multi-device qualification.

## Reading Order and Authority

1. Use this summary to distinguish settled direction from deferred work.
2. Use the linked current design documents for exact fields, rules, selected
   engineering budgets, and recorded evidence.
3. Use source and older implementation documents to understand what exists now,
   not to override the accepted redesign merely because code already exists.

Current owner instructions take precedence. If implementation evidence requires
changing a selected meaning or preservation guarantee, explain the concrete
reason and revisit that contract. Routine implementation choices do not need to
reopen all decisions or prolong this contract-design session.

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

### October 28 Context Addition

The owner subsequently accepted one optional, user-chosen representative URL
per Item, providing direct access to its selected external destination. It is
not the Item's own Stally deep link and is not inferred from note contents.
The URL must be retained across storage, sync, and portable transfer. Older
Items may have no link; an older import's absent field must not clear one.
Favorites remain Bool, with no graded rating selected. Other unstructured
context remains in notes until a concrete feature justifies dedicated fields.
See [the accepted behavior](product-behavior-design.md#accepted-context-and-favorite-decisions).
This addition is not yet in the implemented V3 schema; its successor schema,
wire representation, and runtime behavior require implementation verification.

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

Use one `.stally` document package, identified by
`com.muhiro12.stally.export`, with JSON records and optional separate image files.
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
explicit empty/null values retain their distinct meanings. Invalid/unsupported
files must not become partial success or silent data loss. The
[import design](import-identity-design.md) records detailed reconciliation and
review recommendations that implementation must qualify.

The export's `schemaVersion` aligns with the actual SwiftData schema version;
`formatVersion` versions its container/envelope/encoding separately. App release
numbers are not decoder selectors. Store migration and historical import share
preservation semantics, without requiring the same execution path or code.
Keep historical decoding/fixtures for the supported published formats and make
any retirement deliberate; do not invent a forever-readability promise or a
support cutoff in this summary. The initial physical version pair is still an
integration decision.

## Accepted Platform and Interface Direction

- **Native synchronization:** iCloud is included from the first release. Follow
  native account/mirroring behavior and proportional recovery. No custom shadow
  library, account-independent retention guarantee, or distributed exactly-once
  engine is selected. Do not erase records or silently switch stores when
  entitlement state changes. See [sync lifecycle](sync-lifecycle-design.md).
- **Shared local storage:** begin with App Group-first storage, using the
  selected `group.com.muhiro12.Stally`, for the planned app/extension family.
  Widget/Watch support is anticipated; App Groups themselves are device-local,
  so Watch transport and exact target topology remain implementation design.
- **Links:** Universal Links are in the first release, alongside the existing
  custom-scheme direction. UUID references retain their meaning; a missing
  record is not replaced by a same-name record. Exact HTTPS paths and association
  entries must be selected and verified before publication.
- **App Intents:** represent all application capabilities through Operations-
  backed Intent adapters. Keep non-public adapters for capabilities that must
  not be discoverable. Assess native authentication per action, requiring it
  from the start when the need is clear. Discovery, authentication, and action
  confirmation are separate decisions. Exact action metadata is not frozen by
  the withdrawn small-surface proposal. See [Intent direction](app-intents-contract-design.md).
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
from account-registration evidence. Registry read-back remains release work;
this session did not create or verify external registrations.

## Deferred Decisions and Required Evidence

These are not all merely tests: some are concrete feature/integration decisions
that must be made in the phase capable of evaluating them.

| Work | Decide or verify before | Boundary to preserve |
| --- | --- | --- |
| Physical schema placement, initial version pair, generated CloudKit fields, and App Group store URL | Integrating the new persistence layer and any production schema promotion | Selected model meanings, existing-data handling, and stable store identity |
| Handling current development stores/files/settings | Changing their storage or readers | No automatic destructive reset; no invented public compatibility obligation |
| First-launch sync configuration, any app-controlled switch, and entitlement coupling | Shipping those settings/operations | Native account lifecycle and no entitlement-driven data erasure or silent store substitution |
| Exact Intent types/parameters/properties/results, discovery and authentication policies | Publishing each capability | Complete feature coverage and the meaning relied on by saved workflows |
| HTTPS routes, domain association, actual preference raw values/defaults, extension IDs and widget kinds | Publishing the corresponding surface | Stable identifiers, no incompatible key reuse, selected first-release scope |
| File/resource limits and implementation mechanics | Shipping export/import | Identity, omission, integrity, explicit conflict handling, and failed-save preservation |
| Period readings, calendar intensity, Review/Insights preferences, screen composition | Feature implementation; before externally exposing calculated values | Preserve source precision; do not silently turn a display approximation into stored fact |
| Disk-store, provider/photo, installed document/link/Shortcuts, and multi-device checks | Release qualification | Test actual selected behavior rather than claiming standalone probes prove it |

The [period-readings document](period-readings-design.md) remains an unaccepted
engineering proposal. Its elapsed/total calculation and counting conventions
are not approved by this consolidation. It needs no new persisted totals at
this point. If a reading becomes an Intent result, define its meaning/unit and
unknown-value behavior before publishing that result.

Do not preallocate unrelated extension identifiers, future model columns, or
version-history infrastructure just to make this list look complete.

## Superseded Assumptions to Avoid

Do not revive the following as accepted 1.0 requirements:

- One Mark per Item/day, fixed product categories, or a single start on Item.
- Automatic Tag equivalence, grouped duplicate identities, or permanent merge
  redirects.
- Recompression of every image, blanket metadata stripping, or memory-only
  thumbnail storage.
- Separate user-visible local/cloud libraries or app-owned account retention.
- A deliberately restricted App Intent subset or the proposed five App Shortcuts.
- Standard-only storage until an extension exists, deferring Universal Links,
  or treating iCloud itself as undecided scope.
- Treating prototype IDs, schemas, and old flat `.stallybackup` files as already
  shipped obligations merely because they exist in source.

The previous [first-release model](first-release-data-model.md),
[portable contract](portable-data-contract.md),
[system interface](system-interface-contract.md), and
[publication inventory](publication-contracts.md) remain useful implementation
baselines and historical evidence. They are not the approved target design
where this session explicitly superseded them.

## Handoff and Closure

Start the next development session from this summary and the consolidated Swift
schema. Integrate the shared persistence boundary and explicitly handle current
development data before building the remaining adapters. Complete feature
choices and qualifications in their appropriate phase. Do not resume this
session by redesigning reversible UI under the label of contracts.

Reopen a settled decision only for a concrete requirement or evidence that
changes identity, retained facts, ownership/deletion, public file semantics, or
other continuing obligations. Ending this design session is not build/test
certification, registration verification, or authorization to release or push.
