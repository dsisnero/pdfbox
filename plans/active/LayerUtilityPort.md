# Port Plan: LayerUtility page→form/layer import

**Goal:** `LayerUtility` imports a page as a Form XObject and appends it as an
optional-content layer, matching Java `TestLayerUtility#testLayerImport`.

## Source of truth

- `vendor/pdfbox/.../multipdf/LayerUtility.java` (wrapInSaveRestore,
  importPageAsForm, appendFormAsLayer)
- `vendor/pdfbox/.../multipdf/TestLayerUtility.java`
- `PDAbstractContentStream#setTextMatrix`

## Problem

`multipdf/LayerUtility` was entirely absent (and `TestLayerUtility#testLayerImport`
was falsely marked ported). `PDPageContentStream#set_text_matrix` was missing,
and `PDOptionalContentProperties` failed to read its `/OCGs`/`/D` after
save/reload because indirect references were not dereferenced.

## Steps (red-green)

1. [x] Write `spec/pdfbox/multipdf/layer_utility_test_spec.cr` first (red):
   import + wrap + append; assert `oc1`/group "overlay".
2. [x] Port `LayerUtility` (wrapInSaveRestore / importPageAsForm /
   appendFormAsLayer).
3. [x] `set_text_matrix` (Tm); `PDPropertyList.create` -> OCG for `/Type /OCG`.
4. [x] Fix `PDOptionalContentProperties` indirect-ref dereferencing.
5. [x] Gates; parity.md + inventory.

## Notes

- `wrapInSaveRestore` and content copying are byte-level; `importPageAsForm`
  shares the page resources (Java deep-clones via PDFCloneUtility) — the
  portable subset needed by the test.
