# Phase: Splitter (multipdf) + page import + structure-tree clone

**Goal:** Port `org.apache.pdfbox.multipdf.Splitter` faithfully so the remaining
`multipdf_spec.cr` placeholders become real tests: split a document into new
documents by page range/count, re-embed page content, clone annotations, fix
link destinations, and clone the logical structure tree (`/K`, `/ParentTree`,
`/IDTree`, `/RoleMap`, `/ClassMap`) so `checkForPageOrphans` passes.

## Source of truth

- `vendor/pdfbox/.../multipdf/Splitter.java`
- `vendor/pdfbox/.../pdmodel/PDDocument.java#importPage`
- `vendor/pdfbox/.../pdmodel/common/PDNumberTreeNode.java`, `PDNameTreeNode.java`
- `vendor/pdfbox/.../multipdf/PDFMergerUtility.java#getNumberTreeAsMap/getIDTreeAsMap`
- `vendor/pdfbox/.../cos/COSDictionary.java#resetImportedObjectKeys`, `COSArray`
- `PDFMergerUtilityTest#testSplitWithBrokenDestination`, `#testSplitWithPopupAnnotations`,
  `#testSinglePageSplit`

## Prereqs (red-first, tested via the Splitter tests)

- [ ] COS: `Dictionary#reset_imported_object_keys`, `Array#reset_object_keys`,
      `Dictionary#get_cos_name`/`get_cos_dictionary`/`get_cos_array`.
- [ ] pdmodel: `PDPage#struct_parents`; `PDFormXObject#struct_parents`;
      `PDImageXObject#struct_parent`.
- [ ] `PDParentTreeValue` (COSObjectable wrapper).
- [ ] `PDStructureTreeRoot`: `parent_tree`, `parent_tree=`, `parent_tree_next_key=`,
      `id_tree=`, `class_map=`.
- [ ] `Document#import_page` (clone dict, strip /Parent, re-embed content
      FlateDecode, reset imported object keys, copy crop/media/rotation).
- [ ] `PDFMergerUtility.get_number_tree_as_map`, `#get_id_tree_as_map`.

## Splitter

- [ ] `Splitter#set_start_page`/`#set_end_page`/`#set_split_at_page`/`#split`.
- [ ] `processPages`, `createNewDocumentIfNecessary`, `splitAtPage`,
      `createNewDocument`, `processPage`, `processAnnotations`.
- [ ] `cloneStructureTree`, `cloneIDTree`, `cloneRoleMap`, `cloneTreeElement`,
      `processResources`, `fixDestinations`, `KCloner`.

## Tests (red-green)

- [x] `testSplitWithBrokenDestination` (`PDFBOX-5811-362972.pdf`).
- [x] `testSplitWithPopupAnnotations` (`PDFBOX-5809-509329.pdf`).
- [x] `testSinglePageSplit` (`PDFBOX-5792-240045.pdf`).
- [x] `testSplitWithStructureTree` (`PDFBOX-4417-001031.pdf`).
- [x] `testSplitWithStructureTreeAndDestinations` (`PDFBOX-5762-722238.pdf`).
- [x] `testSplitWithStructureTreeAndDestinationsAndRemovedAnnotations` (`PDFBOX-5762-722238.pdf`).
- [x] `testSplitWithNamedDestinations` (`PDFBOX-5840-410609.pdf`).
- [x] `testSplitWithPgEntryAtTheTop` (`PDFBOX-6009.pdf`; `checkWithNumberTree` minus the marked-content MCID walk, no PDFMarkedContentExtractor yet).
- [x] `testSplitWithOrphanPopupAnnotation` (`PDFBOX-6018-099267-p9-OrphanPopups.pdf`).
- [x] `testOutlinesSelfParent` (`PDFBOX-5939-google-docs-1.pdf`) — required the writer to emit the `/Info` root.
- [x] `testPDFBox515` (`ComSquare1.pdf`, `Ghostscript1.pdf`) — required `mergeInto` info merge and the `/Info` writer root; asserts the encoded image dims (no AWT decode accessor).
- [x] `COSObjectKeyTest#testPDFBox5742` (render-compare; PNG byte equality).
