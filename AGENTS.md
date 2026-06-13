# AGENTS.md

Repository-specific agent contract for Stally.

## Repository Rules

- Use English for branch names, code comments, documentation, and identifiers
  unless UI localization or legal content requires otherwise.
- Follow existing architecture and source style; keep changes small and
  repository-local.
- Treat sibling repositories and external packages as read-only reference
  material unless the user explicitly asks otherwise.
- Markdown must follow
  <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>.
- Swift code must comply with the repository SwiftLint configuration.

## Repository Boundaries

- `Stally/Sources/` owns app composition, SwiftUI screens, platform
  integrations, preference-backed UI state, and runtime/bootstrap setup.
- `Stally/Resources/` owns app-localized resources and assets used by the app
  target.
- `StallyLibrary/` owns reusable domain and persistence logic, SwiftData
  models, services, calculators, backup import/export logic, and shared deep
  linking definitions.
- Prefer moving reusable business or persistence logic into `StallyLibrary/`
  rather than growing `Stally/Sources/`.
- Keep the app target thin: it should assemble dependencies and present UI, not
  absorb shared domain logic.
- `Designs/Architecture/`, `Designs/Decisions/`, and `Designs/Overviews/`
  define the current outer-architecture intent. Update them when you change
  repository structure or responsibility boundaries.

## Build and Test Entry Point

Agents MUST prefer XcodeBuildMCP for Apple build, test, run, Simulator,
runtime log, screenshot, and UI snapshot verification.

Before the first XcodeBuildMCP build, test, or run call in a session, run
XcodeBuildMCP `session_show_defaults`. If defaults do not point at this
repository, set them for the current session before continuing.

Treat library tests, surface builds, and runtime/UI evidence as separate
verification capabilities. Choose the smallest set that proves the current
change, and prefer stronger evidence when public APIs, wire contracts,
SwiftData schema, app lifecycle wiring, or visible UI behavior are affected.

- For shared-library logic, model, or test changes, use XcodeBuildMCP
  `test_sim` with the `StallyLibrary` scheme.
- For public `StallyLibrary` APIs, shared persistence or deep-link contracts,
  SwiftData schema, or adapter-facing contracts, also use XcodeBuildMCP
  `build_sim` with the `Stally` scheme.
- For app compile checks, use XcodeBuildMCP `build_sim` with the `Stally`
  scheme.
- For runtime or UI-sensitive changes, use XcodeBuildMCP `build_run_sim`,
  `launch_app_sim`, `snapshot_ui`, and `screenshot` as appropriate.

Use this supplemental repository-state entrypoint when only change-based shell
checks are needed:

```sh
bash ci_scripts/tasks/verify_repository_state.sh
```

Agents may run `bash ci_scripts/tasks/check_environment.sh --profile verify`
first to diagnose missing local prerequisites.
When Swift files are edited, agents should run
`bash ci_scripts/tasks/format_swift.sh` before the final verification gate.
Use `bash ci_scripts/tasks/verify_task_completion.sh` when the task needs the
retained aggregate shell gate or when MCP coverage is unavailable.
`bash ci_scripts/tasks/verify_pre_commit.sh` reruns the same non-destructive
verification shell for manual final checks and `.pre-commit-config.yaml`.
`bash ci_scripts/tasks/verify_pre_push.sh` is the optional Git `pre-push`
wrapper for the same non-destructive verification gate.
SwiftLint is resolved from the `SimplyDanny/SwiftLintPlugins` package declared
in `Stally.xcodeproj`, not from a separately installed `swiftlint` binary.

Use these narrower entrypoints only when the task specifically needs them:

```sh
bash ci_scripts/tasks/build_app.sh
bash ci_scripts/tasks/test_shared_library.sh
bash ci_scripts/tasks/verify_pre_commit.sh
bash ci_scripts/tasks/verify_pre_push.sh
```

Compatibility scripts write disposable CI artifacts under
`.build/ci/runs/<RUN_ID>/` and shared data under `.build/ci/shared/`. Only the
newest 5 run directories are retained.
