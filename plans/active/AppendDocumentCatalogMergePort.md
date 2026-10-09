# Phase: appendDocument catalog merges

**Goal:** Finish the `appendDocument` catalog merges deferred from the
structure-tree-merge phase: `/PageLabels`, `/OutputIntents`, `/Metadata`, and
the non-empty-destination-outline branch.

## Source of truth

- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/multipdf/PDFMergerUtility.java`
  (`appendDocument` page-label and metadata blocks, `mergeOutputIntents`, and
  the `mergeOutlines`-style append branch).

## Done (red-green)

- [x] `merge_page_labels`: append the source `/PageLabels /Nums` with the
      destination page count added to each label index; clone values; roll back
      the appended entries when a source index is not a number.
- [x] `merge_metadata`: when the destination has no `/Metadata`, create a new
      unfiltered stream from the source's decoded metadata and copy the source
      metadata dictionary except `/Filter`/`/Length`.
- [x] `merge_output_intents`: add each source `/OutputIntents` entry, skipping
      duplicates by `/OutputConditionIdentifier` unless the identifier is
      "Custom".
- [x] Outline append path: when the destination outline has children, clone each
      source child (dropping `/Prev`/`/Next`) after the last destination sibling
      and update `/Last`.
- [x] `spec/pdfbox/multipdf/catalog_merge_spec.cr` (6 tests).

## Notes

- No dedicated Java test exists for these catalog merges, so the specs assert
  the Java behavior directly (offset page labels, duplicate/Custom output
  intents, metadata filtered-vs-unfiltered, sibling ordering).
