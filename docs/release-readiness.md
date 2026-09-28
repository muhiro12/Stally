# iOS 27 Release Readiness

> Status: Working release evidence, September 14, 2026. This is not release
> approval. The integration decision is settled; distribution verification
> remains separate.

The September 14 owner response confirms native advertising with optional
monthly ad removal, following Incomes. Initial advertising setup may be staged
around the first App Store publication. The existing Stally GitHub Pages URLs
and GitHub Issues contact are approved; their publication remains pending.

Remaining external setup and distribution checks are tracked in
[issue #8](https://github.com/muhiro12/Stally/issues/8). The subsequent read-only
Fluel follow-up adds start browsing, yearly milestones, and time sharing/system
readings; it does not clear or alter those external gates. A final distribution
candidate must include and verify these later changes; the retained development
archive predates them.

## Xcode 27 CI Baseline

Local and Cloud builds now use the Xcode 27 family. The configured Cloud
baseline is Xcode 27 RC; local verification uses Xcode 27.0 build `27A266a`.
Check each Cloud run's actual version and result. Earlier references to the
shipping toolchain require verification of the intended Xcode 27 candidate,
not a return to Xcode 26. Build/CI evidence remains separate from App Store
distribution approval and the external gates below.

Repository pushes may run Xcode Cloud CI. GitHub Pages deployment is explicitly
manual through `workflow_dispatch`, so publishing source or running Cloud CI
does not also publish the prepared product/support and privacy pages. The
observed Pages failure was a missing site configuration, not an app CI failure.
Page enablement and deployment remain a separate publication action.

## Current Outcome

The optional-start and non-Mark integration is now implemented locally with a
V1-to-V2 store migration and v2/v3 backup compatibility. Its current results,
synthetic disk fixtures, and screen comparison are recorded in
[item-tracking-verification.md](item-tracking-verification.md). The earlier
backup-only evidence below describes its own unchanged-schema scope, not the
current schema. External gates below remain pre-distribution checks.

The September 14 isolated Simulator continuation recovered actual touch and
accessibility-hierarchy access. Add/Edit, precision validation, Archive,
Review/Insights scope, maximum-text forms, and v2/v3 import confirmations and
conflict protection now have runtime evidence. Reproduced tracking-label
truncation was corrected in `fcdc218`, and clipped Insights headings/percentages
in `a9c61e6`. Remaining manual checks include actual exporter Save,
physical-device VoiceOver, system Shortcuts/Siri, local-midnight
foreground refresh, and other device sizes. The verification record gives
concrete procedures and distinguishes these gaps from completed checks.

Stally builds against the installed iOS 27 SDK. Backup export now checks the
same content constraints as import and enforces the encoded-file limit before
presenting a backup to save. It reports localized validation reasons and
preserves source data on failure.

The earlier backup-safety scope left persisted schema version 1, backup format
version 2, mark semantics, CloudKit identity, package pins, and navigation
unchanged.
The subsequent MHPlatform dependency update is recorded separately below.
The accepted Stally-hosted product semantics are recorded in the
[Fluel integration assessment](fluel-integration-assessment.md). The accepted
[start design][start-proposal] and its implementation evidence supersede that
assessment's earlier model-design gate.

The September 14 local Release archive includes the integration and both
tracking presentation corrections through `a9c61e6`. Its signature verifies, the app
privacy manifest matches source, and no Debug preview launch markers or fixture
files were found in the app. It uses the installed Xcode 27 beta toolchain and
development signing and still contains Google's sample advertising app ID.
No App Store export or distributed build is verified. The read-only check below
found no distribution signing assets and found paired physical devices
disconnected; the archive does not clear those gates. The later Settings Support
link is verified separately and is not included in that retained archive.

## Shared Foundation Assessment

The app now pins MHPlatform 1.13.0 and MHUI 1.18.0. The library uses
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

## Backup-Safety Baseline Checks

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

External product configuration, public destinations, signing assets, and
account/device verification are pre-distribution checks. They do not block
the accepted integration design or isolated domain/migration fixture work.
Implemented changes still require their own local verification evidence.

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
   configuration. If account setup blocks the first release, prepare and verify
   a temporarily ads-disabled configuration without test identifiers and defer
   ad-removal sales with it. This preserves the accepted long-term offer.
   Ad-readiness review after store publication is distinct from ID creation;
   it does not automatically require removing the advertising integration.
   The September 14 time-follow-up audit also reproduced clipped text in the
   small test ad's CTA at maximum Dynamic Type, with oversized ad typography
   persisting after returning to standard text. Retain it as an advertising
   presentation defect to diagnose and recheck before enabling ads; no ad was
   activated, and this observation does not establish production serving.
5. **Privacy and support:** the Settings Privacy Policy destination returned
   HTTP 404 again on September 14. The README Support URL also returns 404.
   Publish the approved Stally GitHub Pages destinations and verify their actual
   content before release. The local About section now includes Support beside
   Privacy Policy and Licenses. Confirm the store metadata and audit the artifact's
   privacy manifests and dependency licenses against actual enabled behavior.
6. **Distribution:** the current local Release archive succeeds; the earlier
   App Store export failed because a distribution certificate with its private
   key and an App Store provisioning profile were unavailable. The read-only
   refresh still found those assets missing, so export was not retried.
   Establish the required signing
   assets, produce the export with the shipping toolchain, check its final
   entitlements and identifiers, and verify the distributed build. Local Debug
   builds and library tests do not prove
   App Store metadata, signing, production CloudKit, or purchase readiness.

The privacy destination inspected was the
[Stally privacy policy](https://muhiro12.github.io/Stally/privacy.html).
Its content and approval remain unresolved; an alternative URL was not guessed.

## Follow-up Evidence

The privacy follow-up changed only the app privacy manifest and documentation.
It did not change persisted models, schema versions, migration stages, backup
format, Mark behavior, or app navigation. Fluel remains read-only.

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

At that checkpoint, external decisions were the Stally-owned production ad
configuration versus an ads-disabled initial offer, Privacy/Support and contact,
and obtaining the missing distribution signing assets. Two-device sync testing
also needs an explicit test environment and permission to create identifiable
synthetic records there; a fixture-only device launch would not prove sync.

## MHPlatform 1.13 Adoption

The dependency update is committed as `fccbbe9`; the runtime adapter correction
is committed as `2417907`. The following evidence applies to that source.

The published [MHPlatform 1.13 release][mhplatform-release] resolves to
`7c6eb2b9ae9c12ba7f486af136ed85505c5d3975`. Stally's app and library lockfiles
now select the same MHPlatform and transitive runtime versions:

| Dependency | Before | After |
| --- | --- | --- |
| MHPlatform | 1.12.0 | 1.13.0 |
| StoreKitWrapper | 1.2.0 | 1.4.0 |
| GoogleMobileAdsWrapper | 1.3.0 | 1.4.0 |
| Google Mobile Ads SDK | 12.14.0 | 13.9.0 |

MHUI 1.18.0, User Messaging Platform 3.1.0, LicenseList 2.5.0, and
SwiftLintPlugins 0.65.0 remain at their existing app revisions. StallyLibrary
requires MHPlatform 1.13 or later within 1.x and still links only
`MHPlatformCore`; no app runtime or advertising import was added to it.

The release's StoreKit bridge now reports verified purchased product IDs
independently of product metadata, and its startup callback is MainActor
isolated. Runtime verification exposed that Stally was still constructing a
runtime-only bootstrap, which omits StoreKit, advertising, and license
adapters and reports an empty purchased-ID set. The app now uses MHPlatform's
default `configuration:` bootstrap so these existing surfaces receive their
package-owned adapters and verified entitlement updates.

Stally consumes `premiumStatus` on the main actor. Its subscription-state
adapter preserves cached state while the runtime is unknown and does not
inspect product price or catalog availability, so that mapping remains intact.

`StallyAdvertisementSection` now accepts `MHNativeAdSize` directly. The app
no longer duplicates the package's small/medium enum and conversion. SDK size
mapping remains inside MHPlatform. The existing runtime availability condition
still excludes the entire ad section when ads are unconfigured or disabled by
premium; Library and Insights retain their persisted subscription guard.

Production Release native ad requests remain disabled. The example app's local
StoreKit catalog and test IDs were not copied into release configuration. No
production advertising IDs, new purchase products, CloudKit setting, model, or
migration were added.

Verification completed at the changed boundary:

- SwiftPM resolved the library and official `xcodebuild` resolved the app's
  graph; the app's actual checkout state matches the committed pins.
- The first native build retained the old graph. After explicit resolution,
  a stale Google Mobile Ads precompiled module failed; cleaning Stally's
  generated build products and rebuilding through Xcode succeeded.
- The existing iOS 27 library suite passed all 114 tests in 25 suites.
- The retained formatter and repository rules passed after both adapter edits.
- After the native connection closed, official `xcodebuild` built the final
  corrected app in isolated DerivedData. The license plugin required the
  standard SourcePackages layout, and refreshing stale package repository
  caches resolved the pinned revisions without changing the lockfiles.
- A dedicated iOS 27 Simulator loaded the small Google test ad in Library.
  Insights and Settings initial viewports were captured. StoreKit reported
  that no auto-renewable product resolved, and Settings showed an empty
  subscription card; this is not a passed purchase-screen check.
- Mac lock and native transport failure prevented scrolling to the medium ad,
  opening Licenses, and confirming restoration of Stally / My Mac. The last
  confirmed native selection was Stally / iPhone 18 Pro. See the dated
  [UI report](ui-preview-report.md) for captures and exact coverage.
- A new local Release archive of the corrected app succeeded, and
  `codesign --verify --deep --strict` passed. The archive contains Google
  Mobile Ads 13.9.0 and UMP 3.1.0. The app privacy manifest matches source;
  both SDK privacy manifests match the earlier archive's declarations.

The new archive is still development-signed and contains Google's sample
application ID. The earlier App Store export failed on missing distribution
signing assets; no new assets were created, export was not retried, and nothing
was uploaded. StoreKit product resolution and the empty purchase card,
purchase/restore, production advertising and consent, approved Privacy/Support
destinations, real-device CloudKit, and the shipping-toolchain distribution
check remain release gates.

Detailed command logs and dependency review are retained under the ignored
`.build/ci/mhplatform-1.13-adoption/` directory.

## MHUI 1.18 Adoption Review

A subsequent release check confirmed that MHUI 1.18 remains the latest
published version and already matches Stally's `ea9b314` lockfile update.
The current native Item Detail, floating action placement, selective native
form styling, and semantic button styles follow the release's adoption guide.
No additional source migration or dependency update was needed. The existing
Debug build and Release archive above include that exact revision; this
documentation review adds no new runtime or distribution evidence. See the
[current UI adoption report](ui-preview-report.md) for the source comparison.

## MHPlatform 1.15 Adoption

The September 29 package update moves Stally to MHPlatform 1.15.0, which
resolves GoogleMobileAdsWrapper 2.0.0 and Google Mobile Ads 13.10.0. UMP 3.1.0,
LicenseList 2.5.0, and StoreKitWrapper 1.4.0 are unchanged. StallyLibrary now
requires MHPlatform 1.15 or later within 1.x and still links only
`MHPlatformCore`.

- Native ads use `MHNativeAdLayout`: Library requests `.compact` and Insights
  requests `.media`, replacing the removed small/medium sizes. Stally never
  persisted those values, so no preference migration is needed.
- Ad sections are reserved with `canDisplayAds`, which combines ads
  availability with consent.
- The runtime configuration opts into MHPlatform's consent lifecycle. When an ad
  unit is configured and premium status resolves as inactive, the runtime
  requests UMP consent information once per session, presents a required form,
  and starts ads only when UMP reports that ads can be requested. Release builds
  still configure no ad unit, so they perform no consent or ads SDK work.
- Settings shows **Ad Privacy Choices** in About only when UMP reports that
  privacy options are required.
- Stally does not remove unknown standard-defaults keys, so no consent-storage
  allowlist is needed. The preference registry is not adopted because Stally has
  no legacy preference keys to migrate.

A Debug run on the iOS 27 simulator with a temporary, uncommitted EEA debug
geography showed Google's test consent form at launch. After consenting,
Settings showed Ad Privacy Choices, and the row presented the privacy options
form over the Settings sheet. The committed configuration uses no debug
geography.

This closes the source-side consent gap described in the September 14 check.
Stally-owned AdMob app and unit IDs, the AdMob Privacy & messaging
configuration, disclosures, and production consent behavior remain release
gates.

## Next Action

The [optional start design][start-proposal] is accepted and implemented through
Operations, V1-to-V2 migration, v2/v3 backups, screens, and App Intents. Do not
repeat the Stally/Fluel product investigation or ask for the same model
approval. Use [item tracking verification](item-tracking-verification.md) for
completed evidence and the remaining interaction/accessibility checks. Fix only
defects established by those checks; do not extend the integrated feature set.

The offer, page destinations, and GitHub Issues contact are accepted. Continue
with Stally-specific AdMob setup, consent preparation, and the page-publication
review described below; do not ask for the same product choices again. Obtain
the account/signing access and selected synthetic test devices needed for
shipping-build, purchase/restore, and sync verification. Production CloudKit
promotion, real-data operations, external account changes, and publication
remain outside the completed local preparation.

## September 14 Read-Only Distribution Check

These checks refreshed external and local setup without changing account
configuration, installing on a physical device, exporting a build, or publishing.
They do not invalidate the completed integration or its migration evidence.

| Gate | Current observation | Required next action |
| --- | --- | --- |
| Advertising offer | Native ads with monthly ad removal are accepted. Release still has no native ad unit and contains Google's sample app ID | Prepare Stally-owned app/unit IDs using unpublished-app setup; follow the staged first-release sequence below if setup is blocked |
| Advertising consent | No consent update, ad-request consent gate, or privacy-options presentation was found in Stally or the resolved MHPlatform/GoogleMobileAdsWrapper sources | Configure the intended privacy messages and complete the app consent flow before enabling production ad requests |
| Public destinations | Both approved Stally Pages URLs still return HTTP 404. Their tracked source and deployment workflow already exist; GitHub Issues returns HTTP 200 | Review the updated page sources, authorize publication, then verify live content and app navigation |
| Distribution signing | A development identity and development profiles are present; no Apple Distribution identity or matching App Store profile was found | Supply the distribution identity with private key and the matching App Store profile, or authorize the account workflow that creates them |
| Physical devices | The paired phone and tablet were disconnected in the current device inventory | Connect and unlock the selected isolated test device; confirm synthetic-data and cloud-environment boundaries before installation or execution |
| Store product | The monthly offer is accepted; browser access reached App Store Connect sign-in, so product state remains unverified | Sign in to the intended account, inspect the Stally product, and run purchase/restore in the selected test environment |

Google's [UMP integration guidance][ump-privacy] requires refreshing consent
information, presenting required messages, gating ad requests with consent
availability, and exposing privacy options when required. Linking the UMP
framework does not implement these steps. This source review identifies a
precondition for an advertising release; it does not enable advertising or
authorize a shared-package change.

The policy and App Store privacy answers must match the chosen shipped
configuration. Google's [SDK disclosure guidance][admob-disclosure] lists
possible IP/location, diagnostic, identifier, advertising, and interaction
data use. Do not claim that an advertising build collects no data merely
because Stally stores its domain records locally or in the user's iCloud.
Final manifest, consent, and privacy answers still require the shipping
artifact and intended account settings.

Raw identity/profile and device inventory evidence stays in ignored local
artifacts under `.build/ci/stally-readiness-continuation-20260914/`. It must not
be copied into public documentation. No signing assets were created, private
keys exported, production CloudKit changed, or real collection opened.

## September 14 Integration Release Archive

After native Simulator verification and restoration of Xcode's original
selection, official `xcodebuild archive` built the current `Stally` scheme at
`a9c61e6` with Release configuration and the generic iOS destination. The native
build capability exposes no archive action, so this bounded CLI step supplies
the missing artifact check. Existing resolved package versions and existing
development signing were used; provisioning updates were not enabled.

| Artifact check | Result |
| --- | --- |
| Build | Archive succeeded with Xcode 27.0 `27A266a` and `iphoneos27.0` |
| Signature | `codesign --verify --deep --strict` passed; development task access and development push environment remain |
| App privacy manifest | Byte-identical to the checked-in UserDefaults declaration |
| Dependency manifests | Google Mobile Ads 13.9.0 and User Messaging Platform 3.1.0 frameworks include their privacy manifests |
| Debug isolation | No preview scenario/route/tracking arguments or preview-host/configuration markers found in the app binary; no fixture stores or backup files bundled |
| Advertising configuration | Google's sample app ID remains in Info.plist; Release native ad requests remain disabled by source configuration |

This refresh replaces the old pre-integration archive as local compile/artifact
evidence. It does not prove StoreKit transactions, actual production ads or
consent, public URL content, real-device sync, shipping-toolchain acceptance,
or distribution signing. The archived app was not launched, exported, uploaded,
or installed on a physical device. No production CloudKit setting changed.

The archive, build log, signature result, private entitlement output, and
inspection JSON are retained in ignored
`.build/ci/stally-readiness-continuation-20260914/`. These private operational
artifacts are not repository publication inputs.

## Accepted First-Release Sequence

The owner retained native advertising and monthly ad removal, following
Incomes, with flexibility for first-release setup timing. This is not a change
to a permanently free, ads-disabled product. Incomes remains a read-only
reference; its production app/unit identifiers must never be copied to Stally.

1. **Prepare the app and unit:** Google's [unpublished-app setup][admob-setup]
   allows adding an iOS app before its store listing is public. After adding
   Stally, use the [native-unit setup][admob-native] to obtain its own app ID
   and ad unit ID. An absent public listing alone does not establish that IDs
   cannot be prepared. Account access and actual setup success remain unverified.
2. **Prepare the advertising build:** replace sample identifiers only with
   verified Stally identifiers, complete consent handling, and verify test-device
   ads and StoreKit purchase/restore. Reconcile the privacy page and App Store
   disclosures with that artifact before production ad requests are enabled.
3. **Complete the public prerequisites:** publish the approved product/support
   and privacy pages, set the store marketing URL, and confirm the publisher
   entry used by app-ads.txt. Google's [crawler documentation][app-ads-setup]
   uses the website hostname, so the relevant file is
   `https://muhiro12.github.io/app-ads.txt`, not a file under `/Stally/`.
   A read-only check returned HTTP 200 for the existing root file and found
   the publisher used by Incomes. Confirm that Stally uses that same AdMob
   account before relying on the entry; no website-root edit was made.
4. **Link after publication:** Google's [readiness process][admob-readiness]
   requires a public supported-store listing and its AdMob link. Verify
   app-ads.txt and the actual readiness status after the first publication.
   Limited or absent fill during this phase is separate from obtaining IDs
   and must not be treated as a compile-time configuration failure.
5. **If account setup really blocks the first release:** retain the planned
   offer but prepare a temporary candidate with production ads disabled and
   ad-removal sales deferred together. Remove test IDs and verify startup,
   purchase presentation, and the final policy for that candidate. Activate
   ads and the offer in a later verified release. This fallback is conditional;
   no monetization, signing, or account configuration was changed in this task.

The shared runtime now owns the consent startup gate and privacy-options
presentation, and Stally adopts them; see
[MHPlatform 1.15 Adoption](#mhplatform-115-adoption). Configure AdMob Privacy &
messaging for the Stally app before enabling production ads. Do not copy SDK
startup into a Stally screen or assume that Incomes already supplies consent.

## Accepted Public Pages and Support

The approved destinations are
[Stally Support](https://muhiro12.github.io/Stally/) and
[Stally Privacy](https://muhiro12.github.io/Stally/privacy.html), with
[GitHub Issues](https://github.com/muhiro12/Stally/issues) as the contact channel.
Both Pages URLs still returned HTTP 404 in the latest check; Issues returned
HTTP 200. No message or issue was submitted.

Stally already had `.github/pages/index.md`, `.github/pages/privacy.md`, and
`.github/workflows/deploy-pages.yml`; the earlier publication gap was not an
absence of source files. The existing workflow follows the same Jekyll Pages
structure as Incomes. The local sources now describe optional starts, non-Mark
items, Archive continuity, independent iCloud access, backup handling, and the
public nature of Issues. No new hosting stack or workflow was added.

The Settings About section now has a native Support link, localized as
`Support` / `サポート`, beside Privacy Policy and Licenses. No account data,
Item model, Operations, package pin, or monetization behavior changed.
Incomes currently lists X as its privacy contact; Stally keeps the explicitly
selected GitHub Issues contact rather than changing it to match that detail.

The page source still accurately describes disabled production advertising.
It must be updated for the actual advertising configuration before advertising
is enabled. This preparation does not claim consent messages are implemented.
Publishing the Pages workflow, pushing commits, editing account settings, or
releasing an app remains a separate action from these local changes.

### Local Preparation Checks

The native Stally build passed with zero errors and extracted app-owned
App Intents metadata. Formatter, SwiftLint/repository boundaries, all six
English/Japanese catalogs, and patch whitespace checks passed. The only new
catalog entry is `Support` / `サポート`; the existing stale `Actions` key and
intentional product-name source copies remain. No domain, schema, backup, or
App Intent behavior changed, so unchanged library suites were not rerun.

The page sources have valid front matter, no unfinished placeholders, and
resolving local links, including the Jekyll `privacy.html` output mapping.
Jekyll is not installed in the local environment, so the hosted Jekyll build
and live page-content verification remain unexecuted. No deployment was run.
The earlier private bilingual brainstorming draft is marked superseded by the
accepted choices and the current tracked page sources.

In the isolated Simulator, actual scrolling reached the English About rows and
Support opened the approved URL in Safari. The page returned the expected
pre-publication 404, so this proves destination routing, not working page content.
The Safari return automation unexpectedly cold-launched Stally without preview
arguments: logs show a new local container and an empty Library. That process
was immediately stopped without further screen actions. No real collection or
CloudKit startup was observed, but local-store creation cannot be excluded.
The isolated store was left untouched. Same-process return remains unverified;
no app behavior was changed to work around the tool's launch behavior.

Fresh explicit preview launch logs were checked before the subsequent Japanese
and English maximum-text About inspection. Both localized screens were readable
after actual scrolling. The [UI report](ui-preview-report.md) retains the
captures and the exact cold-launch limitation. Support is committed as
`2c5b790`; the page-source update is `329dc5a`.

The audit app/session were stopped, Simulator display settings restored, and
only the dedicated Simulator shut down. Xcode's original scheme/destination
was restored and confirmed. The full runtime review found no fatal, crash, or
exception output; it retains the local-container incident rather than claiming
all launches were in memory.

Current preparation logs and URL responses remain in ignored
`.build/ci/stally-launch-preparation-20260914/`.

[ump-privacy]: https://developers.google.com/admob/ios/privacy

[admob-disclosure]: https://developers.google.com/admob/ios/privacy/data-disclosure

[admob-setup]: https://support.google.com/admob/answer/9989980?hl=en

[admob-native]: https://support.google.com/admob/answer/7187428?hl=en

[admob-readiness]: https://support.google.com/admob/answer/10564477?hl=en

[app-ads-setup]: https://support.google.com/admob/answer/9363762?hl=en

[reasons]: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api

[mhplatform-release]: https://github.com/muhiro12/MHPlatform/releases/tag/1.13

[start-proposal]: item-start-and-elapsed-time-proposal.md
