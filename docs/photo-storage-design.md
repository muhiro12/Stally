# Photo Storage Design

## Status and Product Principle

On October 24, 2026, the owner accepted this principle: Stally preserves the
user's record of a subject and their relationship with it; photos are durable
visual material supporting that record. This document selects the 1.0 photo
specification after reevaluating the earlier proposals against that principle.
The principle is owner-confirmed. The numeric limits and implementation choices
below are delegated engineering decisions, not Apple requirements. The owner
subsequently authorized proceeding with this design if two supplied photographs
passed verification. The bounded check below found no reason to change the
then-selected policy. A subsequent review of unnecessary recompression
refines that baseline: preserve qualifying delivered bytes, and transform
only images that exceed the saved byte or dimension limits. This is a
delegated engineering refinement prompted by the owner's comparison with
Cookle, not a claim that the owner mandated copying Cookle's implementation.

This is a design specification with bounded standalone evidence. The production
application has not adopted it. Earlier 2,560-pixel, quality-0.85, five-MiB,
and memory-only-thumbnail recommendations are superseded. The subsequent
owner direction to retain useful delivered metadata supersedes blanket source-
metadata omission; it does not change the Item, Mark, or Period contracts.

## Preservation Responsibility

Keep an independent, useful copy for recognizing the subject and revisiting
visible details, including on a larger display. The source library or provider
remains where the user manages the original. Stally does not promise original
pixel fidelity, photographic editing latitude, or preservation of all camera
resources. Its copy may nevertheless become the user's only surviving image;
being a copy is not justification for reducing it to a list icon.

The saved attachment image is the authoritative representation of the Stally
attachment. Source deletion or editing does not change it. Attachment deletion
does not change the source. Do not add source-path identity, an original-opening
promise, or source-library synchronization.

Distinguish the source original, the saved attachment copy, and its derived
thumbnail. Persist the attachment and a small thumbnail, not another raw source
original. Export uses the saved attachment; it cannot reconstruct the source.

## Selected 1.0 Policy

| Concern | Specification |
| --- | --- |
| Supported input | Decodable still JPEG, HEIC/HEIF, and PNG |
| Input byte limit | 64 MiB before decoding |
| Input dimensions | Positive; at most 16,384 pixels per edge and 100 million pixels total |
| Saved image dimensions | Longest edge at most 3,072 pixels, aspect ratio retained, no upscaling |
| Saved image processing | Preserve valid supported input bytes within both saved limits; otherwise transform once |
| Encoding when transformation is required | JPEG stays JPEG; HEIC/HEIF uses HEIC; PNG or alpha-bearing input uses PNG |
| Lossy quality | ImageIO input 0.90 only when encoding a transformed JPEG or HEIC |
| Saved byte limit | 8 MiB per attachment image |
| Orientation | Preserve source orientation in unchanged data; apply it during display and thumbnail decoding; normalize transformed output |
| Color and alpha | Preserve qualifying source bytes; use native SDR display/thumbnail decoding and SDR transformed output; retain transparency and resulting color profile |
| Source metadata | Retain delivered standard descriptive metadata in imageData, including shooting dates, GPS, camera/lens details, and descriptions; normalize geometry metadata only when transforming pixels |
| Thumbnail dimensions | Longest edge at most 512 pixels, aspect ratio retained, no upscaling |
| Thumbnail encoding | JPEG at quality 0.70 for opaque content; PNG for alpha-bearing content |
| Thumbnail byte limit | 2 MiB safety ceiling; ordinary results should be much smaller |
| Thumbnail storage | Optional thumbnailData on ItemPhoto, persisted through SwiftData |
| Decoded thumbnail reuse | NSCache, initially a 32-MiB cost hint using decoded byte cost |

The quality values are encoder inputs, not percentages of retained fidelity or
comparable perceptual scores across codecs. PNG is lossless for the resulting
pixels; resizing can still remove source detail. These resource limits are
bounds, not byte targets to fill. A high-entropy image can exceed the byte cap
at an otherwise valid resolution.

The 1.0 presentation path uses native SDR decoding. Transformed saved images
are also SDR. An unchanged accepted file may still contain its delivered HDR
or auxiliary data; do not re-encode it solely to erase those resources or
classify HDR through a custom detector. ImageIO supplies the display decode
operation. There is no custom tone mapper or gain-map engine.

