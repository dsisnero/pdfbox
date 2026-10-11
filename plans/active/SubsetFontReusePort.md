# Phase: embedded subset font reuse (testReuseEmbeddedSubsettedFont)

**Goal:** Fix the documented limitation where a reloaded embedded subset font
could not be reused to append more text.

## Source of truth

- `vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/font/TestFontEmbedding.java#testReuseEmbeddedSubsettedFont`
- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java#showText`

## Root cause

`PDPageContentStream#show_text` handled Type0 fonts with a GSUB worker entirely
via `encode_text` → `encode_for_gsub`, which records only **glyph IDs**
(`add_glyphs_to_subset`) and never adds the shown **code points**. The subsetter
therefore built the embedded font's `cmap` from an (almost) empty code-point set
(only whitespace from the non-GSUB space token), producing a subset whose `cmap`
returned glyph 0 for every letter. On reload, `PDCIDFontType2#encode` resolved
letters via that `cmap` → "No glyph".

Java's `PDAbstractContentStream#showText` **always** adds every shown code point
to the subset (`if (font.willBeSubset()) { for each codePoint: font.addToSubset(codePoint); }`),
in addition to the GSUB glyph IDs — so the embedded subset keeps a usable `cmap`.

## Done (red-green)

- [x] `PDPageContentStream#show_text` now adds each shown code point via
      `font.add_to_subset` when `font.will_be_subset?` (mirroring Java), on both
      the GSUB and non-GSUB paths.
- [x] `spec/pdfbox/pdmodel/font/font_embedding_spec.cr#testReuseEmbeddedSubsettedFont`
      is now the real Java test: save text1 with a subset font, reload, append
      text2 with the same font, save, reload, and assert `PDFTextStripper`
      yields `text1 + " " + text2` (previously an `expect_raises` limitation).

## Verification

Direct-path and `show_text`-path subsets are now byte-identical (10740 bytes;
`cmap` 116 bytes; `unicode_cmap_lookup.glyph_id('x') == 16`).
