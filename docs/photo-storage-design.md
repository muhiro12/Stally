# Photo Storage Design

## Decision and Scope

On October 24, 2026, the owner requested a decision on photo ownership,
capacity, thumbnails, and ingestion in this design session. Select an
app-owned, size-bounded attachment representation for Stally 1.0. This
supersedes the earlier preference for preserving received bytes unchanged.
It is a delegated engineering decision, not an implemented ingestion pipeline.

The existing ItemPhoto schema remains unchanged. Its imageData is the
authoritative image for that attachment after ingestion and a successful
save. Stally is not promising preservation of the camera original. The
original photo or provider file remains independently owned by its source.

### User-Facing Meaning

The owner clarified that application storage authority and the user's idea
of an original are different questions. Stally keeps a record-oriented copy
of a source image. The photo library or selected provider remains where the
user manages the original and its full fidelity; Stally does not take over
that archival responsibility when a photo is added.

The copy is nevertheless independently durable. Its role as a copy does not
make it a disposable cache or a live view of the source. Later source edits
do not invalidate it, and source deletion must not remove it. If the user
deletes the source, Stally can return only its saved copy, not reconstruct
the original quality. There is no promise of an original-opening link or
automatic retrieval of a higher-quality version.

Use three distinct terms in design: source original, saved attachment copy,
and rebuildable display thumbnail. The saved copy is the sole authoritative
representation of the Stally attachment, not the universal master of that
photograph. Compression follows the product's promise to retain a useful
record-oriented copy, not the fact that SwiftData owns its storage. A concise
UI explanation can say that photos are resized for storage and source images
are unchanged; ordinary users do not need database or SSOT terminology.

## Ownership and Source of Truth

| Approach | Authoritative image | Consequence |
| --- | --- | --- |
| Reference external content | Photo library or provider file | Access, deletion, edits, and downloads remain external dependencies |
| Import an attachment | Stally's saved representation | Independent lifetime and offline access after materialization and save |
| Maintain both original and derivative | Stally's imported original plus rebuildable derivatives | More storage and an archival promise beyond the selected product scope |

Choose import. The source and attachment cease to be replicas that must stay
identical: the attachment represents what the person added at that time.
Deleting or editing the source must not change an existing Stally attachment.
Deleting the attachment must not delete the source. CloudKit replicas, if
enabled, belong to the same logical Stally attachment; they are not another
source library to reconcile.

PhotosPicker supplies a selected representation, not a durable source path.
Use the system picker and Transferable. Prefer FileRepresentation for large
or multiple selections, copy the temporary delivery into app-controlled
staging only for processing, and clean it up as described below.
Request a generic image with the current encoding policy to avoid a picker
transcode followed by an application transcode. It does not promise unedited
camera bytes or retention of every auxiliary resource.

iCloud Photos may first need to download the selection. Failure or cancellation
must not create a completed attachment or discard an existing one. A file in
iCloud Drive or a third-party File Provider uses the document picker/import
boundary instead. A service such as Google Drive can participate when its
provider is installed, enabled, and exposes the file; PhotosPicker does not
browse arbitrary providers. Materialize authorized bytes under the required
access scope, release that scope after the read or copy, then normalize and
save app-owned content. Do not persist temporary URLs as attachment
identity or build a provider-specific synchronization layer.

### Storage Locations and Lifetime

The only durable application image is ItemPhoto.imageData with
`@Attribute(.externalStorage)`. SwiftData may put those bytes beside its
database internally; that is still the same model attribute and store
lifetime, not an additional original managed by the app. Never delete or
purge SwiftData-managed external files as a cache-cleaning operation.

| Data | Lifetime |
| --- | --- |
| Provider-owned delivery file | Read or copy within the API's permitted access lifetime; never save its URL as permanent identity |
| App-owned raw staging file, when needed | Only until normalization and validation produce independently owned prepared bytes; also remove on failure or cancellation |
| Prepared image in an unconfirmed draft | Retain with the draft until save or cancellation; a save failure keeps the draft available for retry |
| Saved imageData | Retain until an explicit attachment/Item deletion or image replacement changes it |
| Display thumbnail | Discardable cache; rebuild from saved imageData |

Do not keep a second full-resolution original after normalization. If the
process terminates before cleanup, remove abandoned files in the dedicated
app-owned staging area on a later startup, without touching the model store
or active imports. Unconfirmed in-memory drafts are not a durable save
promise. Raw staging is not needed to retry saving already prepared bytes.

## Selected Ingestion Policy

