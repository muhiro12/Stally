# iOS 27 Release Readiness

> Status: Working release evidence, September 13, 2026. This is not release
> approval. Revisit after the product decision and distribution verification.

## Current Outcome

Stally builds against the installed iOS 27 SDK. Backup export now checks the
same content constraints as import and enforces the encoded-file limit before
presenting a backup to save. It reports localized validation reasons and
preserves source data on failure.

The current scope leaves persisted schema version 1, backup format version 2,
mark semantics, CloudKit identity, package pins, and navigation unchanged.
The accepted Stally-hosted product semantics and remaining model-design
boundary are recorded in the
[Fluel integration assessment](fluel-integration-assessment.md).

The follow-up adds the app's missing UserDefaults required-reason declaration.
The final local Release archive contains this manifest and passes signature
verification. App Store export is blocked by missing distribution signing
assets. Physical-device runtime verification is blocked by device connection.

## Shared Foundation Assessment

The app pins MHPlatform 1.12.0 and MHUI 1.17.0. The library uses
`MHPlatformCore`; the app uses the full `MHPlatform` product. Inspection of
the resolved package and Stally's current adapters found no missing shared
capability required by the backup correction or integration assessment.

| Release need | Existing implementation | Boundary |
| --- | --- | --- |
| Startup | `MHAppRuntimeBootstrap` and lifecycle modifier | App assembly |
| Logging | `MHLoggingBootstrap` and `StallyLogging` | Shared mechanism |
| Routes | Route pipeline, inbox, intent URL source | Stally route meaning |
| Preferences | `MHPreferenceStore` and descriptors | Stally keys and defaults |
| Persistence | Versioned SwiftData factory and fallback | Stally data policy |
| Purchases | Runtime subscription section and state sync | StoreKit adapter |
| Ads | Optional native-ad configuration | Stally release identifiers |
| Licenses | Runtime license view in Settings | Existing app surface |

Relevant Stally adapters are in `Stally/Sources/Platform/`,
`Stally/Sources/App/StallyApp.swift`, and `Stally/Sources/Features/Settings/`.
The resolved MHPlatform `MHAppRuntimeAdsBundle` omits both the ads startup
closure and native-ad factory when the ad unit is nil. Stally already supplies
nil in production Release builds. This is a configuration capability, not a
reason to broaden MHPlatform. No shared package was modified.

## Backup Safety Evidence

Before the correction, three regression tests failed: duplicate Item IDs,
duplicate marked days, and unknown categories. Export accepted the duplicates,
although import rejected them; snapshot creation also silently converted an
unknown category to `Other`. The source items were not repaired by this test.

Export now validates a snapshot before encoding, preserves raw category values
for validation, and rejects JSON exceeding the existing 96 MiB import limit.
The existing aggregate photo limit remains 64 MiB. It does not merge duplicate
records, discard photos, truncate notes, or silently repair persisted data.

Nine export tests cover duplicate Item IDs, duplicate marked days, duplicate
Mark IDs, unknown categories, invalid photos, aggregate photo size, encoded
file size, a full restore round trip, and an empty collection. The round trip
compares identifiers, photo bytes, archive state, and marked days.

If validation rejects an export, it has not produced a restorable backup.
Preserve the source store and resolve the reported condition before relying
on a new backup for Replace Library or Delete Everything. Raw snapshot
construction remains available for diagnosis; automatic repair is outside this
change.

## Completed Local Checks

- Toolchain: Xcode 27.0, build `27A266a`; selected developer directory is the
  installed Xcode beta application. This identifies local evidence only.
- Destination: discovered iPhone 18 Pro Simulator, iOS 27.0.
- Library tests: 114 tests in 25 suites passed; the retained
  `ci_scripts/tasks/test_stally_library.sh` completed with `TEST SUCCEEDED`.
- Swift formatter and repository rules passed, including SwiftLint resolved
  from the declared package and the app/library boundary checks.
- English/Japanese audit: all six catalogs have zero incomplete or stale
  keys after reviewing two machine-translated entries. Existing wording and
  placeholders were retained. `Stally` and `CFBundleName` source-copy notices
  are intentional product names; no keys were removed.
- Xcode-native app builds passed with no errors, including the final reviewed
  catalog state, and extracted Stally App Intents metadata.
- Runtime: existing in-memory fixtures reached Library, Item Detail, Insights,
  Backup Center, and Settings. Export opened the native Files sheet and
  dismissal returned to unchanged 5/1/23 collection counts.
- Runtime logs showed preview-container creation and startup readiness, with
  no observed app crash or fatal persistence failure. Simulator service and
  accessibility diagnostics remain in the logs. Full observations and seven
  captures are in [ui-preview-report.md](ui-preview-report.md).

The initial sandboxed test attempt could not access CoreSimulator. Running
the same repository command with the required access produced the regression
failures. That failing run printed all results but stalled during teardown
and was terminated; it is reproduction evidence, not a successful test run.
The post-fix test command completed normally.

The runtime check did not save or import a file, exercise a malformed-export
alert, or change persistent data. The Files Cancel hit point did not match its
remote accessibility hierarchy; dismissing the sheet by swiping succeeded.
The library tests prove export-to-restore data equality in isolated containers.
These are distinct evidence layers.

## Remaining Release Evidence

1. **Visual acceptance:** retain the representative Library, Item Detail,
   Insights, Backup Center, and Settings evidence in
   [ui-preview-report.md](ui-preview-report.md). A technical capture is not
   acceptance of a broad visual redesign. Any new combined Fluel surface needs
   its own review before implementation expands.
