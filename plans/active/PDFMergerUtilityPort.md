# Port Plan: PDFMergerUtility#appendDocument

**Goal:** `PDFMergerUtility#append_document(destination, source)` appends a
source document's pages into the destination, unblocking the remaining
`PDFCloneUtilityTest` cases.

## Source of truth

- `vendor/pdfbox/.../multipdf/PDFMergerUtility.java#appendDocument`
- `PDFCloneUtilityTest#testClonePDFWithCosArrayStream2`, `#testDirectIndirect`

## Problem

`PDFMergerUtility` was missing (the `merge` tool had its own simplified logic),
so `PDFCloneUtilityTest`'s save/reload and direct/indirect cases could not run.

## Steps (red-green)

1. [x] Replace the two empty `PDFCloneUtilityTest` placeholders with real tests
   (red).
2. [x] Port `PDFMergerUtility#append_document`: deep-clone each source page
   (strip `/Parent`), add to the destination tree, copy source OCProperties if
   the destination has none.
3. [x] Gates; parity.md + inventory.

## Notes

- The fuller Java `appendDocument` (AcroForm merge modes, structure-tree merge,
  outlines) is out of scope for this portable subset; `merge`-tool-level
  behaviour is already covered by `spec/tools/merge_spec.cr`.
