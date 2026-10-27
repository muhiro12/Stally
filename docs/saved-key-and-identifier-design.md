# Saved Keys and External Identifiers

## Status and Evidence

Reviewed on October 27, 2026, following the accepted distinction between durable
contracts and interface implementation. The owner subsequently selected App
Group-first storage in preparation for Widget/Watch support, Universal Links
from the first release, and iCloud from the first release. The owner then
accepted descriptive fixed raw keys, the proposed App Group identity, and the
distinction between first-release iCloud support and subscription coupling.
The existing `.stally` package design was reconfirmed. Other recommendations
are identified separately below. This is a source inventory and design
recommendation, not an implementation change or confirmation of registrations
in App Store Connect, the developer account, or CloudKit production.

Reviewed the Xcode project, Info.plist, entitlements, app/library preference
catalogs and consumers, model-container factory, link producers/parsers/tests,
Spotlight identifiers, user activity, monetization, and remote-update wiring.
The [publication inventory](publication-contracts.md) describes the older
implementation; the accepted model, sync, and export designs take precedence
where they supersede it.

Three different deadlines matter: decide the product's durable identity now;
freeze feature-specific persisted/external values before first publication;
keep disposable internal state replaceable within its actual lifetime. A
registered identifier can acquire restrictions before public release, so
"no users yet" is not evidence that an Apple registration is freely renameable.

## Recommend Establishing Now

| Surface | Observed value or selected design | Recommendation |
| --- | --- | --- |
| Main bundle ID | `com.muhiro12.Stally` | Keep the current product identity |
| App Group ID | Selected `group.com.muhiro12.Stally` | Use shared storage from the first release for the planned app/extension family; confirm registration during integration |
| CloudKit container ID | `iCloud.com.muhiro12.Stally` | Keep it aligned with entitlements and model configuration; do not replace it merely for naming cleanup |
| App Store app ID | `6760996986` | Keep the configured product destination; verify the account record before release |
| Monthly product ID | `com.muhiro12.Stally.subscriptions.monthly` | Keep this identity if the monthly product remains; do not reinterpret it as an unrelated purchase |
| Native portable document | `.stally`, selected package UTI `com.muhiro12.stally.export` | Retain the accepted distinct package identity and physical format |
| Product links and Item target | Existing `stally://item/<UUID>` plus first-release Universal Links | Keep UUID addressing; adopt the sibling associated-domain pattern and finalize/verify the Stally HTTPS paths during integration |
| Remote-update configuration | `https://raw.githubusercontent.com/muhiro12/MHAppConfig/main/stally/app.json` | Retain the installed-client endpoint and package policy semantics |

Source declarations are not evidence that all these IDs are registered, that a
purchase is available, or that the production schema is empty. Read back those
external records during release/integration work before acting on them.

Apple fixes a bundle ID after a build has been uploaded and does not allow an
In-App Purchase product ID to be edited or reused for another purchase after
creation. The App Store app ID is assigned by Apple. These restrictions are
not postponed until the first customer installs the app.

The package UTI above was already selected in the
[export design](export-file-format-design.md). The current code instead declares
`com.muhiro12.Stally.data`, `.stallybackup`, `public.json`, and
`application/json`. Do not change that flat-file type into a package or keep
claiming that the new package is JSON. Register the package with
`com.apple.package` and appropriate content conformance; auxiliary JSON sharing
continues to use `.json`/`public.json`. Installed declaration/provider behavior
requires verification during implementation.

Do not mechanically normalize the capitalization of unrelated identifiers.
The existing bundle/container and the selected lowercase package UTI have
separate identities. Their spelling does not need to be made uniform.

## Preference Rules to Establish Now

- Use App Group-first storage from the first release. Put the shared SwiftData
  store, app-owned settings intended for the app/extension family, and route
  handoff in the shared container/suite. Keep SDK-owned and genuinely
  process-specific state under its appropriate owner; do not relocate all
  standard-domain values indiscriminately.
- Independently of existing Stally code, use descriptive, fixed raw keys
  under `stally.`. They expose meaning when inspecting a defaults dump or a
  migration mapping without an additional lookup. Eight-character IDs remain
  technically valid and intentionally chosen by the siblings; there is no
  Apple requirement for either spelling. Record each shipped raw key with
  its stored type, meaning, owner, default/fallback, and retirement handling.
  Swift property renaming need not rename the raw key.
- Never reuse a shipped key for an incompatible purpose or type, even after
  years without reading it. Introduce a different key and an explicit migration
  or retirement decision. This also applies to retired cache/transient keys:
  their bytes may survive their useful lifetime.
- Distinguish an absent value from a stored user selection. Changing fallback
  defaults does not authorize overwriting existing preferences. Use normal
  platform default registration/typed descriptors rather than a second settings
  database or a new application-wide preference schema engine. This does not
  reject the existing MHPlatform preference registry/lifecycle; assess its
  migration and cleanup policy separately from key spelling.
