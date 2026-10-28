# Upcoming chunks (Work Chunks A–AW)

> Part of the parity tracking set; index at [`../parity.md`](../parity.md).
> **Status: complete** — every chunk below is done (2026-10-07). Kept for the
> per-chunk goal / source-of-truth / definition-of-done record.

#### Upcoming chunks

- [x] **Chunk A — PDPageContentStream operator coverage**
  - Goal: `PDPageContentStream` matches Java for graphics/text state operators, CMYK/RGB/gray colors, text-mode guards, and the close contract.
  - Java source of truth: `TestPDPageContentStream.java` (6 tests), `PDPageContentStream.java`.
  - Dependencies: none (content stream infra exists).
  - Done when: all `TestPDPageContentStream` tests ported and green; inventory rows closed.
  - Status: all 5 Java tests ported in `spec/pdfbox/pdmodel/page_content_stream_spec.cr` (plus Crystal draw-image coverage); green. Inventory rows closed.

- [x] **Chunk B — PDModel core document/page round-trips**
  - Goal: `PDDocument`/`PDDocumentCatalog`/`PDDocumentInformation`/`PDPage` save/load and metadata behavior matches Java (including locale-safe save and malformed-catalog handling).
  - Java source of truth: `TestPDDocument.java` (9), `TestPDDocumentCatalog.java` (6), `TestPDDocumentInformation.java` (3), `TestPDPage.java` (2).
  - Dependencies: none.
  - Done when: all listed tests ported and green; inventory rows closed.
  - Status: all tests ported. `TestPDDocument` in `spec/pdfbox/document_spec.cr` (save/load stream+file, versions, delete bad/good file, save-Arabic-locale round-trip), `TestPDDocumentCatalog` in `spec/pdfbox/document_catalog_spec.cr` (page labels incl. malformed, page count, output intents, boolean open action), `TestPDDocumentInformation` in `spec/pdfbox/document_information_spec.cr`, and `TestPDPage#testAddingPageAfterCreatingAnnotation` (PDFBOX-6097) in `spec/pdfbox/pdmodel/page_test_spec.cr`. Green. Inventory rows closed.

- [x] **Chunk C — Page tree navigation + annotation filtering**
  - Goal: `PDPageTree` index-of-destination, insert-before/after-blank-page, and `PDPage#annotations` filtering match Java.
  - Java source of truth: `TestPDPageTree.java` (9), `TestPDPageAnnotationsFiltering.java` (5).
  - Dependencies: existing page-tree and annotation infra.
  - Done when: all listed tests ported and green; inventory rows closed.
  - Status: all `TestPDPageTree` tests ported in `spec/pdfbox/pdmodel/page_tree_spec.cr` + `page_tree_nodeloop_spec.cr` (positiveSingleLevel, positiveMultipleLevel, negative, insertBefore/AfterBlankPage, indexOfPageFromOutlineDestination, PDFBOX-6040 nodeloop); `TestPDPageAnnotationsFiltering` ported in `spec/pdfbox/pdmodel/page_annotations_filtering_spec.cr` (validateNoFiltering, validateAllFiltered, validateSelectedFew) — required adding `PDPage#get_annotations(&block)` filtering overload. Also closed `TestPDPageTransitions` inventory rows (readTransitions, saveAndReadTransitions) already ported in `page_transitions_spec.cr`. Green. Inventory rows closed.

- [x] **Chunk D — FDF document + field load/export**
  - Goal: `FDFDocument`/`FDFField`/`FDFDictionary` round-trip via FDF and XFDF, including malformed-input handling (PDFBOX-5894).
  - Java source of truth: `TestFDF.java` (4), `FDFFieldTest.java` (done), `FDFAnnotationTest.java`.
  - Dependencies: FDF model exists; XFDF annotation parsing is new work.
  - Done when: `TestFDF` ported and green; FDFAnnotation XFDF `<annots>` parsing covered.
  - Status: `TestFDF` ported in `spec/pdfbox/pdmodel/test_fdf_spec.cr` (testLoad2 for withcatalog/nocatalog.fdf field round-trip + acroform import, and testPDFBox5894). `testPDFBox5894` required real COS parsing in `FDFParser` (now extends `Parser`): it locates the xref chain, parses each in-use object into a `Cos::Document` pool, and exposes it via `FDFDocument#get_document` so `objects_by_type(Annot)` returns the 4 sticky-note annotations; model built from the COS catalog (`FDFDocument.from_cos_dictionary`) with text fallback for simple files. `FDFAnnotationTest` ported in `spec/pdfbox/pdmodel/fdf/fdf_annotation_test_spec.cr`: full `FDFAnnotation` COS-backed model + 17 subtypes (Text, Caret, FreeText, FileAttachment, Highlight, Ink, Line, Link, Circle, Square, Polygon, Polyline, Sound, Squiggly, Stamp, StrikeOut, Underline) with XFDF element parsing (page/color/date/flags/name/rect/title/creationdate/opacity/subject/intent, contents + contents-richtext with Java richContentsToString reconstruction, border style width/style/dashes/intensity + border effect), and `<annots>` wiring into `FDFDictionary`. loadXFDFAnnotations (18 annots, PDFBOX-4345/3646 richtext escaping) and testAnnotationWidth (width=0 border style) green. Inventory rows closed.

- [x] **Chunk E — COSArrayList collection semantics**
  - Goal: `COSArrayList` list view (get/add/remove/removeAll/retainAll) over direct and indirect COS entries matches Java, including filtered-list views.
  - Java source of truth: `COSArrayListTest.java` (14).
  - Dependencies: none.
  - Done when: all `COSArrayListTest` tests ported and green; inventory rows closed.
  - Status: all 11 active `COSArrayListTest` methods ported in `spec/pdfbox/pdmodel/common/cosarray_list_test_spec.cr` (getFromList, removeFromListByIndex, removeUniqueFromListByObject, removeAllUniqueFromListByObject, removeMultipleFromListByObject, removeAllMultipleFromListByObject, removeFromFilteredListByIndex/Object raising UnsupportedOperationError, removeSingleDirectObject, removeSingleIndirectObject, retainIndirectObject). Covers list-view mutation staying in sync with the backing COSArray over direct + indirect entries and save/load round-trips. `addToList` is `// @Test`-disabled in Java (not an active test). Superseded COSArrayList blocks removed from `common_parity_spec.cr`. Green. Inventory rows closed.

- [x] **Chunk F — PostScript function (Type 4) interpreter**
  - Goal: Type 4 (PostScript calculator) functions parse and execute per ISO 32000, with the standard operator set.
  - Java source of truth: `TestPDFunctionType4.java`, `type4/TestParser.java`, `type4/TestOperators.java`, `type4/Type4Tester.java`.
  - Dependencies: none (new interpreter).
  - Done when: parser/operator/function tests ported and green; inventory rows closed.
  - Status: all ported and green. `TestOperators` (all 40 operators: add/abs/and/atan/ceiling/cos/cvi/cvr/div/exp/floor/idiv/ln/log/mod/mul/neg/round/sin/sqrt/sub/truncate/bitshift/eq/ge/gt/le/lt/ne/not/or/xor/if/ifelse/copy/dup/exch/index/pop/roll, incl. integer-overflow→real, data-type, and rangecheck/typecheck error cases) in `spec/pdfbox/pdmodel/common/function/type4/operators_spec.cr`; `TestParser` (basics, nested blocks, parseReal incl. `+1`/`1.0E-5`, PDFBOX-804 no-whitespace-`mul}`/line-break) in `parser_spec.cr`; `TestPDFunctionType4` (simple add + clipping, argument order via pop) in `pdfunction_type4_spec.cr`; `Type4Tester` helper ported to `spec/helpers/type4_tester.cr`. Existing `src/pdfbox/pdmodel/common/function/type4/*` interpreter (parser, execution context, operators) fully covers the operator set. Inventory rows closed.

- [x] **Chunk G — Tagged PDF logical structure**
  - Goal: `PDStructureElement` and the logical structure tree round-trip and expose attributes like Java.
  - Java source of truth: `PDStructureElementTest.java` (6).
  - Dependencies: none (new area).
  - Done when: all `PDStructureElementTest` tests ported and green; inventory rows closed.
  - Status: all 3 active test methods ported in `spec/pdfbox/pdmodel/document_interchange/logical_structure/` (`pd_structure_element_spec.cr` for testSimple, `pd_structure_element_fixture_spec.cr` for testClassMap + testPDFBox4197). Added the logical-structure model: `Revisions(T)` (objects + revision numbers), `PDAttributeObject` base + `create` factory dispatching on `/O` owner, `PDDefaultAttributeObject`/`PDUserAttributeObject`, `PDStandardAttributeObject` base + tagged-PDF attribute objects (`PDLayoutAttributeObject` with width/height/blockAlign/inlineAlign, `PDTableAttributeObject` with rowSpan/colSpan/headers/scope/summary, `PDListAttributeObject`, `PDPrintFieldAttributeObject`, `PDExportFormatAttributeObject`), `PDStructureTreeRoot` (K + ClassMap), and `PDStructureElement#attributes`/`attributes=`/`class_names`/`attribute_changed`. Made `Cos::Dictionary#get_dictionary_object` public (Java `getDictionaryObject`); wired `DocumentCatalog#structure_tree_root`/`structure_tree_root=`. `testPDFBox4197` fixture downloaded (SHA512 verified against pom) into `spec/resources/pdfbox/pdmodel/documentinterchange/logicalstructure/`. Both fixture tests green (117/111 attribute counts; 72/45 + 10 classes). Inventory rows closed.

