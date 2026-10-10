# Phase: PDMarkInfo + faithful mergeMarkInfo

**Goal:** Port `org.apache.pdfbox.pdmodel.documentinterchange.logicalstructure.PDMarkInfo`
and make `PDFMergerUtility#mergeMarkInfo` use it exactly like Java.

## Source of truth

- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDMarkInfo.java`
- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/multipdf/PDFMergerUtility.java#mergeMarkInfo`

## Done (red-green)

- [x] `PDMarkInfo` (`COSObjectable`): `marked?`/`marked=`, `uses_user_properties?`/`=`,
      `suspect?` and a faithful `suspect=` that unconditionally writes `/Suspects`
      = false (upstream `PDMarkInfo#setSuspect` quirk retained for parity).
- [x] `DocumentCatalog#mark_info`/`mark_info=`.
- [x] `merge_mark_info` rewritten to `setMarked(true)` + OR the suspect /
      user-properties flags through `PDMarkInfo` (previously wrote the wrong
      `/Suspect` key with raw COS).
- [x] `Cos::Name::MARK_INFO`/`MARKED`/`SUSPECTS`/`USER_PROPERTIES`.
- [x] `spec/pdfbox/pdmodel/document_interchange/logical_structure/pd_mark_info_spec.cr` (2)
      and an `append_document` mark-info assertion in `catalog_merge_spec.cr`.

## Deferred

- `TestFontEmbedding#testReuseEmbeddedSubsettedFont`: reloading and reusing an
  embedded subset font is genuinely broken — the in-document subset path builds
  a `cmap` that returns no glyph IDs (the direct `TTFSubsetter` path is
  correct). Needs a focused font-subsetting chunk.