These numeric values are Stally engineering choices, not Apple requirements
or universal optimums. They can evolve without new model fields. Future
changes must not silently rewrite existing saved attachment bytes.

| Concern | Stally 1.0 selection |
| --- | --- |
| Input formats | Decodable still JPEG, HEIC/HEIF, and PNG |
| Source byte limit | 64 MiB, checked before image decoding |
| Source dimensions | Positive, no edge above 16,384 pixels, at most 100 million pixels |
| Saved dimensions | Aspect ratio retained, longest edge at most 2,560 pixels, no upscaling |
| Saved representation | JPEG stays JPEG, HEIC/HEIF uses HEIC; PNG or any alpha-bearing input uses PNG |
| Lossy encoding | ImageIO quality 0.85 for JPEG and HEIC |
| PNG encoding | Lossless encoding of the resulting pixels, preserving alpha |
| Saved byte limit | 5 MiB per attachment; oversize output is rejected |
| Orientation | Apply the source orientation to the pixels |
| Color | SDR output, retain the resulting color profile rather than forcing sRGB |
| Source metadata | Do not carry over GPS, shooting dates, camera details, or free-form source metadata |
| Thumbnail | Derived on demand, normally at most 512 pixels on its longest edge |

Inspect alpha before choosing the output; a format decision must not silently
flatten transparency. Use ImageIO thumbnail decoding with its orientation
transform and an explicit SDR decode request, followed by the matching image
destination. Do not decode the full source bitmap merely to draw a small
destination. Color profiles and
encoder-generated image properties are needed to interpret the saved pixels;
they are not the source metadata that is omitted above. HDR headroom, depth,
motion, and original pixel resolution are not retained by this policy. This
is intentional normalization, not a claim of lossless original preservation.

A Live Photo selection can supply a supported still representation; the
attachment does not retain its motion component. Reject unsupported formats
and multi-frame image deliveries rather than silently choosing an animation
frame. Do not introduce RAW, video, or general document storage in ItemPhoto.

The byte cap is checked after encoding as well as the source resource checks.
A dimension cap alone cannot bound file size. If an output exceeds 5 MiB,
explain that a smaller image is needed and retain the current draft or existing
attachment. Do not repeatedly lower quality, flatten transparency, discard
other photos, or insert a nil-image record to force the operation to succeed.
The UI should describe storage as optimized image copies, without implying
that full-resolution originals are preserved.

Process imports sequentially initially, with cancellation and bounded staging.
The source byte check is not a promise to limit a provider's network transfer
or internal memory use. A successful import means the required bytes have
been persisted, not merely that a picker returned an item.

Normalize once at external ingestion. Caption edits, reordering, reads,
export, and identity-preserving restoration must not recompress saved images.
An export of the attachment contains its saved representation, with a matching
file type; compatibility conversion, if explicitly selected later, is a
separate export operation and must not replace the saved image.

## Thumbnail and Capacity Policy

Memory-only caching is the selected initial implementation, not an Apple
mandate or a generally proven optimum. It avoids persistent cache lifecycle
and synchronization work, but cache misses require reading the saved image
and generating the thumbnail again. The earlier fixture checks do not prove
collection scrolling or cold-launch performance.

Apple's [Wishlist demonstration][wishlist] persists thumbnail bytes inline
and loads full-size images separately. Persisted thumbnails are therefore
also a legitimate native design: they can avoid repeated generation and
full-size data reads, at the cost of additional stored state and invalidation.
Stally starts with NSCache because images are bounded and no measured problem
yet requires another persisted representation. This reasoning is independent
of a desire to eliminate every additional byte after the owner's question.

Initially keep decoded thumbnails in a process-local NSCache, with a 32-MiB
totalCostLimit using decoded byte cost. This is an eviction hint, not a strict
upper bound on process memory. Clear invalidated entries when image content
changes. Never treat a cached thumbnail as the authoritative attachment.

No thumbnail column, thumbnail entity, persistent thumbnail directory, or
CloudKit thumbnail copy is selected for 1.0. Recompute a missing thumbnail
from the saved image, off the UI's critical path. Use the needed pixel size
for larger detail views, bounded by the saved resolution. Actual memory and
scrolling behavior still require integration measurements; a disk cache can
be added later without changing the attachment's stored meaning.

Compressed file size and decoded image memory are separate. For illustration,
a four-byte-per-pixel 4,032 by 3,024 bitmap needs about 46.5 MiB, while a
512 by 384 thumbnail needs 0.75 MiB. These are bitmap arithmetic, not measured
process peaks. HEIC/JPEG compression does not eliminate decode memory.

