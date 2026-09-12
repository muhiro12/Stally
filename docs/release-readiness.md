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
Model integration is held by the
[Fluel integration assessment](fluel-integration-assessment.md).

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
   contains no test advertising identifiers. Do not enable production ads
   merely because the SDK links successfully.
5. **Privacy and support:** the Settings Privacy Policy destination returned
   HTTP 404 on September 13. Publish or select the approved policy and verify
   the actual link before release. The inspected About section contains
   Privacy Policy and Licenses but no support entry point. Confirm the support
   destination and store metadata, and audit the distribution artifact's
   privacy manifests and dependency licenses against actual enabled behavior.
6. **Distribution:** produce the intended signed archive and export with the
   shipping toolchain, check embedded entitlements and identifiers, and verify
   the distributed build. Local Debug builds and library tests do not prove
   App Store metadata, signing, production CloudKit, or purchase readiness.

The privacy destination inspected was the
[Stally privacy policy](https://muhiro12.github.io/Stally/privacy.html).
Its content and approval remain unresolved; an alternative URL was not guessed.

## Next Decision

Fluel's assessment and domain contract are complete and reconciled in the
host-side assessment. Confirm real-data requirements and the accepted combined
journeys before any model decision. In parallel, address the concrete release
configuration and external evidence gaps above. Keep each correction local
to its demonstrated owner and verify the affected library, adapter, runtime,
or distribution boundary.
