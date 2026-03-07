# Stally

`Stally` keeps the app target separate from `StallyLibrary`, a local Swift
package intended to hold shared domain and infrastructure code as the project
grows.

## Requirements

- Xcode 16 or later with the iOS 18 SDK installed
- `pre-commit`
- `swiftlint`

## Setup

1. Open the repository root.
2. Install hooks with `pre-commit install`.
3. Open `Stally.xcodeproj` in Xcode and use the shared `Stally` or
   `StallyLibrary` scheme as needed.

## Development Commands

Run all pre-commit hooks:

```sh
pre-commit run --all-files
```

Build the app for iOS Simulator:

```sh
bash ci_scripts/tasks/build_app.sh
```

Run the local package tests:

```sh
bash ci_scripts/tasks/test_shared_library.sh
```

Run only the required builds/tests for local changes:

```sh
bash ci_scripts/tasks/run_required_builds.sh
```

Run the local verify flow:

```sh
bash ci_scripts/tasks/verify.sh
```

## CI Artifact Layout

CI helper scripts write all generated artifacts under `.build/ci/`.
Run-scoped outputs are stored in `.build/ci/runs/<RUN_ID>/` and shared caches
and build state live in `.build/ci/shared/`.
