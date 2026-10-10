# Phase: PDFMarkedContentExtractor + checkWithNumberTree MCID walk

**Goal:** Port `org.apache.pdfbox.text.PDFMarkedContentExtractor` and complete
the deferred marked-content/MCID walk in `PDFMergerUtilityTest#checkWithNumberTree`.

## Source of truth

- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/PDFMarkedContentExtractor.java`
- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/markedcontent/PDMarkedContent.java`
- `vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/multipdf/PDFMergerUtilityTest.java#checkWithNumberTree`

## Done (red-green)

- [x] `Pdfbox::Text::PDFMarkedContentExtractor < LegacyPDFStreamEngine`: marked
      content nesting (`begin/end_marked_content_sequence`, `marked_content_point`,
      `add_x_object`, `process_text_position`, `suppress_duplicate_overlapping_text`,
      `get_marked_contents`).
- [x] `PDMarkedContent`: `contents`, `add_text`, `add_marked_content`,
      `add_x_object`, `language`, `alternate_description`, `expanded_form`.
- [x] `check_with_number_tree` now performs the full Java MCID walk (each page
      MCID resolves to a `/ParentTree` array entry whose structure element kids
      reference the MCID) plus the annotation `/StructParent` membership check.
- [x] New spec `spec/pdfbox/text/pdf_marked_content_extractor_spec.cr`.

## Real bugs fixed (exposed by the strengthened test)

- [x] `PDStructureElement#kids`/`#parent`/`#create_kid` dereference indirect
      `/K`/`/P` (the writer emits arrays/refs indirect; multi-kid elements were
      empty after save/reload).
- [x] `CMapParser#increment` no longer overflows at byte 255 in position 0
      (Java casts to `byte`, wrapping 255 -> 0).
- [x] `PDAnnotation#struct_parent` default is -1 (Java
      `COSDictionary#getInt(COSName)`), not 0.

## Notes

- `PDStructureNode.create` is not ported; the MCID walk uses `PDStructureElement`
  directly (equivalent for the kid/MCID reference check).
- `PDArtifactMarkedContent` subclass is not ported (`create` returns
  `PDMarkedContent` for `/Artifact` too) — no behavioral difference for the
  MCID walk.