- [x] **Chunk H — Font embedding / encoding / ToUnicode coverage**
  - Goal: embedded font round-trips (TrueType, CIDFontType2 subset/vertical, Type0), encoding edge cases, and ToUnicode CMap writer ranges match Java.
  - Java source of truth: `TestFontEmbedding.java` (21, incl. `TrueTypeEmbedderTester`), `TestFontEncoding.java`, `TestToUnicodeWriter.java` (9).
  - Dependencies: existing font/fontbox infra.
  - Done when: all listed tests ported and green; inventory rows closed.
  - Status: `TestFontEncoding` (test_add/test_overwrite/test_pdfbox_3884) green in `spec/pdfbox/pdmodel/font/test_font_encoding_spec.cr`; `TestToUnicodeWriter` all 8 methods (4 CMap writers + 4 allow-range predicates) green in `to_unicode_writer_spec.cr` — made `ToUnicodeWriter#allow_cid_to_unicode_range`/`allow_code_range`/`allow_destination_range` public class methods and fixed `allow_destination_range` to use Java's codepoint semantics (single codepoint, no `< 0x10000` gate). `TestFontEmbedding` end-to-end round-trips ported in `spec/pdfbox/pdmodel/font/font_embedding_spec.cr`: testCIDFontType2/Subset (Unicode+Cyrillic+Vietnamese extract round-trip), testSurrogatePairCharacter (ipa font), testSurrogatePairCharacterExceptionIsBmpCodePoint/IsValidCodePoint (IllegalStateError messages), testEmbeddedFontWithZeroWidthChars (zero-width ZWNJ width 0 via W-array deref fix), testMaxEntries (100-entry ToUnicode batch). Fixed `CIDFont#read_widths` to dereference indirect `Cos::Object` entries in the W array (writer emits indirect width objects). Render-compare tests (testBengali/Devanagari/Gujarati/Devanagari2, vertical subset monospace/proportional) are advisory (TestPDFToImage render-compare, Chunk K policy); testIsEmbeddingPermittedMultipleVersions uses Mockito; testReuseEmbeddedSubsettedFont documented as a limitation (subset re-expansion on reload not yet supported — the reloaded subset font has nil @ttf so appending new glyphs raises, asserted in the spec). Inventory rows closed (13 ported, 10 partial).