- A resettable preference is not primary history. Settings remain excluded from
  collection export. Deleting a setting must not delete Items or alter recorded
  facts. Avoid broad defaults clearing, including package-owned state.
- Keep user choice, observed system state, and derived caches distinct. A
  subscription cache is not purchase authority. A sync preference is not a
  claim that the system has completed synchronization.

These are contract rules now; selecting every future preference and default is
not required to finish this session.

## Complete App-Owned Defaults Inventory

The current source declares seven catalog keys plus one transient route slot.
This table inventories them without accepting every old product feature.

| Raw key | Current type/default | Meaning and recommendation |
| --- | --- | --- |
| `stally.needsFirstMarkAfterDays` | Int / 14 | Review threshold for an unmarked Item; retain if that feature survives, finalize its meaning with Review |
| `stally.dormantAfterDays` | Int / 30 | Review inactivity threshold; same treatment, including its relationship to multiple daily Marks |
| `stally.showsCompletedReviewSections` | Bool / true | Review presentation preference; freeze its key/type if persisted, not its entire layout |
| `stally.defaultInsightsRange` | String / consumer fallback `thirty-days` | Stored range selection; finalize range semantics and raw values with Insights |
| `stally.includesArchivedItemsInInsights` | Bool / false | User selection for including archived Items; keep separate from archived state itself |
| `stally.isICloudOn` | Bool / false | Currently selects `.private` versus `.none` at container creation; do not freeze this as the redesigned sync contract |
| `stally.isSubscribeOn` | Bool / false | Cached status refreshed from StoreKit-backed runtime state; not a user preference or proof of purchase |
| `com.muhiro12.Stally.pendingDeepLinkURL` | Optional route string | Single pending foreground-delivery slot; retain only for delivery, reject unusable values, never reuse the key for unrelated data |

The first five are reasonable implementation names if their features remain.
Opaque keys are a deliberate sibling convention, with semantic Swift names
separated from fixed storage IDs. Descriptive fixed raw strings can also retain
identity through a Swift rename. Neither style removes compatibility duties;
Apple API requirements do not establish one as categorically better. Do not
insert a release number into every key without a versioning requirement.
Their exact defaults and new preferences, such as heatmap presentation, belong
to the respective feature design and must be inventoried before publication.

One concrete semantic trap exists: Insights currently stores `year` but computes
an inclusive trailing 365-day window, not a calendar year. If that feature is
retained, prefer an unambiguous value such as `365-days` before first publication.
If `year` ships, never later interpret it as a different interval without an
explicit transition. Other current values are `thirty-days`, `ninety-days`, and
`all-time`. An unrecognized value should use the documented fallback without
silently treating it as a new meaning or rewriting it during an ordinary read.

### What Preference Migration Actually Means

Stally's first release will begin with the selected App Group storage rather
than upgrading a released standard-domain preference layout. No historical
user-preference migration or speculative migration steps are needed for that
initial release. Retain the ownership, fixed-key, and non-reuse rules; assess
actual migrations only when a later change affects shipped values. This does
not decide whether to adopt shared registry-based cleanup, which is a separate
policy. Any handling of existing development stores/settings belongs to the
implementation transition, not a public compatibility promise or an automatic
data reset.

Preference migration moves a value from an old key/domain to a new key/domain,
or deliberately converts its representation while preserving its meaning. For
example, moving a Review threshold from standard defaults to the App Group
suite could preserve the chosen number of days. This is an illustration, not
an Incomes production migration currently observed.

The current Incomes sources register preference descriptors, but no explicit
`legacySources` or custom migration steps were found in the app, library,
Widget, or Watch sources. MHPlatform descriptors default legacy sources to an
empty array, and built-in migration steps are generated from that array. The
registry still runs its lifecycle and cleans unknown keys after the empty
migration phase. Its migration test moves a synthetic display-name value
between isolated suites; it is not evidence of a real user-setting migration.
Thus the earlier statement that Incomes migrates settings was too broad: it
uses a migration-capable mechanism, not a currently configured historical
conversion for those production settings. Preserve declared SDK/platform keys
during cleanup; migration and unknown-key deletion are different operations.

### Sync and Entitlement Are Not Cosmetic Settings

iCloud support is selected for the first release, not a deferred feature. The
[accepted sync direction](sync-lifecycle-design.md) follows native account
and mirroring behavior. It does not accept the old toggle simply because the
code has it. Recommend no new persistent app-controlled switch unless a concrete
product requirement calls for it. If the app retains such a switch, define
start/stop, existing-data handling, and re-enablement before selecting its final
key/default. Do not reinterpret the old key as cloud availability or entitlement.

