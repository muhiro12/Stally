# ADR 0007: Adapter Failure-Surfacing Contract

- Date: 2026-03-23
- Status: Accepted

## Context

Stally already defines a strong library-first boundary, but adapters can still
hide operational failures if they do not classify them consistently. Backup
transfer flows, editor actions, and route-driven app actions all need a shared
contract for when success should block, when retry context should stay visible,
and when a committed mutation should still report follow-up degradation.

## Decision

Every adapter-owned mutation or transfer path must classify failures by phase
and surface them consistently.

| Phase | Examples | Contract |
| --- | --- | --- |
| Preflight failure before mutation | Invalid backup snapshot, unsupported schema version, missing local dependency wiring | Block success. Keep the current context available for retry. Do not present the operation as completed. |
| Primary mutation failure | Persistence failure, fetch failure, item delete failure, import apply failure | Block success. Surface the error to the current caller and keep the user on the current screen or sheet state whenever practical. |
| Post-commit follow-up failure | Share, tip, or other adapter-only follow-up after a successful mutation | Treat as degraded success. Preserve the committed mutation result and surface the follow-up failure distinctly. |

## Required Surface Behavior

- Views must not dismiss edit, import-preview, or other user-owned retry
  context after blocking failures.
- App-owned adapters may wrap underlying errors, but they must preserve the
  failure phase and operation name.
- Transfer adapters must distinguish file-access failures, decode failures, and
  mutation failures instead of collapsing them into one generic message.

## Consequences

- Adapter code must return or store enough metadata to tell blocking failures
  from degraded success.
- `Transfer` flows keep preview context available after blocking failures so
  the user can retry without re-opening the picker.
- Future adapter work can be reviewed against one repository-level contract
  instead of per-feature interpretation.
