# Port Plan: Render inline images (BI operator)

**Goal:** the graphics engine turns a `BI` operator into a `PDInlineImage` and
calls `drawImage`, matching Java `BeginInlineImage`.

## Source of truth

- `vendor/pdfbox/.../contentstream/operator/graphics/BeginInlineImage.java`
- `pdmodel/graphics/image/PDInlineImage.java` (`extends PDImage`)

## Problem

`PDFStreamParser` already parses inline images (params + data on the `BI`
operator), but the graphics engine registered no `BI` handler, so inline
images were dropped during rendering. `PDInlineImage` also did not extend
`PDImage`, so it could not be passed to `draw_image`.

## Steps (red-green)

1. [x] Write `spec/pdfbox/contentstream/inline_image_operator_spec.cr` first
   (red): a `BI` content stream must reach `draw_image` with a `PDInlineImage`.
2. [x] `PDInlineImage < PDImage` (`PDImage#color_space`/`decode` nilable;
   `PDInlineImage#create_input_stream`).
3. [x] `PDFGraphicsStreamEngine#process_operator` intercepts `BI`, builds the
   `PDInlineImage`, calls `draw_image`.
4. [x] Gates; parity.md + inventory.
