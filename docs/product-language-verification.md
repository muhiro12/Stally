# Product Language Verification

## Scope

Issue #18 applies the combined-product glossary in `product-language.md` to
English and Japanese controls, App Intents, report strings, accessibility
text, data-file descriptions, and repository/support copy.

The general start label is now 開始時期, Review is 見直し, and Insights is
振り返り. Import & Export / 読み込みと書き出し replaces the displayed Backup
Center name. Internal types, link destinations, document identifiers,
`.stallybackup`, and wire versions retain their existing contracts.

## Evidence

Verification uses Xcode 27.0 (27A266a) and iOS Simulator 27.0 (24A434).
Each screenshot launch uses DEBUG-only synthetic in-memory data and
per-launch language arguments. No real collection or iCloud data is used.

| Surface | Before | After | Observed change |
| --- | --- | --- | --- |
| Empty Library, English | [Before](ui-preview-screenshots/product-language/before/library-empty-en.png) | [After](ui-preview-screenshots/product-language/after/library-empty-en.png) | Things and places; Import Data |
| Empty Library, Japanese | [Before](ui-preview-screenshots/product-language/before/library-empty-ja.png) | [After](ui-preview-screenshots/product-language/after/library-empty-ja.png) | 大切なものや場所; データを読み込む |
| Add Item, Japanese | [Before](ui-preview-screenshots/product-language/before/add-item-ja.png) | [After](ui-preview-screenshots/product-language/after/add-item-ja.png) | 開始時期 and explicit recording-policy copy |
| Data management, Japanese | [Before](ui-preview-screenshots/product-language/before/backup-center-ja.png) | [After](ui-preview-screenshots/product-language/after/import-export-ja.png) | 読み込みと書き出し and neutral data actions |
| Review, Japanese | Existing source | [After](ui-preview-screenshots/product-language/after/review-ja.png) | 見直し |
| Insights, Japanese | Existing source | [After](ui-preview-screenshots/product-language/after/insights-ja.png) | 振り返り |

Native screenshots and accessibility hierarchies verify these visible labels.
All six screens are free of observed clipping or overlapping controls. Each
launch reaches the synthetic-container and ready events. Runtime logs contain
no app-owned fatal error, crash, exception, or persistence failure. Nonfatal
UIKit, accessibility, WebKit, and Simulator service output remains system/SDK
evidence rather than an application failure. The verification run is stopped
and the final native capture session confirms its own shutdown.
This is a terminology review at the default text size, rather than a complete
accessibility or information-architecture audit.

The app build succeeds, including App Intents metadata extraction. Repository
rule checks, Swift formatting, and English/Japanese catalog coverage pass.
All six catalogs have no incomplete or stale keys; the two source-copy flags
for the brand name Stally are intentional. Markdown checks pass; Pages front
matter is treated as SEO metadata rather than a second visible heading.

Library tests also check localized reports, including the renamed Japanese
start and Insights text: 154 tests across 36 suites pass. The test expectations
retain date precision and read-only report semantics.

## Boundaries

Xcode-native project opening and device capture work. Scheme/destination
discovery does not respond, so app compilation and installation use official
`xcodebuild` and `simctl` with explicit Stally scheme and dedicated destinations.
No active scheme or destination is changed by this verification.

These observations do not prove VoiceOver speech, Siri execution, production
CloudKit, purchase resolution, or distribution readiness. Public/store copy is
prepared in source; no website deployment, Store write, or Git push occurs.
