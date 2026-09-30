# Item Contextual Actions

## Shared Action Contract

`ItemOperations.contextSnapshot` captures an immutable, Sendable reading of
canonical UUID, name, capabilities, today's Mark, and a localized time report.
It contains no live model or mutation permission. `ItemContextActions` uses
that reading for both native context menus and the ordinary Item Actions menu.

| Current Item state | History command |
| --- | --- |
| Active, Mark enabled, unmarked today | Mark Today |
| Active, Mark enabled, marked today | Undo Today's Mark |
| Active, Mark disabled | None |
| Archived, either Mark policy | None |
| Disabled with retained conflicting history | None; history stays intact |

Every state offers Edit Item and Share Item Link. Valid start knowledge also
offers Share Time Together, preserving year/month/day precision. Unknown or
malformed start knowledge offers no time-sharing command. Archive Item appears
only for active Items; Move Back to Library appears only for archived Items.
Placement commands follow a divider. Delete and history adjustment retain their
ordinary, explicit safety flows rather than appearing in these menus.

When a mutation executes, the adapter resolves the captured UUID through a
bounded Operations lookup and uses the current local day. Mark, Undo, Archive,
and move-back call the existing authoritative Operations, which recheck live
policy and placement. Repeated requests remain idempotent. A missing Item or
rejected action presents the existing localized error treatment. Editing also
resolves UUID at the sheet boundary and supplies the live Item by environment;
a missing identity shows an unavailable state rather than editing another Item.

## Selected Surfaces

Library and Archive browsing share `StallyItemNavigationLink`, including search
and filtered collections. Review lane rows use the same row adapter because
their placement and choice actions remain useful secondary tasks. Insights
reports and aggregate summaries are readings, so they receive no Item menus.

Long press accelerates row actions. Item Detail provides the same commands in
an accessible, labeled native toolbar `Menu`. Existing detail Edit, Share Item
Link, Share Time Together, Today Mark/Undo, history, placement, and confirmed
Delete remain reachable through their ordinary controls. Review swipe actions
and selection behavior remain available. No important action becomes menu-only.

## Onscreen Entity Context

Row and detail associations use `.appEntityIdentifier(_:)` with the existing
`StallyItemEntity` type and the canonical UUID string. Names can be duplicated,
and collection placement or start precision cannot reliably be recovered from
rendered text. Explicit identity therefore helps resolve the actual visible
domain Item. The entity remains a small value resolved by the existing query;
private notes, photos, and full history are not added to it.

This is limited to actual Item rows and the selected Item's detail content.
Buttons, labels, aggregate reports, and unrelated screens are not independently
annotated. Native list/navigation context supplies presentation and selection;
the app does not invent selected entities to influence Siri.

Apple's current [contextual-cues guidance][context] supports associating views
with their represented App Entities. The ordinary [SwiftUI association][entity]
matches these native row/detail surfaces. The selection-type variant is useful
for explicit list selection contracts; this navigation row needs no second
selection provider. `appEntityUIElements` serves custom drawn regions, which
these native Lists do not have. A parallel `NSUserActivity` entity association
is unnecessary without an actual Handoff activity. Existing native sharing
does not require adding drag handlers, notifications, Widget, or Watch targets.

Apple describes automatic Ask Siri presentation in its [menu guidance][menus].
Stally supplies native menus and useful entity context, and leaves
availability and presentation to the system. It adds no custom Ask Siri command
and no runtime heuristic or persistent override to force that entry.

## Verification

Xcode 27.0 (27A266a), iOS 27.0 SDK (24A430), and Simulator runtime (24A434)
build the app and extract App Intents metadata without compiler warnings or
errors. StallyLibrary passes 173 tests in 42 suites, including the full policy,
placement, and today's-Mark matrix, invalid/unknown start knowledge, captured
value lifetime, and missing identity after deletion.

All four out-of-process AppIntentsTesting tests pass with zero failures in
31.098 seconds. The added annotation test creates two Items with identical
names, obtains both UUIDs from visible Library rows, opens the second Item and
obtains only its detail identity, then reads its changed Archive property.
This uses Apple's [view annotation testing API][annotation-testing] through the
installed app, separately from the library capability tests.

