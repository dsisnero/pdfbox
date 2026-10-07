# Port Plan: CCITTFactory createFromImage (in-memory raster)

**Goal:** `CCITTFactory.createFromImage`/`prepareImageXObject` build a CCITT
Group 4 image XObject from an in-memory 1-bit raster, actually encoding it.

## Source of truth

- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/image/CCITTFactory.java`
  (`createFromImage`, `prepareImageXObject`)
- `CCITTFactoryTest#testCreateFromBufferedImage`, `#testCreateFromBufferedChessImage`
- Encoder: `CCITTFaxEncoderStream` / `CCITTFaxFilter#encode` (Chunk P)

## Problem

The prior Crystal `prepare_image_x_object` stored the raw bitmap behind a
`CCITTFaxDecode` filter (no encoding) and set a self-referential DecodeParms.
The two tests were marked partial as "AWT BufferedImage/raster path not in
Crystal".

## Steps (red-green)

1. [x] Write the two specs first (red): a 343×287 chess raster and the
   `ccittg4.tif`-derived raster must round-trip through the stored G4 stream.
2. [x] `prepare_image_x_object` runs `CCITTFaxFilter#encode` with Columns/Rows,
   builds the XObject dict (Width/Height/1 bpc/DeviceGray/CCITTFaxDecode) and
   attaches a separate DecodeParms dict (Columns/Rows/K=-1).
3. [x] `create_from_image(document, width, height, binary_data)` takes bit 1 =
   black (Java's `~(getRGB & 1)` raster); drop the old bit-flip.
4. [x] Expose `PDImageXObject#stream` (Java `getCOSObject()` returns the COSStream).
5. [x] Run gates; update parity.md + inventory.

## Notes

- Java's `createFromImage` validates 1-bit; the Crystal API takes a fixed 1-bit
  raster, so no bit-depth check is possible/needed.