2. **CloudKit and startup recovery:** verify persistent local-to-cloud use,
   device-to-device sync, offline edits, relaunch, and fallback using real
   devices and the intended environment. Temporary storage must remain visibly
   temporary; a simulator launch cannot prove durable production sync.
3. **StoreKit:** verify the configured Stally product, purchase, restore,
   expiration/revocation, and ad-removal behavior with the intended store
   environment. Keep iCloud independent of subscription state.
4. **Advertising configuration:** Release native ads are disabled, but
   `Stally/Configurations/Info.plist` still embeds Google's sample application
   identifier. Before distribution, provide Stally-owned production
   configuration or complete and verify an ads-disabled configuration that
   contains no test advertising identifiers. An ads-disabled first release
   must also resolve the new ad-removal subscription offer; it cannot sell
   removal of ads that are not served. Do not enable production ads merely
   because the SDK links successfully.
5. **Privacy and support:** the Settings Privacy Policy destination returned
   HTTP 404 again on September 13. The README Support URL also returns 404.
   Publish or select the approved policy and support destination and verify
   the actual link before release. The inspected About section contains
   Privacy Policy and Licenses but no support entry point. Confirm the support
   destination and store metadata, and audit the distribution artifact's
   privacy manifests and dependency licenses against actual enabled behavior.
6. **Distribution:** the local Release archive now succeeds; App Store export
   fails because a distribution certificate with its private key and an App
   Store provisioning profile are unavailable. Establish the required signing
   assets, produce the export with the shipping toolchain, check its final
   entitlements and identifiers, and verify the distributed build. Local Debug
   builds and library tests do not prove
   App Store metadata, signing, production CloudKit, or purchase readiness.

The privacy destination inspected was the
[Stally privacy policy](https://muhiro12.github.io/Stally/privacy.html).
Its content and approval remain unresolved; an alternative URL was not guessed.

## Follow-up Evidence

This pass changes only the app privacy manifest and documentation. It does not
change persisted models, schema versions, migration stages, backup format,
Mark behavior, or app navigation. Fluel remains read-only.

- The app uses standard-domain UserDefaults through app-owned preference
  descriptors and `@AppStorage`, but the initial archive contained only the
  Google Mobile Ads and User Messaging Platform privacy manifests. Added
  `Stally/Resources/PrivacyInfo.xcprivacy` with
  `NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1` for the app's own
  settings. This is not a completed store data-collection declaration or a
  published privacy policy. See Apple's [required-reason API guidance][reasons].
- Final Xcode-native iOS 27 physical-device Debug build passed. Its bundled
  app manifest matches the source. No Swift or library behavior changed, so
  the earlier library tests were not rerun as new evidence.
- Final local Release archive passed with Xcode `27A266a`, and the archived
  app manifest matches the source. `codesign --verify --deep --strict` passed.
  The native tool inventory has no archive/export action, so these checks
  used official `xcodebuild`. The first archive attempt was blocked by sandbox
  cache access; the retry with that access completed.
- The archive is development-signed: it has development push entitlement
  and `get-task-allow`. This is not a production distribution signature. It
  still contains Google's sample App ID despite Release ad requests being
  disabled; distribution remains gated on the advertising decision above.
- App Store export used local `destination=export` without provisioning
  updates or upload. It failed on the missing distribution certificate/private
  key and App Store profile. No signing assets were created and no build was
  uploaded. Shipping-toolchain and distributed-build evidence remain open.
- Physical-device interaction is not supported by the current native session
  API. A bounded official CoreDevice fallback could discover the device, but
  installation failed with `Connection reset by peer`. No fixture launch,
  physical-device screenshot, or runtime log was obtained. Reconnect and unlock
  the device before retrying; CloudKit and StoreKit remain unverified.
- The app's generated license catalog includes Google Mobile Ads, User
  Messaging Platform, GoogleMobileAdsWrapper, LicenseList, and SwiftLintPlugins.
  License text is compiled from generated Swift, so absence of standalone
  license files in the archive is not evidence of absent notices. Full
  dependency attribution and the reachable Licenses screen remain review gates.
- Plist validation, repository rules, local Markdown links, and patch
  whitespace checks passed. A Markdown lint CLI was not available; changed
  prose was checked for heading, list, and line-wrap consistency.
  Xcode's original `Stally / My Mac` selection was restored and confirmed.

Private signing, device, command logs, and manifest inventories are retained
under the ignored `.build/ci/release-followup-20260913/` directory. No
persistent domain or cloud records were created, edited, imported, or deleted.

External decisions are the Stally-owned production ad configuration versus an
ads-disabled initial offer, approved Privacy/Support URLs and public contact,
and obtaining the missing distribution signing assets. Two-device sync testing
also needs an explicit test environment and permission to create identifiable
synthetic records there; a fixture-only device launch would not prove sync.

## Next Decision

Fluel's assessment and domain contract are complete and reconciled in the
host-side assessment. The initial scope requires no Fluel data transfer,
includes records without Marks outside choice-oriented Review and Insights,
and keeps time running while archived. Translate these accepted constraints
into a bounded implementation before changing models. In parallel, address the
concrete release configuration and external evidence gaps above. Keep each
correction local to its demonstrated owner and verify the affected library,
adapter, runtime, or distribution boundary.

[reasons]: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