The dedicated iPhone native session confirms these state transitions:

- Canvas Tote's context-menu Mark changes 3 Marks to 4 and exposes Undo;
  context-menu Undo restores 3 Marks and the original unmarked state.
- Home's non-Mark menu offers time sharing and no Mark/Undo. Context-menu Edit
  opens Year Only / 2020 with Record Marks off; Cancel preserves that input.
  Share Time Together opens the native sheet with the September 30, 2026
  reference-day report, then dismisses without sending.
- Travel Weekender's archived menu offers move-back and no Mark/Undo. Moving
  back and archiving again retain its 3 Marks and restore Archive's count to 2.
- Review's Daily Field Notes row uses the same native secondary actions.
- Detail's labeled Item Actions button opens the ordinary menu; separate Edit,
  link-sharing, and Mark controls remain accessible. Scrolling reaches Adjust
  History, Archive Item, and the ordinary confirmed Delete boundary.
- Japanese context and ordinary menus use translated commands and the
  accessible Item Actions label. The dedicated iPad's 1032-by-1376-point scene
  presents both native menu types while retaining its adaptive tabs, detail
  history, and ordinary Mark control.

All three owned synthetic launches reach preview creation and startup ready.
Scoped logs contain zero app-owned ERROR/FAULT entries and zero fatal
persistence/crash entries. Framework/provider diagnostics remain separately
recorded: 257 iPhone and 199 iPad lines, including automation accessibility,
WebKit, and CoreTelephony messages. They are not silently relabeled as app
failures. Owned processes and native sessions are stopped after the checks;
ordinary data is unchanged.

Formatter, SwiftLint and architecture rules, six-catalog EN/JA audit, Markdown
lint, and diff whitespace checks pass. Original V1 fixtures retain all eight
checksums. Native project/scheme discovery remains unresponsive, so build/test
uses the explicit Xcode 27.0 CLI fallback and dedicated discovered Simulator.
Native run, touch, screenshots, and hierarchy inspection work directly without
computer-use fallback. The original Xcode scheme/destination is unchanged.

Representative native captures:

| Item capability | Native evidence |
| --- | --- |
| Active Mark-enabled | [Canvas Tote][mark-proof] |
| Active non-Mark with known start | [Home][time-proof] |
| Archived Mark-enabled | [Travel Weekender][archive-proof] |
| Ordinary detail menu | [Daily Field Notes][detail-proof] |
| Japanese ordinary menu | [Canvas Tote][japanese-proof] |
| iPad context menu | [Canvas Tote row][ipad-context-proof] |
| iPad ordinary menu | [Canvas Tote detail][ipad-menu-proof] |

These synthetic Simulator checks do not establish physical Siri speech,
locked-device authorization, real CloudKit sync, or release readiness.
Ask Siri availability is not forced as an acceptance mechanism.

[context]: https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri
[entity]: https://developer.apple.com/documentation/swiftui/view/appentityidentifier(_:)
[menus]: https://developer.apple.com/videos/play/wwdc2026/278/
[annotation-testing]: https://developer.apple.com/documentation/appintentstesting/appentitydefinition/viewannotations()
[mark-proof]: ui-preview-screenshots/contextual-actions/canvas-context-mark-en.png
[time-proof]: ui-preview-screenshots/contextual-actions/home-context-nonmark-en.png
[archive-proof]: ui-preview-screenshots/contextual-actions/archived-context-en.png
[detail-proof]: ui-preview-screenshots/contextual-actions/detail-ordinary-menu-en.png
[japanese-proof]: ui-preview-screenshots/contextual-actions/detail-ordinary-menu-ja.png
[ipad-context-proof]: ui-preview-screenshots/contextual-actions/ipad-canvas-context-en.png
[ipad-menu-proof]: ui-preview-screenshots/contextual-actions/ipad-ordinary-menu-en.png
