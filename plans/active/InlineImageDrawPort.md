# Port Plan: PDPageContentStream#draw_image(PDInlineImage)

**Goal:** drawing an inline image writes `q <matrix> cm BI ... ID <data> EI Q`,
matching Java `PDAbstractContentStream#drawImage(PDInlineImage, ...)`.

## Source of truth

- `vendor/pdfbox/.../pdmodel/PDAbstractContentStream.java#drawImage(PDInlineImage, x, y, width, height)`
- `pdmodel/graphics/color/PDColorSpace.java#getName`

## Problem

`PDPageContentStream#draw_image(PDInlineImage, ...)` only performed the
text-mode guard and wrote nothing, so inline images could not be added to a
content stream.

## Steps (red-green)

1. [x] Write `spec/pdfbox/pdmodel/inline_image_draw_spec.cr` first (red):
   round-trip through `PDFStreamParser` yields a `BI` operator with the
   W/H/BPC/CS params and the image data; Decode/stencil dict coverage.
2. [x] Implement the Java writer sequence (save, transform, `BI` dict, `ID` +
   raw data, `EI`, restore).
3. [x] Declare `PDColorSpace#name` abstract (PDPattern -> "Pattern").
4. [x] Gates; parity.md + inventory.

## Notes

- Java writes a line separator between the data and `EI`; the Java-identical
  parser includes it in the image data (asserted in the spec).
