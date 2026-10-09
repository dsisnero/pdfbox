# Port Plan: PDFMergerUtility file merge + AcroForm legacy merge

**Goal:** `PDFMergerUtility#mergeDocuments`/`addSource` and the AcroForm legacy
merge (rename conflicting fields), matching Java; plus `PageExtractorTest`.

## Source of truth

- `vendor/pdfbox/.../multipdf/PDFMergerUtility.java` (`mergeDocuments`,
  `addSource`, `acroFormLegacyMode`)
- `MergeAcroFormsTest#testLegacyModeMerge`, `PageExtractorTest#testExtract`

## Problem

`PDFMergerUtility` had only `append_document`; file-level merge and AcroForm
merge were missing. The deep clone also surfaced a latent overflow: the
value-based `Set(Cos::Dictionary)` hashes cyclic direct dicts.

## Steps (red-green)

1. [x] Replace the empty `MergeAcroFormsTest#testLegacyModeMerge` and
   `PageExtractorTest#testExtract` placeholders with real tests (red).
2. [x] `PDFMergerUtility`: `add_source`, `merge_documents`,
   `destination_file_name`, `acro_form_merge_mode` + `AcroFormMergeMode`, and
   `acro_form_legacy_mode` (rename clashes to `dummyFieldNameN`).
3. [x] Fix `PDFieldFactory.find_field_type` / `PDAcroForm#walk_field_tree`
   visited sets to object identity.
4. [x] Gates; parity.md + inventory.

## Notes

- Java's legacy mode does not deduplicate; it renames incoming fields whose FQN
  already exists (see `dummyFieldName1..6` in the reference fixture).
