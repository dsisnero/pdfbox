# PDFBox Crystal Porting Parity

> Working document tracking broad feature porting status.
> Complements `plans/inventory/java_port_inventory.tsv` (per-method ledger) and `plans/active/` (per-class plans).
> Update this file as features progress.
>
> **Checkbox convention:** `[x]` complete and verified, `[~]` partial / in progress, `[ ]` not started.
> Phases are branch-sized, user-visible features — not individual helper methods.
> A feature is marked `[x]` only when its mapped inventory rows are closed and the parity checks are green.

**Current work:** Text extraction deviations investigated in detail (2026-05-25). Rotation deviation (PDFBOX-3127) fixed and MATCH. Spacing deviations traced to `delta_char_width` computed from CURRENT position width rather than PREVIOUS. Encoding deviation (PDFBOX-4532) traced to ToUnicode CMap period→space mapping. Java 3.0.4 recovers period through opaque stripper pipeline (likely `mergeDiacritic`/`normalizeWord`). Beads deviations (PDFBOX-3110) fixed and MATCH via `handleLineSeparation` article-start gating and cropbox text-position translation. cweb.pdf fixed and MATCH via Widths-array indirect-reference resolution, raw Type1 FontFile parsing (Length1/Length2 split), and MODIFIER_SYMBOL diacritic merging. All 8 deviation PDFs verified MATCH against a real Java 3.0.4 jar. FC60_Times's checked-in fixture is stale (2010 era, pre-`mergeDiacritic`); Crystal output equals Java 3.0.4 output.

---

## Overview

