# Tag Naming and Identity Design

## Status

This is the recommended Stally 1.0 behavior after comparing native Foundation
text handling, SwiftData persistence, and Apple's public tag interactions.
The owner requested this comparison and recommendation; explicit acceptance
of these detailed rules has not yet been recorded. Production models,
Operations, and UI have not changed.

Keep the selected Tag schema: uuid, name, and optional items. UUID identifies
the record; the name is its editable label. No persisted comparison key,
alias table, uniqueness constraint, merge log, or background deduplicator is
required for the recommendation.

## Stored Spelling

For ordinary local creation and renaming, trim leading and trailing characters
in Foundation's whitespacesAndNewlines set. Reject an empty result and embedded
control characters, line separators, or paragraph separators. Internal spaces,
including repeated spaces, remain meaningful. Preserve case, width, accents,
emoji sequences, and other user spelling. Do not require a hash prefix,
convert spaces to underscores, transliterate, or lowercase stored names.

The control check uses Unicode general categories control, lineSeparator, and
paragraphSeparator, rather than stripping all format characters. Emoji joiners
and variation selectors must remain intact. Foundation's whitespace set also
recognizes some invisible spacing characters; the probe includes trailing
U+200B. This is ordinary single-line input handling, not a custom confusable-
character or security-normalization system.

No additional NFC field or normalization pass is needed for equality: Swift
String equality already recognizes canonical equivalence. Composed and
combining forms of the same accented letter or voiced kana can compare equal
while preserving the entered spelling. The [Swift language guide][swift-equal]
documents this behavior.

These input rules do not authorize silently rewriting or deleting incomplete
records received through sync. Import validation and error reporting remain
part of the separate portable-data contract.

## Comparing Names

Use Foundation folding with caseInsensitive and widthInsensitive under the
fixed en_US_POSIX locale, followed by Swift String equality. Compute this from
name in memory. The fixed locale is a Stally comparison choice: a user's
language/region change must not redefine a creation or rename collision.
It is not a claim that English rules are the linguistically correct collation
for every language. Use localized behavior for presentation and search instead.

```swift
import Foundation

func tagNamesMatch(_ first: String, _ second: String) -> Bool {
    let locale = Locale(identifier: "en_US_POSIX")
    let options: String.CompareOptions = [.caseInsensitive, .widthInsensitive]
    let firstValue = first
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: options, locale: locale)
    let secondValue = second
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: options, locale: locale)
    return firstValue == secondValue
}
```

This function compares labels for local reuse/collision decisions. It does not
compare Tag identity, merge records, establish distributed uniqueness, or
supply a permanent export key. Foundation/Unicode behavior can evolve across
OS versions; do not persist the result as independent truth or rewrite stored
labels following a rule change.

### Alternatives Compared

All comparisons first trimmed the same leading/trailing whitespace.

| Candidate | Observed behavior and tradeoff | Decision |
| --- | --- | --- |
| Swift String equality | Canonical forms compare equal; case and width remain distinct | Too narrow for routine tag reuse |
| Lowercasing then equality | Handles common case differences, but misses width and Unicode case-fold expansions | No need to approximate Foundation folding |
| Foundation compare with case/width options | Also equated hiragana and katakana in the tested fixed locale | Too broad for the intended collision rule |
| Foundation case/width folding then equality | Handles spelling variants while retaining tested accents, kana script, and internal spaces | Recommended |
| Adding diacritic-insensitive folding | Equated cafe and cafe-with-acute, and expanded dotted-I equivalence | Useful broad-search idea, too broad for collisions |
| Compatibility normalization (NFKC) | Also equated circled digit one with plain digit one | More normalization than the chosen meaning requires |
| User-current-locale folding | Turkish I comparisons changed with locale | Suitable for localized interactions, not the fixed collision rule |

The difference between compare and folding is a measured current-platform
result, not a universal statement about every locale or all future OS versions.
[Foundation folding][folding] is a standard API intended for comparison forms;
Stally adds no Unicode mapping table or custom comparison algorithm.

### Selected Examples

| Names | Match for local reuse/collision? |
| --- | --- |
| Shoes / shoes / full-width SHOES | Yes |
| Half-width voiced katakana / its full-width equivalent | Yes |
| Composed cafe-with-acute / the same text with a combining acute | Yes |
| Composed voiced kana / the same kana with combining voicing | Yes |
| cafe / cafe-with-acute | No |
| はな / ばな | No |
| くつ / クツ | No |
| 革 靴 / 革靴 | No |
| A followed by two spaces and B / A followed by one space and B | No |
| 靴01 / 靴1; circled digit one / digit one | No |
| Straße / STRASSE; ff ligature / ff | Yes, through native Unicode case folding |
| I / i | Yes |
| Dotted capital I / i; I / dotless small i | No under the selected locale |
| Distinct emoji, skin-tone variants, or variation-selector spellings | Distinct in the tested cases |

Do not implement special exceptions for individual languages to change the
native folding results. Tags that need distinct meanings should have visibly
distinct labels rather than relying only on distinctions intentionally ignored
by the selected rule.

## Search and Candidate Presentation

Search is not the equality rule. For discovery, Apple's
localizedStandardContains supports locale-aware case/diacritic-insensitive
substring search. It may offer cafe-with-acute when the person types cafe;
that does not prohibit creating the distinct unaccented label. Present all
existing candidates that satisfy tagNamesMatch even if a broader search path
would omit one. Prefer exact/reuse matches, then broader localized suggestions.

