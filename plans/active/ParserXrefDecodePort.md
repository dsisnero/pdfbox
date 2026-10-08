# Port Plan: Parser xref-stream multi-filter decoding

**Goal:** the parser's xref-stream decode handles a `/Filter` array and any
filter, matching Java `COSStream.createInputStream`.

## Source of truth

- `vendor/pdfbox/.../pdfparser/PDFXrefStreamParser.java`
- `vendor/pdfbox/.../cos/COSStream.java#createInputStream`

## Problem

`Parser#decode_stream_data` (used for xref streams) handled only a single
`FlateDecode` name and raised `SyntaxError("Multiple filters not yet
supported")` on any `/Filter` array, so xref streams with filter arrays (or a
non-Flate filter) failed to parse.

## Steps (red-green)

1. [x] Write `spec/pdfbox/pdf_parser/parser_stream_decode_spec.cr` first (red):
   single Flate + predictor, `[/FlateDecode]`, stacked
   `[/ASCIIHexDecode /FlateDecode]`, and no filter.
2. [x] `decode_stream_data`: single `FlateDecode` keeps the lenient
   `decompress_flate` reader and applies the predictor through
   `Predictor.decode_data`; everything else goes through
   `Cos::Stream#decode_filters` (FilterFactory).
3. [x] Remove the now-dead `apply_png_predictor` / `apply_png_filter_*` helpers.
4. [x] Gates; parity.md.

## Notes

- The lenient Flate reader (zlib, raw deflate, skip-2-byte fallback) is kept for
  the common single-Flate xref stream; malformed streams still parse.