The per-photo cap is not a collection quota: 1,000 photos averaging 500 KiB
need about 488 MiB of image bytes; 1,000 photos at the 5-MiB cap need about
4.88 GiB, before store overhead, temporary files, or cloud copies. No arbitrary
photo-count limit is selected. Storage exhaustion must remain a failed save
that preserves already saved data, not permission to purge attachments.

## Caption and Ordering

The owner accepted the attachment-local caption and ordering rationale.

`caption` and `sortOrder` belong to the attachment: the caption describes this
image in this Item, and the position belongs to this Item's photo collection.
An integer position is an ordinary representation for a user-reorderable
owned collection; it is not a universally required database design. It is
selected because SwiftData relationship arrays do not promise persisted order.
This rationale does not depend on Cookle's schema or shared-asset architecture.

Keep the existing `sortOrder` followed by UUID presentation order and the
first-photo cover rule. Duplicate positions after synchronization remain
visible. There is no distributed ranking algorithm, mandatory renumbering
repair, or separate `isCover` truth. No source-path or source-library
identifier field is needed.

## Evidence and Limits

The bounded ImageIO probe compared longest-edge limits of 1,600, 2,560, and
4,096 pixels with five fixtures: generated oriented JPEG, transparent PNG,
HEIC, high-entropy transparent PNG, and an existing Stally UI screenshot.
These are functional fixtures, not a representative camera-photo corpus.

At the selected 2,560-pixel limit, the local macOS run produced:

| Fixture | Input bytes | Saved bytes | Result |
| --- | ---: | ---: | --- |
| Oriented JPEG | 498,482 | 233,905 | Rotation applied, metadata omitted |
| Transparent PNG | 791,822 | 533,655 | Alpha retained |
| HEIC | 208,960 | 61,887 | Remained HEIC |
| UI screenshot PNG | 183,595 | 227,499 | PNG size increased despite slight downsampling |
| High-entropy transparent PNG | 34,081,456 | 25,142,387 | Exceeds the selected cap; reject |

The same generated HEIC converted to JPEG produced 228,852 bytes at 2,560
pixels, larger than the input. This is evidence against mandatory JPEG
conversion, not a universal codec quality or compression ranking. Numeric
quality 0.85 is an encoder input, not an 85-percent fidelity guarantee or
equal visual quality across codecs.

The final macOS 27.2 probe passed 134 assertions, including encoding,
dimensions, orientation, retained color profiles, alpha flags, omitted GPS
and shooting dates, thumbnail sizes, and malformed-image detection. The
five-model persistence probe separately verified external binary recovery;
this run did not repeat SwiftData tests. Visual inspection covered the resized
UI screenshot, not all formats or a photographic quality study.

The same source compiled for the iOS 27 Simulator SDK but was not run there.
Physical-device peak memory, HDR camera fixtures, iCloud Photos, third-party
providers, and CloudKit transfer were not exercised. These are implementation
verification obligations, not unresolved ownership or capacity decisions.

Source and comparison output remain in the local temporary directory
`/private/tmp/stally-photo-policy.OTt3Yw`. The ordinary sandbox could not run
the HEIC encoder; the final run used the selected Xcode toolchain outside
that sandbox. An initial malformed-image assertion incorrectly expected a
nil image source; ImageIO can return a source with no frames. The final probe
checks that response rather than treating source allocation as successful
image validation.

## Official References

- [PhotosPicker loading and temporary file ownership][picker-loading]
- [Picker encoding policies and metadata choices][picker-encoding]
- [Document picker copy mode][document-copy]
- [File Provider access][file-providers]
- [ImageIO for reducing decoded image memory][image-memory]
- [Image destination and metadata handling][image-destination]
- [NSCache cost limits are advisory][cache-limit]

[picker-loading]: https://developer.apple.com/documentation/photokit/bringing-photos-picker-to-your-swiftui-app
[picker-encoding]: https://developer.apple.com/videos/play/wwdc2023/10107/
[document-copy]: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init(foropeningcontenttypes:ascopy:)
[file-providers]: https://developer.apple.com/documentation/uikit/providing-access-to-directories
[image-memory]: https://developer.apple.com/documentation/xcode/making-changes-to-reduce-memory-use
[image-destination]: https://developer.apple.com/documentation/imageio/cgimagedestination
[cache-limit]: https://developer.apple.com/documentation/foundation/nscache/totalcostlimit
[wishlist]: https://developer.apple.com/videos/play/wwdc2026/275/
