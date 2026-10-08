# Port Plan: createInputStream(stopFilters)

**Goal:** decode a stream's filters up to (but not including) the first filter in
`stopFilters`, matching Java `PDStream#createInputStream(List<String>)`.

## Source of truth

- `vendor/pdfbox/.../pdmodel/common/PDStream.java#createInputStream(List<String>)`
- `vendor/pdfbox/.../pdmodel/graphics/image/PDImageXObject.java#createInputStream(List<String>)`

## Problem

`PDStream#create_input_stream(stop_filters)` and
`PDImageXObject#create_input_stream(stop_filters)` ignored `stop_filters`
(returning fully- or un-decoded data). Java uses this to get e.g. the raw JPEG
bytes of a Flate+DCT image.

## Steps (red-green)

1. [x] Write `spec/pdfbox/cos/stream_stop_filters_spec.cr` first (red): filter
   arrays, stopping at the first/middle filter, predictors, and PDStream/
   PDImageXObject delegation.
2. [x] `Cos::Stream#create_input_stream(stop_filters)` +
   `decode_filters_with_stop` (uses `decode_with_filter` so DecodeParms apply).
3. [x] `PDStream`/`PDImageXObject` delegate.
4. [x] Strengthen the JPEG factory round-trip with
   `create_input_stream(["DCTDecode"])` (Java `checkJpegStream`).
5. [x] Gates; parity.md + inventory.

## Notes

- `stopFilters` is matched by PDF filter name (e.g. `"DCTDecode"`); decoding
  stops before applying that filter.