- [x] **Chunk I — Image factories (CCITT + lossless)**
  - Goal: `CCITTFactory` and `LosslessFactory` produce PDF images with Java-parity dimensions/color spaces.
  - Java source of truth: `CCITTFactoryTest.java` (10), `LosslessFactoryTest.java` (21), `ValidateXImage.java` (support helper).
  - Dependencies: image infra; CCITT/DCT filters may be needed.
  - Done when: all listed tests ported and green; inventory rows closed.
  - Status: `CCITTFactory` ported in `src/pdfbox/pdmodel/graphics/image/ccitt_factory.cr` + `spec/pdfbox/pdmodel/graphics/image/ccitt_factory_spec.cr` (TIFF header/IFD parsing — byte/short/long tags incl. big-endian and garbage-padded fields, single + multi-page strip extraction, `create_from_byte_array`/`create_from_file(number)`; dict parity: CCITTFaxDecode filter, 1 bpc, DeviceGray, Columns/Rows/K/BlackIs1 decode parms; file-not-locked behavior). `LosslessFactory` ported in `lossless_factory.cr` + `lossless_factory_spec.cr` (gray → Flate DeviceGray at source bit depth; RGB(A) → PNG predictor-15 + Flate DeviceRGB with DecodeParms Predictor/Colors/Columns/BitsPerComponent; best-row none/sub/up/average/paeth selection; soft mask for transparency — 8-bit translucent vs 1-bit BITMASK binary alpha, mirroring Java's PredictorEncoder `return null` for binary-alpha fallback; ≤50×50 classic-compare path). Pixel round-trip/ImageIO/render assertions are advisory (Chunk K policy). 2082 examples green. CCITTFactoryTest + LosslessFactoryTest inventory rows closed (24 ported, 10 partial).

- [x] **Chunk J — DeviceCMYK + remaining color space model**
  - Goal: `PDDeviceCMYK` model parity (instance, color space creation, components).
  - Java source of truth: `PDDeviceCMYKTest.java` (4, incl. `CustomDeviceCMYK` helper).
  - Dependencies: color infra.
  - Done when: all `PDDeviceCMYKTest` tests ported and green; inventory rows closed.
  - Status: ported in `spec/pdfbox/pdmodel/graphics/color/pd_device_cmyk_spec.cr` + `src/pdfbox/pdmodel/graphics/color/pddevice_cmyk.cr`. `testCMYK` (custom `PDDeviceCMYK` subclass instantiation + DeviceCMYK contract) green — made the Crystal constructor non-private to match Java's protected constructor; added `default_decode` returning `[0,1,0,1,0,1,0,1]` (Java `getDefaultDecode`). `testPDFBox5787` (AWT ICC_Profile + ColorConvertOp CMYK→RGB, jdk21 homebrew check) and the ICC-backed `init`/`toRGB`/`toRGBImage` documented as advisory (AWT/ICC-specific); Crystal `to_rgb` uses the standard subtractive CMYK→RGB formula. 2087 examples green. Inventory rows closed (3 ported, 1 partial).

- [x] **Chunk K — Render-compare gated tests (advisory rendering)**
  - Goal: cover the behavioral (non-rendering) assertions of the render-compare tests — `AppearanceGenerationTest#renderTest`, `PDAcroFormFlattenTest`, `TestCustomPageDrawer`, `TestHelloWorld` — where feasible, and document the render-only assertions.
  - Java source of truth: the listed test files.
  - Dependencies: PDFRenderer/PageDrawer (partial).
  - Done when: behavioral assertions ported; render-only assertions documented as advisory/out-of-scope.
  - Status: behavioral assertions ported; render-only documented. `PDAcroFormFlattenTest` in `spec/pdfbox/pdmodel/interactive/form/pd_acro_form_flatten_test_spec.cr` (merged with the existing `PDAcroFormTest` flatten tests): `flattenSingleField` (MultilineFields.pdf — field removed, count reduced by one), `flattenTestPDFBOX5254` (fields empty + 72 page-0 annotations), `flattenTestPDFBOX5225` (field-tree count 76 + 59 page-0 annotations), and `testFlatten` cases `PDFBOX-4788` (non-widget annotations retained: 1 per page) + `PDFBOX-4955` (fields empty). JIRA fixtures vendored under `spec/resources/pdfbox/pdmodel/interactive/form/` with SHA512 recorded (f1040sb test.pdf, SourceFailure.pdf, PDFBOX-4788.pdf, PDFBOX-4955.pdf). `AppearanceGenerationTest` render-only tests documented in `appearance_generation_render_spec.cr`: `renderTest` (TestPDFToImage render-compare, advisory) and `rectangleFullStrokeNoFill` (disabled in Java — "content stream differs"; Crystal regenerated tokens likewise differ). `TestHelloWorld` (text-extraction checkOutputFile) and `TestCustomPageDrawer` (PNG render non-null) were already ported/documented in the examples specs. 2094 examples green. Inventory rows closed.

- [x] **Chunk L — Examples-layer CLIs (examples/**)**
  - Goal: exercise the examples CLI entry points (CreateSimpleForm, AddBorderToField, embedded-font forms, radio buttons, multi-widget forms) end to end.
  - Java source of truth: `examples/.../TestCreateSimpleForms.java`, `TestCreateGradientShadingPDF.java`, `TestCreateSignature.java`, `TestRubberStampWithImage.java`.
  - Dependencies: tools/CLI infra; PDFRenderer.
  - Done when: example CLIs run and their assertions pass; documented as examples-layer parity.
  - Status: `TestCreateSimpleForms` ported in `spec/pdfbox/examples/interactive/form/test_create_simple_forms_spec.cr` (7 tests green) exercising the newly ported example CLIs in `src/examples/interactive/form/` (`CreateSimpleForm`, `AddBorderToField`, `CreateMultiWidgetsForm`, `CreateCheckBox`, `CreateRadioButtons`, `CreatePushButton`, `CreateSimpleFormWithEmbeddedFont`): field-value round-trips, `Łódź` ArgumentError with Java-parity message, appearance-characteristics border/background colors, multi-widget page association, checkbox on/check, radio export values/selection, push-button field presence, embedded-font value round-trip (`Sample field İ`). Fixed `PDPage#annotations` to lazily create the `/Annots` array in the page dict (Java `getAnnotations` behavior — `.add` now writes back). Added `PDAppearanceContentStream#draw_image` (+ native-size overload) and `stroking_color(gray)`; ported the full 188-entry `ZapfDingbatsEncoding` table (was empty — needed for checkbox appearance glyphs). Java `renderImage` calls are advisory (Chunk K); `testCreateSimpleFormWithEmbeddedFont`'s `setValue("Łódź")` regenerate + post-reload F1 resource lookup documented as limited by the subset-reload limitation (Chunk H). `TestCreateGradientShadingPDF` (render color-count), `TestCreateSignature`, `TestRubberStampWithImage` remain documented as examples/render-layer advisory in `pdmodel_examples_spec.cr`. 2101 examples green. Inventory rows closed (7 ported, 1 partial).

- [x] **Chunk M — Rendering suite (advisory render-compare)**
  - Goal: port the behavioral assertions of `TestPDFToImage.java`, `TestQuality.java`, `TestRendering.java` (PDFBOX-4831 etc.); document the render-compare output assertions as advisory (full raster rendering is out of scope).
  - Java source of truth: `rendering/TestPDFToImage.java`, `rendering/TestQuality.java`, `rendering/TestRendering.java`.
  - Dependencies: PDFRenderer (partial).
  - Done when: non-rendering assertions ported; render-only assertions documented.
  - Status: behavioral assertions ported in `spec/pdfbox/rendering/rendering_suite_spec.cr` (4 examples) against the 10 `input/rendering` fixtures. `TestPDFToImage#doTestFile` behavioral parts (>= 1 page, `setAllSecurityToBeRemoved` + save, clean reload) green for all 10 fixtures; `TestRendering#render` load-smoke green for all 10 and `render_image(0)` smoke green for 8/10 (documented gaps: `source.pdf` unsupported A85 stream filter, `survey.pdf` matrix-illegal-values — both are render-only). `TestQuality#testPDFBox4831` (300-dpi colorCount == 2 + checkIdent) documented as render-only/advisory. All render-compare PNG/diff helpers (`diffImages`, `createEmptyDiffImage`, `filesAreIdentical`, PNG comparison) are AWT/ImageIO-based and out of scope. 2105 examples green. Inventory rows closed (18 rows).

- [x] **Chunk N — ImageIO util + misc helpers**
  - Goal: port `TestImageIOUtils.java` behavioral assertions (format detection) and the `PDIntegerNameTreeNode` helper surface.
  - Java source of truth: `tools/imageio/TestImageIOUtils.java`, `pdmodel/common/PDIntegerNameTreeNode.java`.
  - Dependencies: imageio infra (partial).
  - Done when: behavioral assertions ported; helper surface matches Java; inventory rows closed.
  - Status: `PDIntegerNameTreeNode` (a test-tree helper in Java, already present as `spec/helpers/pd_integer_name_tree_node.cr`) — `convertCOSToPD` now raises `IO::Error` (Java `IOException`) "integer expected here, but got <base>" and `createChildNode` returns the integer-node type, covered in `spec/pdfbox/pdmodel/common/pd_integer_name_tree_node_parity_spec.cr` (3 tests). `TestImageIOUtils` behavioral helpers ported in `spec/pdfbox/tools/imageio/imageio_utils_spec.cr` (3 tests): `checkFileTypeByContent` (FileTypeDetector magic-byte detection for PNG/JPEG/BMP/GIF/TIFF), `checkBmpResolution` (BMP pixels-per-meter at byte offsets 38/42, pure bytes), and `checkTiffCompression` (TIFF IFD Compression tag 259 reading, pure bytes). The render + ImageIO write/read pipeline (`writeImage`, `doTestFile`, `testRenderImage`, `checkResolution` via IIOMetadata, `checkSaveResources`, `checkImageFileSize*`) is render-compare advisory (Chunk M policy). 2111 examples green. Inventory rows closed (18 rows).

- [x] **Chunk O — Certificate-based encryption/decryption tools**
  - Goal: `pdfbox encrypt --certFile` and `pdfbox decrypt --keyStore/--alias` encrypt/decrypt documents using X.509 certificates, matching the Java `Encrypt`/`Decrypt` tools (previously stubbed as "not yet implemented").
  - Java source of truth: `tools/.../Encrypt.java` (certFile branch), `tools/.../Decrypt.java` (keyStore/alias branch); behavioral crypto covered by `TestPublicKeyEncryption.java` (already green).
  - Dependencies: public-key crypto port (Chunk complete), `Loader.load_pdf(bytes, password, key_store, alias)`.
  - Done when: tools perform cert-based protect/decrypt round-trips and specs are green; inventory rows closed.
  - Status: complete. `Tools::Encrypt` reads `--certFile` (DER or PEM X.509, PEM base64 body decoded then `from_der?`), builds a `PublicKeyProtectionPolicy` + `PublicKeyRecipient` (Java's single-recipient loop), honors `--keyLength`, and now mirrors Java's "Document is already encrypted." guard. `Tools::Decrypt` opens the `--keyStore` PKCS#12 file and calls `Loader.load_pdf(bytes, password, key_store_io, alias)`, keeping the password-only path; missing keystore reports an error. `spec/tools/encrypt_spec.cr` (+3: cert DER protect→keystore reload, PEM cert, missing cert file) and `spec/tools/decrypt_spec.cr` (+2: keystore-based decrypt round-trip, missing keystore). Also fixed the stale `encryption_dir` in `decrypt_spec.cr` that silently skipped its password tests. 2176 examples green.

- [x] **Chunk P — CCITT Group 4 (T.6) fax encoder**
  - Goal: `CCITTFaxEncoderStream` + `CCITTFaxFilter#encode` complete the CCITT filter (previously decode-only) with Java-parity T.6 encoding.
  - Java source of truth: `filter/CCITTFaxEncoderStream.java`, `filter/CCITTFaxFilter.java#encode`; Huffman tables from the already-ported `CCITTFaxDecoderStream`.
  - Dependencies: CCITT decode port (CCITTFaxDecoderStream/Filter, trees), `TIFFExtension`.
  - Done when: encoder round-trips through the Java-validated decoder and pins the exact T.6 bit stream; gates green; inventory rows closed.
  - Status: complete. `src/pdfbox/filter/ccitt_fax_encoder_stream.cr` ports the input row buffer, changing-element analysis, 2D pass/horizontal/vertical modes, Huffman run codes derived from the decoder tables, left-to-right fill order, and the trailing EOL+EOL+fill. `CCITTFaxFilter#encode(input, parameters)` reads Columns/Rows (Java `encode`) and pipes through the encoder. `spec/pdfbox/filter/ccitt_fax_encoder_spec.cr` (4 tests, written first): exact T.6 bytes for an all-white row, plus round-trips of the decoded `ccittg4.tif` bitmap, a synthetic alternating bitmap, and an all-black bitmap. 2180 examples green.

- [x] **Chunk Q — CCITTFactory file-less image construction (`createFromImage`)**
  - Goal: `CCITTFactory.createFromImage`/`prepareImageXObject` build a CCITT image from an in-memory 1-bit raster, actually G4-encoding it (previously the raw bitmap was stored behind a `CCITTFaxDecode` filter without encoding).
  - Java source of truth: `CCITTFactoryTest#testCreateFromBufferedImage`/`testCreateFromBufferedChessImage`; `CCITTFactory#createFromImage`/`prepareImageXObject` (uses the G4 encoder from Chunk P).
  - Dependencies: CCITT G4 encoder (Chunk P).
  - Done when: the stored stream decodes back to the source raster and the dictionary matches Java's `validate`; gates green; inventory rows closed.
  - Status: complete. `prepare_image_x_object` now runs `CCITTFaxFilter#encode` (Chunk P) over the raster with Columns/Rows, builds the XObject dict (Width/Height/1 bpc/DeviceGray/CCITTFaxDecode) and attaches a separate DecodeParms dict (Columns/Rows/K=-1) — replacing the prior self-referential, unencoded dict. `create_from_image(document, width, height, binary_data)` takes bit 1 = black (Java's `~(getRGB & 1)` raster). `spec/pdfbox/pdmodel/graphics/image/ccitt_factory_spec.cr` (+2, test-first): the 343×287 chess raster and the `ccittg4.tif`-derived raster round-trip through the stored G4 stream. 2182 examples green.

- [x] **Chunk R — PNGConverter direct PNG → PDF image conversion + PDIndexed**
  - Goal: `PNGConverter.convertPNGImage` builds a `PDImageXObject` from a PNG byte stream without recoding (Flate + PNG Predictor 15, DeviceRGB / ICCBased / Indexed + soft mask), returning nil for unsupported grayscale/alpha types; `PDIndexed` color space added.
  - Java source of truth: `PNGConverterTest.java` (checkImageConvert / checkImageConvertFail / testImageConversion* / testImageConversionIntentIndexed); `PNGConverter.java#convertPNGImage`; `PDIndexed.java`.
  - Dependencies: filter set (Flate), `PDICCBased`, `LosslessFactory.prepareImageXObject`.
  - Done when: structural XObject/dictionary/colorspace/soft-mask parity for the PNG fixture corpus; gates green; inventory rows closed.
  - Status: complete. `PNGConverter` now ports `parsePNGChunks`, `convertPNGImage`/`convertPng`, `buildImageObject` (DeviceRGB + gAMA gate + iCCP/sRGB ICCBased + cHRM gate), `buildIndexImage`/`setupIndexedColorSpace`/`buildTransparencyMaskFromIndexedData` (DeviceGray 8-bit SMask), `buildDecodeParams`, and `readInt`/`readPNGFloat`. New `PDIndexed` (`src/pdfbox/pdmodel/graphics/color/pdindexed.cr`, base/hival/lookup + `PDColorSpace.create` dispatch; base class gained abstract `cos_object`). sRGB-only PNGs use an embedded standard sRGB ICC profile (`SRGBICCProfile`). `PDImageXObject.create_from_byte_array` now tries `convertPNGImage` first (Java parity) with raster fallback. `spec/pdfbox/pdmodel/graphics/image/png_converter_spec.cr` (+7, test-first) covers the RGB/gamma/iCCP/indexed/indexed-alpha/sRGB-intent/nil cases; the AWT BufferedImage/ImageIO pixel comparisons and the JDK-exact sRGB profile byte comparison remain advisory. 2189 examples green.

- [x] **Chunk S — PDOutlineItem destination/action/structure-element/text-color + findDestinationPage**
  - Goal: complete the `PDOutlineItem` model surface — `destination`, `action`, `structure_element`, `text_color`, and `findDestinationPage` (page destinations, GoTo actions, named destinations via `/Names /Dests`).
  - Java source of truth: `PDOutlineItem.java` (`getDestination`/`setDestination`, `getAction`/`setAction`, `getStructureElement`/`setStructureElement`, `getTextColor`/`setTextColor`, `findDestinationPage`).
  - Dependencies: `PDDestination` factory, `PDActionFactory`, `PDColor`/`PDDeviceRGB`, `PDStructureElement`.
  - Done when: the surface round-trips and destination page resolution matches Java; gates green; inventory rows closed.
  - Status: complete. Implemented on the canonical `PDOutlineItem`; `DocumentCatalog#find_named_destination_page` added (walks `/Names /Dests` names/kids trees, falls back to the catalog `/Dests` dictionary). `spec/pdfbox/pdmodel/interactive/outline_item_model_spec.cr` (10 tests, test-first): default nil/black, destination/action/structure-element round-trips, text-color default+round-trip, and `find_destination_page` via page destination, GoTo action, page-number destination, named destination, and nil. 2199 examples green.

- [x] **Chunk T — PNG/TIFF predictor decoding in Flate/LZW**
  - Goal: `FlateFilter`/`LZWFilter` apply the `DecodeParms` predictor after inflation/decompression (Java `Predictor.wrapPredictor`), so predicted streams decode correctly.
  - Java source of truth: `filter/Predictor.java` (`decodePredictorRow`, `calculateRowLength`, `wrapPredictor`/`PredictorOutputStream`), `filter/FlateFilter.java#decode`.
  - Dependencies: existing `Predictor.getBitSeq`/`calcSetBitSeq`, `Filter` params-aware decode.
  - Done when: all predictor modes decode and the Flate/Cos::Stream paths apply them; gates green; inventory rows closed.
  - Status: complete. `Predictor.decode_predictor_row` ports all modes (TIFF PRED SUB incl. 1/8/16 bpc + generic, PNG NONE/SUB/UP/AVG/PAETH); `Predictor.decode_data` ports the row-buffering `wrapPredictor`/`PredictorOutputStream` (per-row predictor byte for >=10, zero-filled final partial row). `FlateFilter#decode(encoded, decode_params, ...)` and `LZWFilter#decode(...)` apply it. `spec/pdfbox/filter/predictor_decode_spec.cr` (8 tests, test-first): each mode plus end-to-end Flate and `Cos::Stream#create_input_stream`. This also makes the previously-inert `Predictor` inventory rows true and fixes PNGConverter transparency-mask decode. 2207 examples green.

- [x] **Chunk U — Xref-stream multi-filter decoding in the parser**
  - Goal: the parser's xref-stream stream decode accepts a `/Filter` array and any filter (not just a single `FlateDecode`), matching Java's `COSStream.createInputStream`.
  - Java source of truth: `pdfparser/PDFXrefStreamParser.java` (uses `COSStream.createInputStream`), `cos/COSStream.java#createInputStream`.
  - Dependencies: `Cos::Stream#decode_filters`, predictor decoding (Chunk T).
  - Done when: filter arrays and non-Flate filters decode on the parser path; gates green.
  - Status: complete. `Parser#decode_stream_data` now routes a single `FlateDecode` through the lenient `decompress_flate` + `Predictor.decode_data`, and everything else (filter arrays, other filters) through `Cos::Stream#decode_filters` — previously any `/Filter` array raised `SyntaxError("Multiple filters not yet supported")`. Removed the now-dead `apply_png_predictor`/`apply_png_filter_*` helpers (186 lines). `spec/pdfbox/pdf_parser/parser_stream_decode_spec.cr` (4 tests, test-first): single Flate + predictor, `[/FlateDecode]`, stacked `[/ASCIIHexDecode /FlateDecode]`, and no filter. 2211 examples green.

- [x] **Chunk V — `createInputStream(stopFilters)` semantics**
  - Goal: `COSStream`/`PDStream`/`PDImageXObject#create_input_stream(stop_filters)` decode filters up to (but not including) the first stop filter, matching Java `PDStream#createInputStream(List)`.
  - Java source of truth: `pdmodel/common/PDStream.java#createInputStream(List<String>)`; `PDImageXObject.createInputStream(List)`.
  - Dependencies: `Cos::Stream#decode_filters`/`decode_with_filter`, predictor decoding (Chunk T).
  - Done when: stop-filter decoding works for filter arrays/single filters and image streams; gates green; inventory rows closed.
  - Status: complete. `Cos::Stream#create_input_stream(stop_filters)` walks the `/Filter` list applying `decode_with_filter` (so DecodeParms/predictors apply) and breaks at the first stop filter; `PDStream` and `PDImageXObject` delegate. Previously `PDStream`/`PDImageXObject` ignored `stop_filters` (returning fully- or un-decoded data). `spec/pdfbox/cos/stream_stop_filters_spec.cr` (6 tests, test-first), and the JPEG factory round-trip now asserts `create_input_stream(["DCTDecode"])` yields the raw JPEG (Java `checkJpegStream`). 2217 examples green.

- [x] **Chunk W — PDFGraphicsStreamEngine Form XObject rendering**
  - Goal: the graphics engine processes `Do` of a Form XObject (recursively), using the form's own resources, with Java's 50-level recursion guard; plus port `JPEGFactoryTest#testPDFBox5137`.
  - Java source of truth: `contentstream/operator/graphics/DrawObject.java` (`increaseLevel`/`getLevel > 50`/`decreaseLevel`, `showForm`), `TestRendering` fixture `tiger-as-form-xobject.pdf`.
  - Dependencies: `PDFStreamEngine#process_form_xobject` (text path), predictor/stop-filter decode (Chunks T/U/V).
  - Done when: forms render (operators reach the graphics callbacks), recursion is bounded, and all rendering fixtures render; gates green; inventory rows closed.
  - Status: complete. `OperatorDrawObject` now calls `context.process_form_xobject` (made public) for `/Form`, using `context.resources || page.resources` so nested forms resolve their own `/XObject`, with `increase_level`/`level > 50`/`decrease_level` mirroring Java `DrawObject` (this bounds the self-referential `PDFBOX-4372-p4` fixture that previously stack-overflowed). `spec/pdfbox/contentstream/graphics_form_xobject_spec.cr` (2 tests, test-first): single and nested forms reach the callbacks. `JPEGFactoryTest#testPDFBox5137` ported in `jpeg_factory_spec.cr` with the SHA512-verified `PDFBOX-5196-lotus.jpg` fixture (structural `validate` + `checkJpegStream`). 2220 examples green.

- [x] **Chunk X — FreeText annotation default appearance generation**
  - Goal: `PDAnnotationFreeText#construct_appearances` builds the default `PDFreeTextAppearanceHandler`, which clips the writing area and lays out the contents with `PlainTextFormatter` (wrapped lines), matching Java.
  - Java source of truth: `PDAnnotationFreeText.java#constructAppearances`, `handlers/PDFreeTextAppearanceHandler.java` (addRect + clip + PlainTextFormatter).
  - Dependencies: `PDAppearanceContentStream#clip`, `PlainTextFormatter`/`AppearanceStyle`/`PlainText`.
  - Done when: `construct_appearances` produces a normal appearance with a clip and the text; gates green; inventory rows closed.
  - Status: complete. `PDAnnotationFreeText#construct_appearances` now instantiates `PDFreeTextAppearanceHandler` (custom handler still respected); the handler emits `cs.clip` and renders the contents via `PlainTextFormatter` (`.wrapLines(true).initialOffset(xOffset, yOffset)`), matching Java — previously `construct_appearances` was a no-op and the handler skipped clip/text wrap. Also fixed the handler's constructor to inherit the base `Document?` parameter. `spec/pdfbox/pdmodel/interactive/annotation/free_text_appearance_spec.cr` (2 tests, test-first). 2222 examples green.

- [x] **Chunk Y — `COSStream#toTextString` + complete `PDAcroFormFromAnnotsTest`/`TestCMapSubtable`**
  - Goal: port `COSStream#toTextString` (decode stream data as a PDF text string) and finish the remaining portable Java tests.
  - Java source of truth: `cos/COSStream.java#toTextString`, `pdmodel/interactive/form/PDVariableText.java#getRichTextValue`; `PDAcroFormFromAnnotsTest` (4985CorrectionMode/WithoutCorrectionMode, 3891ValidateFont); `TestCMapSubtable`.
  - Dependencies: `Cos::Stream#create_input_stream`, `Cos::String` text decoding.
  - Done when: `to_text_string` decodes UTF-16/PDFDocEncoding/Flate text and is used by `getRichTextValue`; remaining tests ported; gates green; inventory rows closed.
  - Status: complete. `Cos::Stream#to_text_string` added (decode through filters + `Cos::String` text decoding, `""` on failure) and `PDVariableText#get_string_or_stream` now uses it (was raw bytes). `PDAcroFormFromAnnotsTest` now fully ported (all 6 methods: added `4985CorrectionMode`, `4985WithoutCorrectionMode`, `3891ValidateFont` with the font-descriptor comparison), and the already-covered `TestCMapSubtable` rows reconciled. `spec/pdfbox/cos/stream_to_text_string_spec.cr` (4 tests, test-first). 2229 examples green.

- [x] **Chunk Z — Missing graphics operator names (SCN/scn/F)**
  - Goal: the graphics engine handles `SCN`/`scn` (generic color on pattern-capable spaces) and `F` (legacy fill non-zero), matching Java's registrations.
  - Java source of truth: `contentstream/PDFGraphicsStreamEngine.java`, `operator/color/SetStrokingColorN.java`, `SetNonStrokingColorN.java`, `operator/graphics/LegacyFillNonZeroRule.java`.
  - Dependencies: existing `OperatorSetStrokingColor`/`OperatorSetNonStrokingColor`/`OperatorFillNonZeroRule`.
  - Done when: content streams using `SCN`/`scn`/`F` apply the color/fill; gates green; inventory rows closed.
  - Status: complete. Registered `OperatorSetStrokingColorN` (SCN), `OperatorSetNonStrokingColorN` (scn) and `OperatorLegacyFillNonZeroRule` (F) — previously these operators were silently dropped (unhandled names). `spec/pdfbox/contentstream/graphics_operator_names_spec.cr` (3 tests, test-first): `F` fires `fill_path`, `SCN`/`scn` set the stroking/non-stroking color. 2232 examples green.

- [x] **Chunk AA — Shading model + `PDPageContentStream#shading_fill` resource wiring**
  - Goal: `PDShading.create` (types 1-7) and `PDResources#add(PDShading)`/`#shading` exist, and `shading_fill` adds the shading to the page resources and writes the resource name + `sh` (Java `shadingFill`), instead of an operand-less `sh`.
  - Java source of truth: `pdmodel/graphics/shading/PDShading.java#create`, `pdmodel/PDResources.java#add(PDShading)`/`getShading`, `pdmodel/PDPageContentStream.java#shadingFill`.
  - Dependencies: `PDColorSpace.create`, `Cos::Dictionary`.
  - Done when: shading fill round-trips through resources and content; unknown type raises; gates green; inventory rows closed.
  - Status: complete. `PDShading` base (cos_object/shading_type/color_space) + `PDShadingType1..7` + `create` (unknown type -> ArgumentError); `PDResources#add(PDShading)` (prefix "sh") and `#shading(name)`; `PDPageContentStream#shading_fill(shading : PDShading)` writes `/<name> sh` and stores the resource (was an operand-less `sh`). `spec/pdfbox/pdmodel/graphics/shading_spec.cr` (3 tests, test-first). 2235 examples green.

- [x] **Chunk AB — `PDPageContentStream#draw_image(PDInlineImage)`**
  - Goal: drawing an inline image writes the `q <matrix> cm BI ... ID <data> EI Q` sequence, matching Java `PDAbstractContentStream#drawImage(PDInlineImage,...)`.
  - Java source of truth: `pdmodel/PDAbstractContentStream.java#drawImage(PDInlineImage, ...)`; `PDColorSpace#getName`.
  - Dependencies: `PDInlineImage` model, `OperatorName` (BI/ID/EI), `PDFStreamParser` inline image handling.
  - Done when: the generated content re-parses to an inline-image operator with the parameters/data; gates green; inventory rows closed.
  - Status: complete. `draw_image(PDInlineImage, x, y, width, height)` now writes the inline image (previously a no-op after the text-mode guard): `q`, matrix `cm`, `BI` dict (W/H/CS/D/IM/BPC), `ID` + raw data, `EI`, `Q`. `PDColorSpace#name` declared abstract (PDPattern returns "Pattern"). `spec/pdfbox/pdmodel/inline_image_draw_spec.cr` (2 tests, test-first): round-trips through `PDFStreamParser` (params + data) and covers the Decode/stencil dict. 2237 examples green.

- [x] **Chunk AC — Render inline images (BI operator)**
  - Goal: the graphics engine turns a `BI` operator into a `PDInlineImage` and calls `drawImage`, matching Java `BeginInlineImage`.
  - Java source of truth: `contentstream/operator/graphics/BeginInlineImage.java`; `PDInlineImage extends PDImage`.
  - Dependencies: `PDFStreamParser` inline-image parsing, `PDInlineImage`.
  - Done when: a content stream with an inline image reaches `draw_image` with a `PDInlineImage`; gates green; inventory rows closed.
  - Status: complete. `PDInlineImage` now extends `PDImage` (`PDImage#color_space`/`decode` made nilable, `create_input_stream` added); the graphics engine overrides `process_operator` to handle `BI` (build `PDInlineImage` from the operator's parsed params/data, call `draw_image`). Previously `BI` was dropped. `spec/pdfbox/contentstream/inline_image_operator_spec.cr` (1 test, test-first): a `BI` content stream yields one `PDInlineImage` with W/H/BPC/DeviceGray. 2238 examples green.

- [x] **Chunk AD — `PDPageContentStream` path operators write their operands**
  - Goal: `addRect`/`moveTo`/`lineTo`/`curveTo`/`curveTo1`/`curveTo2` write their operands before the operator, matching Java `PDAbstractContentStream`.
  - Java source of truth: `pdmodel/PDAbstractContentStream.java` (addRect/moveTo/lineTo/curveTo/curveTo1/curveTo2).
  - Dependencies: `write_operands`/`write_operator`.
  - Done when: the generated content re-parses to `<operands> <operator>`; gates green; inventory rows closed.
  - Status: complete. The six path methods previously wrote only the operator (`re`/`m`/`l`/`c`/`v`/`y`) with no operands (invalid content); they now call `write_operands(...)` first. Note Java's mapping: `curveTo1` -> `y` (replicate final point), `curveTo2` -> `v` (replicate initial point). `spec/pdfbox/pdmodel/page_content_stream_path_spec.cr` (3 tests, test-first). 2241 examples green.

- [x] **Chunk AE — Marked content generation (`beginMarkedContent`/`endMarkedContent`)**
  - Goal: `PDPageContentStream` writes `BMC`/`BDC`/`EMC` for marked content, with property lists (OCG) added to `/Resources /Properties` — the content-generation half of `TestOptionalContentGroups#testOCGGeneration`.
  - Java source of truth: `pdmodel/PDAbstractContentStream.java` (`beginMarkedContent` x3, `endMarkedContent`), `PDResources#add(PDPropertyList)`; `TestOptionalContentGroups#testOCGGeneration`.
  - Dependencies: `PDPropertyList`/`PDOptionalContentGroup`, `PDResources`.
  - Done when: the generated content re-parses to `/Tag BMC`, `/Tag /oc1 BDC`, `/Tag <</MCID n>> BDC`, `EMC` and the OCG is in the page resources; gates green; inventory rows closed.
  - Status: complete. Added `begin_marked_content` (tag, tag+mcid, tag+property list with the PDFBOX-5890 MCID simplification) and `end_marked_content`; `PDResources#add(PDPropertyList)` (prefix "oc" for OCG, "Prop" otherwise); `PDOptionalContentGroup` now extends `PDPropertyList`. `spec/pdfbox/pdmodel/page_content_stream_marked_content_spec.cr` (4 tests, test-first). 2245 examples green.

- [x] **Chunk AF — `LayerUtility` page→form/layer import**
  - Goal: `LayerUtility` (`wrapInSaveRestore`, `importPageAsForm`, `appendFormAsLayer`) imports a page as a Form XObject and appends it as an optional-content layer, matching Java `TestLayerUtility#testLayerImport`.
  - Java source of truth: `multipdf/LayerUtility.java`; `TestLayerUtility.java`; `PDAbstractContentStream#setTextMatrix`.
  - Dependencies: `PDFormXObject`, `PDOptionalContentGroup`, `PDPageContentStream` (marked content), `PDResources`.
  - Done when: the imported layer lands in `/Resources /Properties` (oc1) and the catalog OCProperties (group "overlay"); gates green; inventory rows closed.
  - Status: complete. `LayerUtility` ported (wrap q/Q, import page content as a form with the page's resources and bbox, append the form under `/OC /oc1 BDC`). Added `PDPageContentStream#set_text_matrix` (Tm) and made `PDPropertyList.create` dispatch `/Type /OCG` → `PDOptionalContentGroup`; fixed `PDOptionalContentProperties#get_ocgs`/`get_d`/`to_dictionary` to dereference indirect refs (the OCG lookup failed after save/reload). `spec/pdfbox/multipdf/layer_utility_test_spec.cr` (1 test, test-first, incl. PDFBOX-5232). 2246 examples green.

- [x] **Chunk AG — `PDFCloneUtility` deep clone (+ real `multipdf_spec`)**
  - Goal: `PDFCloneUtility#clone_for_new_document` deep-clones COS objects (arrays/dicts/streams, indirect remap, self-references) into a destination document, matching Java; replace the empty `multipdf_spec` placeholder with a real `PDFCloneUtilityTest#testClonePDFWithCosArrayStream`.
  - Java source of truth: `multipdf/PDFCloneUtility.java`; `PDFCloneUtilityTest.java`; `PDPage#getContentStreams`.
  - Dependencies: COS model.
  - Done when: the cloned page dict has two content streams; gates green; inventory rows closed.
  - Status: complete. Ported `PDFCloneUtility` (cloneForNewDocument/cloneCOSBase/cloneCOSArray/cloneCOSStream/cloneCOSDictionary/cloneMerge/hasSelfReference); added `PDPage#content_streams` (getContentStreams). `spec/pdfbox/multipdf/multipdf_spec.cr` now runs a real `PDFCloneUtilityTest#testClonePDFWithCosArrayStream` (the file was a stub of empty `it` blocks; the merger-dependent cases 2/DirectIndirect are marked partial pending `PDFMergerUtility#appendDocument`). 2246 examples green.

- [x] **Chunk AH — `PDFMergerUtility#appendDocument`**
  - Goal: `PDFMergerUtility#append_document(destination, source)` appends a source document's pages into the destination (deep-cloned via `PDFCloneUtility`, optional-content properties merged), unblocking the remaining `PDFCloneUtilityTest` cases.
  - Java source of truth: `multipdf/PDFMergerUtility.java#appendDocument`; `PDFCloneUtilityTest` (CosArrayStream2, DirectIndirect).
  - Dependencies: `PDFCloneUtility`, `Document#add_page`, optional content.
  - Done when: the merged document has the combined pages and saves/reloads; gates green; inventory rows closed.
  - Status: complete. `PDFMergerUtility` ported (portable subset): `append_document` deep-clones each source page (stripping `/Parent`), adds it to the destination tree, and copies the source OCProperties when the destination has none. `spec/pdfbox/multipdf/multipdf_spec.cr` runs real `PDFCloneUtilityTest#testClonePDFWithCosArrayStream2` (3 appended content streams → merge → save/reload 1 page) and `#testDirectIndirect` (1+1 pages). 2246 examples green.

- [x] **Chunk AI — `PDFMergerUtility` file merge + AcroForm legacy merge**
  - Goal: `mergeDocuments`/`addSource` and AcroForm legacy merge (rename conflicting fields to `dummyFieldNameN`), matching Java, plus `PageExtractorTest#testExtract`.
  - Java source of truth: `multipdf/PDFMergerUtility.java` (`mergeDocuments`, `addSource`, `acroFormLegacyMode`); `MergeAcroFormsTest#testLegacyModeMerge`; `PageExtractorTest#testExtract`.
  - Dependencies: `PDFCloneUtility`, `PDAcroForm`, `PageExtractor`.
  - Done when: merging the same AcroForm document twice yields the reference field set; page-range extraction counts match; gates green; inventory rows closed.
  - Status: complete. `PDFMergerUtility` gained `add_source`, `merge_documents`, `destination_file_name`, `acro_form_merge_mode` (AcroFormMergeMode) and `acro_form_legacy_mode` (clone each source root field, renaming clashes to `dummyFieldNameN`). Also fixed `PDFieldFactory.find_field_type` and `PDAcroForm#walk_field_tree` to use identity-based visited sets — the deep clone creates direct/cyclic dict references that made the value-based `Set(Cos::Dictionary)` stack-overflow on `hash`. `spec/pdfbox/multipdf/multipdf_spec.cr` runs the real `MergeAcroFormsTest#testLegacyModeMerge` (12 root fields incl. renamed) and `PageExtractorTest#testExtract`. 2246 examples green.

- [x] **Chunk AJ — Named destinations + merge annotation/AP tests**
  - Goal: `PDDocumentNameDestinationDictionary`/`DocumentCatalog#dests` and merging source `/Dests` in `append_document`; port `MergeAcroFormsTest#testAnnotsEntry`/`#testAPEntry` and `MergeAnnotationsTest#testLinkAnnotations`.
  - Java source of truth: `pdmodel/PDDocumentNameDestinationDictionary.java`, `PDDocumentCatalog#getDests`, `PDFMergerUtility` destination merge; the three tests.
  - Dependencies: `PDFMergerUtility`, `PDFCloneUtility`, `PDDestination`.
  - Done when: merged docs carry all annotations/fields and the combined `/Dests` dictionary; gates green; inventory rows closed.
  - Status: complete. Added `PDDocumentNameDestinationDictionary` (getDestination), `DocumentCatalog#dests`, and `/Dests` merge in `append_document`; ported the three tests with SHA512-verified fixtures (`PDFBOX-1031-{1,2}.pdf`, `PDFBOX-1100-{1,2}.pdf`, `PDFBOX-1065-{1,2}.pdf`) under `spec/resources/pdfbox/multipdf/`. 2246 examples green.

- [x] **Chunk AK — OpenAction preservation across merge**
  - Goal: `DocumentCatalog#open_action` returns destinations or actions (Java `PDDestinationOrAction`) with a setter, and `append_document` preserves the source `/OpenAction`; port `PDFMergerUtilityTest#testPDFMergerOpenAction`.
  - Java source of truth: `PDDocumentCatalog#getOpenAction`/`setOpenAction`, `PDFMergerUtility#mergeOpenAction`, `PDPageDestination#getPage`; the test.
  - Dependencies: `PDFMergerUtility`, `PDFCloneUtility`, `PDDestination`.
  - Done when: merged OpenAction points at the correct merged page index; gates green; inventory rows closed.
  - Status: complete. `PDAction` now includes `PDDestinationOrAction`; `DocumentCatalog#open_action` returns a destination (array) or action and gained a setter; `append_document` copies the source OpenAction when the destination has none; `PDPageDestination#page` now dereferences indirect references (previously nil after reload). `spec/pdfbox/multipdf/multipdf_spec.cr` runs the real `PDFMergerUtilityTest#testPDFMergerOpenAction` (merged OpenAction -> page index 4). 2246 examples green.

- [x] **Chunk AL — Splitter + structure-tree clone + page import**
  - Goal: port `org.apache.pdfbox.multipdf.Splitter` so a document can be split into per-page/range documents with cloned annotations, fixed link destinations, and a cloned logical structure tree; port `PDFMergerUtilityTest#testSinglePageSplit`, `#testSplitWithPopupAnnotations`, `#testSplitWithBrokenDestination`.
  - Java source of truth: `multipdf/Splitter.java` (+ `KCloner`), `PDDocument#importPage`, `COSDictionary#resetImportedObjectKeys`/`COSArray#resetObjectKeys`, `PDFMergerUtility#getNumberTreeAsMap`/`getIDTreeAsMap`, `PDStructureTreeRoot` parent/ID-tree accessors, `PDParentTreeValue`.
  - Dependencies: `PDFCloneUtility`/`PDFMergerUtility`, `PDStructureTreeRoot`, `PDNumberTreeNode`/`PDNameTreeNode`, `PDAnnotation` model, `PDPage`.
  - Done when: split output passes the Java structure-tree orphan checks and destination fixups; gates green; inventory rows closed.
  - Status: complete. New `Splitter` (+ `KCloner`) in `src/pdfbox/multipdf/splitter.cr`, `Document#import_page`, COS `reset_imported_object_keys`/`reset_object_keys`, `PDFMergerUtility.get_number_tree_as_map`/`get_id_tree_as_map`, `PDParentTreeValue`, `PDStructureTreeRoot#parent_tree`/`id_tree=`/`parent_tree_next_key`/`=`, `PDStructureElement#page`, and struct-parent accessors on `PDPage`/`PDFormXObject`/`PDImageXObject`. Fixed `PDNumberTreeNode#numbers`/`#kids` and `PDNameTreeNode#names`/`#kids` to dereference indirect entries (Java `getObject`). Follow-ups all ported: `testSplitWithStructureTree` (4417), `testSplitWithStructureTreeAndDestinations`/`...AndRemovedAnnotations` (5762), `testSplitWithNamedDestinations` (5840), `testSplitWithPgEntryAtTheTop` (6009), `testSplitWithOrphanPopupAnnotation` (6018), `testOutlinesSelfParent` (5939), `testPDFBox515` (ComSquare1/Ghostscript1), and `COSObjectKeyTest#testPDFBox5742`. The latter three surfaced real gaps now fixed: `PDFMergerUtility#mergeInto` info-dictionary merge in `append_document`, the writer's `/Info` object root in `build_roots` (Info was silently dropped on save), and `PDFRenderer#render_image_png` (`CrImage::PNG.write`). 2246 examples green.

- [x] **Chunk AM — appendDocument structure-tree merge**
  - Goal: merge `/StructTreeRoot` `/K`/`/ParentTree`/`/IDTree`/`/RoleMap` across appendDocument with `/StructParent(s)` offsets, matching Java; port `testStructureTreeMerge1-7`, `testParentTree`, `testMissingParentTreeNextKey`, `testStructureTreeMergeIDTree`, `testMergeBogusStructParents1/2`, `testPDFBox5198_2/3`, `testFileDeletion`, `testPDFMergerUtility`/`...2`/`testJpegCcitt`.
  - Java source of truth: `PDFMergerUtility.appendDocument` + merge helpers, `PDFMergerUtilityTest`.
  - Done when: merged trees pass the orphan/number-tree checks and K/Parts structure; gates green; inventory rows closed.
  - Status: complete. `append_document` rewritten to Java's catalog + page loop, plus `merge_k_entries`/`merge_role_map`/`merge_id_tree`/`update_page_references`/`update_struct_parent_entries`/`merge_mark_info`/`merge_language`/`merge_viewer_preferences`. New `/Info` writer root and cyclic-container protection in `COSWriter`. 18 tests ported with SHA512-verified fixtures. 2246 examples green. `plans/active/StructureTreeMergePort.md`.

- [x] **Chunk AN — Overlay rotation tests / multipdf closeout**
  - Goal: port the last multipdf placeholders (`OverlayTest#testRotatedOverlays`, `#testRotatedOverlaysMap`, `#testOverlayOnRotatedSourcePages`) and close the duplicate `TestLayerUtility#testLayerImport` placeholder.
  - Java source of truth: `OverlayTest.java`, `Overlay.java`.
  - Status: complete. Added `Overlay#default_overlay_pdf=`; fixed `Overlay#extract_content_text`/`#add_original_content` to dereference indirect `/Contents` (an indirect overlay page content produced an empty Form XObject that failed to render). The three overlay tests pass with pixel-identical rendering against the Java model PDFs; `TestLayerUtility#testLayerImport` already lived in `spec/pdfbox/multipdf/layer_utility_test_spec.cr` (removed the duplicate placeholder). No empty `it` blocks remain in `multipdf_spec.cr`.

- [x] **Chunk AO — pdfbox-io ScratchFile + IOUtils + backlog cleanup**
  - Goal: port the genuinely-unported pdfbox-io tests (`ScratchFileBufferTest`, `TestIOUtils`) and remove the stale duplicate placeholders.
  - Java source of truth: `vendor/pdfbox/io/src/main/java/org/apache/pdfbox/io/{ScratchFile,ScratchFileBuffer,MemoryUsageSetting}.java`, `IOUtils.java`; tests under `vendor/pdfbox/io/src/test/java`.
  - Status: complete. Added `MemoryUsageSetting` (main-memory/temp-file), `ScratchFile`/`ScratchFileBuffer` (Java seek semantics: negative -> IOException, past-end -> EOFException, no `createView`), and `IOUtils.populateBuffer` (`Utils.populate_buffer`). New specs `spec/pdfbox/io/scratch_file_buffer_spec.cr` (7) and `spec/pdfbox/io/io_utils_spec.cr` (1). Deleted the auto-generated `spec/porting/pdfbox-6req_spec.cr` (89 vacuous placeholders for the 10 IO classes, all covered by the real `spec/pdfbox/io/*` suites). 2164 examples green (89 vacuous placeholders removed, 8 real added).

- [x] **Chunk AP — appendDocument catalog merges (page labels / output intents / metadata / outline)**
  - Goal: finish the `appendDocument` catalog merges deferred from Chunk AM.
  - Java source of truth: `PDFMergerUtility.appendDocument` (page-label block, metadata block, `mergeOutputIntents`) and the outline-append branch.
  - Status: complete. `merge_page_labels` (source `/PageLabels /Nums` appended with the destination page-count offset, rollback on a non-numeric index), `merge_metadata` (destination has none -> decoded source metadata copied to a new unfiltered stream, dict merged except `/Filter`/`/Length`), `merge_output_intents` (skip duplicate identifier unless "Custom"), and the outline-append path (clone source children after the last destination sibling, fixing `/Prev`/`/Last`). New spec `spec/pdfbox/multipdf/catalog_merge_spec.cr` (6). 2170 examples green.

- [x] **Chunk AQ — pdfparser test coverage (`TestPDFParser`, `TestCOSParser`, `EndstreamFilterStreamTest`)**
  - Goal: port the remaining `org.apache.pdfbox.pdfparser` test suites (falsely marked ported).
  - Java source of truth: `TestPDFParser.java` (18), `TestCOSParser.java` (1), `EndstreamFilterStreamTest.java` (2).
  - Done when: all ported and green; inventory rows closed.
  - Status: complete. `spec/pdfbox/pdf_parser/test_pdf_parser_spec.cr` (18: missing-catalog load, PDFBOX-3208/3783/3785/3940/3947/3948/3949/3950/3951/3964/3977/4153/4338/4339/4490/5025, parseGenko), `cos_parser_spec.cr` (testCheckForEndOfString), `endstream_filter_stream_spec.cr` (filter buffer-crossing CRLF + embedded-zip 17660 bytes). Fixed `Xmpbox::DateConverter.parse_offset_seconds` to strip the PDF `HH'mm'` apostrophe offsets (PDFBOX-3208/3977 red before). Fixtures (`spec/resources/pdfbox/pdparser/`, 20 files) SHA512-verified + `SHA512SUMS` added. 2191 examples green.

- [x] **Chunk AR — remaining falsely-ported font/CMap tests + placeholder cleanup**
  - Goal: close the last falsely-ported test rows and stale placeholders.
  - Java source of truth: `TestCMap.java#testPDFBox3997`; `PDMMType1Font.java`; the `org/apache/pdfbox/text` suites.
  - Status: complete. Ported `TestCMap#testPDFBox3997` (NotoEmoji glyph 0x1F681 → 886) with the SHA512-verified `spec/resources/fontbox/cmap/NotoEmoji-Regular.ttf` + `SHA512SUMS`; made `PDMMType1Font` a faithful `PDType1Font` subclass (removed the misleading "Not implemented" rescue) and tightened the font-factory spec to assert the exact subtype; removed the redundant `spec/porting/pdfbox-9zt_spec.cr` (BidiTest/PDFTextStripperByAreaTest/TestTextStripper already covered by `spec/pdfbox/text/*`) and repointed those inventory rows; removed stray AppleDouble `._*` files. 2191 examples green.

- [x] **Chunk AS — resolve TTFSubsetter TODO + final placeholder cleanup**
  - Goal: turn the last stale spec TODO into a real assertion and remove the remaining vacuous porting stubs.
  - Java source of truth: `TTFSubsetterTest.java#testEmptySubset2` (selected tables); the `org/apache/pdfbox/text`, `pdmodel/interactive/action` suites.
  - Status: complete. `testEmptySubset2` now asserts every selected table (`head`/`hhea`/`loca`/`maxp`/`cvt `/`prep`/`glyf`/`hmtx`/`fpgm`/`gasp`) is present in the subset (was a TODO). Deleted the last 9 vacuous `spec/porting/pdfbox-*` stubs (directories covered by real specs) and repointed `PDActionURITest` inventory rows to `pd_action_uri_test_spec.cr`. 2182 examples green (9 vacuous stubs removed).

- [x] **Chunk AT — PDFMarkedContentExtractor + full checkWithNumberTree MCID walk**
  - Goal: port `text/PDFMarkedContentExtractor` and complete the deferred marked-content/MCID walk in the merger's `checkWithNumberTree`.
  - Java source of truth: `PDFMarkedContentExtractor.java`, `PDMarkedContent.java`, `PDFMergerUtilityTest#checkWithNumberTree`.
  - Status: complete. New `Pdfbox::Text::PDFMarkedContentExtractor` (marked-content nesting + MCID/text collection, `suppress_duplicate_overlapping_text`); `PDMarkedContent` gained `contents`/`add_text`/`add_marked_content`/`add_x_object`/`language`/`alternate_description`/`expanded_form`; `multipdf_spec`'s `check_with_number_tree` now performs the full Java MCID walk (each MCID resolves to a structure element whose kids reference it) and checks annotation `/StructParent`s. Fixed real bugs exposed by the strengthened test: `PDStructureElement#kids`/`#parent`/`#create_kid` didn't dereference indirect `/K`/`/P` (multi-kid elements empty after save/reload); `CMapParser#increment` overflowed at byte 255 in position 0 (Java byte-wrap); `PDAnnotation#struct_parent` used default 0 instead of Java's -1. New `spec/pdfbox/text/pdf_marked_content_extractor_spec.cr`; 41 multipdf + 2183 total examples green.

- [x] **Chunk AU — PDArtifactMarkedContent**
  - Goal: close the `/Artifact` deviation documented in Chunk AT.
  - Java source of truth: `PDArtifactMarkedContent.java`.
  - Status: complete. `PDArtifactMarkedContent < PDMarkedContent` with `type`/`subtype`/`bbox`/`top_attached?`/`bottom_attached?`/`left_attached?`/`right_attached?`; `PDMarkedContent.create` now dispatches the `/Artifact` tag to it. New spec `spec/pdfbox/pdmodel/document_interchange/marked_content/pd_artifact_marked_content_spec.cr` (2). 2185 examples green.

- [x] **Chunk AV — PDMarkInfo + faithful mergeMarkInfo**
  - Goal: port `PDMarkInfo` and make `PDFMergerUtility#mergeMarkInfo` use it exactly like Java.
  - Java source of truth: `PDMarkInfo.java`, `PDFMergerUtility#mergeMarkInfo`.
  - Status: complete. New `PDMarkInfo` (`marked?`/`marked=`, `uses_user_properties?`/`=`, `suspect?`, faithful `suspect=` that writes `/Suspects` false like the upstream quirk); `DocumentCatalog#mark_info`/`mark_info=`; `merge_mark_info` rewritten to `setMarked(true)` + OR suspect/user-properties via `PDMarkInfo` (previously wrote a wrong `/Suspect` key). New `spec/pdfbox/pdmodel/document_interchange/logical_structure/pd_mark_info_spec.cr` + an `append_document` mark-info assertion in `catalog_merge_spec.cr`. 2188 examples green.

- [x] **Chunk AW — embedded subset font reuse (`testReuseEmbeddedSubsettedFont`)**
  - Goal: fix the documented limitation so a reloaded embedded subset font can be reused to append text.
  - Java source of truth: `TestFontEmbedding#testReuseEmbeddedSubsettedFont`, `PDAbstractContentStream#showText`.
  - Status: complete. Root cause: `PDPageContentStream#show_text` took the GSUB-worker branch (only recording glyph IDs) without adding the shown code points, so the embedded subset's rebuilt `cmap` contained only whitespace → the reloaded font returned glyph 0 for every letter. Java's `showText` **always** adds every code point to the subset (in addition to the GSUB glyph IDs); mirrored that. `spec/pdfbox/pdmodel/font/font_embedding_spec.cr#testReuseEmbeddedSubsettedFont` is now the real Java test (append text2, reload, extract `text1 + " " + text2`) instead of the `expect_raises` limitation. 2188 examples green.

> **Inventory note (2026-08-17):** The test-parity inventory was reconciled against the spec tree — ~680 rows for already-ported classes (COS model, encryption, filters, IO, multipdf, text stripper, tools CLIs, graphics color/blend/inline-image/optional-content/rendering-intent, parser edge cases) were moved from `missing` to `ported`. The genuinely-remaining test work is the 16 classes above (Chunks G–N); everything else in `missing` is out-of-scope (debugger/benchmark/examples) or stale-inventory residual.
>
> **Unmapped mining (2026-10-10):** mined the 525 `unmapped` `falsely_ported` rows for systematic 1:1 renames to encode as `owner_aliases`/`renames`. Result: **no systematic 1:1 pattern exists** — the rows are dominated by N:1 / 1:N relationships and coincidental canonical collisions, which `owner_aliases` (1:1) cannot express: e.g. `PDAbstractContentStream.beginText` legitimately resolves to `page_content_stream`/`appearance_content_stream`/`form_content_stream`/… (40+28+17+13 rows); `RandomAccessRead.read` to a dozen `random_access_*`/`ttf*`/`ntta_stream` targets; `type4.<Operator>` classes to per-operator modules (`arithmetic_operators`, `bitwise_operators`, …). Only one clean 1:1 rename was found (`FSFontInfo → FontInfo`, applied). **Recommendation:** close the 738 `falsely_ported` at the tool level, not with rules — attribute inherited/interface members to the concrete Crystal types in `chiasmus-facts`, or add a name+signature "interface member" match mode that tolerates differing owners.
>
> **Chiasmus reconciliation refresh (2026-10-10):** the rebuilt `chiasmus-parity` (chiasmus.cr) plus the updated rules (`renames: DefaultResourceCache→ResourceCache`, extra `owner_aliases`) improved the map markedly: match rate 26% → 33% (`matched 3153→3518`, `unmapped 7310→5632`), `falsely_missing 56→20`, `falsely_ported 824→738`, `surface_match 2267→2440`. `--format divergences` now emits `target_file`/`target_owner`/`basis`, so the 20 `falsely_missing` rows were all verifiable owner matches (`DefaultResourceCache`, `CIDSystemInfo`, `Standard14Fonts`, `GlyphList`, `PDImage`, `CharStringCommand`, `PDTransitionDirection`) and were applied to both source inventories → `falsely_missing` is now 0. Remaining work: the 738 `falsely_ported` rows (525 unmapped + 213 no_facts) — more rename/owner rules or per-row verification.
>
> **Source-inventory reconciliation (2026-10-09, chiasmus-assisted):** built a Crystal type index from the tree-sitter symbol tables (chiasmus `map`/`graph facts` produce `defines(File, Symbol, Kind, …)` facts) plus a direct scan of `class/module/struct/enum/alias` declarations, then matched the Java `missing` rows: exact class/interface names, and methods whose camelCase name maps to a `def <snake_case>` in the class's Crystal file (stripping `get_`/`set_`/`is_`). Moved 3,486 source rows (`java_source_parity.tsv`) and 135 (`java_port_inventory.tsv`) from `missing` to `ported` with repo-relative refs, excluding debugger/tools/console/benchmark/examples. Remaining `missing` are renamed/consolidated classes (e.g. `COSBase` → `Base`) or genuinely unimplemented. No code changed; gates green.
>
> **Inventory reconciliation (2026-08-18):** the test-parity inventory was fully reconciled — all 1936 test rows now have a status (1701 `ported`, 235 `partial`, 0 `missing`). ~460 stale `missing` rows for fontbox (afm/cff/cmap/type1/ttf/gsub) and xmpbox (schema/type/parser/date) classes whose Crystal specs already exist were moved to `ported`; the remaining rows are test constants, mock-server/debug/helper test-infra classes, and render-advisory helpers (ValidateXImage), all marked `partial`/out-of-scope. New behavioral coverage added this pass: `GlyphSubstitutionTableLiberationFontTest` (default `latn` script, unsupported-script null, `cyrl` subs/sups features, all 7 supported script tags with UNSPECIFIED language) in `spec/fontbox/ttf/gsub_worker_liberation_font_spec.cr`.
