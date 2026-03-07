# Stally

## Requirements

- Xcode 16 or later with the iOS 18 SDK installed
- `pre-commit`
- `swiftlint`

## Setup

1. Open the repository root.
2. Install hooks with `pre-commit install`.
3. Open `Stally.xcodeproj` in Xcode and use the shared `Stally` scheme.

## Development Commands

Run all pre-commit hooks:

```sh
pre-commit run --all-files
```

Build the app for iOS Simulator:

```sh
bash ci_scripts/tasks/build_app.sh
```

Run the local verify flow:

```sh
bash ci_scripts/tasks/verify.sh
```
