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
  review the name/note/link, then choose Fill Empty Fields.
- Existing editor text is preserved exactly, including whitespace. Photos, Tags,
  draft identity, and the original edit snapshot are retained. Fields are checked
  when applying, not when generation begins. Applying does not save.
- The person can correct filled fields before the ordinary Save operation.
  No Mark, Period, Tag, photo, or saved Item is generated automatically.
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

Use `SystemLanguageModel.default` with a fresh session and guided generation for
each request. Instructions require source-language preservation and verbatim
excerpts. All nonempty generated fields must occur in the source; links must
also pass the existing representative-URL validator. This reduces invented
content but does not prove that an excerpt describes the intended subject, so
human review remains necessary. Missing or unreliable names fail visibly.

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

Library tests cover input budgets, unsupported fields and links, cancellation
after generation, visible failures, preservation of intervening edits and draft
identity, no writes before Save, and persistence after reopen without history.
Model probes and UI evidence are separate from those deterministic tests.
Physical-device quality, VoiceOver, and final-candidate distribution qualification
remain release checks. A successful synthetic probe is not a general accuracy or
performance guarantee.
