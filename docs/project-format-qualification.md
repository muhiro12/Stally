# Xcode Project Format Qualification

## Outcome

The October 18, 2026 local trial for
[issue #23](https://github.com/muhiro12/Stally/issues/23) confirmed that Xcode
can convert Stally to `project.xcproj` without changing effective app settings.
The JSON configuration is now retained as a local, unpushed implementation.
The shared verification helpers now support both project formats. A follow-up
on the retained JSON candidate passed evidence-mode repository rules through
the existing adapter, plus lint matching against its source commit with the
updated shared checker. The original shared-tooling blocker is resolved;
final app/test qualification and publication evidence remain pending.

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
uses the updated helpers without changing its adapter or hook. No new app
build, library or system test run, archive, or publication receipt was produced
for the reapplication or shared-tooling follow-up. The trial results below
remain historical evidence, not a current-commit push receipt.

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
The updated shared verification skill now includes a
[project-format guide][shared-guide] incorporating the adopter observations;
that guide is separate from the skills exported by Xcode.

## Initial Dependency Audit

The following findings describe the original trial, before the shared helpers
were updated. Their resolved state is recorded in the follow-up below.

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
Ordinary checks passing did not establish push-evidence compatibility. The
follow-up reproduced the same command successfully without restoring the old
format.

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
  independently. The original shared-tool failure above was resolved in the
  follow-up; Stally did not need its own copy of the shared parser.

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

## Shared-Tooling Follow-up

The October 18 Incomes handoff incorporated Stally, Cookle, and Incomes
observations into the shared verification skill. The installed skill contains
`4fdbbcc` (both-format SwiftLint evidence), `8c9b934` (source-commit matching),
and `f71f613` (format and recovery guidance). Its implementation is maintained
separately; no parser was copied into Stally and no hook was changed.

The updated adapters:

- Select exactly one `project.pbxproj` or `project.xcproj`, rejecting missing,
  ambiguous, or symlinked configurations. Normalize with native `plutil` and
  parse the object model appropriate to the selected filename.
- Follow legacy package references from the project root, or JSON `packages`,
  preserving canonical remote, version requirement, package resolution,
  actual binary, artifact manifest, and tracked-pin checks.
- Match the authoritative configuration from the evidence source commit and
  its content hash. New proofs include `project_path`; when present it must
  match. An arbitrary proof path or current working-tree file cannot select
  the input.
- Retain checker API 1, contract and proof schema 1, and receipt schema 2.
  Stally's existing `runpy` delegate remains compatible, with no new Python
  dependency. The checker hash changed, so an old receipt is not current proof.

Stally reran the evidence-mode command from the dependency audit on the clean
`be45a898f71a3f9a5d6b13159eb1b54a8cedcaa7` source snapshot. It completed with
exit status 0 using SwiftLint 0.65.1 across all 300 tracked Swift files;
captured output contained zero warnings and errors. The shared execution
helper recorded an unchanged clean snapshot and hashed raw output.

The installed matcher's `passed_record` and `lint_quality_record` checks also
accepted that actual result and output against the source commit. The proof
identified `Stally.xcodeproj/project.xcproj` with SHA-256:

```text
fae0e1ecedda444920b5fe5f6386ab0f1ccb13bd01ba200416e66906e63aed69
```

This matches the retained converter output. These were lint-record checks,
not a full publication-gate invocation; no receipt was installed or rewritten.
The subsequent documentation changes do not relabel that source snapshot as a
new execution.

The handoff separately reports 24 shared reader tests and 41 matcher tests
passing, alongside broader skill-repository checks. Those suites were not
rerun by Stally's follow-up. The direct Stally results above establish local
delegate compatibility; they do not establish another app's local rules or
app build/test results.

Adopter-specific package boundaries remain with each repository. Incomes
observed reordered Frameworks inputs; Stally's own comparison preserved their
order. Do not transfer an adopter's difference or normalize ordered build
inputs merely because membership and evaluated settings match.

## Remaining Verification and Rollback

Shared adapter compatibility is now confirmed for the tested snapshot. Before
publication, complete the required app, library, and system verification plus
diagnostic review for the intended source and explicitly selected toolchain.
Recheck settings and project relationships if their inputs change. Xcode 27.1
scheme discovery remains discovery evidence, not a build result.

Follow the [receipt compatibility procedure][receipt-guide] and produce
appropriate current-source evidence and a new receipt before any separately
authorized push. Do not replace an old receipt's helper hash or disable the
existing hook to bypass its source or checker binding.

Archive and Xcode Cloud execution remain explicitly deferred, outside this
follow-up. Their results cannot be inferred from local checks, and neither is
introduced as an additional gate for this task. Duo qualification stays
independent of this migration. The Issue remains open and no push was made.

To roll back the current candidate, revert its reapplication commit and review
the associated documentation changes. For an uncommitted conversion, restore
the removed tracked property-list file and remove only the generated JSON file.
Keep exactly one authoritative configuration. A generated round-trip file is
useful for comparison, but Git restoration preserves the exact original file.

[conversion]: https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format
[shared-guide]: https://github.com/muhiro12/agent-skills/blob/main/ci-verify-and-summarize/references/xcode-project-format.md
[receipt-guide]: https://github.com/muhiro12/agent-skills/blob/main/ci-verify-and-summarize/references/push-verification.md
