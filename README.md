# Stally

Stally is a pre-release iPhone and iPad app for keeping a quiet record of the
things and places that matter to you. Record everyday choices with Marks,
look back on time together, or keep both kinds of knowledge for the same Item.

The repository is in rebuild implementation. The legacy implementation was
removed after product intent was preserved under `docs/`, and the current tree
now contains a fresh Apple-platform app project plus a local library package:

- `Stally.xcodeproj`, with the `Stally` app target and `Stally` scheme.
- `Stally/`, a SwiftUI sidebar/list/detail app for collections, search, Tags,
  Item state, Mark and Period editing, startup recovery, and shared runtime wiring.
- `StallyLibrary/`, a local Swift package for the five-model SwiftData schema,
  App Group/CloudKit configuration, domain Operations, and localized errors.
- `StallyLibrary/Tests/`, Swift Testing coverage for the integrated foundation,
  plus preserved historical fixture resources.
- `ci_scripts/`, repository-managed lint, rule, and library-test entrypoints.
- `Stally.xcodeproj/xcshareddata/xcodecloud/manifest.json`, an Xcode Cloud
  manifest.

The current implementation is intentionally small. It is not a restoration of
the removed legacy architecture, navigation, persistence model, or feature set.

## Rebuild Documentation

Start with the documentation relevant to the changed boundary:

| Decision | Current entry point |
| --- | --- |
| Accepted first-release contract direction and implementation handoff | [Contract summary](docs/first-release-contract-summary.md), [consolidated Swift schema](docs/model-schema-design.md), [design history](docs/core-record-design.md) |
| Product capabilities and behavior after the foundation | [Product behavior design](docs/product-behavior-design.md): owner-directed design order, contract consequences, and proposals |
| Product purpose, domain, workflows, and language | [Product brief](docs/product-brief.md), [purpose](docs/product-purpose.md), [preserved concepts](docs/preserved-concepts.md), [domain](docs/domain-concepts.md), [workflows](docs/user-workflows.md), [experience principles](docs/user-experience-principles.md), [language](docs/product-language.md) |
| Owner-directed baseline and scope | [Rebuild implementation direction](docs/rebuild-implementation-direction.md), [implementation principles](docs/rebuild-implementation-principles.md) |
| Live SwiftData read ownership and value lifetimes | [App data flow](docs/swiftdata-app-data-flow.md) |
| Durable writes and cross-surface use cases | [Domain Operations](docs/domain-operations.md) |
| Shared update policy, offline behavior, and protected writes | [Remote update control](docs/remote-update.md) |
| Current persistence baseline before the redesign | [First release data model](docs/first-release-data-model.md) |
| Publication identities, stored preferences, and support lifetimes | [Publication contracts](docs/publication-contracts.md), [saved-key and identifier review](docs/saved-key-and-identifier-design.md) |
| Accepted export/import direction and current implementation | [File design](docs/export-file-format-design.md), [import identity](docs/import-identity-design.md), [older portable baseline](docs/portable-data-contract.md) |
| App Intents, entity identity, replay, and Widget/Watch scope | [Current system interface](docs/system-interface-contract.md), [redesign direction and contract boundary](docs/app-intents-contract-design.md) |
| Derived Item search, index recovery, and synthetic isolation | [Spotlight indexing](docs/spotlight-indexing.md) |
| Samples, DEBUG profiles, frozen migration evidence, and scale | [Fixture architecture](docs/fixture-architecture.md), [original V1 fixtures](StallyLibrary/Tests/Default/Fixtures/V1/README.md), [current interchange fixtures](StallyLibrary/Tests/Default/Fixtures/Interchange/README.md) |
| Earlier implemented single-start behavior | [Item start and elapsed time](docs/item-start-and-elapsed-time-proposal.md) |
| Current unified interface | [Library interface implementation](docs/library-interface-implementation.md) |
| Earlier UI and integration evidence | [Tracking verification](docs/item-tracking-verification.md), [combined interface](docs/combined-interface-design.md), [near-term brief](docs/near-term-development-brief.md) |
| Legacy extraction evidence | [Rebuild handoff](docs/rebuild-handoff.md) |