Likewise, decide whether a separate persisted subscription cache is still useful
when integrating the native entitlement runtime. If retained, name and document
it as a cache rather than a user-controlled subscription switch. Do not grant
purchase authority to the Boolean. Neither an unknown/expired entitlement nor
changing a preference may silently replace the store or erase records.

These are bounded conditions for feature implementation, not permission to
invent a second library, custom synchronization engine, or account backup.

## External Routes and System Identities

Current destination routes are `library`, `archive`, `review`, `insights`,
`backup-center`, `create-item`, and `settings`. Recommend retaining meaningful
semantic destinations and changing the unshipped `backup-center` spelling to
`import-export` when implementing the accepted export design. `create-item`
opens creation UI; merely opening a route must not create a record.

Route coverage and final destination spellings can be finalized with navigation
before first publication. After publication, saved destination URLs need an
intentional compatibility/retirement decision even if their screen is redesigned.
A missing Item UUID must not select a same-name Item. A custom URL scheme is
not proof of caller identity or exclusive OS ownership; use the existing native
link mechanism for current behavior. Universal Links are now selected for the
first release. Follow the sibling associated-domain pattern, using
`applinks:muhiro12.github.io` as the integration candidate; verify ownership,
the Stally-specific association-file entry, paths, entitlements, and installed
behavior before publication. No website or entitlement has been changed here.

| Identifier/state | Observed source | Recommended treatment |
| --- | --- | --- |
| User activity type | `com.muhiro12.Stally.viewItem` | Retain the meaningful name; confirm emitted payload/identity before publication. Current Handoff, search, and prediction flags are false |
| Spotlight domain | `com.muhiro12.Stally.items` | Retain ownership scope; changing it requires old-domain cleanup and rebuilding derived results |
| Spotlight item ID | `<domain>/<UUID>` | Preserve UUID meaning; index rebuild does not authorize redirecting stale results to a different Item |
| Search recovery ledger | Application Support `Stally/SearchIndex/<namespace>.json` | Reconstructible state; version/reset/rebuild within owned scope rather than migrating primary records |
| Test search namespace | `com.muhiro12.Stally.search-tests.<UUID>` | Disposable and isolated from production cleanup |
| App Intent identities | Current type/parameter/entity names | Follow the accepted [Intent direction](app-intents-contract-design.md); finalize metadata before publication, not the full feature inventory in this session |

Spotlight index contents are derived, but the OS uses their identifiers to
return to the app. Their lifetime is therefore different from both primary
records and an ordinary in-memory cache. Cleanup/reconciliation is sufficient
for the index; any separately saved activity or Item reference must still be
handled according to its actual reader and lifetime.

## Physical Storage and Framework-Owned Values

The current ModelConfiguration supplies neither an explicit store name nor an
explicit URL. It uses the framework-selected location. Before first release,
configure the shared App Group container deliberately and verify its resolved
store URL, migration baseline, generated CloudKit record/field identities, and
all consumers. Use native group-container configuration rather than a manually
guessed filesystem path. The owner now has a concrete sharing requirement;
the earlier standard-domain-only recommendation is superseded. After users have data, an accidental
configuration/path change can select an empty store and must be treated as a
data transition, not cosmetic refactoring.

The five model names and meanings are already selected. Their physical schema
integration, initial schema/file version pair, and explicit handling of existing
development stores remain implementation work. CloudKit production promotion
must follow verification; an unshipped app does not prove that no schema was
already promoted. Do not independently choose CloudKit-generated record names,
record IDs, or mirroring internals to force a preferred naming convention.

The configured APNs entitlement and `remote-notification` background mode support
the CloudKit-enabled app. This source inventory found no app-owned notification
categories/requests, Widget/Watch/Live Activity identities, App Group,
associated-domain entitlement, or app-owned Keychain access group. Do not
confuse that current source inventory with the newly selected scope. App Group
and Universal Link registrations are now first-release work. Widget/Watch are
planned, so their target IDs and any saved widget kinds should be fixed before
their own publication, without inventing the full target topology in this step.
App Groups share data between processes on the same device; they do not make
an iPhone store or defaults suite directly shared with an Apple Watch. Choose
the native cross-device transport separately when implementing Watch support.

The source has development ad identifiers and no Release native ad unit in its
configuration. Production ad setup is deployment work, not a reason to freeze
sample IDs as a product contract. Keep SDK-owned consent, StoreKit state, and
MHPlatform update evidence under their respective owners. Do not duplicate their
keys into Stally's catalog or clear them to simplify a migration. The remote
configuration URL is different: old installed binaries continue to request it,
so moving its repository/path requires continuity planning.

## Recommendation and Exit Condition

