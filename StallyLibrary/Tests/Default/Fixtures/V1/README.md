# Original V1 Persistence Fixtures

These are synthetic fixtures captured before changing the persisted models.
The model, migration plan, and backup writer are from commit `36a00d0`.
The capture ran on Xcode 27.0 (`27A266a`), iOS 27.0 Simulator, on
September 13, 2026. Its unchanged V1 writer passed 115 tests in 26 suites.

- `Stally.store` and `.Stally_SUPPORT/` contain four Items, four Marks, one
  archived Item, never-marked Items, and a valid external JPEG photo.
- `Empty/` contains an actual empty V1 store written by that same model.
- `backup-v2.stallybackup` is the original restorable v2 export.
- `photo.jpg` and `links.json` retain independent photo/link expectations.
- `schema.txt` lists the original entity and property names.
- `CaptureV1FixtureTests.swift.txt` is the capture source, deliberately not
  part of the current test target. Run it only against the original V1 writer.
- `SHA256SUMS` records every retained fixture file except this README and
  the checksum list itself.

The store was closed before copying. Its WAL files were empty; transient
WAL/SHM files are omitted. Preserve the support directory and external data
when copying the store. Never open the checked-in originals for writing.
Tests open disposable copies with CloudKit explicitly disabled.

Original store version: `1.0.0`. Original model checksum:
`5XFt0lptsXyG3MozLSUwfbVkkrnxiyHyutli/Z42MWA=`.

Do not regenerate these fixtures with a newer model or rewrite the v2 export
when the current wire format advances. Compare UUIDs, fields, Mark ownership,
and photo bytes after migration and repeated reopen. Array order in a
SwiftData relationship is not a preservation requirement.
