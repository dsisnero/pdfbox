# Phase: remaining font/CMap tests + placeholder cleanup

**Goal:** Close the last falsely-ported test rows and stale auto-generated
placeholders.

## Source of truth

- `vendor/pdfbox/fontbox/src/test/java/org/apache/fontbox/cmap/TestCMap.java#testPDFBox3997`
- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDMMType1Font.java`
- `vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/text/{BidiTest,PDFTextStripperByAreaTest,TestTextStripper}.java`

## Done (red-green)

- [x] Ported `TestCMap#testPDFBox3997`: `NotoEmoji-Regular.ttf` unicode cmap
      lookup of `0x1F681` -> glyph 886. Fixture SHA512-verified against
      `fontbox/pom.xml` and vendored with `spec/resources/fontbox/cmap/SHA512SUMS`.
- [x] `PDMMType1Font` now faithfully delegates to `PDType1Font` (Java has no
      extra behavior); removed the misleading `rescue -> raise "Not
      implemented"` and tightened the factory spec to assert the exact subtype.
- [x] Removed the redundant `spec/porting/pdfbox-9zt_spec.cr` (its three text
      suites are covered by `spec/pdfbox/text/*`); repointed the inventory rows.
- [x] Removed stray AppleDouble `._*` files.

## Notes

- The broader `pdfbox-io`/`pdfparser`/COS/fontbox test inventories are now
  backed by real specs; remaining `missing`/`partial` source rows are renamed/
  consolidated classes handled by the chiasmus reconciliation.
