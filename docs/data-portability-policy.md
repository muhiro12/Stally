# Data Portability and Compatibility Policy

Accepted development direction, November 10, 2026. This document defines product
intent and maintenance judgment; it does not claim that the illustrative copy
below is already displayed in the app.

## Export purpose and supplementary import

Export primarily lets people use their records in AI tools and other software
of their choice. Import is a supplementary capability, currently intended
mainly for timely transfer between devices. Do not design or present this pair
as a complete backup service with indefinite restoration support.

Device transfer normally means exporting and importing close together, such as
the same day or within about a week. These are usage expectations, not an expiry
rule or a guaranteed support period. Other uses may justify their own scope
later; they do not silently expand the first-release import contract.

## File compatibility

Support an explicit set of published `formatVersion` and `schemaVersion` pairs.
Retain recent readers to accommodate ordinary device transfer across app
updates. Do not make every app release invalidate the previous release's files.
The number of readers and any future retirement timing remain undecided.

Do not reject a supported file solely because it was exported long ago. File
age is not the compatibility boundary, and no per-file expiration is selected.
An older file can remain importable while its format is supported. Changes to
Stally's import support do not expire or alter the exported content itself.

Historical readers need not be maintained forever regardless of cost. Review
any proposed retirement against released promises, expected transfer behavior,
and the ability of older apps to keep producing that format. Supporting one
previous version alone does not establish a transfer window when releases can
occur close together. State the supported pairs and qualify their adapters;
do not infer support from an app release number.

Required updates can help coordinate a transition, but do not convert existing
files or by themselves prove that old writers have stopped. Account for actual
offline and export behavior described in [update control](remote-update.md).
This policy introduces no additional network requirement or export restriction.

Supplementary scope does not weaken correctness. Validate before mutation,
review meaningful differences, preserve omitted destination facts, and reject
unsupported input without partial writes. See the [import contract](import-identity-design.md)
and [file specification](export-file-format-design.md).

## Explain the useful action and its limits

Use ordinary language to describe external use, device transfer, and prompt
re-import. Avoid schema numbers, implementation explanations, and defensive
"not a backup" disclaimers in the ordinary flow. Make the support limit clear
where someone chooses to export or import, without implying that the exported
information itself becomes unusable outside Stally.

Illustrative copy, to adapt to the actual surface and localize before release:

> Use your records in other apps or transfer them to another device.
> If you plan to import the file into Stally, do so soon after exporting.
> Older files may not be supported by future versions of Stally.

If import rejects a file, explain that the file is unsupported. Suggest a new
export only when the original records remain available; do not imply that
re-exporting is always possible. Keep existing photo and record-scope disclosures.

## Internal database maintenance

Aim to protect everyone who has used Stally. Also consider the continuing cost
of historical migration support during daily design and development. A major
release may be a useful time to revisit that tradeoff, without requiring a
retirement schedule, automatic cutoff, or removal of working migration paths.

Elapsed time and usage observations can inform judgment; neither alone proves
that no returning or offline user needs an old migration. Any concrete removal
requires its own compatibility decision. This is an internal engineering stance,
not a user-facing data expiry rule.

Database migration and exported-file compatibility have separate responsibilities.
Retiring an import reader does not authorize dropping a store migration, and
retaining store migrations does not promise indefinite import support.
