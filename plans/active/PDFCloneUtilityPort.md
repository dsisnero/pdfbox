# Port Plan: PDFCloneUtility deep clone

**Goal:** `PDFCloneUtility#clone_for_new_document` deep-clones COS objects into
a destination document (arrays/dicts/streams, indirect remap, self-references),
matching Java; and replace the stub `multipdf_spec` placeholder with a real
`PDFCloneUtilityTest#testClonePDFWithCosArrayStream`.

## Source of truth

- `vendor/pdfbox/.../multipdf/PDFCloneUtility.java`
- `vendor/pdfbox/.../multipdf/PDFCloneUtilityTest.java`
- `pdmodel/PDPage.java#getContentStreams`

## Problem

`multipdf_spec.cr` was a stub of empty `it` blocks (passing vacuously) and
`PDFCloneUtility` / `PDPage#getContentStreams` were missing, so the whole
multipdf area was falsely marked ported.

## Steps (red-green)

1. [x] Replace the empty `PDFCloneUtilityTest#testClonePDFWithCosArrayStream`
   placeholder with a real test (red).
2. [x] Port `PDFCloneUtility` (cloneForNewDocument + clone helpers + cloneMerge +
   hasSelfReference), keyed by object identity.
3. [x] `PDPage#content_streams` (getContentStreams).
4. [x] Gates; parity.md + inventory (mark the still-unported merger-dependent
   cases partial).

## Notes

- The remaining `PDFCloneUtilityTest` cases (CosArrayStream2, DirectIndirect)
  need `PDFMergerUtility#appendDocument`, which is still unported.