RAW input, animation, Live Photo motion, and auxiliary-resource editing or
round-trip guarantees across transformations remain out of scope. A Live Photo
may supply a supported still representation. Reject unsupported or multi-frame
deliveries rather than silently selecting an animation frame. Successful
native SDR decoding is required regardless of the preservation branch.

### Preserve Before Transforming

Apply these steps in order:

1. Validate delivered bytes: supported still JPEG/HEIC/HEIF/PNG, complete source
   and image status, a single image, positive dimensions within input guards,
   and successful orientation-aware native SDR pixel decoding. Header/status
   checks alone are insufficient; malformed or truncated data is not accepted
   merely because its byte count is small.
2. If the complete delivered file is at most eight MiB and its longest pixel
   edge is at most 3,072, store those exact bytes in imageData. Do not encode a
   candidate to see whether it could be smaller. This includes metadata,
   orientation, color profile, and any embedded resources already in the file.
3. Otherwise, downsample without upscaling and encode once using the selected
   format, metadata, and quality policy. Validate the result against the saved
   limits. Failure must not fall back to saving the oversized original.
4. Generate the independent 512-pixel preview from the selected saved bytes.
   Display decoding applies orientation and requests SDR. A preview failure
   retains the valid saved image under the existing optional-preview policy.

An unchanged file is an independently owned attachment, not a reference to its
source. Store just one authoritative imageData payload; no second original,
normalization flag, format column, or schema migration is required. Native
readers inspect the saved format and orientation when needed. Export that
requires metadata exclusion must process a separate output copy.

This deliberately prioritizes preservation over additional storage reduction
for qualifying images. For example, a seven-MiB JPEG below the edge cap remains
seven MiB even if quality 0.90 could produce a three-MiB copy. The eight-MiB cap
is the explicit storage budget; it is not a target file size or a guarantee
that every saved image was compressed as far as possible. This also avoids
recompressing all inputs just to compare two file sizes.

## Why These Choices

### Exact Constants and Strength of Evidence

The selected constants do not all have the same evidential strength. The
direction of the quality/size tradeoff has measured support; exact resolution
and rejection thresholds are engineering budgets, not discovered optima.

- 3,072 means a roughly three-thousand-pixel detail image, expressed as three
  times 1,024. There is no demonstrated special advantage over 3,000 or 3,200,
  nor an assumed power-of-two optimization. The rationale is more detail than
  a roughly two-thousand-pixel copy with lower maximum decode cost than a
  four-thousand-pixel copy. The largest photographic fixtures were 3,000
  pixels, so the experiment does not establish the exact best upper limit.
- Eight MiB provides output headroom above the measured roughly three-MiB
  detailed JPEGs and accommodates some larger PNGs, while rejecting unusually
  large saved payloads. It is neither a SwiftData/CloudKit requirement nor a
  percentile derived from a representative personal photo library. Six or
  ten MiB could also be defensible budgets; eight is the selected initial one.
- A 512-pixel preview initially targets small collection cells: a 160-point
  fitted image at scale three needs 480 pixels on that edge. This is a design
  assumption, not proof that every actual layout fits. Larger presentations
  or aspect-fill crops needing more source pixels must use the saved image.
- Preview quality 0.70 prioritizes recognition at small sizes and reduced
  repeated storage/decoding over magnified detail. Wishlist uses 0.70 as its
  thumbnail encoder input too, but its different size and UIKit encoding path
  do not make the value an Apple-wide recommendation or an identical codec
  calibration. The additional ImageIO comparison below supports its size
  effect, not a universal no-visible-loss claim.

### Numeric Budgets and Boundary Rules

Binary byte units and bitmap arithmetic make the budgets explainable; powers
of two do not by themselves make image dimensions faster or higher quality.
Keep the current values after the codec comparisons and boundary checks. These
are initial application budgets, not undocumented Apple platform limits.

