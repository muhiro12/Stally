# Photo Storage Design

## Status and Product Principle

On October 24, 2026, the owner accepted this principle: Stally preserves the
user's record of a subject and their relationship with it; photos are durable
visual material supporting that record. This document selects the 1.0 photo
specification after reevaluating the earlier proposals against that principle.
The principle is owner-confirmed. The numeric limits and implementation choices
below are delegated engineering decisions, not Apple requirements.

This is a design specification with bounded standalone evidence. The production
application has not adopted it. Earlier 2,560-pixel, quality-0.85, five-MiB,
and memory-only-thumbnail recommendations are superseded.

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
| Saved image encoding | JPEG stays JPEG; HEIC/HEIF uses HEIC; PNG or alpha-bearing input uses PNG |
| Lossy quality | ImageIO compression-quality input 0.90 for saved JPEG and HEIC |
| Saved byte limit | 8 MiB per attachment image |
| Orientation | Apply the source orientation to the saved pixels |
| Color and alpha | SDR output; preserve resulting color profile and transparency |
| Source metadata | Omit GPS, shooting dates, camera details, and free-form source metadata |
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

The saved image remains SDR in 1.0. ImageIO supplies the SDR decode operation;
do not implement tone mapping or gain-map processing in app code. HDR headroom,
RAW editing data, depth, animation, and Live Photo motion are outside the saved
representation. A Live Photo may supply a supported still representation.
Reject unsupported or multi-frame deliveries instead of silently picking an
animation frame. Do not imply that preserving HEIC as a format preserves every
HEIC auxiliary resource.

## Why These Choices

### Resolution and Compression

Compare long-edge limits of 2,048, 2,560, 3,072, and 4,096 pixels and quality
inputs of 0.80, 0.90, and 0.95. Choose 3,072 and 0.90 to leave useful detail
beyond a small phone preview while bounding decode size and storage. A square
8-bit RGBA image at this limit has 36 MiB of pixel data, versus 64 MiB at
4,096; this is bitmap arithmetic, not a measured process-memory ceiling.

The larger Apple sample photographs in the comparison were 3,000 by 2,000
pixels. The selected limit avoids resampling them; quality 0.90 reduced their
roughly 7.3-7.7 MiB source files to 2.7-3.3 MiB. Smaller Wishlist photos were
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

SDR is an explicit first-release scope choice for these record-oriented copies,
not an Apple limitation. Apple also provides native gain-map preservation for
HEIF. Keeping every HDR representation is a valid alternative for a product
that promises photographic fidelity; that is not Stally's selected promise.

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

Generate the thumbnail from the final saved-image bytes during creation and
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

Use ImageIO to downsample with orientation correction and SDR decoding, then
encode the selected format with the resulting color profile. Inspect alpha
before choosing the output. Process imports sequentially initially and support
cancellation. The input-byte guard does not bound a provider's internal download
or memory use.

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
policy. It covered HEIC, alpha PNG, orientation, color profiles, source-
metadata omission, malformed data, thumbnail size/byte bounds, and rejection
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

## Official References

- [Wishlist and its persistence demonstration][wishlist]
- [Wishlist sample source][wishlist-source]
- [Landmarks sample used for image fixtures][landmarks]
- [PhotosPicker loading and temporary file ownership][picker-loading]
- [Picker encoding and metadata choices][picker-encoding]
- [ImageIO for reducing decoded image memory][image-memory]
- [Native HEIF gain-map preservation][gain-map]
- [NSCache cost limits are advisory][cache-limit]

[wishlist]: https://developer.apple.com/videos/play/wwdc2026/275/
[wishlist-source]: https://developer.apple.com/documentation/SwiftUI/wishlist-planning-travel-in-a-swiftui-app
[landmarks]: https://developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass
[picker-loading]: https://developer.apple.com/documentation/photokit/bringing-photos-picker-to-your-swiftui-app
[picker-encoding]: https://developer.apple.com/videos/play/wwdc2023/10107/
[image-memory]: https://developer.apple.com/documentation/xcode/making-changes-to-reduce-memory-use
[gain-map]: https://developer.apple.com/documentation/imageio/kcgimagedestinationpreservegainmap
[cache-limit]: https://developer.apple.com/documentation/foundation/nscache/totalcostlimit
