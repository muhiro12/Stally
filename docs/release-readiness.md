# First-release qualification

Use the [implementation record](remaining-capabilities-implementation.md#remaining-contract-work)
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
  Confirm the production advertising configuration and subscription offer.
  The source Info.plist contains a sample advertising app ID. Resolve the
  advertising configuration for the actual candidate before distribution.
- Verify the support and privacy destinations, App Store disclosures, dependency
  licenses and signed distribution artifact against the behavior being shipped.
  Stally support and privacy page sources live under `.github/pages/`.
