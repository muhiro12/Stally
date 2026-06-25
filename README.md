# Stally

Stally is an unfinished iPhone app for quietly tracking the personal items a
user keeps choosing over time.

The repository is in seed rebuild implementation. The legacy implementation
was removed after product intent was preserved under `docs/`, and the current
tree now contains a fresh Apple-platform app project:

- `Stally.xcodeproj`, with the `Stally` app target and `Stally` scheme.
- `Stally/`, a SwiftUI app source tree with starter SwiftData persistence.
- `Stally.xcodeproj/xcshareddata/xcodecloud/manifest.json`, an Xcode Cloud
  manifest.

The current app project is intentionally small. It is not a restoration of the
removed legacy architecture, navigation, persistence model, or feature set.

## Rebuild Documentation

Use the documents under `docs/` as the rebuild documentation set:

- `docs/product-brief.md`
- `docs/product-purpose.md`
- `docs/preserved-concepts.md`
- `docs/domain-concepts.md`
- `docs/user-workflows.md`
- `docs/user-experience-principles.md`
- `docs/product-language.md`
- `docs/rebuild-handoff.md`
- `docs/rebuild-implementation-direction.md`

These documents describe what Stally is, why it exists, which concepts must
survive, and which legacy implementation details were intentionally discarded.
`docs/rebuild-implementation-direction.md` separately records explicit rebuild
direction that did not come from the removed legacy source.

Some documents preserve the phase-boundary language from when they were
created. This README and `AGENTS.md` describe the current repository state.

## Current Repository State

This repository currently contains a buildable seed app target.

It does not currently contain a shared library target, Swift package manifest,
test target, or local verification scripts. Further implementation decisions
should continue to use the preserved product intent and owner-directed rebuild
direction in `docs/`, without inferring requirements from the removed legacy
implementation.

The project currently targets the iOS 27 family. Compile checks should build
the `Stally` scheme for iOS Simulator with a matching Xcode and SDK.
