# Stally

Stally is a pre-release iPhone and iPad app for keeping a quiet record of the
things and places that matter to you. Record everyday choices with Marks,
look back on time together, or keep both kinds of knowledge for the same Item.

## Branches and release review

Use `develop` for daily development. Keep agent review and the documented
verification checks in the daily workflow. `main` tracks the released baseline.
Before shipping, review `main...develop` and record the exact candidate commit.
After publication, merge that released commit into `main`; do not include later
work added to `develop`. Preserve commit ancestry so the next release comparison
starts from the previous released candidate.

There is no released baseline before the first release. Until then, `main` is
only a provisional snapshot, and the first release requires review of the full
candidate rather than only the difference from that snapshot.

## Development

Start with the [first-release contracts](docs/first-release-contract-summary.md).
Use the [product behavior](docs/product-behavior-design.md) to derive Operations
and the app and system interfaces that call them.
Apply the [data portability policy](docs/data-portability-policy.md) when deciding
export/import scope, user explanations, or historical compatibility costs.

| Work | Entry point |
| --- | --- |
| Persistence and record ownership | [Five-model schema](docs/model-schema-design.md), [native sync](docs/sync-lifecycle-design.md) |
| Editing, photos and time together | [Item editing](docs/item-context-implementation.md), [period readings](docs/period-readings-design.md) |
| Import, export and conflicts | [File format](docs/export-file-format-design.md), [identity and review](docs/import-identity-design.md) |
| Published interfaces | [Identifiers](docs/saved-key-and-identifier-design.md), [App Intent inventory](docs/app-intents-publication-review.md) |
| Implementation and release work | [Operations and remaining checks](docs/remaining-capabilities-implementation.md), [distribution readiness](docs/release-readiness.md) |
| Local development | [DEBUG store and samples](docs/fixture-architecture.md), [diagnostics](docs/diagnostics-access.md), [update policy](docs/remote-update.md) |

`Stally/` contains the SwiftUI app and App Intent adapters. `StallyLibrary/`
owns the SwiftData schema and shared Operations. MHPlatform 1.21.0 supplies
strict HTTPS routing, bounded package I/O and guarded writes. MHUI supplies
shared native List and Form presentation. The app composes MHAppRuntime,
MHAppRuntimeDefaults and MHAppRuntimeLicenses without the advertising bundle.

Production opens the same App Group store with optional native CloudKit
mirroring, selected at launch from the subscription state and sync preference.
A failed open surfaces the error. DEBUG can select an isolated local store with sample
records before opening a container. Incompatible prerelease test installations
can be reinstalled. The first-release schema and portable format define the
compatibility baseline for future published versions.

## Build and Test

Development uses Xcode 27.2. The project uses the JSON `project.xcproj`
configuration, and all declared app/library deployment targets are 27.2. See the
[conversion and qualification record](docs/project-format-qualification.md)
for the original comparison, shared-verifier compatibility, and exact rollback.
Historical trial results do not replace current-source verification below or
qualify a beta toolchain for release.

Use the Xcode-native integration available in the environment for app build,
run, runtime-log, Preview, live UI, and screenshot evidence. Resolve current
actions from its runtime inventory.

Before changing Xcode selection, record the original scheme and destination,
switch only to discovered values, and end sessions or runs started solely for
verification. Restore the original scheme first, rediscover its destinations,
restore the original destination, and confirm the selection. Report failed
restoration.

Choose the smallest evidence set proving the changed boundary:

- Shared-library logic, models, resources, or tests: run
  `bash ci_scripts/tasks/test_stally_library.sh`. Set
  `CI_IOS_SIMULATOR_DESTINATION` to a discovered iOS 27.2 Simulator rather than
  relying on the script's default device name.
- Public APIs, `*Operations`, persistence, wire, or adapter contracts: also
  build `Stally.xcodeproj`, scheme `Stally`, on a discovered iOS 27.2 Simulator.
- Swift or Xcode project changes: build the `Stally` app scheme.
- App Intents: confirm app-build metadata extraction and catalog-backed intent
  strings, and test the underlying library behavior with unit tests. These
  checks do not prove out-of-process intent execution, spoken Siri, or
  locked-device behavior; obtain separate manual evidence when needed.
- Runtime persistence, CloudKit, or monetization wiring: run the app and review
  relevant SwiftData, CloudKit, ModelContainer, App Intents, StoreKit, Google
  Mobile Ads, fatal, crash, and exception logs.
- Visible UI: use targeted Preview, manual smoke review, or screenshots when
  the changed risk warrants it. Do not introduce an automated UI test runner.
  Launch success alone does not prove visible behavior. Use the library's
  disk-store tests for Mark and Period edits, sample insertion refusal, and
  persistence after reopen. Revisit the live flow when the control wiring,
  displayed counts, or app startup path changes.
- Localization: audit catalogs for `en,ja`, confirm app resource processing,
  and capture the affected English/Japanese surfaces. When the
  `string-catalog-maintainer` skill is available, resolve its audit script from
  the loaded skill package and pass `--project-root . --required-locales en,ja
  --format markdown`; do not assume a provider-specific skill installation path.

After Swift edits, run the explicit formatter. Run retained rules when the
changed boundary affects their checks:

```sh
bash ci_scripts/tasks/format_swift.sh
bash ci_scripts/tasks/check_repository_rules.sh
```

The rules entry point runs repository-managed SwiftLint and architecture checks.
SwiftLint comes from the project-declared `SwiftLintPlugins` dependency.
Follow the repository SwiftLint configuration and existing Swift source style.
Markdown follows the [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md).

`bash ci_scripts/tasks/verify_task_completion.sh` is a compatibility aggregate
of retained rules, library tests, and whitespace checks. It does not replace
app build or runtime evidence. `StallyLibrary` package builds are available
through the native package scheme; the library-test script drives package tests.
Xcode Cloud owns formal CI builds, tests, and archives.

Release UI smoke auditing remains a separate, non-destructive pass. Do not
erase Simulator data, reset containers, or add test targets solely for an audit
unless explicitly requested. Keep UI review reports separate from preserved
product-intent documents.

## Optional Local Push Verification

`ci_scripts/push_verification.json` declares the `Stally` app build, the complete
`StallyLibraryTests` unit-test plan, and retained rules. Automated UI tests and
out-of-process AppIntentsTesting UI runners are not part of this contract.
The optional local hook invokes
`python3 ci_scripts/lib/agent_verification.py push <remote-name> <remote-location>`.
It requires the installed `ci-verify-and-summarize` skill; set
`CI_VERIFICATION_SKILL` for a non-default installation. Missing helpers or
unsupported versions leave verification incomplete. Ordinary builds, rules,
and Xcode Cloud do not require the skill.

Set `CI_VERIFICATION_EVIDENCE=1` when capturing retained rules for a receipt.
This binds strict SwiftLint execution to the registered project artifact, tracked
package pin, and complete tracked Swift input list. Source searches distinguish
no match from execution failure. The hook matches private `.git/push-verification`
evidence without rerunning QA or scanners. Follow the skill's
[receipt procedure](https://github.com/muhiro12/agent-skills/blob/main/ci-verify-and-summarize/references/push-verification.md)
for complete native results, zero diagnostics, full outgoing-history scan/review,
compatibility checks, and receipt refresh. Activation and publication are separate.

## Support and Privacy

- [Support](https://muhiro12.github.io/Stally/)
- [Privacy Policy](https://muhiro12.github.io/Stally/privacy.html)
