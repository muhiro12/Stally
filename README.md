# Stally

Stally is an unfinished iPhone app prepared for a future full rebuild.

The legacy Xcode project and Swift implementation have been removed. The
repository now preserves product intent only, so a future rebuild can start
from a clean Xcode project without losing the essential product knowledge.

## Rebuild Documentation

Use the documents under `docs/` as the preserved product-intent source:

- `docs/product-brief.md`
- `docs/product-purpose.md`
- `docs/preserved-concepts.md`
- `docs/domain-concepts.md`
- `docs/user-workflows.md`
- `docs/user-experience-principles.md`
- `docs/product-language.md`
- `docs/rebuild-handoff.md`

These documents describe what Stally is, why it exists, which concepts must
survive, and which legacy implementation details were intentionally discarded.

## Current Repository State

This repository does not currently contain a buildable app target.

Do not infer architecture, project structure, persistence design, or framework
choices from the removed implementation. Future implementation decisions should
be made during the rebuild phase using the preserved product intent in `docs/`.
