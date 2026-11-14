# First-release qualification

Use the [implementation record](remaining-capabilities-implementation.md#implemented-contracts-and-release-checks)
and the [App Intents inventory](app-intents-publication-review.md) for the release
candidate. [Issue #8](https://github.com/muhiro12/Stally/issues/8) tracks distribution
setup. Record the candidate, environment and result for each check.
The [November 14 repository review](first-release-review.md) records source fixes
and Simulator evidence separately from the distribution checks below.

Store text and the monthly offer are maintained in
[Store resources](../AppStore/README.md). The identifiers include the Store SKU.

## Repository privacy declarations

The app's `PrivacyInfo.xcprivacy` declares the required-reason API uses in the
app and its statically linked StallyLibrary:

- UserDefaults: `CA92.1` for app-only preferences and `1C8F.1` for the App Group
  preferences used by the app and its system entry points.
- File attributes: `C617.1` for operation-owned staging files and `3B52.1` for
  user-selected import files. The transfer reader uses `fstat` to validate file
  type and size; it does not use timestamps to order records or identify people.
- Disk space: `E174.1` for rejecting transfer staging or import when capacity
  is insufficient. Available capacity is not transmitted.

These reasons follow [Apple's required-reason API inventory](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
Validate the packaged manifest in the release artifact as part of distribution
qualification. This declaration does not replace App Store privacy disclosures
or the privacy manifests owned by dependencies.

## November 11 Store configuration

App Store Connect read-back confirmed app ID `6760996986`, bundle ID and SKU
`com.muhiro12.Stally`. Active Apple-issued App Store provisioning profiles contain
`group.com.muhiro12.Stally` and `iCloud.com.muhiro12.Stally`, matching the source
entitlements and model-container configuration. This confirms registration and
profile alignment, not the signature of a future release archive or production
CloudKit synchronization.

The monthly product `com.muhiro12.Stally.subscriptions.monthly` is registered
with a one-month period. Its English and Japanese names and descriptions, and
the app's version 1.0 descriptions, were applied and read back exactly. A fresh
Apogee metadata plan reported both descriptions unchanged.

Japan is JPY 300 per month and the United States is USD 2.99. The other 173
territories use Apple's equalized prices from the USA USD 2.99 price point;
Japan overrides the equalized JPY 500 price. All 175 price points and
subscription availability entries were read back and matched. The app download
price is free in all 175 price territories. New subscription territories are
enabled automatically, matching the intended broad distribution policy.

Store descriptions do not promote the absence of advertising because ads are
planned soon after the first release. The current paid benefit remains optional
iCloud synchronization.

The subscription remains `MISSING_METADATA`; its review screenshot is absent.
App distribution availability is also not yet configured. Review screenshots,
remaining Store submission fields, purchase/restore tests and production sync
qualification remain release work. No review submission or release was performed.

## Remaining release checks

- Confirm the signed app, App Group, CloudKit container, associated domain
  and Store record use the intended [identifiers](saved-key-and-identifier-design.md).
  Verify the production schema and device-to-device synchronization, offline
  writes and account transitions with the intended environment.
- Open a shared HTTPS Item link from outside an installed app. Check locked-device
  authentication and replay of saved Shortcuts. Verify photo and file-provider
  access on devices with a representative workload.
- Qualify [text input assistance](item-input-assistance.md) on eligible hardware:
  Japanese/English prose, missing or ambiguous details, unsupported language,
  Intelligence disabled or preparing, cancellation/retry, and VoiceOver review.
  Manual editing must remain usable; suggestions must not silently save or
  replace existing draft text. Verify Prepare Item from Text through Shortcuts.
- Qualify the configured StoreKit purchase, restore and expiration behavior.
  Release 1.0 has no advertising and offers optional iCloud sync as the paid
  benefit. Sample ad IDs and advertising SDK linkage have been removed. Verify subscription
  product metadata, price, purchase, restore, renewal, expiration and revocation;
  the app must explain that sync configuration changes apply on next launch.
  Qualify same-store enable/disable transitions and offline entitlement startup.
  Before adding ads in the planned minor release, obtain production identifiers,
  configure consent and disclosures, and verify subscription-based ad removal.
  Do not promise that later benefit in the initial purchase description.
- Verify the support and privacy destinations, App Store disclosures, dependency
  licenses and signed distribution artifact against the behavior being shipped.
  Stally support and privacy page sources live under `.github/pages/`.

## November 8 source preparation

The current source implements the initial no-ads, paid-sync offer and exposes
Settings, purchase/restore, support, privacy, terms and licenses. The site source
has been updated; publication and App Store Connect product metadata are separate
steps. No Store product, price, CloudKit production schema or public site was
changed by this implementation pass.

Describe the paid app feature as Stally library synchronization, not additional
iCloud storage capacity. Qualify the actual offer and disclosures against
[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
before submission; implementation or another app's approval is not approval of
this offer.

Deferred verification must cover filter reset and return navigation, new/link
Item visibility, repeated Mark additions and Undo, package versus JSON export,
and settings/purchase flows, in addition to the sync transitions above.

Source checks passed: Simulator app build, signed iOS Release build, repository
rules, all five English/Japanese catalogs and 105 local documentation links.
The Release artifact passes signature verification, extracts 38 App Intents and
contains neither advertising SDK bundles nor an AdMob app ID. Its dSYM generation
reported seven missing SDK module-cache references; qualify a clean distribution
archive and its symbols before release. This is not Store or device validation.
