# Saved Keys and External Identifiers

## First-release identifiers

| Surface | Observed value or selected design | Recommendation |
| --- | --- | --- |
| Main bundle ID | `com.muhiro12.Stally` | Keep the current product identity |
| App Group ID | Selected `group.com.muhiro12.Stally` | Use shared storage from the first release for the planned app/extension family; confirm registration during integration |
| CloudKit container ID | `iCloud.com.muhiro12.Stally` | Keep it aligned with entitlements and model configuration; do not replace it merely for naming cleanup |
| App Store app ID | `6760996986` | Keep the configured product destination; verify the account record before release |
| App Store SKU | `com.muhiro12.Stally` | Preserve the existing Store record identity |
| Monthly product ID | `com.muhiro12.Stally.subscriptions.monthly` | Keep this identity if the monthly product remains; do not reinterpret it as an unrelated purchase |
| Native portable document | `.stally`, selected package UTI `com.muhiro12.Stally.data` | Retain the accepted package identity and physical format |
| Product links and Item target | `https://muhiro12.github.io/Stally/item/<UUID>` | Address the Item itself across UI changes and restore; use query parameters for optional views or filters |
| Remote-update configuration | `https://raw.githubusercontent.com/muhiro12/MHAppConfig/main/stally/app.json` | Retain the installed-client endpoint and package policy semantics |

Verify account and store registrations separately before distribution.
The OS document declaration and JSON discriminator share the same product
identifier. The standalone JSON exporter uses `public.json`.

The other destination paths are `library`, `archive`, `import-export` and
`create-item`. The custom scheme is `stally`. See the
[link and deployment contract](remaining-capabilities-implementation.md#links-and-external-deployment)
and [published Intent identifiers](app-intents-publication-review.md).

App Intents types initially use framework-provided identifiers. Preserve the
published identifier explicitly when renaming a shipped action, entity or enum
type, and verify extracted metadata and saved-workflow replay. See the
[type identity policy](app-intents-publication-review.md#type-identity-policy).

## Preference ownership

- Use App Group-first storage from the first release. Put the shared SwiftData
  store, app-owned settings intended for the app/extension family, and route
  handoff in the shared container/suite. Keep SDK-owned and genuinely
  process-specific state under its appropriate owner; do not relocate all
  standard-domain values indiscriminately.
- Independently of existing Stally code, use descriptive, fixed raw keys
  under `stally.`. They expose meaning when inspecting a defaults dump or a
  migration mapping without an additional lookup. Eight-character IDs remain
  technically valid and intentionally chosen by the siblings; there is no
  Apple requirement for either spelling. Record each shipped raw key with
  its stored type, meaning, owner, default/fallback, and retirement handling.
  Swift property renaming need not rename the raw key.
- Never reuse a shipped key for an incompatible purpose or type, even after
  years without reading it. Introduce a different key and an explicit migration
  or retirement decision. This also applies to retired cache/transient keys:
  their bytes may survive their useful lifetime.
- Distinguish an absent value from a stored user selection. Changing fallback
  defaults does not authorize overwriting existing preferences. Use normal
  platform default registration/typed descriptors rather than a second settings
  database or a new application-wide preference schema engine. This does not
  reject the existing MHPlatform preference registry/lifecycle; assess its
  migration and cleanup policy separately from key spelling.
- A resettable preference is not primary history. Settings remain excluded from
  collection export. Deleting a setting must not delete Items or alter recorded
  facts. Avoid broad defaults clearing, including package-owned state.
- Keep user choice, observed system state, and derived caches distinct. A
  subscription cache is not purchase authority. A sync preference is not a
  claim that the system has completed synchronization.

The [DEBUG store controls](fixture-architecture.md#developer-controls) apply
only to local development. The shared store lives at
`Library/Application Support/Stally.store` inside the App Group. The
[container factory](../StallyLibrary/Sources/Persistence/StallyModelContainerFactory.swift)
owns this location and the CloudKit container selection.

## Initial shipped preferences

| Raw key | Type/default | Owner and meaning | Retirement |
| --- | --- | --- | --- |
| `stally.sync.iCloudEnabled` | Bool / false | App Group suite; the person's requested sync selection, applied on next launch; cleared after a resolved inactive subscription | Never reuse for another meaning; an absent value leaves mirroring off |
| `stally.subscription.isActive` | Bool / false | App Group suite; last resolved MHPlatform/StoreKit entitlement for startup, retained while status is unknown; not purchase authority | Refresh from StoreKit; never use removal to erase library data |

Both preferences are device-local and excluded from exported records. The same
store URL is used in either sync mode. See [sync lifecycle](sync-lifecycle-design.md).