| Value | Basis and practical meaning |
| --- | --- |
| 3,072-pixel saved edge | 3 x 1,024; at most 36 MiB for a square 8-bit RGBA bitmap, versus 64 MiB at 4,096; additional detail beyond 2,048 |
| Quality 0.90 when transforming | Native JPEG/HEIC measurements show substantial byte reduction versus 1.0; not a 10-percent fidelity reduction |
| 8-MiB saved bytes | A binary storage budget with over twice the headroom of the largest approximately 3.3-MiB photographic result; not a guarantee for every PNG |
| 512-pixel preview | Binary size covering a fitted 160-point image at scale three; one MiB for square 8-bit RGBA pixels |
| Quality 0.70 | Small-preview tradeoff with measured roughly 30-percent JPEG savings versus 0.90; also used as an input by the Wishlist sample, not an Apple-wide rule |
| 2-MiB preview bytes | Twice the one-MiB 8-bit RGBA bitmap budget; a safety ceiling for encoded derivatives, not a compression or file-size theorem |
| 32-MiB decoded cache cost | About 32 square 512-pixel 8-bit RGBA previews, excluding object/allocator overhead; NSCache may evict earlier or exceed the hint |
| 64-MiB input bytes | An explicit staging/transfer acceptance budget, eight times the saved-image cap, allowing larger source files before normalization |
| 16,384-pixel input edge | 16 x 1,024; bounds very elongated images while allowing wider panoramas than the output cap |
| 100-million input pixels | A decimal 100-megapixel acceptance budget, including 8,064 x 6,048 sources; prevents the edge bound from admitting a 268-million-pixel square |

The input ceilings are checked together, before asking for decoded pixels.
Positive dimensions, byte counts at or below the ceiling, and pixel counts at
or below the ceiling are accepted; any excess is rejected. Avoid multiplication
overflow when validating dimensions. A source at the pixel ceiling could need
about 381 MiB just for a full 8-bit RGBA bitmap. Therefore the policy uses
ImageIO downsampling, sequential imports, and cancellation; it does not allocate
that bitmap deliberately or claim the guards guarantee a process-memory bound.
The 64-MiB input budget is not a cap on provider-internal downloads or buffers.

These byte and input ceilings remain engineering choices, rather than measured
population percentiles or platform constants. Exact neighboring values are not
materially better established. Revisit them if actual device/provider evidence
shows rejection or memory problems; no schema migration is needed to change an
import budget. Existing attachments must not be rewritten or deleted to enforce
new limits retroactively.

### Metadata Preservation

Preserved input bytes retain all delivered metadata unchanged. When
transformation is required, retain useful facts through standard ImageIO
metadata APIs. This follows the owner's
record-preservation intent and replaces the earlier blanket-omission policy.
Keeping those facts does not require extra SwiftData fields, a new entity,
raw-source retention, or a source-library dependency. They remain embedded in
the saved imageData bytes and share the attachment's lifetime.

Preservation covers standard shooting date/time, any supplied UTC offset and
subsecond precision, GPS, camera make/model, lens and exposure information,
and descriptive/rights metadata such as IPTC descriptions and keywords. Keep
available descriptions in the image; do not automatically overwrite the
independently editable ItemPhoto.caption. Retain supported descriptive XMP
through ImageIO's metadata representation, without promising byte-identical
EXIF/XMP serialization or round trips for every proprietary namespace.

On the transformation branch, read metadata with
CGImageSourceCopyMetadataAtIndex, make a native mutable copy, and write it with
CGImageDestinationAddImageAndMetadata alongside the normalized pixels. Normalize
orientation and image dimensions to the saved pixels; source geometry is not a
historical shooting fact. Do not copy an obsolete embedded preview into
transformed output or claim that proprietary MakerNotes, editing instructions,
face/depth geometry, gain maps, or other auxiliary camera resources survive as
usable resources. Supporting those beyond native descriptive metadata is outside
the selected 1.0 image contract, not a reason to discard dates or GPS.

An absent timestamp, offset, or location remains absent. Do not infer it from
file creation time, ItemPhoto.createdAt, the device's current time zone, an
ItemPeriod, or a Mark. Shooting time without an offset stays an offset-free
source fact; it does not become a trustworthy global instant. This preserves
the existing core-model meanings without expanding their schemas.

Respect the picker/provider's delivered representation. Do not request broader
photo-library access to recover excluded metadata, or add location permission
merely to retain coordinates already supplied in an image. The source library
may contain information that the selected delivery does not include; Stally
does not promise to recover it.