Accept the stable product/container/document/Item-link identities and the
non-reuse/ownership rules now. Defer feature-specific preference details,
destination routes, Intent metadata, shared-container integration, and concrete
extension IDs to implementation, with a required pre-publication review.
App Group-first storage, first-release Universal Links, and first-release
iCloud are selected product scope rather than optional future additions.

The only additional product decision arises if an app-controlled sync switch
is retained: its data-lifetime effects must be defined, not hidden inside a
Boolean rename. This inventory does not select that feature or reopen accepted
native sync behavior. Cache naming, thresholds, presentation choices, and
hypothetical extension identifiers do not need to prolong the contract session.

## Sibling Comparison and Corrections

Read-only comparison on October 27, 2026 used the local Incomes and Cookle
checkouts and the relevant MHPlatform preference lifecycle sources. It did not
verify deployed versions, domain association files, or runtime behavior, and
it changed neither reference repository.

- **Align: ownership and access.** All three use a central key catalog and typed
  MHPreferenceDescriptors/MHPreferenceStore access. Loss-tolerant settings are
  distinct from authoritative SwiftData records. This is the architectural base
  being preserved, not a recommendation to copy every product preference.
- **Naming judgment, re-evaluated without legacy preference:** Incomes and Cookle
  prescribe fixed eight-character storage identifiers while Swift symbols carry
  meaning. Stally's current raw keys are descriptive. The initial rationale
  included current-source continuity; the later evaluation
  removes that factor and still recommends readable, fixed raw keys for direct
  inspection and maintenance. No security or compatibility advantage over
  fixed opaque keys is claimed. Swift symbol renaming must not automatically
  rename either kind of raw key. No source rename was performed.
- **Align the available mechanism, assess the policy:** The siblings use
  MHPreferenceRegistry for declared migrations and unknown-key cleanup, including
  explicitly preserved external descriptors. That is intentional lifecycle
  design, not just historical migration baggage. Stally currently has no such
  registry wiring. Incomes currently configures no historical source values to
  migrate through it; distinguish the capability from actual conversions.
  Prefer reusing the shared mechanism if lifecycle management
  is adopted; scope the declared domains, preserved SDK state, and tolerated
  retirement explicitly. The prior warning against a new settings engine does
  not prohibit the existing platform facility or require preserving all obsolete
  preferences forever.
- **Align: sharing domains.** Both siblings declare App Groups and share route
  handoff values. The owner clarified that Widget/Watch support is planned from
  the outset or soon afterward. Stally therefore selects App Group-first storage
  before first release rather than delaying the sharing boundary until a target
  happens to exist in source. The current code has not yet been integrated.
- **Align when implementing external links:** Both sibling URL builders prefer
  Universal Links and retain custom-scheme paths/fallbacks. Stally currently
  has only its custom-scheme registration. A custom-scheme-only recommendation
  cannot be justified merely by avoiding new infrastructure when shared domain
  infrastructure already exists. Keep the current scheme and evaluate the
  existing Universal Link pattern, now explicitly selected for the first release;
  exact Stally URLs and association are still implementation/publication work.
- **Adapt policy, not Boolean technology:** Both siblings retain subscription
  and iCloud Booleans; current entitlement handling can turn the iCloud setting
  off for inactive subscriptions. Stally has not accepted that coupling for its
  redesigned data lifetime. iCloud itself is explicitly in first-release scope;
  that does not by itself decide the initial toggle value or paid entitlement
  coupling. A cache is still valid; discarding it or removing a
  toggle is not already decided. The difference comes from the accepted Stally
  lifecycle boundary, not an assertion that a Boolean or StoreKit cache is bad.
- **Mostly align: document registration.** Current Incomes declares a JSON
  `.incomes` type. Current Cookle already declares `.cookle` as a package with
  `com.apple.package`/`public.content`; do not describe Cookle as necessarily a
  flat JSON/Base64 design. Stally's package direction is therefore similar to
  current Cookle. Stally's separate new UTI distinguishes it from its old flat
  development format. Lowercasing the product component and using `export`
  rather than `data` are naming choices, not technical requirements.

Primary local references: each sibling's `*UserDefaultsKeys.swift`,
`MHPreferenceDescriptors+*.swift`, architecture guide, app entitlements and
Info.plist; IncomesPreferenceLifecycle, CooklePreferenceCatalog, both deep-link
URL builders, and MHPlatform's MHPreferenceRegistry/MHPreferenceLifecycleService.
Cookle ADR 0006 explicitly records loss-tolerant preferences and declared cleanup.

## References

- [Apple app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information).
- [In-App Purchase identity](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/).
- [Custom document types](https://developer.apple.com/documentation/uniformtypeidentifiers/defining-file-and-data-types-for-your-app).
- [Registered defaults](https://developer.apple.com/documentation/foundation/userdefaults/register(defaults:)).
- [CloudKit production schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema).
- [Custom URL schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app).
