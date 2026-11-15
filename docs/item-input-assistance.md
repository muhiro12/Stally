# Item text input assistance

## First-release scope

The November 12 scope decision adds optional Foundation Models input assistance.
Incomes' form extraction and Cookle's source-grounded recipe extraction informed
the flow: one description becomes an unsaved suggestion, reviewed before normal
editing and explicit saving. Stally's existing Item model remains authoritative.

[Issue #3](https://github.com/muhiro12/Stally/issues/3) supplies the related
editable-draft and no-invented-history boundary. Its photo recognition, cropping,
and subject selection exploration remains separate. This text implementation does
not complete that issue. [Issue #29](https://github.com/muhiro12/Stally/issues/29)
tracks release qualification; broader AI summaries and search remain deferred.

## Behavior and ownership

- Add/Edit Item opens Input Assistance. Type or paste one description, generate,
  review the name/note/link and optional period candidates, then choose Use Suggestion.
- By default, existing editor text is preserved exactly, including whitespace.
  Replace Existing Text explicitly opts into replacing the name, note and link
  that the suggestion supplies. Missing suggestion fields never erase current
  values. Photos, Tags, staged periods, draft identity, and the original edit
  snapshot are retained. Fields are checked when applying, not when generation
  begins. Applying does not save.
- Period candidates show their source passage and distinguish purchase, order,
  delivery and relationship dates. Review each desired candidate, edit its partial
  dates, choose an ongoing or ended state when unresolved, and choose Use Period.
  The application section shows how many periods will be added. While any remain
  unreviewed, its primary action opens the next period review. Applying without
  unreviewed periods is a separate, explicit action rather than silent omission.
  An empty period result is displayed explicitly. Different acquisition dates can be
  alternatives for one period; they are not automatically separate saved periods.
- The person can edit or remove staged periods and correct filled fields before
  ordinary Save. Metadata, photos, Tags and reviewed period additions save in one
  transaction. Existing periods are rechecked for conflicts in the writer context
  and never overwritten. Validation or save failure retains the draft and saves
  none of that submission. No Mark, Tag, photo or Item is generated automatically.
- Stopping a request preserves source text. Editing the source invalidates the
  suggestion. Closing the sheet discards its temporary input. Task cancellation
  and request identity prevent late completions from changing a newer request.
- Prepare Item from Text exposes the same Operations through `InferItemIntent`.
  It requires authentication and returns readable text without saving or opening
  links. It has no template grammar and is not a lossless interchange format.

`ItemInputOperations` owns extraction, availability, validation, and empty-field
application in the shared library. UI and App Intents are thin adapters. The
operation does not receive a ModelContext or read the saved collection.

## Model boundary

Use `SystemLanguageModel.default` with fresh sessions and guided generation for
each request. Instructions require the complete identifying name and descriptive
passage, including supplied dates, prices, specifications, experiences and
uncertainties. Comparisons with other products remain descriptive context.
The complete note is retained even when its dates also supply period candidates.

Date extraction is separate from text generation. The app locates explicit
Gregorian date expressions in Japanese, ISO/slash notation and English month-name
notation, retaining their stated year/month/day precision. Relative, invalid and
unsupported dates remain in the note rather than being completed from today's
date. The on-device model classifies each located date's meaning in a fresh
session; it cannot supply or change a date. Model/release years, prices, repairs,
exchanges, future plans, and dates by which an Item was already owned are not
relationship starts. Semantic classification still requires human review.
Classification uses the sentence around a date, narrowing separate clauses when
several dates share a sentence. The generated action must occur in the source,
and events about another Item are excluded. Explicit Japanese from/until markers
preserve the boundaries of a recognized relationship range. Current use requires
an explicit statement; past use alone does not establish it.

Orders, purchases and original deliveries remain distinct alternatives. Explicit
start/end dates form candidates in source order; a later resumption remains a new
candidate. An end can have an unknown start. Purchase/order/delivery alone does
not assert ongoing ownership, and a missing end never establishes continuation.
At most 24 date expressions are classified per request; larger inputs fail
visibly rather than silently dropping dates. Cancelling stops further requests
and prevents any late result from applying.

Names and links must occur verbatim in the source. Notes first use exact excerpt
matching. When only whitespace or line breaks differ, validation accepts a
single unambiguous contiguous source passage and restores its original text.
It does not join separated excerpts, change punctuation, repair factual changes,
or normalize names and URLs. Links also pass the existing representative-URL
validator. Unsupported fields still reject the suggestion; there is no silent
partial-result fallback. This reduces invented content but cannot establish that
an excerpt is complete or describes the intended subject. Human review remains
necessary, and missing or unreliable names fail visibly.

Input is trimmed and limited to 4,000 characters without silent truncation.
Context exhaustion still reports a shorter-input recovery because character
count is not token count. Unavailable hardware, disabled Intelligence, preparing
models, unsupported language, refusal, and generation failure have localized
recovery text. There is no network fetch, PCC model, external provider, automatic
retry, saved transcript, or raw-input logging.

Apple references: [guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation),
[model availability](https://developer.apple.com/documentation/FoundationModels/generating-content-and-performing-tasks-with-foundation-models),
and [language support](https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models).

## Verification boundary

Library tests cover input budgets, unsupported fields and links, restoration of
multiline notes, ambiguous matches, changed facts and excerpt order, cancellation
after generation, visible failures, preservation of intervening edits and draft
identity, no writes before Save, and persistence after reopen. Period tests cover
partial-date preservation, date-role mapping, explicit adoption, alternatives,
ended and resumed relationships, conflict rechecks, and atomic save failure.
Model probes and UI evidence are separate from those deterministic tests.
Physical-device quality, VoiceOver, and final-candidate distribution qualification
remain release checks. A successful synthetic probe is not a general accuracy or
performance guarantee.

For extraction evaluation, compare short prose, labelled multiline descriptions,
and unlabelled equivalents. Record generation errors, source validation, complete
names, complete notes, and supplied links separately before applying or saving.
An export alone cannot distinguish model omissions from later manual edits or
establish how many requests failed. Keep private inputs and raw model outputs
outside the repository and CI; use unrelated synthetic data for retained tests.

Treat well-formed source examples as an acceptance gate: require complete names,
notes and supplied links, all supported acquisition/relationship candidates,
correct date precision and event meaning, and no unsupported additions. Repeat
model evaluation after prompt or schema changes; do not count a merely nonthrowing
request as correct. Evaluate informal prose and ambiguous dates separately, and
keep model/OS/runtime evidence distinct from physical-device qualification.