Generate thumbnails from decoded saved pixels without copying descriptive
metadata. The saved image already retains those facts; the preview is a
rebuildable derivative. Include embedded metadata when enforcing the saved byte
ceiling. If transformation metadata writing fails or the result exceeds the
ceiling, fail the import while retaining the previous record/draft; do not retry
by silently stripping metadata. Native inability to preserve arbitrary
proprietary fields is outside the stated contract and does not justify a custom
parser.

Preservation and outward disclosure are separate decisions. A later export
policy may offer a copy with metadata omitted or masked; it must not modify
the saved attachment. Do not assume that removing the standard GPS dictionary
anonymizes every image: Apple notes that proprietary metadata can also contain
location, and image pixels or descriptions can disclose it. Exact export
controls and defaults belong to the export-contract discussion. This decision
neither exports images nor finalizes those controls.

### Resolution and Compression

Compare long-edge limits of 2,048, 2,560, 3,072, and 4,096 pixels and quality
inputs of 0.80, 0.90, and 0.95. Choose 3,072 and transformation quality 0.90 to
leave useful detail beyond a small phone preview while bounding decode size and
storage. A square 8-bit RGBA image at this limit has 36 MiB of pixel data,
versus 64 MiB at 4,096; this is bitmap arithmetic, not a measured process-memory
ceiling.

The larger Apple sample photographs in the comparison were 3,000 by 2,000
pixels. The selected limit avoids resampling them; the earlier always-encode
comparison at quality 0.90 reduced their
roughly 7.3-7.7 MiB source files to 2.7-3.3 MiB. Under the revised policy those
qualifying source files are retained unchanged. Smaller Wishlist photos were
also tested without upscaling. The larger samples cannot establish a visual
difference between 3,072 and 4,096 because both preserve their dimensions.
The upper-resolution choice is a product/resource tradeoff, not a claimed
experimentally optimal number.

Use eight MiB as output headroom for varied content, including PNG, rather
than reducing quality repeatedly to meet a small target. It is independent
of the resolution bound. The same native codec family avoids mandatory
HEIC-to-JPEG conversion, which increased size in the earlier functional probe.
Retain the current input resource guards: they accommodate common high-pixel-
count sources while rejecting excessive work before full decoding.

SDR display and transformed output are explicit first-release scope choices, not
Apple limitations or reasons to recompress otherwise acceptable bytes. Apple
also provides native gain-map preservation for HEIF. Keeping every HDR
representation is a valid alternative for a product that promises photographic
fidelity; that is not Stally's selected promise.

### Persistent Thumbnail Instead of Memory-Only Generation

Select persistent thumbnails plus decoded-memory reuse. Stally repeatedly shows
photos in collections and details; a thumbnail should survive process exit so
the list does not need to regenerate every preview from the saved images.
This is a concrete recurring read requirement, not a hypothetical scale issue.

Apple's Wishlist source stores thumbnailData and external image bytes and
uses the thumbnail for collection display. Adopt that separation of roles,
with thumbnailData on ItemPhoto rather than an Item-level duplicate or a new
model. Stally has multiple attachments and no need for a shared asset layer.
Apple's sample uses a 1,290-pixel thumbnail for its large travel cards; Stally
selects 512 for collection previews and reads the saved image for larger views.
Do not copy the sample's display-specific numeric constants.

This trades a small persisted derivative for avoiding repeated image processing
on cache misses after restart. The measured detailed-photo previews were about
96-105 KiB each, approximately 3-4 percent of the corresponding saved images.
These are fixture measurements, not a universal overhead percentage. A PNG
preview can be larger. The two-MiB ceiling is a guard, not an expected size.

thumbnailData is rebuildable, optional data. It is not the source for export,
editing, or saved-image recovery. It can arrive before or after imageData in
sync. A thumbnail-only record can show its preview but must not claim the full
image is available. If the thumbnail is absent and imageData is available,
generate a display fallback without automatically writing sync repair records.
If both are unavailable, retain attachment metadata and show an unavailable
state. Never delete the attachment to repair a missing derivative.

