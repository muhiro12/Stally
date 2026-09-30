# Interchange Fixtures

`v3.stallybackup` is a hand-authored synthetic golden file for the current
portable contract. It contains a non-Mark Home with a year start and an
archived Mark-enabled coat with a month start, fractional recording instants,
UUIDs, and whitespace/Unicode note text. It contains no personal data or photo.
Photo bytes and every start precision have separate complete round-trip tests.

Keep this fixture stable when evolving the format. Add a new version and its
conversion/rejection test deliberately. Original V1 stores and v2 interchange
capture provenance remain separately frozen under `../V1/`.
