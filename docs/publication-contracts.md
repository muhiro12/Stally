# Publication Contracts

For the October 27 source inventory and proposed division between decisions now
and implementation-time freezes, see [saved keys and external identifiers](saved-key-and-identifier-design.md).
That review does not change registrations, preferences, stores, or source code.

The [October 22 core record design](core-record-design.md) reopens selected
pre-release contracts. This inventory describes the current implementation;
development names and formats are not already-shipped obligations. Proposed
changes have not altered the live schema, file codecs, or external identities.

Stally's first public release establishes the commitments below. Development
history alone does not make every prototype name permanent. Change a contract
according to what survives on a device, in a file, or in a saved system action.

## Product and Service Identity

The bundle identifier `com.muhiro12.Stally`, CloudKit container
`iCloud.com.muhiro12.Stally`, and App Store ID `6760996986` identify this product
and its cloud collection (`identity-fixed`). A spelling change is not a safe
cleanup: it can separate installed apps, purchases, or cloud records from their
original identity. The monthly product is
`com.muhiro12.Stally.subscriptions.monthly`; keep entitlement lookup aligned
with that registered product for as long as its purchases need recognition.

The [remote-update endpoint and policy](remote-update.md) are a separate
installed-client commitment. Preserve the `stally/app.json` endpoint and the
MHPlatform policy/evidence semantics while released clients use them. Follow
the configuration repository's revision and activation rules when changing
policy. Source configuration is not evidence of App Store availability.

## Primary Data and Portable Files

The [first-release model](first-release-data-model.md) retains SwiftData V2,
the tested V1 migration, Item/Mark UUIDs, category strings, partial starts, and
the original store location (`migration-required`, `legacy-support`). The V1
schema fixes its original defaults independently of current domain enums.
Append future schemas rather than editing historical definitions. Keep V1
support until a deliberate support decision accounts for stores that have
never opened in a newer build. Do not reset stores after initialization failure.

The [portable contract](portable-data-contract.md) registers
`com.muhiro12.Stally.data` and `.stallybackup`. The earlier development type
`com.muhiro12.stally.backup` has no registration alias. This changes OS document
registration, not JSON bytes or interpretation: v3 maps to persisted V2 and
v2 maps to persisted V1. Both readers remain intentional compatibility.
Exported files outlive an app installation; changing their fields, date/day
encoding, category values, or UUID meaning requires conversion or an explicit
retirement decision. Preserve frozen fixtures as independent evidence.

## Device Preferences

The [key catalog](../StallyLibrary/Sources/Preferences/StallyUserDefaultsKeys.swift)
and [descriptors](../StallyLibrary/Sources/Preferences/MHPreferenceDescriptors+Stally.swift)
own seven standard-domain `stally.*` keys. Their descriptive namespace is
consistent within Stally; matching another app's opaque key spelling would
discard settings or introduce unnecessary migration work.

Review thresholds are integers (defaults 14 and 30 days). Its completed-lane
visibility is a Boolean (default true). Insights stores the range strings
`thirty-days`, `ninety-days`, `year`, or `all-time`, with a 30-day fallback, and
an include-Archive Boolean (default false). These are meaningful preferences:
preserve their keys and interpretation until migration or deliberate retirement
(`migration-required`). They do not belong in collection exports.

The iCloud Boolean defaults to false and records device-local sync choice;
renaming it could silently disable a chosen service. The subscription Boolean
also defaults to false but is refreshed from StoreKit: it is cached entitlement
state, not proof of purchase or a portable entitlement. SDK-owned consent and
update evidence remain package-owned; no app-wide defaults cleanup is needed.

## Saved Routes and System Actions

The [route and intent contract](system-interface-contract.md) keeps `stally://`
destination paths, including `backup-center` and `create-item`, and
`stally://item/<UUID>`. Preserve externally saved URLs, Item UUID meaning,
intent/entity types, parameters, and enum raw values while saved actions depend
on them (`legacy-support`). Display labels may evolve independently. Literal
destination URLs are exercised by library tests so a parser/producer rename
cannot accidentally redefine both expectations together.

`com.muhiro12.Stally.pendingDeepLinkURL` in standard defaults holds one pending
URL for foreground replay. It is consumed by the route pipeline, not retained
as collection history. Its compatibility window is pending delivery; do not
give this disposable slot the lifetime of Item identity.

Spotlight's [owned index and recovery policy](spotlight-indexing.md) keep search
derived from saved Items. Its namespace changes need owned-index cleanup and
reconciliation, not a primary-data migration. Test namespaces never clear the
production index. Navigation selection and previews are also disposable state.

Notifications, Widget, Watch, and Live Activities are outside the current
implementation. There are no contracts to normalize for those surfaces yet.