Generate the thumbnail from the selected saved-image bytes during creation and
import. Caption edits and reordering change neither image nor thumbnail bytes.
A deliberate image replacement creates a new ItemPhoto and replaces the old
attachment through an explicit operation; the UI may carry over caption and
position. Treat a saved attachment's image content as immutable in ordinary
operations, so two separately arriving derivatives refer to one image identity.
This is not a distributed transaction guarantee: related insertions/deletions
can still arrive separately. Do not add a synchronization engine to hide that.

Use no app-managed persistent thumbnail directory. Native SwiftData manages
saved bytes and their deletion; NSCache reuses decoded previews in process.
Its 32-MiB cost limit is advisory, not a hard process-memory bound. Detail views
request the display size they need, bounded by the saved image dimensions.

## Ingestion and Failure Behavior

Use PhotosPicker and Transferable for photo-library selection. Request the
current generic image representation to avoid a redundant intermediate
transcode. Prefer FileRepresentation for large or multiple transfers. Use the
system document import boundary for files exposed by iCloud Drive or third-
party providers. PhotosPicker does not browse arbitrary external providers.

Read/copy within the granted access lifetime, then release external access.
An app-owned raw staging file lasts only until independently owned prepared
bytes exist, or until failure/cancellation. Remove abandoned app-owned staging
files after process termination on a later startup without touching live
imports or SwiftData-managed files. Do not retain another raw original.

Use the preserve-before-transforming decision above. When transformation is
required, use ImageIO to downsample with orientation correction and SDR
decoding, then encode the selected format with the resulting color profile and
supported descriptive metadata. Normalize geometry metadata with pixels. Inspect
alpha before choosing the output. Process imports sequentially initially and
support cancellation. The input-byte guard does not bound a provider's internal
download or memory use.

If the saved image exceeds eight MiB, reject that import with a clear message
and preserve the existing photo and draft. Do not flatten alpha, repeatedly
lower quality, or silently discard another photo. If generating a derivative
fails or exceeds its cap, retain the valid saved image with nil thumbnailData;
a display fallback can be retried later. The thumbnail is not primary data.

A prepared draft remains available after a save failure. Cancelled or failed
source loading must not create a completed attachment with missing image data.
Successful saving, not picker selection, establishes the durable attachment.

Do not recompress saved image bytes when reading, editing captions, reordering,
exporting, or restoring an identity-preserving Stally export. A portable export
need not include thumbnails; import can regenerate them from the saved image.
Existing limits may evolve without new fields, but changes do not authorize
silently rewriting prior saved image bytes.

## Schema and Capacity

Add one optional property to the selected ItemPhoto model:

```swift
var thumbnailData: Data?
```

Keep imageData as `@Attribute(.externalStorage)`. It is the only authoritative
saved-image representation; SwiftData-managed external files are part of that
attribute's lifetime. thumbnailData is an ordinary optional Data attribute,
following the sample's small-preview pattern. Do not promise a physical SQLite
layout; storage placement is framework-managed. There is no thumbnail entity,
source-path field, codec field, or persisted decoded-image cache.

Keep uuid, caption, sortOrder, createdAt, and item unchanged. The owner accepted
the attachment-local caption and ordering rationale. Item deletion cascades to
its photos; child deletion preserves Item. Sort by sortOrder then UUID, using
the first ordered photo as cover. Ties after sync remain visible.

No arbitrary photo-count or collection quota is selected. One thousand images
averaging one MiB, with 100-KiB previews, occupy about 1.07 GiB of encoded
bytes.
At both hard ceilings, one thousand image/preview pairs could occupy about
9.77 GiB, before store overhead, staging, and cloud copies. These are explicit
capacity tradeoffs, not a promise that all libraries remain small. A failed
save must preserve existing records rather than purging them for space.

## Verification Evidence and Limits

Apple sample source inspection covered Wishlist's Trip, TripImage, its image
view, and its creation path. The locally cached source contains both the
nonpersistent and SwiftData examples; the current WWDC26 demonstration confirms
the persistent-preview pattern. Sample-specific UI dimensions, simplified
errors, and temporary-file code were not treated as production requirements.

The new ImageIO comparison encoded 84 JPEG variants: four Wishlist photographs
at four size caps and three quality values, plus three 3,000-by-2,000 Landmarks
photographs with the same matrix. The first group is smaller than 2,048 pixels,
so it evaluates recompression without resolution reduction. Visual inspection
covered a selected Landmarks photograph; this is not a comprehensive perceptual
quality study or proof that every small label remains legible.

