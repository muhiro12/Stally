# AGENTS.md

Repository-specific agent contract for Stally.

## Current State

Stally is between rebuild phases.

The legacy Xcode project, Swift sources, old architecture documents, and
legacy verification scripts have been removed after product intent was
preserved under `docs/`.

This repository does not currently contain a buildable app target.

## Repository Rules

- Use English for branch names, code comments, documentation, and identifiers
  unless UI localization or legal content requires otherwise.
- Treat `docs/` as the source of truth for preserved product intent.
- Do not recreate an Xcode project, Swift source tree, architecture, CI
  scripts, or implementation plan unless the user explicitly asks.
- Do not infer future architecture, persistence, navigation, framework, or
  tooling decisions from the removed legacy implementation.
- Markdown must follow
  <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>.

## Documentation Boundaries

- `docs/product-brief.md` summarizes what Stally is.
- `docs/product-purpose.md` explains why it exists and what problem it solves.
- `docs/preserved-concepts.md` separates preserved product concepts from
  discarded implementation details.
- `docs/domain-concepts.md` defines the core product domain.
- `docs/user-workflows.md` records user-facing workflows.
- `docs/user-experience-principles.md` records the intended experience and
  tone.
- `docs/product-language.md` records preserved nouns, verbs, labels, and copy
  direction.
- `docs/rebuild-handoff.md` records the extraction audit and phase boundary.

## Verification

For documentation-only changes, inspect the Markdown diff and run lightweight
checks such as `git diff --check`.

There is no app build, Swift package test, SwiftLint, or repository CI script
available until a future rebuild creates a new project.
