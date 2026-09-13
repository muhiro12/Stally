# Near-Term Development Brief

> Status: Temporary execution brief, September 13, 2026. The bounded integration
> is implemented. Use the current verification record before further work;
> distribution readiness remains a separate gate.

## Target Outcome

Release a coherent, trustworthy iOS 27-or-later Stally that uses current Apple
platform capabilities extensively while preserving its quiet item-choice
domain. Stally is the primary full-MHUI proving ground and consumes the complete
MHPlatform runtime. Current pins are MHPlatform 1.13.0 and MHUI 1.18.0.

Stally is the release product. The accepted integration adds optional starts,
calendar date precision, elapsed time, and items that do not record Marks.
Fluel data migration is unnecessary; Fluel remains unchanged. Do not reopen
those decisions or expand the integration into additional Fluel features.

## Order of Work

1. Start from [item tracking verification](item-tracking-verification.md).
   Complete pending interaction and accessibility checks with an isolated
   iOS 27 Simulator and synthetic data. Keep unsupported checks explicit and
   leave reproducible manual steps instead of treating screenshots as a pass.
2. Fix only confirmed integration defects and repeat the affected checks.
   Keep app-specific composition and product language in Stally. Do not change
   a shared package without a demonstrated package defect and authorization.
3. Preserve current Operations, schema migration, backup compatibility,
   identity, photo, link, and Mark behavior. The immutable V1 fixtures must
   never be regenerated with the current schema; use disposable copies.
4. Keep local completion separate from [release readiness](release-readiness.md).
   Obtain concrete decisions on advertising/product settings, approved
   Privacy/Support destinations, and distribution signing before acting on
   those external settings. Do not ship test advertising identifiers.
5. In a separately authorized distribution task, verify the shipping build,
   purchase/restore, real-device sync and startup recovery with selected test
   accounts/devices. No production CloudKit promotion, real-data operation,
   or publication belongs to the current integration audit.

## Completed Integration Boundary

- One Stally Item retains its identity and Mark relationship. Optional starts
  have year, month, or day precision; unknown dates are never inferred.
- Non-Mark items remain in Library and Archive and generic entity lookup.
  Review and choice metrics exclude them; note/photo coverage retains them.
- Archive is only collection storage. Time continues while archived; ending
  a relationship is a separate concept and is not implemented here.
- Frozen V1 disk fixtures verify the additive V2 migration. Backup v3 exports
  coexist with the frozen v2 reader, and the old app safely rejects v3.
- Operations, screens, and App Intents are implemented. The verification
  report separates completed tests/captures from pending interaction checks.

The [accepted design](item-start-and-elapsed-time-proposal.md) is the contract.
Milestones, activity timelines, presets, broader navigation, and a Fluel
importer are outside this integration.

## Guardrails

- Do not copy Fluel's app shell, platform bootstrap, MHUI adapters, or release
  configuration into Stally.
- Do not redesign the accepted model during verification or add new features.
- Do not broaden MHPlatform or MHUI for a need that exists only in a proposal.
- Treat wrapper modernization as separate work unless a concrete Stally need,
  defect, platform change, or measurable development benefit justifies it.
- Preserve versioned SwiftData migrations and public Operations behavior.
- Keep the current direct-to-`main` and tag workflow unchanged.

## Completion Evidence

Choose evidence for the changed boundary: library tests for domain behavior,
repository rules and app build for Swift changes, and runtime interaction or
accessibility evidence for affected UI. Documentation-only alignment does not
require repeating unchanged library tests. Commit fixes and verification/docs
in meaningful units, preserving unrelated work.

Do not report integration-wide interaction or accessibility completion while
the verification ledger still has gaps. Local evidence does not establish
real-device CloudKit, production StoreKit/AdMob, or distribution readiness.