| Larger fixture | Source bytes | Selected saved bytes | 512-pixel preview bytes |
| --- | ---: | ---: | ---: |
| Landmarks 1016 | 8,035,245 | 2,850,071 | 98,251 |
| Landmarks 1009 | 7,953,242 | 3,461,574 | 102,435 |
| Landmarks 1019 | 7,643,378 | 2,892,127 | 107,172 |

A SwiftData disk probe passed 36 assertions across six separate macOS processes.
It checked saved image and thumbnail byte equality after reopening, thumbnail
bounds, thumbnail-only partial availability, display-only regeneration for a
missing thumbnail, unchanged image bytes after caption/order edits, and owned
cascade deletion. All stages exited successfully; Core Data emitted routine
post-save vacuum debug messages. This was not a CloudKit arrival simulation or
an I/O/scrolling benchmark. It does not establish that the framework never
reads image bytes while fetching a model; app display paths must avoid using
imageData unnecessarily.

The store probe also compiled for iOS Simulator, and the complete five-model
Swift illustration compiled after adding thumbnailData. A separate ImageIO
run passed 59 assertions at the selected 3,072-pixel, quality-0.90, eight-MiB
policy before the metadata-preservation revision. It covered HEIC, alpha PNG,
orientation, color profiles, the then-selected source-metadata omission,
malformed data, thumbnail size/byte bounds, and rejection
of an oversized high-entropy PNG. This does not cover every input-boundary
combination or measure real HDR-camera rendering. The selected limits and
new schema still require production
integration tests, device memory/scrolling checks, real HDR-camera validation,
and cloud/provider round trips before release. Those are verification work,
not unselected first-release preservation policy.

Local comparison and store evidence are retained under
`/private/tmp/stally-photo-final.GflLbm`; earlier functional evidence is under
`/private/tmp/stally-photo-policy.OTt3Yw`. No sample source or image fixtures
were added to the application repository.

## Metadata and Resource-Boundary Evidence

A new native ImageIO probe passed 151 assertions on macOS 27.2 with Xcode 27.2.
Synthetic JPEG, HEIC, and alpha PNG inputs carried a shooting timestamp, UTC
offset, subsecond value, make/model, lens, exposure, GPS, copyright,
description, and keywords. The probe checked that these supported fields were
present in the input and equal after normalization. Images were reduced from
4,032 x 3,024 and rotated to 2,304 x 3,072; saved orientation and EXIF
dimensions matched the result. It also checked color-profile presence, PNG
alpha, absent metadata remaining absent, thumbnail omission of shooting/GPS
facts, and saved-file byte identity on reread.

| Format | Saved bytes with metadata | Without metadata | Difference |
| --- | ---: | ---: | ---: |
| JPEG | 320,025 | 316,753 | 3,272 |
| HEIC | 115,810 | 114,329 | 1,481 |
| PNG | 683,157 | 680,972 | 2,185 |

These are synthetic metadata/codec fixtures, not a personal-library size
survey. Differences include encoder/container behavior, not a universal EXIF
allocation. They show no material capacity obstacle for the selected standard
fields. They do not prove preservation of arbitrary proprietary metadata,
real camera HDR rendering, all eight orientations, or provider delivery.
The same source compiled for iOS Simulator; it was not run there or on a device.

A separate probe passed 35 assertions covering input byte/edge/pixel boundaries,
nonpositive and extreme integer values, saved-image and thumbnail byte limits,
native no-upscale behavior, and bitmap-budget arithmetic. Boundary predicate
checks do not prove successful decoding of a 100-megapixel image or measure
peak memory.

Sources and results are under the local evidence directory's metadata/ folder.
These additions replace the earlier metadata-omission expectation; earlier
compression, store-lifetime, and thumbnail evidence remains relevant within
its stated limits. No production models or application paths were changed.

## Owner-Supplied Photograph Validation

Two owner-supplied JPEG deliveries were processed with the selected 1.0 path:
orientation-aware ImageIO decoding without upscaling, quality-0.90 JPEG with
standard metadata retained, and a 512-pixel quality-0.70 preview. The source
files were read only. All generated images and probe files remained outside
the repository. No source filenames, library paths, metadata values, image
payloads, or image hashes are recorded here or included in the commit.

