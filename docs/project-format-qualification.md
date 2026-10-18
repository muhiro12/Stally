# Xcode Project Format Qualification

## Outcome

The October 18, 2026 local trial for
[issue #23](https://github.com/muhiro12/Stally/issues/23) confirmed that Xcode
can convert Stally to `project.xcproj` without changing effective app settings.
The JSON configuration is now retained as a local, unpushed implementation.
Final qualification remains deferred: the installed shared push-verification
helpers still require `project.pbxproj` and its object model.

Commit `12c180a` isolates the supported conversion. Commit `304eda1` restored
the original configuration and recorded the trial. Commit `fc923f3` reapplies
exactly the same converter output, following the decision to retain
implementation while shared-tooling verification is pending. The Issue remains
unfinished. No source was pushed, no Cloud build was triggered, and no archive
was produced by this work.

## Local Implementation and Publication Boundary

The October 18 hook inspection found active `pre-push` checks, with no active
`pre-commit` or `commit-msg` checks, in Stally, Cookle, and Incomes. The hooks
do not prevent source changes or local commits. Restoring the old format was a
temporary implementation decision, not a hook requirement.

The existing hook remains enabled and unchanged. Local staging does not assert
that the final verification contract passed or that the Issue is complete.
Shared-tooling work is handled separately; Stally retains the candidate and
the handoff below until that prerequisite is ready. No new app build, library
or system test run, archive, or publication receipt was produced for this
reapplication. The trial results below remain historical evidence, not a
current-commit push receipt.

## Toolchain Requirements

[Apple's conversion guidance][conversion] documents JSON conversion in
Xcode 27.2 and later, and compatibility with both formats in Xcode 27 and later.
Xcode 27.0 is the documented minimum reader; it was not installed for this
trial.
Conversion support does not establish release-toolchain qualification.

The selected local Xcode was 27.2 beta, build `27B5038j`. The other installed
toolchain was Xcode 27.1, build `27A9275`. No global developer-directory
setting, SDK requirement, deployment target, or Cloud workflow was changed.

The migration sources were Apple's guide and the installed `xcodebuild` help.
No skill dedicated to JSON project migration was included in the 11 skills
exported from this Xcode build on October 18. This does not establish which
skills other Xcode versions or separate distributions provide.

## Dependency Audit

- `ci_scripts/tasks/check_environment.sh` already discovers one authoritative
  `project.pbxproj` or `.xcproj` file and inspects it with `plutil`. It accepted
  the actual converted JSON, including Xcode's trailing commas. No change was
  required.
- `ci_scripts/lib/swiftlint.sh` resolves packages through the `.xcodeproj`
  bundle and runs the registered SwiftLint binary. Ordinary lint and boundary
  checks passed with the JSON project.
- The installed `ci-verify-and-summarize` skill's
  `scripts/swiftlint_evidence.py` hardcodes `project.pbxproj` and reads
  `objects` / `XCRemoteSwiftPackageReference`. JSON stores requirements under
  `packages`. Both file selection and requirement parsing need support for the
  new format.
- That skill's `scripts/check_push_verification.py` also hashes the hardcoded
  `project.pbxproj` from the evidence source commit. The verifier must bind the
  authoritative configuration at that commit, including its actual path and
  contents, rather than inspecting a different working-tree file.
- `ci_scripts/lib/agent_verification.py` delegates to those shared helpers; it
  does not own a project-format parser. Fix the canonical shared helpers rather
  than copying their implementation or weakening the hook in Stally.
- Shared schemes, package pins, the Cloud manifest, and other repository
  scripts refer to the project bundle or package schemes. The tracked-source
  audit found no additional direct dependency on the old filename or syntax.

The failure was reproduced with the converted project:

```sh
CI_VERIFICATION_EVIDENCE=1 bash ci_scripts/tasks/check_repository_rules.sh
```

The helper exited with status 2 when it tried to read the removed
`Stally.xcodeproj/project.pbxproj`. The same command passed after restoration.
Ordinary checks passing therefore do not establish push-evidence compatibility.

## Converter Run Notes for the Next Adopter

The supported conversion completed on both the disposable copy and the actual
Stally project. No converter failure was confirmed. Keep the following
observations separate from app behavior and shared-verifier compatibility:

- **Format selector:** the tested JSON selector was `Xcode Project`; the
  round-trip selector was `Xcode 27.0`. Check the command below and the selected
  Xcode's help rather than assuming the UI label is a CLI argument.
- **JSON reader compatibility:** the generated file contains trailing commas.
  A later read-only check rejected the raw output with Python's strict
  `json.loads` at line 6, while `plutil -convert json -o -` followed by the same
  reader succeeded. This parser mismatch does not establish a corrupt Xcode
  project. Use a reader supporting the actual format or native normalization
  before strict JSON parsing; do not remove commas with a text substitution.
- **Comparison scope:** conversion regenerated internal identifiers and
  reorganized some declarations. The serializer-only differences listed below
  were reviewed for Stally. Do not copy that normalization list into another
  app without reviewing its meaning, or sort executable build phases and
  framework links merely to make a comparison pass.
- **Execution context:** a restricted shell emitted cache-access and
  CoreSimulator-connection diagnostics during disposable-copy probing. The
  successful conversion used the approved Xcode execution context. Classify
  permission/service errors separately from format errors; this trial needed
  no global developer-directory change or Simulator data reset.
- **Shell reporting:** a disposable-copy wrapper assigned to zsh's read-only
  `status` variable after the JSON file had been written. The wrapper failed;
  that was not evidence that conversion failed. Capture the exit code with a
  task-specific name such as `conversion_result`, and inspect the output before
  retrying an ambiguous invocation.
- **Verification tooling:** conversion does not update repository-owned checks
  or shared evidence adapters. Audit their filename and syntax dependencies
  independently. The reproducible shared-tool failure is recorded above.

## Semantic Comparison

Xcode's supported converter was first exercised on a disposable project copy,
then on the real project. Their JSON outputs were identical. The conversion
command exposed by this Xcode's `xcodebuild -help` was:

```sh
xcodebuild -project Stally.xcodeproj -convert-project 'Xcode Project'
```

A disposable JSON copy was converted back using `-convert-project 'Xcode 27.0'`.
The original and round-trip property-list graphs each contained 38 objects.
After resolving object references, comparison preserved configuration values,
targets and products, build phases, package requirements, synchronized target
membership and its exclusions, resources, signing and entitlement settings,
deployment targets, and the UI-test host relationship.

The comparison accounted explicitly for serializer-only differences:

- Internal object identifiers were regenerated; target and product identifiers
  used by the existing schemes were preserved.
- Target creation-tool metadata was omitted and the preferred property-list
  serializer version became 110 rather than 77. The original object version
  was already 110.
- The `StallyLibrary` navigator reference omitted its inferred `wrapper` file
  type. Its local package reference and linked product were retained.
- Known-region and package-product declaration ordering was normalized;
  executable build-phase and framework-link ordering was preserved.

Xcode-native before/after readings also compared all evaluated build settings
for both targets on the same My Mac destination: 571 app settings and 572
UI-test settings matched with zero differences. Schemes, package pins, the Cloud
manifest, application sources, and stored-data contracts were unchanged.

## Original Trial Verification Evidence

- Xcode 27.2 opened the converted project and discovered `Stally`,
  `StallyLibrary`, and `StallySystemTests`.
- Xcode 27.1 successfully read the converted project using
  `xcodebuild -list -json`: both targets, both Debug/Release configurations,
  and all three schemes
  were present. This was discovery evidence, not a 27.1 build or test result.
- The app built before and after conversion on the dedicated iPhone 17
  Simulator using Xcode 27.2, with no reported build errors.
- The converted project's `StallyLibrary` test result reported Passed:
  184 tests, zero failures, skips, expected failures, or runtime warnings on
  iOS 27.2 Simulator. The native tool response timed out after 300 seconds;
  the completed result bundle was decoded separately after stopping the owned
  test process. The package link emitted a macOS/iOS sysroot warning, so this
  is not a zero-build-diagnostics receipt.
- Ordinary repository rules passed with JSON. Both repository Python tests
  passed. Evidence-mode rules failed with JSON and passed with the restored
  property-list project, reproducing and isolating the shared-tool dependency.
- The existing app Archive action still selected Release and included the app
  for archiving. No local archive, 27.1 build, system UI-test run, or Xcode
  Cloud candidate run was performed. Those checks remain open.

The original scheme and destination were restored, the owned test process
was stopped, and the workspace opened for this trial was closed.

The retained native summary reports 184 overall test cases and 224 passes at
the device/configuration level. Its statistics identify 11 dynamically
parameterized tests with 51 runs. These are different aggregation levels, not
two independent suites to add together. Future verification adapters should
preserve the chosen counting level and compare like-for-like native fields.
The response timeout, SDK warning, and result-reader cache permissions are
execution/evidence observations; none was established as a JSON-converter bug.

## Shared-Tooling Handoff

Collect migration experience in Stally, then Cookle, then Incomes, and use that
combined evidence for the subsequent verification-skill update. Shared-skill
implementation remains a separate task. This repository supplies the following
reproducible requirements rather than changing the shared skill now:

1. With the JSON project present, run the evidence-mode command in the
   dependency audit. The current adapter fails while reading the removed
   `project.pbxproj`. Ordinary lint passing does not resolve that failure.
2. In `swiftlint_evidence.py`, select exactly one authoritative configuration.
   Support the old property-list package references and JSON `packages` while
   preserving canonical remote, version-range, artifact, and pin validation.
   Xcode's JSON output contains trailing commas; the original trial confirmed
   that native `plutil` reads it.
3. In `check_push_verification.py`, resolve the configuration from the evidence
   source commit and bind its path and content hash. Reject missing, ambiguous,
   unsupported, or tampered configurations; do not trust an arbitrary proof
   path or substitute the current working tree for the captured source.
4. Retain compatible adapter/proof contracts, or update consumers explicitly
   if those contracts change. Stally's delegate checks `CHECKER_API_VERSION`.
   Test both formats and negative cases, including configuration ambiguity,
   changed dependency requirements, mismatched source hashes, and invalid pins.
5. Account for adopter-local checks. Cookle still has old-filename dependencies
   in environment, test-posture, package-boundary, and project-link checks.
   Incomes retains local evidence/matcher implementations plus environment
   and MHPlatform-boundary parsing. Updating the shared skill alone does not
   establish that those repository-local paths support JSON.

Only those adopter files and hooks were inspected; their full verification
was not run and their source was not changed by this work. Hook disabling or
bypassing is not needed to stage the implementations locally.

At Cookle and Incomes, append the actual toolchain and command result, reviewed
configuration differences, app-local parser failures, and deferred checks.
Distinguish repeated cross-app cases from adopter-specific exceptions before
incorporating them into the shared verification skill. Preserve backward
compatibility with consumers still using the property-list format.

## Remaining Verification and Rollback

After shared tooling is ready, confirm adapter compatibility, compare current
settings and project relationships, and complete the affected build/test and
archive checks with explicitly selected toolchains. Produce fresh evidence
for the current source and run the existing publication gate before any
separately authorized push.
Qualify the actual Xcode Cloud path when a candidate is available; do not treat
local success as a Cloud or distribution result. Duo qualification stays
independent of this migration.

To roll back the current candidate, revert its reapplication commit and review
the associated documentation changes. For an uncommitted conversion, restore
the removed tracked property-list file and remove only the generated JSON file.
Keep exactly one authoritative configuration. A generated round-trip file is
useful for comparison, but Git restoration preserves the exact original file.

[conversion]: https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format