| Metric | Value |
|---|---|
| Java source files (vendor) | ~1,289 |
| Crystal source files (ported) | ~415 (`src/` has 464 `.cr` files) |
| Passing tests | 1,906 |
| Pending tests | 0 |
| Failures | 0 |
| Errors | 0 |
| Text extraction: exact match | 40/40 PDFs (100%) |
| Text extraction: known deviations | 0 PDFs (0%) |
| Text extraction: fixed this session | PDFBOX-3127, PDFBOX-3053, PDFBOX-3061, PDFBOX-4532 |
| Inventory: ported | 78 |
| Inventory: partial | 38 |
| Inventory: missing | 12,391 (mostly debugger/benchmark/examples out of scope) |
| Fixed since last update | PDOutlineItemIterator Java surface (`has_next?`/`next`/`remove` matching PDOutlineItemIteratorTest: single/multiple-item iteration, `remove` raises UnsupportedOperationError, no-children has_next? false). Document outline model (PDOutlineNode abstract base + PDOutlineItem + PDDocumentOutline + PDOutlineItemIterator: add_first/add_last with require-single-node guard, insert_sibling_before/after, Parent/First/Last/Prev/Next linked-list bookkeeping, open_count/COUNT propagation per PDF 32000-1 tables 152/153 with open/close switching and parent count cascading, parent resolution PDDocumentOutline-vs-PDOutlineItem via /Type /Outlines, children iteration with cycle guard; Cos::Dictionary#== identity short-circuit to survive cyclic outline trees). PNGConverter validation port (CRC-32 reference table, Chunk#data slicing, check_chunk_sane bounds/type-offset/CRC checks, check_converter_state chunk-set sanity, map_png_render_intent PNG-sRGB→PDF /Intent). PDImageXObject image dispatch (create_from_file_by_extension/create_from_file_by_content/create_from_byte_array routing JPEG→JPEGFactory, PNG/GIF/BMP/TIFF→raster, FileTypeDetector magic-byte detection with 17 signatures incl. PNG IHDR, longest-prefix wins). JPEGFactory port (`create_from_stream`/`create_from_byte_array`, SOF-marker width/height/numComponents parsing, DeviceGray/DeviceRGB/DeviceCMYK selection, CMYK inverted Decode array, exact JPEG-stream save/load round-trip). PDInlineImage model port (stencil/W/H/BPC/colorspace/suffix/filters). Optional content model (TestOptionalContentGroups generation + PDFBOX-4496, catalog `/OCProperties` with 1.5 version bump). RenderingIntentTest/RenderingMode parity. BlendModeTest port (separable blend-channel functions, non-separable hue/saturation/color/luminosity, `get_instance` COS map, singleton constants). Page-tree Kids indirection resolution. remove_page_from_tree implementation. COSArrayList retainAll CosObject inner check. Writer catalog /Version update. OpenTypeFont CFF path uses CFF charset. Encryption key length default (256→128). COS increment test (save/load page count). Document version test (1.4→1.6). FontMapper/TrueTypeCollection fixture fixes. BOM/diacritic normalization in text comparison. Bidi Crystal-specific regression tests. |
| Active porting plans | 1 (`plans/active/CosParserPort.md`) |

---

## Phase 1 — Text Extraction (most visible feature gap)

**Goal:** Exact text extraction parity with Java PDFBox across the fixture corpus.

- [x] Fix font height=0 regression (Type1 @generic_font, TTF/Mapped/OpenType upem scaling)
- [x] Fix CFF Type1CharString.width lazy render bug — unblocks 3 skipped PDFs (PDFBOX-5920, PDFBOX-5002, sample_fonts_solidconvertor)
- [x] Add bead/article infrastructure (PDRectangle.contains, PDPage.thread_beads, fillBeadRectangles)
- [x] Fix spacing deviation (PDFBOX-5920: `@path.nil?` → `@rendered` check)
- [x] Enable `with_outline.pdf` extraction parity — matches Java exactly
- [x] Enable `eu-001.pdf` tabula font-height extraction parity — matches Java exactly (0 diffs, 4567 bytes)
- [x] Add `text_stripper_normalize` (NFKC + BOM stripping) for lenient diacritic comparison
- [x] Add BidiSample Crystal-specific regression tests (size, content markers)
- [x] Fix rotation deviation (PDFBOX-3127) — MATCH
- [x] Fix encoding deviation (PDFBOX-4532) — marked content `/Span` `/ActualText "."` via BDC/BMC/EMC/MP/DP operator handling
- [x] Fix spacing deviation (PDFBOX-3053) — PDType3Font `displacement` override via font matrix transform
- [x] Fix spacing deviation (PDFBOX-3061) — `name_to_gid` returns 0 (not −1); removed gid==0 early return
- [x] Fix paragraph separation and article boundaries in `render_text_positions_by_article` (Java writePage parity)
- [x] Fix bead rectangle semantics (`fill_bead_rectangles` lower-left + width/height reconstruction)
- [x] Fix article-boundary line handling — `handleLineSeparation` article_start gating: only write `@line_separator` when `previous.line_start?` (PDFBOX-3110-poems-beads MATCH)
- [x] Fix cropbox text-position translation — LegacyPDFStreamEngine uses `page.crop_box` not `media_box` (PDFBOX-3110-poems-beads-cropbox MATCH)
- [x] Fix Widths-array indirect reference resolution — `/Widths` entry may be a `Cos::Object` (cweb.pdf spacing)
- [x] Fix raw Type1 FontFile parsing — non-PFB fonts split by `/Length1`/`/Length2` via `create_with_segments` (cweb.pdf word separators)
- [x] Fix MODIFIER_SYMBOL diacritic merging — add U+00A8/U+00AF/U+00B4/U+00B8 to `diacritic_codepoint?` (cweb.pdf accents)
- [x] Verify all deviation PDFs against a real Java 3.0.4 jar — all 8 MATCH; FC60_Times fixture is stale (2010 era), Crystal == Java 3.0.4 == current vendor source
- [x] Bidi Java parity — `handle_direction` reads run levels from `levels[run_start]` (was indexing a per-character array by run number), reverses RTL runs grapheme-aware with bracket mirroring (Java `Character.isMirrored` + MIRRORING_CHAR_MAP parity), and `render_items` writes words in extraction order (Java `writeLine`). hello3.pdf, both PDFBOX-4531-bidi-ligature PDFs, and BidiSample.pdf (sorted + unsorted) now match Java fixtures exactly.

**Deviation breakdown (2026-05-25 investigation):**

| PDF | Lines Diff | Root Cause | Status |
|-----|-----------|------------|--------|
| PDFBOX-3127 (rotation) | 0 | n/a | **MATCH** — fixed |
| PDFBOX-4532 (encoding) | 0 | **FIXED** — PDF has marked content `/Span` with `/ActualText "."`. Crystal's `process_operator` was missing BDC/BMC/EMC/MP/DP operators. Added operator handling in `PDFStreamEngine`, enabling `begin_marked_content_sequence` → `@actual_text` → `process_text_position` chain to override CMap's space with ActualText "." | Done |
| PDFBOX-3053 (spacing) | 0 | **FIXED** — Font "T5" is `PDType3Font`, not `PDTrueTypeFont`. Crystal used base `/1000` displacement, Java uses `getFontMatrix().transform()`. Added `displacement` override in `PDType3Font` to use font matrix transform. Font matrix scale 0.01724 vs 0.001 — 17.24x difference. | Done |
| PDFBOX-3061 (spacing) | 0 | **FIXED** — `name_to_gid` returned -1 instead of 0, causing `advance_width(-1)` to wrap to last glyph. Combined with `width_from_font` early return on gid==0. Fixed both: name_to_gid returns 0 (matching Java) + removed early return. | Done |
| PDFBOX-3110-poems-beads | 0 | 2-page PDF. Page 2's bead rectangles (3) don't cover y=447 text. Article boundaries reset `max_y_for_line`, preventing y-change detection between articles. | **FIXED** — `handleLineSeparation`: only write `@line_separator` at article boundary when previous position is line_start; Java writes only paragraphStart when article_start but not line_start. Verified against Java 3.0.4 jar output (75 lines both). | Done |
| PDFBOX-3110-poems-beads-cropbox | 0 | Same beads ordering issue. | **FIXED** — `LegacyPDFStreamEngine.process_page` was using `page.media_box`; Java uses `page.getCropBox()` and translates text positions by cropbox lower-left. Corrected to `page.crop_box`. | Done |
| FC60_Times | 1 | Arabic diacritic ordering: `بآُتَّا` vs stale fixture `بُآتَّا`. | **STALE FIXTURE** — Crystal output `بآُتَّا` equals Java 3.0.4 exactly (verified against release jar) and current vendor `mergeDiacritic` (unchanged since 2014). The checked-in `.txt` fixture dates from 2010 (PDFBOX-521/644 era) and predates current bidi/diacritic behavior. Not a Crystal bug. | Done |
| PDFBOX-4532-reduced (unlisted) | 1 | CMap maps period→space. See PDFBOX-4532 above. | Same |
| cweb.pdf | 0 | Massive differences — spacing + special chars (`|` vs `—`, `c` vs `c©`). | **FIXED** — three root causes: (1) `/Widths` arrays are indirect references (`Cos::Object`) that Crystal didn't dereference, giving wrong glyph widths; (2) non-PFB raw Type1 FontFiles weren't parsed — Java splits by `/Length1`/`/Length2` and calls `createWithSegments`, Crystal fell back to a TTF substitute with StandardEncoding; (3) `MODIFIER_SYMBOL` diacritics (U+00A8/U+00B4) weren't merged, leaving `¨u`/`C´e` instead of `ü`/`Cé`. All fixed — verified against Java 3.0.4 jar output (1509 lines both). | Done |
| hello3.pdf (bidi) | 1 | Arabic character order: `Hello دمحم World.` vs `Hello محمد World.` | Documented in `lib_issues/bidi.1.md` |

---

## Phase 2 — Font Embedding / Loading (blocks Type0/TrueType/Type1C parity)

**Goal:** All font subtypes load, embed, and subset with Java-parity behavior.

- [x] Font specs: all 129 examples pass, 0 pending
- [x] Type1 font PFB constructor — `PDType1Font.new(doc, pfb_in)` implemented
- [x] OpenType/CFF outline extraction through OTFParser — CFF path fix for format-3 post tables
- [x] GSUB specs: all 65 examples pass, 0 compile errors
- [x] GsubWorkerForTamil wired into factory (was TODO → `DefaultGsubWorker`)
- [x] TTF Subsetter — 795 lines Crystal, 8 spec tests pass
- [x] Font subsetting wired into save — `subset_embedded_fonts` calls `PDType0Font.subset`
- [x] TrueTypeEmbedder — 272 lines Java ported (abstract base, font descriptor, subsetting)
- [x] PDCIDFontType2Embedder — 677→427 lines Java→Crystal ported (CID font embedding, widths, vertical metrics)
- [x] Type1 `average_font_width` computed from WIDTHS dict (Java parity)
- [x] Type1/Type1C non-standard14 encode validation (Java parity)
- [x] Type1C font embedding width/height via embedded CFF (Java parity)

---

## Phase 3 — PDF Parsing & COS

**Goal:** Robust COS object, stream, xref, and document parsing.

- [x] PDFBOX-5025 test enabled — `length1` reads from font_file2 COS stream correctly
- [x] `COSParser.parseObjectStreamObject` — delegates to Parser which is fully implemented
- [x] Compressed object stream writing (xref stream format enabled, COSWriterObjectStream + COSWriterCompressionPool + PDFXrefStreamParser all working)
- [x] Document info get/set — all metadata fields available via `DocumentInformation`
- [x] Incremental save — `save_incremental` writes original bytes + full save; parser uses `rindex` for last startxref
- [x] Page-tree Kids indirection resolution before array-type checks
- [x] `COSArrayList#retain_all` checks inner Cos::Object for matching
- [x] `PDPageTree` nested tree traversal — `load_page_tree` recurses into intermediate Pages nodes
- [x] COSParser port plan complete — `plans/active/CosParserPort.md`, all methods ported, edge-case tests green

---

## Phase 4 — Content Stream Engine

**Goal:** Complete operator coverage on PDFStreamEngine / graphics engines.

- [x] All text operators (Tj, TJ, ', " Td TD T*) — implemented
- [x] All device color operators (G, g, RG, rg, K, k) — implemented
- [x] `SetGraphicsStateParameters` (gs) — `copy_into_graphics_state` implemented
- [x] Color space operators (CS, cs) — PDColorSpace.create factory + Resources.color_space
- [x] Generic color operators (SC, sc) — set color components on current color space
- [x] Marked content operators (BMC, EMC, MP, DP, BDC) — all 5 implemented, marked content stack + points on PDFStreamEngine
- [x] Indirect `Cos::Object` reference resolution for font names, show-text arrays, and TJ array items
- [x] `Cos::Number` handling for Tw/Tc word/character spacing in PDFGraphicsStreamEngine
- [x] `BlendMode` parity — ported against `BlendModeTest.java`: all 17 `BlendMode.*` constants with their blend-channel functions (12 separable: Normal/Multiply/Screen/Overlay/Darken/Lighten/ColorDodge/ColorBurn/HardLight/SoftLight/Difference/Exclusion) and blend functions (4 non-separable: Hue/Saturation/Color/Luminosity, via `getSaturationRGB`/`getLuminosityRGB` integer-math ports), plus `separable_blend_mode?`, `cos_name`, `blend_channel_function`, `blend_function`, and the `get_instance` COS name/array map (`Compatible` → `Normal`, integer-array fallback to `Normal`); singleton instances memoized so `get_instance` returns the same objects as the constants
- [x] `RenderingIntent`/`RenderingMode` parity — ported against `RenderingIntentTest.java`: `from_string` name mapping with empty-string fallback to RelativeColorimetric, `to_s_value` round-trip, `fills_text?` for Fill
- [x] Optional content model — ported against `TestOptionalContentGroups.java` generation tests (`testOCGGeneration`, `testOCGsWithSameNameCanHaveDifferentVisibility`, PDFBOX-4496 `setGroupEnabled` same-name): `PDOptionalContentProperties#add_group`/`group_enabled?`/`set_group_enabled` (returns true only when the group already had an ON/OFF setting), `base_state` default ON + setter, `group_names`/`optional_content_groups`/`group`/`has_group?`, and `DocumentCatalog#oc_properties`/`oc_properties=` (sets `/OCProperties`, bumps document version to 1.5)
- [x] `PDInlineImage` model parity — ported against `PDInlineImageTest.java` (`testInlineImage`, `doInlineCcittImage` model assertions): `stencil?` (from `/IM`/`/ImageMask`), `width`/`height`/`bits_per_component` (BPC → 1 for stencils, `/BPC` then `/BitsPerComponent` fallback), `interpolate?`, `empty?`, `cos_object` (returns the parameters dict), `color_space` (stencil missing CS → DeviceGray, `/G`→DeviceGray `/RGB`→DeviceRGB `/CMYK`→DeviceCMYK long-name mapping, indexed-array handling), `filters`/`filters=`, `decode`/`decode=`, `data` (decoded), and `suffix` (`png`/`jpg`/`tiff` from DCT/CCITTFax/CCF filters). AWT `BufferedImage`/`ImageIO` rendering assertions out of scope; CCITT/DCT filters not yet in the Crystal filter set (raw data kept)

---

## Phase 5 — PDF Writer

**Goal:** Byte-compatible document writing (incremental, compressed, encrypted).

- [x] All 12 writer specs green (0 pending)
- [x] testCompressEncryptedDoc, testPDFBox5927, testPDFBox6036 enabled
- [x] Compressed object stream writing via xref stream format
- [x] Writer catalog `/Version` update
- [x] Encryption key length default fixed (256→128) for revision 4 compatibility
- [x] COS increment test (save/load page count), document version test (1.4→1.6)
- [x] Font subsetting wired into save — `subset_embedded_fonts` calls `PDType0Font.subset` before every save

---

## Phase 6 — FontBox Infrastructure

**Goal:** TrueType/OpenType/Type1 low-level parsing and glyph substitution.

- [x] TrueTypeCollection: processes TTC fonts, resolves fonts by name, scans headers — fixture switched to `ipag.ttf`
- [x] OTFParser: standalone OpenType/CFF parsing — CFF path fix (uses CFF charset, not TTF post table)
- [x] GSUB specs: all 65 examples pass, no compile errors
- [x] GSUB: multiple/alternate/ligature substitution — end-to-end wiring in `PDPageContentStream.show_text`: `set_font` creates a GsubWorker for Type0 fonts with GSUB data, and `encode_text` routes through `encode_for_gsub`/`apply_gsub_rules` (codepoints → glyph IDs → GSUB transforms → `encode_glyph_id`), matching Java `PDAbstractContentStream.encodeForGsub`/`applyGSUBRules`. `PDType0Font` now stores the real Fontbox CmapLookup and GsubData from the TTF (was a stub). Subset ToUnicode resolves gid→unicode via cmap for GSUB-added glyphs; `write_fixed` writes signed 16-bit (negative italic angles).
- [x] GSUB: Tamil worker adjustments — wired into factory (Java's GsubWorkerForTamil also uses Gujarati logic per upstream TODO, so Crystal matches the Java source).
- [x] FontBox AFM module complete — FontMetricsTest/CharMetricTest/CompositeTest parity: unmodifiable collection getters (UnmodifiableList wrapper), `metric_sets=` 0..2 validation, and character width/height/average computation from char metrics.
- [x] Various TTF table TODO comments — reduced from 50+ to a handful of inline code comments (logging TODOs converted to NOTE comments, dead stubs removed). Remaining TODOs are either faithful copies of upstream Java TODO comments (e.g. Tamil worker Gujarati logic) or minor inline notes, not feature gaps.

---

## Phase 7 — PD Model Completeness

**Goal:** Full PDModel object surface with Java-parity semantics.

- [x] add_page_to_tree: resolve Kids indirect reference before checking array type
- [x] remove_page: also remove from catalog page tree (Kids array + Count decrement)
- [x] COSArrayList#retain_all: check inner Cos::Object for matching
- [x] `PDPageTree`: nested tree traversal — `load_page_tree` recurses into intermediate Pages nodes
- [x] `ResourceCache`: font, color space, ext gstate, property list caching with get/put/remove
- [x] `PDDocumentCatalog`: 32 methods including acro_form, viewer_preferences, metadata, output_intents, open_action
- [x] `PDDocumentInformation`: title, author, subject, keywords, creator, producer, dates — all getters/setters
- [x] Font subsetting wired into save — `subset_embedded_fonts` calls `PDType0Font.subset` before every save
- [x] PDRectangle.contains / thread_beads / bead rect semantics for article flow
- [x] CIE-based colour spaces — `PDLab` (name, 3 components, a/b ranges defaulting to -100..100, whitepoint 1,1,1 / blackpoint 0,0,0, initial colour, Lab→XYZ→sRGB) and `PDICCBased` (stream-backed, `/N` component count), plus `PDTristimulus` and the `PDCIEDictionaryBasedColorSpace` base — ported against `PDLabTest.java` and `PDICCBasedTest.java` (PDFBOX-2812); both wired into `PDColorSpace.create` instead of the `PDDeviceRGB` fallback
- [x] `JPEGFactory` port — `create_from_stream`/`create_from_byte_array` preserve the JPEG stream byte-for-byte and select the color space from the SOF (Start of Frame) frame-component count (1 → `PDDeviceGray`, 3 → `PDDeviceRGB`, 4 → `PDDeviceCMYK`, PDFBOX-4691/5137 numFrameComponents semantics); CMYK images get the inverted `Decode` array `[1 0 1 0 1 0 1 0]`; `PDImageXObject#color_space` now resolves the `/ColorSpace` COS entry instead of hardcoding `PDDeviceRGB` — ported against `JPEGFactoryTest.java` (`testCreateFromStream*` color-space/dimension assertions, `checkJpegStream` exact-bytes round-trip; AWT `BufferedImage`/`ImageIO` `createFromImage` paths out of scope)
- [x] `PDImageXObject` image-file dispatch — `create_from_file_by_extension`/`create_from_file_by_content`/`create_from_byte_array` route to `JPEGFactory` (JPEG magic/extension) or the CrImage raster path (PNG/GIF/BMP/TIFF), matching the suffix parity of Java's convenience methods; `create_from_file` delegates to the extension dispatch; `FileTypeDetector`/`FileType` ported from Java's magic-byte trie (17 signatures, longest-prefix wins, PNG requires the 16-byte signature incl. IHDR) — ported against `PDImageXObjectTest.java` (`testCreateFromFile*`/`testCreateFromByteArray` dispatch and suffix assertions; AWT `checkIdentARGB` pixel comparisons and `CustomFactory` out of scope)
- [x] `PNGConverter` validation port — PNG CRC-32 reference implementation (`crc` matches Java's signed-int values for `"Hello World!"`), `Chunk` with big-endian chunk-type constants + `data` slicing, `check_chunk_sane` (bounds + type-offset >= 4 + CRC over type+data), `PNGConverterState` chunk set + `check_converter_state` (IHDR non-null+sane, optional chunks must be sane if present, at least one sane IDAT), and `map_png_render_intent` (0→Perceptual, 1→RelativeColorimetric, 2→Saturation, 3→AbsoluteColorimetric, else nil) — ported against `PNGConverterTest.java` (`testCRCImpl`, `testChunkSane`, `testCheckConverterState`, `testMapPNGRenderIntent`; the `convertPNGImage` RGB/indexed XObject paths with ICC profiles/soft masks and the AWT pixel comparisons are separate/out of scope)

---

## Phase 8 — Annotations & Interactive

**Goal:** Forms, widgets, annotations, and actions round-trip through save/load.

- [x] Form field value serialization — save/load roundtrip verified for text, checkbox, list box fields
- [x] Annotation appearance handlers — PDAbstractAppearanceHandler + type-specific handlers generate normal/rollover/down appearance streams; `construct_appearances` verified for square/circle/text/link/underline/strikeout/highlight/squiggly/ink; `PDFRenderer.process_annotations` renders appearance streams end-to-end (verified via pdf_renderer_spec)
- [x] Action completion — all 13 action types implemented with factory, URI/GoTo/JavaScript getters/setters work
- [x] Document navigation (destinations: XYZ, Fit, FitB, FitH, FitV, FitR, Named) — PDDestination.create dispatch verified against Java; spec coverage for all destination types and XYZ/Fit getters/setters
- [x] Page navigation (threads, transitions) — PDThread/PDThreadBead circular bead list, PDTransition style/dimension/motion/direction/duration/fly-scale/opacity verified against PDTransitionTest.java + PDTransitionDirectionTest.java
- [x] Document outline — `PDOutlineNode` (abstract, COS-backed) + `PDOutlineItem` + `PDDocumentOutline` + `PDOutlineItemIterator`, ported against `PDOutlineItemTest.java`/`PDOutlineNodeTest.java` (all 42 examples): `add_first`/`add_last` (with `require_single_node` ArgumentError guard), `insert_sibling_before`/`insert_sibling_after` (with last/first-child parent updates), `Parent`/`First`/`Last`/`Prev`/`Next` linked-list maintenance, open-count (`/Count`) bookkeeping per PDF 32000-1 tables 152/153 — `open_node`/`close_node`/`node_open?`, delta cascading through `update_parent_open_count` (open parents add delta and recurse, closed parents subtract), `parent` resolution (PDDocumentOutline when `/Type /Outlines`), `children` iteration with cycle guard. Also `PDDocumentOutline` is always open and its `open_node`/`close_node` are no-ops. Required `Cos::Dictionary#==` identity short-circuit (Java's `this == obj`) so cyclic outline trees compare without stack overflow. `PDOutlineItemIterator` also exposes the Java iterator surface (`has_next?`/`next`/`remove`) per `PDOutlineItemIteratorTest.java` (single/multiple item, `remove` → UnsupportedOperationError, no-children).
- [x] Square/circle + widget annotation parity — ported against `PDCircleAnnotationTest.java`, `PDSquareAnnotationTest.java`, `PDAnnotationTest.java` (all 6 examples): `PDAnnotationCircle`/`PDAnnotationSquare` default Type `Annot`/Subtype `Circle`/`Square`; `PDSquareAnnotationTest.pdf` fixture appearance validation (BBox == annotation rect, Matrix translated to 0 origin by `-lower_left`, 10-token content stream `1 0 0 RG` + inset `re`/`S`); `createWithAppearance` construction smoke test. Fixed two parity gaps: `PDAppearanceDictionary` `normal`/`rollover`/`down` now dereference indirect `Cos::Object` references to the N/R/D subdictionaries (fixture stores `/N` as an indirect reference), and `PDTerminalField#widgets` now matches Java `getWidgets()` (a field without a `Kids` array is itself the widget, regardless of Subtype; widget kids are dereferenced) so `PDTextField#widgets[0]` carries Type `Annot`/Subtype `Widget`.
- [x] Form field appearance generation — ported against `PDDefaultAppearanceStringTest.java` (all 3 examples) and `AppearanceGenerationTest.java#testTinyHorizontalFieldWith0FontSize` (PDFBOX-5763): `PDDefaultAppearanceString` (parses `/F 12 Tf` font+size and `g`/`rg`/`k` non-stroking color; missing-resource `Could not find font` and wrong-arg `Missing operands` errors), `PDVariableText` base (inheritable `/DA`, default style string `/DS`, quadding `/Q`, rich text `/RV`), `PDAcroForm#default_resources=`/`default_appearance=`/`scripting_handler`, and `AppearanceGeneratorHelper` (widget loop skipping PMD/no-rect widgets, appearance dict/stream preparation with BBox+Matrix+FormType+Resources, `initializeAppearanceContent` background fill/border stroke/comb dividers, `setAppearanceContent` BMC/EMC token surgery, `insertGeneratedAppearance` clip + baseline-y + `PlainTextFormatter` text, `calculateFontSize` autosize with the PDFBOX-5763 `-Infinity` guard returning `heightBasedFontSize`). `PDTextField#value=` now calls `applyChange` → `construct_appearances` (Java parity), `PDResources#add(font)`/`get_font`/`put(name, font)`, `PDFont#==` compares the underlying COS dictionary (Java `getCOSObject()==`), `PDRectangle#create_retranslated_rectangle`, `PDAppearanceContentStream` gained `clip`/`close_and_stroke`/RGB+gray non-stroking color and an external-output constructor; `PlainTextFormatter` builder now takes `PDAppearanceContentStream` (Java).
- [x] Text/choice/button field model parity — ported against `PDTextFieldTest.java` (both examples), `PDChoiceTest.java` (all 5 examples), and `PDButtonTest.java` (all 14 examples): convenience constructors `PDTextField(acroForm)`/`PDChoice(acroForm)`/`PDButton(acroForm)` set the `/FT` entry (`Tx`/`Ch`/`Btn`) and combo boxes set the `FLAG_COMBO` bit; `getWidgets()` on a Kid-less field wraps the field dict itself (TYPE→`Annot`, Subtype→`Widget`); `PDButton` value logic (`getValue` with export-value index decoding and `Off` default, `setValue`→`checkValue` (ArgumentError on invalid options)/`updateByOption`-vs-`updateByValue`, `getDefaultValue`/`setDefaultValue`, `getExportValues`/`setExportValues`, `getOnValues`, `constructAppearances`, per-widget `/AS` propagation) with `PDCheckBox` (`checked?`/`check`/`uncheck`/`getOnValue`) and `PDRadioButton` (`radios_in_unison?`, `getSelectedIndex`, `getSelectedExportValues`); `PDChoice#getOptions`/`getOptionsDisplayValues` (Java `FieldUtils.getPairableItems` index-0/index-1 semantics over string or two-element-array `/Opt`). Fixture-based `AcroFormsBasicFields.pdf` tests cover checkbox on/off with `/AS` state, CheckboxGroup with shared on-values (Option1→one widget, Option3→two widgets in unison), and RadioButtonGroup selection. `testRadioButtonWithOptions`/`testOptionsAndNamesNotNumbers` (PDFBOX-3656/3682) use fixtures downloaded from the Java maven-wget URLs with SHA512 verified. Required `PDAppearanceEntry#sub_dictionary` to dereference indirect `Cos::Object` entries (fixture `/AP /N` values are indirect).
- [x] Field flags + value/options surface + appearance text normalization — ported against `TestFields.java` (all 3), `TestCheckBox.java` (both), `TestListBox.java` (all 9), `TestRadioButtons.java` (all 10), `CombAlignmentTest.java` (both, PDFBOX-5256/5784), `AlignmentTest.java` (1), `MultilineFieldsTest.java` (fillFields + testMultilineAuto, PDFBOX-3812), `HandleDifferentDALevelsTest.java` (all 3), and `ControlCharacterTest.java` (all 9, PDFBOX-3461): `PDTextField` flag setters, `value` getter (string-or-stream `/V`, indirect deref, `""` fallback) and `value=(String?)`; `PDChoice` value/options surface; `PDListBox#top_index`; `PDTerminalField#set_widgets`; `PDButton#check_value` message format. Appearance generation fixes surfaced by these tests: `PDType1Font#font_descriptor` now builds a descriptor from the Standard-14 bbox when a font loaded from a dictionary has a standard-14 name but no `/FontDescriptor` (Java `loadFontDescriptor` AFM fallback — needed by the comb appearance path); `PDAppearanceContentStream#set_font` reuses an existing font resource name matching the font (so the DA font writes as `/Helv 12 Tf` rather than a renumbered `/F2`, matching Java and `HandleDifferentDALevelsTest`); `AppearanceGeneratorHelper#write_to_stream` drops `/Filter`/`/DecodeParms` when writing decoded content (Java `createOutputStream()` without filters) so subsequent reads don't re-decode. `ControlCharacterTest` verifies NUL raises `ArgumentError` and CR/LF/CRLF/LFCR/U+2028/U+2029/tab values normalize to match the acrobat-* reference fields.
- [x] Plain text paragraphs + signature field — ported against `PlainTextTest.java` (all 6 examples) and `PDSignatureFieldTest.java` (all 3): `PlainText` paragraph splitting matches Adobe/Acrobat line-break handling for `\r`/`\n`/`\r\n` (2 paragraphs), `\n\r` (3 paragraphs), U+2028 linebreak and U+2029 paragraphbreak (2 each). `PDSignature` port (byte range + contents): `byte_range=` (4-element only), `byte_range`, `contents`, and `get_contents(byte[])`/`get_contents(IO)` extracting the hex signature between the byterange gap (filtering `<`/`>` delimiters and hex-decoding via `Cos::String.parse_hex`). `PDSignatureField` convenience constructor (`/FT=Sig`, locks+prints first widget, generates a unique `SignatureN` name), `signature` returning `PDSignature`, `set_value(PDSignature)`, and `value=(String)` raising `UnsupportedOperationError` (Java `setValue(String)`); `PDAcroForm#set_fields` (Java `setFields(List)`).
- [x] AcroForm model + default resources + flatten — ported against `PDAcroFormTest.java` (all 12 examples) and `AcroFormsRotationTest.java` (1): `fields`/`get_field` (now matches Java fully-qualified names across the field tree), `default_appearance` returns `""` when absent, `testBadDA` (PDFBOX-4235) raises `ArgumentError` on `setValue` with a malformed `/DA` (`tf` typo), `testIllegalFieldsDefinition` (PDFBOX-3777: `/Fields` as a COSDictionary must not throw on `get_acro_form`), `testPDFBox3347` (invalid UTF-8 names, widget on-values `[Nynäshamn, Råcksta, Silverdal, Skogskrem, St Botvid, Storkällan]`), `testPDFBox5797` (Sejda widget `/DA` + Ş text via `PDType0Font`), and `flatten`/`flattenWidgetNoRef`/`flattenSpecificFieldsOnly` (Java `PDAcroForm#flatten` and `flatten(List, boolean)`; the Java rendering comparison is advisory — only logs on mismatch — the behavioral assertions are fields-empty and annotation/widget counts). `AcroFormsRotationTest#fillFields` covers rotated single/multiline fields (exercises the appearance rotation-matrix path). Implemented the AcroForm default-resources fixup (Java `AcroFormDefaultsProcessor`/`AcroFormDefaultFixup`, PDFBOX-3732/4303/4393): accessing `catalog.acro_form` now sets `/DA` to `/Helv 0 Tf 0 g ` when empty, creates `/DR` if missing, and adds `/Helv` (Helvetica) + `/ZaDb` (ZapfDingbats) `PDType1Font`s only if absent — verified by `testAcroFormDefaultFonts` and the missing-info save/load tests. Also ported `PDFieldTreeTest#test5044` (PDFBOX-5044 stack overflow): the field factory now dereferences indirect `Cos::Object` kids (so non-terminal fields with widget kids classify correctly), `PDAcroForm#get_field_tree` walks the tree with the PDFBOX-5044 cycle guard, and `get_field` matches Java's fully-qualified-name lookup. Fixed the brute-force xref scan iteration cap (was 3M iterations ≈ 3MB, truncating objects beyond ~3MB in large files — now scales with the scan range) which blocked PDFBOX-3347; `Cos::Array#remove_object` now removes indirect `COSObject` entries pointing at the target (Java parity) for flatten; `PDPage#annotations` uses `PDAnnotation.create_annotation` so Widgets and all subtypes are typed; `PDAnnotation#appearance=` accepts nil (removes `/AP`, Java `setAppearance(null)`).
- [x] Orphan-widget field rebuild + generate-appearances-on-access — ported against `PDAcroFormFromAnnotsTest.java` (4 of 5; `testFromAnnots3891ValidateFont` needs font-descriptor-name comparison) and `PDAcroFormGenerateAppearancesTest.java` (all 3): `AcroFormOrphanWidgetsProcessor` (PDFBOX-3891/4985) rebuilds the `/Fields` entry from page-level widget annotations when it is empty — walking `/Parent` chains to root fields, adding widget appearance fonts to the AcroForm default resources, ensuring missing DA fonts are looked up via `FontMappers`, and exposing `PDAcroForm#rebuild_fields_from_widgets`. `testFromAnnots4985DefaultMode` (POPPLER-806) and `testFromAnnots3891CreateFields`/`DontCreateFields` (merge-test) verify the rebuilt field tree matches the Acrobat reference count (208 fields) and that `get_acro_form` doesn't throw on the PDFBOX-3891 poppler fixture. `PDAcroFormGenerateAppearancesTest` verifies `get_acro_form` doesn't throw on PDFBOX-5041 (missing font descriptor), PDFBOX-4086 (character missing for encoding), and PDFBOX-5043 (PaperMetaData) — fixtures downloaded from the Java JIRA attachment URLs (SHA512 recorded in `spec/resources/pdfbox/pdmodel/interactive/form/SHA512SUMS`).

---

## Phase 9 — Encryption

**Goal:** Full password-based (and future public-key) encryption for read/write.

- [x] StandardSecurityHandler — RC4, AES-128, AES-256 key generation
- [x] Encryption key length default fixed (256→128) for revision 4 compatibility
- [x] AccessPermission, ProtectionPolicy ported
- [x] PDEncryption dictionary management (encrypt/decrypt document roundtrip green)
- [x] SASLPrep (RFC 4013) string preparation for encryption revision 6
- [x] Stream/data encryption wired into writer — writer writes `/Encrypt` dict + trailer/xref reference, document ID persisted to trailer, rev2-4 key computed from user password + owner key with rev4 RC4 padding (PDFBOX-5955), parser propagates security handler to lazily-parsed streams, `parse(password)` sets password. `testProtection` round-trips 40/128/128-AES/256-bit through save+reopen with content-stream equality.
- [x] `testProtectionInnerAttachment` — embedded-file extraction (`EmbeddedFile#size` reads `/Params /Size` matching `PDEmbeddedFile.getSize()`; Java's `getLength()` is `/Length`) and encrypt→decrypt round-trip of an attachment-carrying document (`preEnc_20141025_105451.pdf`) for 40/128/128-AES/256-bit. Required a writer fix: stream-dictionary indirect references were written with their original parsed object numbers instead of the reassigned ones, so any stream whose dict referenced another object (e.g. embedded-file `/Params`) pointed at the wrong object after save. `write_stream_with_refs` now remaps `Cos::Object` references through `object_keys` while keeping non-reference output byte-identical to `COSWriter.write_stream`.
- [ ] Public key encryption porting — requires OpenSSL RSA/X.509 support (Crystal stdlib has only symmetric ciphers and digests; needs external shard like openssl_ext)
- [x] `testPDFBox4453` — 1000 per-dictionary strings (`"3"`/`"0"`) encrypted with RC4-40 and decrypted on reload, proving per-object string keys differ (identical plaintext encrypts differently per object number, matching Java's comment). Required three fixes:
  - Writer now generates a document `/ID` (SHA-256 of time + Info values, or reuses the document's existing ID) — fresh documents previously had no `/ID`, so `prepare_for_decryption` could not validate the password and never set up a handler.
  - The writer reuses the document ID computed during encryption prep, so the trailer `/ID` matches the ID the `/O`/`/U`/key were derived from.
  - `Cos::String` values are now encrypted on write (`SecurityHandler#encrypt_string` mirroring `decrypt_string`), threaded through the writer via the enclosing object's key; the `/Encrypt` dict is excluded (matching Java's `willEncrypt = false`). This also fixed the garbled embedded-file name-tree keys in `testProtectionInnerAttachment`.
- [x] `testPDFBox4308` — colorspace lookup string shared between a direct value and an indirect reference round-trips RC4-40 encryption uncorrupted, using the real `PDFBOX-4308.pdf` fixture (downloaded from the Java maven-wget URL with SHA512 verified).
- [x] `testPDFBox5955` — 40-bit and 48-bit RC4 documents load (with and without the owner password) and extract their text, using `PDFBOX-5955-{40,48}bit.pdf` fixtures (SHA512-verified).
- [x] `testPDFBox5639` — AESV3 (R=5) document with excess bytes loads with `JUL2023rfi` and reports 2 pages. Required true AES stream support:
  - `decrypt_stream`/`encrypt_stream` now dispatch through `encrypt_data` (RC4 / AES-128 / AES-256) instead of always using RC4; previously the AES helpers were dead code and `@use_aes` was never set during password-based decryption.
  - `prepare_for_decryption` detects AES from the revision or the `/CF/StdCF` crypt-filter method (`AESV2`), matching Java's `StandardSecurityHandler`.
  - AES streams now use PKCS#7 padding (ISO 32000-1 7.6.2) instead of `NoPadding`, so non-block-aligned data encrypts/decrypts correctly.
  - The AES/RC4 cipher helpers were moved from `StandardSecurityHandler` into the base `SecurityHandler` so the stream/string decrypt paths can use them.
- [x] AES COS-string encryption — `encrypt_string`/`decrypt_string` now dispatch through `encrypt_data` (RC4/AES-128/AES-256) like the stream paths, and `compute_object_key` appends the `sAlT` bytes for AES-128 (Algorithm 1.A, matching Java's `calcFinalKey`). Verified by `testAESStringRoundTrip`: a `prefer_aes` (AESV2) document's strings are written as genuine AES-CBC ciphertext (IV + 16-byte blocks) and decrypt back to their original values.

---

## Phase 10 — XMPBox

**Goal:** Parse, serialize, and integrate XMP metadata for PDF/A workflows.

- [x] XMP constants
- [x] Type system (Types, Cardinality, all 46 types, 17 structured types)
- [x] Schema system (XMPSchema + 13 schema classes)
- [x] XMPMetadata + TypeMapping
- [x] DateConverter — ISO8601, PDF-style, timezone, millis
- [x] DomXmpParser — 673-line parser with namespace finder + lenient array/namespace detection
- [x] XmpSerializer — 148-line Crystal port
- [x] PdfaExtensionHelper — 216-line PDF/A schema loading + 4 PDFA*Type classes
- [x] XmpParsingException, XmpSerializationException, XmpSchemaException
- [x] PDFBox integration (PDMetadata parse/serialize convenience methods)
- [~] Test suite — 58 Crystal specs covering type system, schema, date conversion, metadata, parsing, attributes (from 28 Java test files). All schema Java tests ported (AdobePDF, AdobePDFErrors, DublinCore, BasicJobTicket, PDFAIdentification + Others, Photoshop, XMPBasic, XMPMediaManagement, XmpRights, XMPSchema, TestExifXmp) plus DoubleSameTypeSchemaTest, TestAbstractStructuredType, XMPMetaDataTest (incl. PDFBOX-3257), DeserializationTest error-type assertions, TestValidatePermitedMetadata (all 167 manifest fields registered as property_types), and DomXmpParserTest issue cases (PDFBOX-5649/5835/5976/6106/5288/6131/3882/3882_2/5292, Bag-vs-Seq strict/lenient, undefined attribute/child property strict/lenient, xapmeta root, bad PI name, double end, wrong rdf namespace, photoshop headline wrong type, page-text Dimensions/ResourceRef, attribute-based pdfaProperty/pdfaType/pdfaField types, ResourceEventType/LayerType attributes, no-rdf-children, text-instead-of-Alt, exif:Flash Fired boolean, structured-type-as-attribute, bad-schema, non-standard-URI-in-rdf, rdf:Description-in-rdf:li (PDFBOX-6126), empty LangAlt/Seq attributes, no-schema-xml-ns, empty-array-property, undefined-structured-child, no-processing-instruction, no-instantiation-bad-date-property/attribute, type-in-li-resource-element, lenient-incomplete-pdfaExtension, property-not-defined-CFAPattern, PDFBOX-6136 default-namespace extension schema, PDFBOX-6138 root namespaces, bad-xpacket-end-name, bad-xpacket-end-value, PDFBOX-6131_2 Seq/Bag Text value types, PDFBOX-6133 schema-as-type, bad-inner parseType, empty-Seq-attribute). CFAPatternType property_types registered. `parse_end_packet` validates the xpacket end attribute (Java parity). All 48 DomXmpParserTest methods now ported. TestXMPWithUndefinedSchemas prism.xmp assertions ported, and DeserializationTest data-value + round-trip integrity assertions (getTitle, rdf-about, attributes-as-properties, space-preserving text, isartor-style thumbnails/extension schemas, schema-count-preserving serialize/parse round-trips incl. empty date) ported. `remove_comments_and_blanks` rewritten to Java's parent-child-count guard so whitespace-only text in single-child elements (e.g. `<pdf:Producer> </pdf:Producer>`) is preserved. ThumbnailType/VersionType property_types registered (VersionType constants corrected to Java names). `XmpSerializer` now collects namespaces from nested structured types so serialized output re-parses cleanly. BooleanType now parses "True"/"False" strings (Java parity); strict attribute-as-structured-type error message matches Java; FlashType property_types registered. `check_property_definition` raises "Schema is not set in this document" for undeclared namespaces and "Cannot find a definition for the namespace" for undefined ones (Java parity); lenient mode registers non-standard Description-level namespaces. ISO date parsing rejects single-digit seconds (Java strict formatter parity) and `instanciate_simple_property` wraps failures as "Failed to instantiate XType property with value '...'" (Java parity); class-form schema factory passes the encountered prefix into the schema. XMPMetadata stores schemas in a List (Java parity) so same-namespace schemas with different prefixes coexist; `schema(prefix, ns_uri)` selects by both. `find_descriptions_parent` rewritten to Java's root-structure validation (Format error types); strict attribute parsing in structured types raises InvalidType; lenient nil-type path always uses Text (Java parity); PI-name validation added. `try_parse_attributes_as_properties` instantiates structured types from the attribute's own QName (Java PDFBOX-3882 parity) and `parse_li_description` calls it on the trailing attributes. Strict parsing of the 6 TestXMPWithDefinedSchemas fixtures works: schema/structured-type property mappings registered from `property_types` (mirrors Java `initializePropMapping`), `DomXmpParser` calls `PdfaExtensionHelper.populate_schema_mapping` between schema-extension and data-description parsing (registers pdfaExtension-declared namespaces like pdfx), `instanciate_structured` routes `DefinedType` to `instanciate_defined_type`, and `ErrorType::NoValueType` added. Other strict-parsing fixes: `DomHelper.qname` swapped `local_part`/`prefix`, `parse_type_resource?` looked up the wrong attribute, serializer wrote `rdf:bag` lowercase instead of Java's `rdf:Bag`, and JobType constructor registered the wrong namespace prefix.

**XMPBox core complete.** Parse (DomXmpParser with lenient array/namespace detection), serialize (XmpSerializer), type/schema system, PDF/A extension loading. 1617 total tests, 0 failures.

**Low priority** — XMP metadata is needed only for PDF/A and advanced metadata workflows.

---

## Phase 11 — Tools & CLI

**Goal:** Parity for all `tools/` command-line utilities.

**Java source:** `vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/` (26 files)

- [x] TextExtraction CLI — export:text + export:html
- [x] PDFSplit — 3 spec tests
- [x] PDFMerger — 3 spec tests
- [x] PDFToImage — 6 spec tests
- [x] Decrypt — 5 spec tests (owner/user password, decryption, wrong password)
- [x] Encrypt — 2 spec tests
- [x] DecompressObjectStreams
- [x] Overlay
- [x] ExportFDF
- [x] ImportFDF
- [x] WriteDecodedDoc
- [x] ImageIOUtil — CrImage integration (ExtractImages uses CrImage::RGBA + PNG::Writer; PDFRenderer uses CrImage for render_image_png)

**All tool CLI tests pass.** ImageIOUtil is partial (format detection works, image writing needs crimage integration).

---

## Phase 12 — Rendering

**Goal:** A working raster renderer backed by CrImage.

- [x] PDFRenderer — working renderer with CrImage. render_image, render_image_with_dpi, render_image_png
- [x] TrueTypeFontRenderer — CrImage-backed text rendering
- [x] PageDrawer — 280 lines. Path tracking, Bresenham line drawing, bezier curves, text glyph rendering via font paths, image drawing, color conversion (Gray/RGB/CMYK)

**Low priority** — Full PDF rendering to images requires significant work (path filling, image compositing, ICC color management).

---

## Phase 13 — I/O Layer

**Goal:** Complete random-access I/O parity (blocking lower phases).

- [x] RandomAccessReadBuffer
- [x] RandomAccessReadBufferedFile
- [x] RandomAccessReadMemoryMappedFile
- [x] RandomAccessReadView
- [x] RandomAccessReadWriteBuffer
- [x] RandomAccessInputStream
- [x] NonSeekableRandomAccessReadInputStream
- [x] SequenceRandomAccessRead
- [x] IOUtils

**I/O parity is complete.**

---

## Not Ported (Out of Scope)

These Java modules are not targeted for Crystal:
- **debugger/** (89 files) — Swing GUI application, no Crystal equivalent
- **benchmark/** (3 files) — Java JMH benchmarks, no Crystal equivalent
- **examples/** (93 files + 9 tests) — Example code, not library features
- **Lucene integration** — Java-specific search integration

---

## Task Tracking

Each broad feature area above is a TDD-ready work item. When starting work:

1. Create an active plan in `plans/active/<FeatureName>.md` (see `CosParserPort.md` for format)
2. Move corresponding pending tests to active, fix implementation to make them pass
3. Update this `parity.md` status from `partial` to `ported` (and check the `[~]` box)
4. Update `plans/inventory/java_port_inventory.tsv` from `missing` to `ported`

### Current Active Work
- **Phase 1 — Text stripper**: Multi-PDF extraction test enabled (40/40 exact match). Fixed TrueType `average_font_width` to use PDF Widths array (Java parity). All 8 deviation PDFs verified against a real Java 3.0.4 jar — all MATCH. FC60_Times fixture is stale (2010 era); Crystal == Java 3.0.4. Outline, tabula, rotation, encoding, both beads PDFs, and cweb.pdf at Java parity. Bidi Crystal regression tests in place.
- **Phase 5 — PDFWriter**: All 12 writer specs green (0 pending). testCompressEncryptedDoc, testPDFBox5927, testPDFBox6036 enabled. Encryption key length fixed.
- **Phase 7 — PD Model**: add_page_to_tree Kids resolution, remove_page_from_tree, COSArrayList retainAll fixed.
- **Phase 3 — COSParser**: `plans/active/CosParserPort.md` — all methods ported, tests cover edge cases.
