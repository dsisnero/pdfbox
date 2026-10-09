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

- [ ] `testSplitWithBrokenDestination` (`PDFBOX-5811-362972.pdf`).
- [ ] `testSplitWithPopupAnnotations` (`PDFBOX-5809-509329.pdf`).
- [ ] `testSinglePageSplit` (`PDFBOX-5792-240045.pdf`) if reachable.
