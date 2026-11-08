# First-release qualification

Use the [implementation record](remaining-capabilities-implementation.md#implemented-contracts-and-release-checks)
and the [App Intents inventory](app-intents-publication-review.md) for the release
candidate. [Issue #8](https://github.com/muhiro12/Stally/issues/8) tracks distribution
setup. Record the candidate, environment and result for each check.

- Confirm the signed app, App Group, CloudKit container, associated domain
  and Store record use the intended [identifiers](saved-key-and-identifier-design.md).
  Verify the production schema and device-to-device synchronization, offline
  writes and account transitions with the intended environment.
- Open a shared HTTPS Item link from outside an installed app. Check locked-device
  authentication and replay of saved Shortcuts. Verify photo and file-provider
  access on devices with a representative workload.
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
