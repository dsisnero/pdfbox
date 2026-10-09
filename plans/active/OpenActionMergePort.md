# Port Plan: OpenAction preservation across merge

**Goal:** `DocumentCatalog#open_action` returns a destination or action (Java
`PDDestinationOrAction`) with a setter, `append_document` preserves the source
`/OpenAction`, and `PDPageDestination#page` resolves indirect refs.

## Source of truth

- `vendor/pdfbox/.../pdmodel/PDDocumentCatalog.java` (`getOpenAction`/`setOpenAction`)
- `vendor/pdfbox/.../multipdf/PDFMergerUtility.java#mergeOpenAction`
- `pdmodel/interactive/documentnavigation/destination/PDPageDestination.java#getPage`
- `PDFMergerUtilityTest#testPDFMergerOpenAction`

## Problem

`open_action` returned only actions (nil for array destinations) and was
read-only; the merger dropped the source OpenAction. `PDPageDestination#page`
returned nil for indirect (reloaded) destinations.

## Steps (red-green)

1. [x] Replace the empty `PDFMergerUtilityTest#testPDFMergerOpenAction`
   placeholder with a real test (red).
2. [x] `PDAction include PDDestinationOrAction`; `DocumentCatalog#open_action`
   returns destination/action + `open_action=`.
3. [x] `append_document` copies the source OpenAction when the destination has
   none; `PDPageDestination#page` dereferences indirect refs.
4. [x] Gates; parity.md + inventory.
