# Phase: appendDocument structure-tree merge

**Goal:** Port the structure-tree merge half of `PDFMergerUtility.appendDocument`
so merging documents preserves and combines `/StructTreeRoot` `/K`,
`/ParentTree` (+ offsets), `/IDTree`, `/RoleMap`, `/MarkInfo`, `/Lang` and
`/ViewerPreferences`, and so merged pages have consistent `/StructParent(s)`.
Turns the remaining `PDFMergerUtilityTest` placeholders into real tests.

## Source of truth

- `vendor/pdfbox/.../multipdf/PDFMergerUtility.java` (`appendDocument`,
  `mergeKEntries`, `mergeIDTree`, `mergeRoleMap`, `updatePageReferences`,
  `updateStructParentEntries`, `mergeMarkInfo`, `mergeLanguage`,
  `mergeViewerPreferences`, `hasOnlyDocumentsOrParts`, `updateParentEntry`).
- `PDFMergerUtilityTest` structure-tree tests.

## Done (red-green)

- [x] `append_document` now mirrors Java: version, threads, names, dests,
  outline, page mode, OCProperties, mergeInto info, page loop with
  resources/boxes/rotation, `/StructParent(s)` offsets, obj mapping.
- [x] `merge_k_entries` (+ `has_only_documents_or_parts?`/`update_parent_entry`),
  `merge_role_map`, `merge_id_tree`, `update_page_references` (3 overloads),
  `update_struct_parent_entries`, `merge_mark_info`, `merge_language`,
  `merge_viewer_preferences`.
- [x] Tests: `testStructureTreeMerge` (3999), `...2` (flatten), `...3` (4408),
  `...4`/`...5` (4417), `...6` (4418), `...7` (4423),
  `testMissingParentTreeNextKey`, `testStructureTreeMergeIDTree`,
  `testMergeBogusStructParents1/2`, `testParentTree`, `testPDFBox5198_2/3`,
  `testFileDeletion`, `testPDFMergerUtility`/`...2`/`testJpegCcitt`
  (render-compare).

## Fixes surfaced

- `PDNumberTreeNode#numbers`/`#kids`/limits now dereference indirect entries
  (`COSArray.getObject` parity) — the writer emits arrays as indirect objects.
- `DocumentNameDictionary#cos_object` returned the wrong ivar and the class
  didn't implement `COSObjectable`.
- Writer: `COSWriter#write_dictionary`/`#write_array` now break cyclic direct
  containers (the `/K` <-> `/P` structure-tree cycle) instead of recursing
  forever.

## Deferred

- `mergeOutputIntents`, `mergePageLabels`, `mergeMetadata`, and the outline
  append path (dest outline non-empty) are not yet ported; no ported test
  exercises them.
