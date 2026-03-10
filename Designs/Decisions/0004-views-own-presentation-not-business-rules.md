# ADR 0004: Views Own Presentation, Not Business Rules

- Date: 2026-03-10
- Status: Accepted

## Context

SwiftUI views are convenient places to add local decisions for review scoring,
archive filtering, backup branching, or insight summaries. Over time, those
decisions become hard to reuse and easy to diverge from other surfaces.

## Decision

Views own presentation state, local interaction state, and navigation.
Reusable business decisions and mutations belong in shared services such as
`ItemService`, `MarkService`, `ItemReviewCalculator`, and
`ItemInsightsCalculator`. App-side coordinators and screen adapters may
orchestrate UI flows, but they should delegate the actual rules.

## Consequences

- If a view reconstructs shared logic, that is a refactoring target.
- Thin app-side coordinators or snapshot builders are acceptable when they
  adapt shared services to a screen.
- Business rules used by multiple screens should move toward shared service or
  adapter APIs rather than staying embedded in one view.
- Existing direct calculator reads in `Home`, `Archive`, `Review`, and
  `Insights` are tolerated for now, but additional branching should trigger a
  refactor rather than further growth inside the view.
