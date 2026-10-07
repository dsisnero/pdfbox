# Port Plan: CCITT Group 4 (T.6) Fax Encoder

**Goal:** Port `CCITTFaxEncoderStream` and wire `CCITTFaxFilter#encode` so the
CCITT filter is no longer decode-only.

## Source of truth

- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/CCITTFaxEncoderStream.java`
- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/CCITTFaxFilter.java` (`encode`)
- Huffman tables: `CCITTFaxDecoderStream` (`WHITE_CODES`/`BLACK_CODES` +
  run lengths), already ported.

Java ships no unit test for the encoder (`TestFilters#testFilters` explicitly
skips `CCITTFaxFilter`), so the contract is pinned with:
1. an exact bit-stream assertion for an all-white row (deterministic T.6), and
2. round-trips through the already-Java-validated `CCITTFaxDecoderStream`.

## Steps (red-green)

1. [x] Write `spec/pdfbox/filter/ccitt_fax_encoder_spec.cr` first (red with a
   not-implemented stub).
2. [x] Port `CCITTFaxEncoderStream`: input row buffer, changing-element
   analysis, 2D pass/horizontal/vertical modes, Huffman run codes derived from
   the decoder tables, left-to-right fill order, trailing EOL+EOL+fill.
3. [x] `CCITTFaxFilter#encode(input, parameters)` reads Columns/Rows and pipes
   through the encoder (Java `CCITTFaxFilter#encode`).
4. [x] Run gates: `crystal tool format --check src spec`, `ameba src spec`,
   `crystal spec`; update parity.md + inventory.

## Notes

- The general `Cos::Stream#encode_with_filter` path calls `Filter#encode(Bytes)`
  without a parameter dict; CCITT encoding is invoked through the explicit
  two-argument `encode` (as Java requires Columns/Rows).
