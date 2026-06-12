# Rebuild Handoff

## Purpose

This documentation set preserves the product knowledge needed before the old
Xcode project and source code are deleted.

Phase 2 may remove the legacy project and implementation. The rebuild should
use `docs/` as the preserved product-intent source, not as an implementation
plan.

## Documentation Set

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
- `docs/rebuild-handoff.md` records the extraction audit and boundaries.

## Evidence Inspected

The extraction used the following repository evidence:

- `README.md`.
- `TASKS.md`.
- Existing product and architecture overviews under `Designs/Overviews/`.
- User-facing localization catalogs in the app and shared library resources.
- Swift source comments and names where they expressed product meaning.
- App copy in home, item, review, archive, insights, settings, backup, and
  tip surfaces.
- Sample item names and notes.
- Unit tests that encode user-visible rules for marks, review, insights,
  backup import, and item list behavior.
- Commit history, used only where it described user-facing capabilities.
- Asset inventory. No meaningful product assets beyond app icon and accent
  color placeholders were present in the repository listing.

## Canonical Product Summary

Stally is a quiet iPhone app for tracking the personal items a user keeps
choosing over time.

The user adds real items, marks them on days they are chosen, and lets those
marks become a calm history. The app helps the user keep the active Library
focused, preserve past favorites in Archive, review items that drift, read
collection patterns in Insights, and protect the collection with backups.

## What Must Survive Source Deletion

- Product name and quiet personal tone.
- Item, category, note, photo, mark, and history concepts.
- Active Library and preserved Archive distinction.
- Review lanes for Needs First Mark, Dormant, and Recovery Candidates.
- Insights concepts: activity, consistency, categories, rankings, rhythm, and
  recommendations.
- Time ranges: 30 Days, 90 Days, 365 Days, and All Time.
- Optional archived-item scope for insights.
- Backup export, import preview, merge, replace, and reset safety concepts.
- Shareable app and item links.
- The product vocabulary in `docs/product-language.md`.

## What Should Not Survive As Requirements

- Legacy Xcode project shape.
- Legacy source directories.
- Old module boundaries.
- SwiftUI screen composition.
- SwiftData model design.
- Framework and package choices.
- Routing implementation.
- Backup schema implementation.
- CI and verification scripts.
- Architecture decisions that only explain the old implementation.

## Audit Coverage

The final documentation covers source-only knowledge that would otherwise be
easy to lose:

- Sample items and their tone are captured in `docs/domain-concepts.md`.
- Sample item note language is captured in `docs/domain-concepts.md` and
  `docs/product-language.md` as tone evidence, not required seed data.
- The "one mark per item per day" meaning is captured in
  `docs/domain-concepts.md` and `docs/user-workflows.md`.
- Archived items being preserved, not deleted, is captured across
  `docs/domain-concepts.md`, `docs/user-workflows.md`, and
  `docs/user-experience-principles.md`.
- Review lane meanings and actions are captured in
  `docs/preserved-concepts.md`, `docs/domain-concepts.md`, and
  `docs/user-workflows.md`.
- Adjustable review and insight preferences are captured in
  `docs/user-experience-principles.md`.
- Insights metrics, ranges, and recommendation meanings are captured in
  `docs/domain-concepts.md` and `docs/product-language.md`.
- Backup safety, merge, replace, reset, validation, and non-sync framing are
  captured in `docs/domain-concepts.md`, `docs/user-workflows.md`, and
  `docs/product-language.md`.
- Shareable route and item link intent is captured in
  `docs/domain-concepts.md` and `docs/user-workflows.md`.
- The quiet product voice is captured in `docs/product-purpose.md`,
  `docs/user-experience-principles.md`, and `docs/product-language.md`.
- The legacy Insights placeholder for longer-range comparisons, saved reports,
  and trend views is captured as an undefined product hint in
  `docs/domain-concepts.md`, not as a rebuild requirement.

## Unknown Or Unspecified By Legacy Evidence

The repository does not provide durable product intent for:

- App Store positioning.
- Pricing.
- Account systems.
- Cloud sync.
- Notifications.
- Widgets.
- Social features.
- Shopping, recommendation, or resale integrations.
- A broader category taxonomy beyond the preserved five categories.
- Exact behavior for longer-range comparisons, saved reports, or trend views
  beyond the existing Insights concepts.
- Monetization and advertising behavior. Legacy configuration evidence exists,
  but no durable user-facing product intent is defined.

Do not infer these during source deletion. Future product decisions should make
them explicitly if they become relevant.

## Phase Boundary

This handoff does not redesign Stally.

It does not choose a new architecture, create a new Xcode project, select
frameworks, or plan implementation tasks. It only preserves the product intent
needed so the old source code can be safely removed later.
