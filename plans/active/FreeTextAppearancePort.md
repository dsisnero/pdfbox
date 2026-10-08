# Port Plan: FreeText annotation default appearance

**Goal:** `PDAnnotationFreeText#construct_appearances` builds the default
`PDFreeTextAppearanceHandler`, which clips the writing area and lays out the
contents with `PlainTextFormatter` (wrapped lines), matching Java.

## Source of truth

- `vendor/pdfbox/.../interactive/annotation/PDAnnotationFreeText.java#constructAppearances`
- `vendor/pdfbox/.../interactive/annotation/handlers/PDFreeTextAppearanceHandler.java`
  (`cs.addRect(...); cs.clip();` + `PlainTextFormatter`)

## Problem

`PDAnnotationFreeText` used the no-op `AppearanceHandlerSupport#construct_appearances`
(never built the default handler), and `PDFreeTextAppearanceHandler` had the
clip commented out and showed raw text instead of `PlainTextFormatter`.

## Steps (red-green)

1. [x] Write `spec/pdfbox/pdmodel/interactive/annotation/free_text_appearance_spec.cr`
   first (red): a normal appearance with a `W` clip operator and the displayed
   text.
2. [x] `PDAnnotationFreeText#construct_appearances` -> default
   `PDFreeTextAppearanceHandler` (custom handler still wins).
3. [x] Handler: `cs.clip` + `PlainTextFormatter` builder (style/text/width/
   wrapLines/initialOffset), `rescue ArgumentError -> IO::Error`, `ensure endText`.
4. [x] Fix the handler constructor to inherit the base `Document?` parameter.
5. [x] Gates; parity.md + inventory.

## Notes

- `yOffset` (previously discarded as `_y_offset`) is now used by the formatter.
