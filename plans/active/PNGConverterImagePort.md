# Port Plan: PNGConverter.convertPNGImage + PDIndexed

**Goal:** `PNGConverter.convertPNGImage` builds a `PDImageXObject` straight from
a PNG byte stream (no recoding), matching Apache PDFBox; add `PDIndexed`.

## Source of truth

- `vendor/pdfbox/.../graphics/image/PNGConverter.java` (`convertPNGImage`,
  `parsePNGChunks`, `convertPng`, `buildImageObject`, `buildIndexImage`,
  `setupIndexedColorSpace`, `buildTransparencyMaskFromIndexedData`)
- `vendor/pdfbox/.../graphics/color/PDIndexed.java`
- `PNGConverterTest.java` (checkImageConvert / checkImageConvertFail /
  testImageConversion* / testImageConversionIntentIndexed)

## Steps (red-green)

1. [x] Write the structural specs first (red): RGB/gAMA/iCCP/indexed/
   indexed-alpha/sRGB-intent/nil cases (`png_converter_spec.cr`).
2. [x] `PDIndexed` (base/hival/lookup, `name`, `default_decode`, `initial_color`,
   `to_rgb`), wired into `PDColorSpace.create`; base class gained abstract
   `cos_object` (PDPattern returns `/Pattern`).
3. [x] `PNGConverter` conversion path (Flate + Predictor 15; gAMA/cHRM gates;
   iCCP/sRGB ICCBased; Indexed + DeviceGray SMask).
4. [x] Embed a standard sRGB ICC profile (`SRGBICCProfile`) for the sRGB chunk.
5. [x] Wire `PDImageXObject.create_from_byte_array` to try `convertPNGImage`
   first, raster fallback (Java parity).
6. [x] Gates; parity.md + inventory.

## Notes

- AWT `BufferedImage`/ImageIO pixel comparisons and the JDK-exact sRGB profile
  byte comparison in `checkImageConvert`/`testImageConversionIntentIndexed` are
  render/ICC advisory.