These documents describe what Stally is, why it exists, which concepts must
survive, and which legacy implementation details were intentionally discarded.
The October 27 [contract summary](docs/first-release-contract-summary.md) is the
entry point for accepted redesign decisions, deferred feature choices, and
required implementation evidence. The [core record design](docs/core-record-design.md)
preserves their history. These decisions supersede earlier constraints where
stated, and now guide the integrated foundation described below.
`docs/rebuild-implementation-direction.md` separately records explicit rebuild
direction that did not come from the removed legacy source.

Some documents preserve the phase-boundary language from when they were
created. This README describes the current repository state. The selected
first-release model and accepted implementation choices govern current model
work; earlier integration assessments and their approval gates are historical
evidence. Do not infer architecture, persistence, routes, or future features
from removed legacy implementation details. Keep product-intent documents in
their existing English voice and distinguish extracted evidence from later
owner-directed decisions.

The owner's October 28 clarification establishes the next design order:
accepted foundational contracts, product capabilities and behavior, Operations,
then app/system adapters. Current Operations and temporary UI are implementation
evidence, not an approved feature specification. Start new feature design from
the [behavior discussion](docs/product-behavior-design.md). Older product
documents retain legacy requirements such as mandatory categories, one Mark per
day, and whole-library replacement; those do not override the accepted contracts
or require restoration of the old product surface. New behavior proposals remain
proposals until selected.

## Current Repository State

The first-release foundation now implements the five-model schema, shared
App Group persistence, Item/Mark/Period/Tag Operations, and Library/detail
adapters. Read [foundation implementation](docs/first-release-foundation-implementation.md)
for schema 3.0.0 and the explicit development-store guard. The subsequent
[unified library interface](docs/library-interface-implementation.md) adds the
sidebar/list/detail experience, search, Tag controls, and calendar-based editors.
Historical documentation and old fixtures are retained as evidence, not as
constraints overriding the accepted redesign.

The app and library require OS 27.2 or later. Development uses Xcode 27.2;
match distribution verification to the candidate's actual Xcode Cloud build.
MHPlatform owns shared runtime and remote-update infrastructure; MHUI owns
shared presentation, typography, and spacing through its native List/Form
integration. Product Operations and tests remain in StallyLibrary.

The old category/single-start/day-toggle adapters, flat backup codec, Review,
Insights, search projections, sample profiles, and old Intent adapters have been
retired. Their redesigned features remain first-release work as applicable.
The new package import/export, full Intent coverage, and Universal Links are
not implemented by this foundation step. Photo storage is implemented;
photo ingestion and presentation are not. DEBUG launches now use isolated local
development records; see [development setup](docs/fixture-architecture.md#current-development-setup)
for initial seeding, empty-store opt-out, and explicit shared-store verification.
The sidebar [Debug screen](docs/diagnostics-access.md) is available in all
builds; its development controls remain DEBUG-only.
No period readings have been accepted or implemented by implication.

Startup never automatically deletes a development store or substitutes an empty
library on error. DEBUG local storage is selected before opening a container;
it is not a fallback for shared-store failure. When opening the shared store,
the old development locations cause an explanatory stop until reviewed recovery
is implemented. No shipped-user compatibility is claimed for
unreleased V1/V2 stores or flat files. Never open the checked-in V1 fixtures for
writing or regenerate them; any future recovery test must use disposable copies
including external photo storage and disable CloudKit.

Verification centers on library unit tests and the app consumer build. Do not
add or run automated UI test suites. Use targeted native manual interaction for
runtime evidence. Simulator App Group access and local disk persistence do not
prove signed-device provisioning, real-device CloudKit convergence, or deployed
production-schema compatibility. Support/privacy sources remain under
`.github/pages/`; their manually dispatched deployment is separate from commits.

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
  Launch success alone does not prove visible behavior.
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