| Input | Input pixels | Input bytes | Saved bytes | Preview pixels | Preview bytes |
| --- | --- | ---: | ---: | --- | ---: |
| A | 1,024 x 768 | 307,796 | 271,450 | 512 x 384 | 70,065 |
| B | 1,086 x 724 | 250,649 | 269,817 | 512 x 341 | 56,794 |

Both saved images retained their input dimensions. The native probe passed 38
assertions, including input/output bounds, orientation, color-profile name,
standard metadata equality, preview GPS omission, saved-file reread, and source
byte equality after processing. It compared 53 and 61 existing standard
metadata fields respectively, excluding geometry that must describe the saved
pixels and opaque proprietary MakerNote blocks. Supplied shooting timestamps
and offsets survived. The inputs did not exercise absent shooting-time fields;
that case remains covered by the prior synthetic probe.

Visual inspection of both saved images and previews against the supplied
images found no conspicuous color shift, block artifacts, or detail loss that
would undermine record-oriented use. Subject detail and larger lettering
remained useful in the saved images. The smaller preview is for recognition;
small text and fine texture must be viewed using the saved image. This is a
bounded visual judgment, not proof of perceptual identity or a calibrated
color assessment.

Input B increased by 19,168 bytes (approximately 7.6 percent) after re-encoding.
A fixed encoder-quality value does not guarantee a smaller file than an
already compressed source. Both outputs remained comfortably within the byte
budget; this result does not justify another compression pass or a special
codec workaround. The specification promises bounded useful copies, not a
size reduction for every import.

The inputs were already reduced JPEG deliveries, both below the saved-image
size limit. They do not validate reduction from full camera resolution, HDR,
HEIC/PNG ingestion, cloud sync, or runtime scrolling/memory behavior. Source
originals were not sought elsewhere in the library. An initial restricted
execution failed in native image finalization; the same unmodified probe
completed under normal local execution permissions. This is macOS ImageIO
runtime evidence, not an iOS device or production-app test.

This check originally supported the always-encode design. The subsequent
pass-through evaluation below revises that choice. Production adoption and the
remaining device/provider checks retain their existing scope; no production
schema or image pipeline was changed by this validation.

## Conditional Preservation Review

Read-only comparison with Cookle at revision
8f0b85a3d68725b9205d4c73e430eb1004b0831b covered
CookleLibrary/Sources/Photo/PhotoImageProcessor.swift, its behavior tests, and
the app's CooklePhotoImageCompressor adapter. compressedData returns original
bytes when both limits are met. Its defaults are 500 KiB and 2,048 pixels;
its conversion path sweeps JPEG quality to approach the byte target. Its
existing contract can return invalid input unchanged or a result above the
requested target. Those policies serve its callers and are not adopted as
Stally's import-validation contract. Cookle was not modified.

Adopt the conditional preservation decision, with Stally's limits, format and
metadata policies, and strict rejection of invalid/unsupported input or an
oversized transformed result. This is consistent with the owner's preservation
principle independently of Cookle. Apple's orientation-aware thumbnail and
SDR decoding APIs let display normalization remain separate from stored bytes.

A new isolated macOS ImageIO probe passed 112 assertions. The two supplied
photographs were byte-identical after preparation and file reopening; original
source files remained unchanged. Metadata equality follows from complete byte
identity, without serializing any private metadata into repository records.

| Input | Previous always-encode bytes | Selected unchanged bytes | New preview bytes |
| --- | ---: | ---: | ---: |
| A | 271,450 | 307,796 | 64,806 |
| B | 269,817 | 250,649 | 56,531 |

The saved images incur no additional compression loss. The new previews were
also visually inspected and remained useful for collection display. Input A
uses more space than its previous transformed copy; this is the deliberate
preservation tradeoff, not a claim of universal space savings.

Additional cases covered unchanged small HEIC and alpha PNG, all eight EXIF
orientation values through native display decoding, exact 3,072-pixel retention
versus 3,073-pixel conversion, byte-only excess requiring conversion, rejection
of a PNG still too large after conversion, malformed/truncated JPEG rejection,
and unsupported TIFF/animated GIF rejection. The orientation cases checked
output dimensions and equivalence to the same native decoding of the source;
they were not independent pixel-oracle tests of Apple's orientation algorithm.