Initially compare the fetched Tag set in the Operations context using the same
function for candidate resolution and final validation. Do not assume an SQL
predicate, SwiftData predicate translation, or a stored lowercased value has
identical semantics. The selected schema needs no normalizedName field. Avoid
loading Items or photos merely to compare names. Revisit fetching/caching only
if actual tag counts demonstrate a performance issue; no benchmark is claimed.

## Creation, Renaming, and Duplicates

| Action or state | Recommended behavior |
| --- | --- |
| Create with no matching name | Create one Tag with a new UUID and the cleaned user spelling |
| Create with one matching existing name | Offer that existing Tag for selection; do not create another or overwrite its spelling |
| Create with several matching names | Show the candidates and require selection of the intended record; never silently take the first |
| Attach an existing Tag again | Keep one assignment to that record; use record identity, not name, to decide |
| Rename to an unused label | Change only name; preserve UUID and every Item assignment |
| Change only the current label's case/width spelling | Allow it; update the shared visible spelling |
| Rename to match a different existing Tag | Explain the collision and leave the name and assignments unchanged |
| Receive separately identified same-name records | Retain and display each; no automatic merge, deletion, or UUID replacement |
| Remove a Tag from one Item | Remove that assignment only |
| Delete a Tag | Explicitly remove its assignments, retaining Items and their owned history/photos |

The creation UI can make reuse its clearly labeled primary action, without an
extra confirmation dialog. It must not make name entry silently rename the
existing record. Candidate selection is by identity, with associated Items or
an editing affordance when equal names need disambiguation; raw UUIDs need not
become user-facing labels.

Validate against the current local context at commit time, excluding the
record being renamed. If the proposed spelling still matches its own current
label, allow that spelling correction even when a same-name duplicate already
exists. This does not introduce a new collision and avoids making those
records uneditable. Renaming to a different collision class is blocked before
mutation. An unchanged submission is an ordinary no-op.

Serialize ordinary writes through the existing Operations/context ownership.
This prevents avoidable local duplicates; a fetch-before-insert check does not
promise uniqueness across devices, processes, stale contexts, or concurrent
imports. Apple's [CloudKit integration guidance][cloudkit] explicitly excludes
unique constraints and atomic relationship synchronization. Keep the selected
native synchronization behavior and tolerate duplicate arrivals.

## Explicit Consolidation as a Separate Feature

Apple Notes on Mac permits renaming a tag to an existing name to group notes.
Its [public guide][notes-mac] establishes that interaction, not Notes' private
schema, UUID policy, or synchronization implementation. Stally's tags have
portable UUID identity, so silently treating rename as a graph merge would
expand the meaning of an otherwise simple edit.

Compare three choices:

- Allow every local duplicate: minimal validation, but makes accidental
  duplicate classification easy and ordinary selection ambiguous.
- Merge on rename or synchronized name equality: convenient, but changes
  assignments and record identities as well as a label. Do not choose it.
- Encourage local reuse, block new rename collisions, and retain incoming
  duplicates: chosen for the initial release, with explicit identity intact.

A dedicated user-initiated consolidation is possible with ordinary SwiftData
relationship updates and deletion. A bounded local probe verified unioning
assignments without doubling an Item already assigned to both tags. This does
not prove multi-device merge atomicity or define how older exports referencing
the removed UUID should import.

Do not require a dedicated bulk-consolidation feature in 1.0. People can change
an Item's selected Tag and explicitly delete an unused label. Later, a dedicated
consolidation can choose a retained UUID and preview the affected Items. That
feature does not inherently require a new model; permanent redirect/alias
behavior would be a separate contract if actually needed. Deferral is a scope
recommendation, not an Apple restriction or a claim that native merging is
impossible.

## Verification Evidence

On macOS 27.2 with Xcode 27.2 / Swift 6.4.2:

- Compared seven approaches across 23 pairs, including Japanese script/width,
  canonical Unicode forms, accents, Turkish locale differences, ligatures,
  spacing, numbers, and emoji.
- Passed 61 name-rule assertions: the selected 23 cases in both directions,
  invalid single-line input, trimming, and retained spelling/emoji sequences.
- Used the current five-model Swift illustration, including thumbnailData,
  in a local SwiftData disk store with CloudKit explicitly disabled. Passed
  29 assertions across eight separate processes: shared rename and UUID
  retention, validation before mutation, preserved duplicates, case-only edit
  amid duplicates, detachment, nullify deletion, and unused-tag retention.
- An alternative explicit-consolidation probe passed five assertions across
  three processes, including reopening the unioned assignments and retained
  destination UUID. This is comparison evidence, not an implemented feature.
- The recommended schema/rename probe also compiled for iOS Simulator.

A restricted macro invocation failed because the compiler plugin could not
start under the sandbox; the same source compiled with normal local toolchain
permissions. Synthetic probes and results are under
/private/tmp/stally-tag-design. No app source, actual store, cloud container,
or sibling repository was changed.

The duplicate-arrival scenario inserted separate records in a local store; it
was not a real CloudKit event or multi-device test. No iOS runtime, interactive
UI, save-failure injection, large-tag-set performance, or cross-OS-version
Unicode compatibility proof is claimed. Normal save failures must preserve
previous data using the app's established transaction boundaries when this
recommendation is implemented.

[swift-equal]: https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html
[folding]: https://developer.apple.com/documentation/foundation/nsstring/folding(options:locale:)
[cloudkit]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
[notes-mac]: https://support.apple.com/guide/notes/use-tags-apdc88ed7f1d/4.13/mac/27
