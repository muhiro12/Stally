# Near-Term Development Brief

> Status: Temporary execution brief, September 14, 2026. The bounded integration
> is implemented. Use the current verification record before further work;
> distribution readiness remains a separate gate.

## Target Outcome

Release a coherent, trustworthy iOS 27-or-later Stally that uses current Apple
platform capabilities extensively while preserving its quiet item-choice
domain. Stally is the primary full-MHUI proving ground and consumes the complete
MHPlatform runtime. Current pins are MHPlatform 1.13.0 and MHUI 1.18.0.

Stally is the release product. The accepted integration adds optional starts,
calendar date precision, elapsed time, and items that do not record Marks.
Fluel data migration is unnecessary; Fluel remains unchanged. The subsequent
[follow-up comparison](fluel-integration-assessment.md#september-14-follow-up-integration)
adds start-aware collection browsing, derived yearly milestones, and read-only
time sharing/Shortcuts. These use existing saved fields; do not reopen the
accepted identity, date, Mark, or Archive decisions.

## Order of Work

1. Start from [item tracking verification](item-tracking-verification.md).
   The isolated iOS 27 run now verifies actual Add/Edit, validation,
   precision changes, Archive, Review/Insights scope, maximum-text interaction,
   localized accessibility hierarchies, and v2/v3 import confirmations and
   conflict protection. Continue only the explicitly remaining checks; do not
   repeat completed cases without a changed boundary or new failure.
2. Fix only confirmed integration defects and repeat the affected checks.
   Keep app-specific composition and product language in Stally. Do not change
   a shared package without a demonstrated package defect and authorization.
3. Preserve current Operations, schema migration, backup compatibility,
   identity, photo, link, and Mark behavior. The immutable V1 fixtures must
   never be regenerated with the current schema; use disposable copies.
4. Keep local completion separate from [release readiness](release-readiness.md).
   The accepted offer remains native ads with optional monthly ad removal,
   following Incomes. Prepare Stally's AdMob app and unit before publication
   when possible; store linking and ad-readiness approval follow publication.
   If setup is blocked, retain the offer direction and prepare a temporarily
   ads-disabled candidate with ad-removal sales deferred. Do not ship test IDs
   or sell removal while advertising is deliberately disabled.
   The approved destinations are the existing Stally GitHub Pages URLs with
   GitHub Issues for support. Verify the final pages before authorized
   publication; account, signing, and device steps remain separate.
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
  report separates completed domain/adapter tests and actual interaction from
  remaining exporter Save, physical VoiceOver, system Shortcuts/Siri,
  local-midnight foreground refresh, and other device-size checks.

The [accepted design](item-start-and-elapsed-time-proposal.md) is the contract.
Yearly milestones, start-aware browsing, and time sharing/Shortcuts are derived
follow-ups within the same Item boundary. Activity timelines, presets, broader
navigation, relationship-ending records, and a Fluel importer remain deferred
for the reasons in the follow-up comparison.

## Guardrails

- Do not copy Fluel's app shell, platform bootstrap, MHUI adapters, or release
  configuration into Stally.
- Keep the follow-up read-only; do not redesign the accepted saved model or
  expand into deferred Fluel capabilities without a concrete new use case.
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

The September 14 integration Release archive passes local build, signature,
manifest, and Debug-fixture exclusion checks. It predates the subsequent Support
link and read-only time follow-up and remains development-signed with the sample
advertising app ID; it is not a cleared distribution artifact.

Do not report integration-wide interaction or accessibility completion while
the verification ledger still has gaps. Local evidence does not establish
real-device CloudKit, production StoreKit/AdMob, or distribution readiness.