The final probe also compiled for iOS Simulator. It did not execute on iOS,
measure device memory, or validate actual HDR photographs. Native SDR handling
for retained HDR-bearing files remains an integration verification requirement;
no original-HDR-fidelity promise or custom HDR classifier was introduced.
Local probe sources, images, and results remain outside the repository under
/private/tmp/stally-photo-pass-through. No owner image, source filename,
metadata value, image hash, or personal library path was added to Git.

## Additional Compression Evidence

An additional same-pixel comparison encoded 36 variants from three Landmarks
JPEG photographs, using JPEG and HEIC at quality 0.70, 0.90, and 1.0, for both
saved-image and 512-pixel preview sizes. The preview inputs were the selected
saved JPEGs, matching the derivative path. Results on the local ImageIO encoder:

| Representation | Quality 0.70 | Quality 0.90 | Quality 1.0 |
| --- | ---: | ---: | ---: |
| Saved JPEG | 1.85-2.38 MiB | 2.72-3.30 MiB | 8.48-8.97 MiB |
| Saved HEIC | 1.09-1.36 MiB | 2.25-2.64 MiB | 8.47-8.98 MiB |
| 512-pixel JPEG preview | 95.95-104.66 KiB | 133.24-145.48 KiB | 365.34-431.48 KiB |

For the same individual images, quality 0.90 reduced JPEG bytes by 63-69 percent
and HEIC bytes by 69-75 percent relative to 1.0. This establishes a substantial
size effect in these fixtures, not equal fidelity or a universal reduction.
The HEIC inputs here were decoded JPEG photographs, not a camera-HEIC corpus.
No perceptual-equivalence test or noncompressed-image comparison was performed.
The output and source are under the local evidence directory's `rationale/`.

ImageIO's compression-quality input is not a linear file-size or fidelity
percentage. A value of 1.0 is not an uncompressed-file mode; Apple specifies
lossless compression at that value when the destination format supports it.
See the [compression-quality API][compression-quality].

## Official References

- [Wishlist and its persistence demonstration][wishlist]
- [Wishlist sample source][wishlist-source]
- [Landmarks sample used for image fixtures][landmarks]
- [PhotosPicker loading and temporary file ownership][picker-loading]
- [Picker encoding and metadata choices][picker-encoding]
- [ImageIO for reducing decoded image memory][image-memory]
- [Native HEIF gain-map preservation][gain-map]
- [ImageIO metadata objects and native field mapping][mutable-metadata]
- [Writing normalized pixels with metadata][add-metadata]
- [GPS exclusion scope][exclude-gps]
- [Orientation-aware display decoding][orientation-transform]
- [Native SDR decode request][decode-sdr]
- [Image source status][source-status]
- [NSCache cost limits are advisory][cache-limit]

[wishlist]: https://developer.apple.com/videos/play/wwdc2026/275/
[wishlist-source]: https://developer.apple.com/documentation/SwiftUI/wishlist-planning-travel-in-a-swiftui-app
[landmarks]: https://developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass
[picker-loading]: https://developer.apple.com/documentation/photokit/bringing-photos-picker-to-your-swiftui-app
[picker-encoding]: https://developer.apple.com/videos/play/wwdc2023/10107/
[image-memory]: https://developer.apple.com/documentation/xcode/making-changes-to-reduce-memory-use
[gain-map]: https://developer.apple.com/documentation/imageio/kcgimagedestinationpreservegainmap
[cache-limit]: https://developer.apple.com/documentation/foundation/nscache/totalcostlimit
[compression-quality]: https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality

[mutable-metadata]: https://developer.apple.com/documentation/imageio/cgmutableimagemetadata
[add-metadata]: https://developer.apple.com/documentation/imageio/cgimagedestinationaddimageandmetadata(_:_:_:_:)
[exclude-gps]: https://developer.apple.com/documentation/imageio/kcgimagemetadatashouldexcludegps

[orientation-transform]: https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailwithtransform
[decode-sdr]: https://developer.apple.com/documentation/imageio/kcgimagesourcedecodetosdr
[source-status]: https://developer.apple.com/documentation/imageio/cgimagesourcestatus
