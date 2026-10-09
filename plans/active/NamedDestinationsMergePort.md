# Port Plan: Named destinations + merge annotation/AP tests

**Goal:** `PDDocumentNameDestinationDictionary` / `DocumentCatalog#dests` and
merging source `/Dests` during `append_document`; port the annotation- and
field-preservation merge tests.

## Source of truth

- `vendor/pdfbox/.../pdmodel/PDDocumentNameDestinationDictionary.java`
- `PDDocumentCatalog#getDests`; `PDFMergerUtility` destination merge
- `MergeAcroFormsTest#testAnnotsEntry` / `#testAPEntry`,
  `MergeAnnotationsTest#testLinkAnnotations`

## Problem

`PDDocumentNameDestinationDictionary` / `DocumentCatalog#dests` were missing,
and `append_document` did not merge the source `/Dests`, so merged link
annotations lost their named destinations.

## Steps (red-green)

1. [x] Replace the empty placeholders with real tests and vendor the SHA512-
   verified fixtures (`PDFBOX-1031`, `PDFBOX-1100`, `PDFBOX-1065`).
2. [x] `PDDocumentNameDestinationDictionary` (getCOSObject/getDestination) +
   `DocumentCatalog#dests`.
3. [x] Merge `/Dests` in `append_document` (`cloneMerge`, or clone when absent).
4. [x] Gates; parity.md + inventory.

## Notes

- The `annoRef_` destination-name linking comes from the source PDFs, not the
  merger; the test matches each source annotation's `/Dest` to the target's
  `annoRef_<name>`.
