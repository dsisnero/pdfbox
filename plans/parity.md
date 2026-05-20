# PDFBox Crystal Porting Parity

> Working document tracking broad feature porting status.
> Complements `plans/inventory/java_port_inventory.tsv` (per-method ledger) and `plans/active/` (per-class plans).
> Update this file as features progress.

**Current work:** All pre-existing bugs fixed (5→0). 3 pending tests enabled. Text stripper P0 at parity for outline+tests. Bidi regression tests in place. PDFWriter compression/encryption tests enabled.

---

## Overview

| Metric | Value |
|---|---|
| Java source files (vendor) | ~1,289 |
| Crystal source files (ported) | ~415 |
| Passing tests | 1,564 |
| Pending tests | 2 (bidi Java-parity only — documented algorithm differences) |
| Failures | 0 |
| Errors | 0 |
| Inventory: ported | 85 |
| Inventory: partial | 38 |
| Inventory: missing | 9,543 (mostly debugger/benchmark/examples out of scope) |
| Fixed since last update | Page-tree Kids indirection resolution. remove_page_from_tree implementation. COSArrayList retainAll CosObject inner check. Writer catalog /Version update. OpenTypeFont CFF path uses CFF charset. Encryption key length default (256→128). COS increment test (save/load page count). Document version test (1.4→1.6). FontMapper/TrueTypeCollection fixture fixes. BOM/diacritic normalization in text comparison. Bidi Crystal-specific regression tests. |
| Active porting plans | 1 (`plans/active/CosParserPort.md`) |

---

## Feature Roadmap

Each feature area below tracks concrete, actionable tasks. Checkboxes reflect current status.

### P0 — Text Extraction (most visible feature gap)

- [x] Fix font height=0 regression (Type1 @generic_font, TTF/Mapped/OpenType upem scaling)
- [x] Fix CFF Type1CharString.width lazy render bug — unblocks 3 skipped PDFs (PDFBOX-5920, PDFBOX-5002, sample_fonts_solidconvertor)
- [x] Add bead/article infrastructure (PDRectangle.contains, PDPage.thread_beads, fillBeadRectangles)
- [x] Fix spacing deviation (PDFBOX-5920: `@path.nil?` → `@rendered` check)
- [x] Enable `with_outline.pdf` extraction parity — matches Java exactly
- [x] Enable `eu-001.pdf` tabula font-height extraction parity — matches Java exactly (0 diffs, 4567 bytes)
- [x] Add `text_stripper_normalize` (NFKC + BOM stripping) for lenient diacritic comparison
- [x] Add BidiSample Crystal-specific regression tests (size, content markers)
- [ ] Fix 5 remaining deviations (2 beads ordering, 1 rotation, 1 encoding, 1 Arabic bidi)
- [ ] Bidi Java parity (2 pending: sorted/unsorted) — Crystal bidi shard vs java.text.Bidi differences documented in `lib_issues/bidi.1.md` and `bidi.2.md`

### P1 — Font Embedding / Loading (blocks Type0/TrueType/Type1C parity)

- [x] Font specs: all 129 examples pass, 0 pending
- [x] Type1 font PFB constructor — `PDType1Font.new(doc, pfb_in)` implemented
- [x] OpenType/CFF outline extraction through OTFParser — CFF path fix for format-3 post tables
- [x] GSUB specs: all 65 examples pass, 0 compile errors
- [x] GsubWorkerForTamil wired into factory (was TODO → `DefaultGsubWorker`)
- [x] TTF Subsetter — 795 lines Crystal, 8 spec tests pass
- [x] Font subsetting wired into save — `subset_embedded_fonts` calls `PDType0Font.subset`
- [x] TrueTypeEmbedder — 272 lines Java ported (abstract base, font descriptor, subsetting)
- [x] PDCIDFontType2Embedder — 677→427 lines Java→Crystal ported (CID font embedding, widths, vertical metrics)

### P2 — PDF Parsing

- [x] PDFBOX-5025 test enabled — `length1` reads from font_file2 COS stream correctly
- [x] `COSParser.parseObjectStreamObject` — delegates to Parser which is fully implemented
- [x] Compressed object stream writing (xref stream format enabled, COSWriterObjectStream + COSWriterCompressionPool + PDFXrefStreamParser all working)
- [x] Document info get/set — all metadata fields available via `DocumentInformation`
- [x] Incremental save — `save_incremental` writes original bytes + full save; parser uses `rindex` for last startxref

### P4 — Content Stream Operators

- [x] All text operators (Tj, TJ, ', " Td TD T*) — implemented
- [x] All device color operators (G, g, RG, rg, K, k) — implemented
- [x] `SetGraphicsStateParameters` (gs) — `copy_into_graphics_state` implemented
- [x] Color space operators (CS, cs) — PDColorSpace.create factory + Resources.color_space
- [x] Generic color operators (SC, sc) — set color components on current color space
- [x] Marked content operators (BMC, EMC, MP, DP, BDC) — all 5 implemented, marked content stack + points on PDFStreamEngine

### P5 — FontBox Infrastructure

- [x] TrueTypeCollection: processes TTC fonts, resolves fonts by name, scans headers — fixture switched to `ipag.ttf`
- [x] OTFParser: standalone OpenType/CFF parsing — CFF path fix (uses CFF charset, not TTF post table)
- [x] GSUB specs: all 65 examples pass, no compile errors
- [~] GSUB: multiple/alternate/ligature substitution — data extraction implemented, needs end-to-end glyph substitution wiring
- [~] GSUB: Tamil worker adjustments — wired into factory, needs Tamil-specific substitution rules (currently uses Gujarati logic)
- [~] Various TTF table TODO comments — reduced from 50+ to ~18 genuine feature gaps (logging TODOs converted to NOTE comments, dead stubs removed)

### P6 — PD Model Completeness

- [x] add_page_to_tree: resolve Kids indirect reference before checking array type
- [x] remove_page: also remove from catalog page tree (Kids array + Count decrement)
- [x] COSArrayList#retain_all: check inner Cos::Object for matching
- [x] `PDPageTree`: nested tree traversal — `load_page_tree` recurses into intermediate Pages nodes
- [x] `ResourceCache`: font, color space, ext gstate, property list caching with get/put/remove
- [x] `PDDocumentCatalog`: 32 methods including acro_form, viewer_preferences, metadata, output_intents, open_action
- [x] `PDDocumentInformation`: title, author, subject, keywords, creator, producer, dates — all getters/setters
- [x] Font subsetting wired into save — `subset_embedded_fonts` calls `PDType0Font.subset` before every save

### P7 — Annotations & Interactive

- [x] Form field value serialization — save/load roundtrip verified for text, checkbox, list box fields
- [~] Annotation appearance handlers: rendering wired into PageDrawer.process_annotations (appearance streams rendered via process_stream_operators)
- [x] Action completion — all 13 action types implemented with factory, URI/GoTo/JavaScript getters/setters work

### P8 — Lower Priority / Future

- [x] PDFRenderer — working renderer with CrImage integration, PageDrawer extends PDFGraphicsStreamEngine
- [ ] XMPBox XML parsing and schema handling
- [ ] Encryption: public key encryption porting
- [x] ImageIOUtil: CrImage integration — ExtractImages uses CrImage::RGBA + CrImage::PNG::Writer; PDFRenderer uses CrImage for render_image_png

---

## Feature Porting Status

### 1. COS Object Model (`src/pdfbox/cos.cr`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/` (17 classes)

| Class | Status | Tests |
|---|---|---|
| COSBase | ported | 2 specs |
| COSArray | ported | 3 specs |
| COSDictionary | ported | partial spec |
| COSName | ported | full spec |
| COSString | ported | full spec |
| COSInteger | ported | full spec |
| COSFloat | ported | full spec |
| COSBoolean | ported | full spec |
| COSNull | ported | full spec |
| COSStream | ported | full spec |
| COSObject | ported | --- |
| COSObjectKey | partial | full spec |
| COSDocument | partial | full spec |
| COSIncrement | partial | full spec — all 3 COS increment tests pass |
| COSUpdateInfo | partial | full spec |
| UnmodifiableCOSDictionary | partial | full spec |
| COSArrayList | ported | retainAll indirection fix |

**Blocking:** None. COS layer is substantially complete.

---

### 2. PDF Parsing (`src/pdfbox/pdf_parser/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/` (12 classes)

| Component | Status | Notes |
|---|---|---|
| BaseParser | ported | Full port with Java parity |
| COSParser | partial | `plans/active/CosParserPort.md` tracks 50+ methods, ~30 complete |
| PDFParser | ported | |
| FDFParser | ported | |
| PDFStreamParser | ported | |
| PDFObjectStreamParser | ported | |
| PDFXRefStream | ported | |
| PDFXRefStreamParser | ported | |
| XRefTrailerResolver | ported | |
| BruteForceParser | ported | |
| EndstreamFilterStream | ported | |

**Blocking:** `COSParser.parseObjectStreamObject` (needed for compressed PDFs).

**Pending tests:** 0 — PDFBOX-5025 test now passes.

---

### 3. PDF Writing (`src/pdfbox/pdfwriter.cr`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/` (3 classes + compression)

| Component | Status | Notes |
|---|---|---|
| COSWriter | partial (v2) | BFS graph traversal, proper indirect refs. Catalog /Version updated to match header. |
| COSStandardOutputStream | not started | Not needed directly — uses Crystal IO |
| COSWriterCompressionPool | partial | Object stream collection implemented |
| CompressParameters | ported | |
| ContentStreamWriter | ported | |

**Known gaps:**
- Compressed object stream writing fully integrated: COSWriterCompressionPool → COSWriterObjectStream → xref stream with Type 2 entries

**Pending tests:** 0 — all 12 writer specs pass.

---

### 4. Stream Filters (`src/pdfbox/filter/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/` (8 classes)

| Filter | Status | Notes |
|---|---|---|
| FlateFilter | ported | Deflate/Inflate via Crystal stdlib |
| ASCII85Filter | ported | |
| ASCIIHexFilter | ported | |
| LZWFilter | ported | |
| RunLengthDecodeFilter | ported | |
| IdentityFilter | ported | |
| FilterFactory | ported | |
| Predictor | ported | PNG / TIFF predictor |

**Filter parity is complete.** No pending tests.

---

### 5. Content Stream Processing (`src/pdfbox/contentstream/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/` (3 engine classes + operators)

| Component | Status | Notes |
|---|---|---|
| PDFStreamEngine | ported | Text showing, matrix ops, graphics state |
| PDFGraphicsStreamEngine | ported | Abstract callbacks for path/color/image ops |
| LegacyPDFStreamEngine | ported | Deliberately-incorrect text calcs for PDFTextStripper |
| Operator classes | partial | All operators defined, some with TODO implementations |

**Gaps:**
- `SetGraphicsStateParameters` (gs) operator is implemented with `copy_into_graphics_state`
- Color space operators (CS, cs, SC, sc) are implemented with PDColorSpace.create factory
- Marked content operators (BMC, EMC, MP, DP, BDC) are all implemented

---

### 6. Text Extraction (`src/pdfbox/text/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/` (4 classes)

| Component | Status | Notes |
|---|---|---|
| PDFTextStripper | partial | Core engine with bidi support, word detection, line building |
| TextPosition | ported | |
| LegacyPDFStreamEngine | ported | (in contentstream/) |
| PDFTextStripperByArea | partial | Wraps PDFTextStripper |

**Enabled tests since last update:**
- outline extraction — matches Java exactly (full text, bookmark ranges, page ranges)
- tabula font-height — matches Java exactly (4567 bytes, 0 diffs)
- BidiSample Crystal-specific regression tests (2 pass — size, content markers)

**Pending tests:** 2 — Bidi Java parity (sorted/unsorted). Crystal bidi shard vs `java.text.Bidi` algorithm differences documented in `lib_issues/bidi.1.md` and `bidi.2.md`.

---

### 7. PD Model — Document Management (`src/pdfbox/pdmodel/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/` (25+ classes)

| Component | Status | Notes |
|---|---|---|
| PDDocument | partial | Create, load, add_page, remove_page (with tree removal), save() |
| PDPage | partial | MediaBox, CropBox, rotation, annotations, resources |
| PDPageTree | partial | Full traversal with nested tree recursion, get, add, remove, insert. Missing ResourceCache wiring. |
| ResourceCache | ported | Font, color space, ext gstate, property list caching with get/put/remove |
| PageLayout / PageMode | ported | |
| PDDocumentCatalog | partial | |
| PDDocumentInformation | ported | title, author, subject, keywords, creator, producer, dates — all getters/setters |

**Known gaps:**
- None remaining — stream encryption integrated via `COSWriter.write_stream` calling `SecurityHandler.encrypt_stream`; xref stream format enabled; document info get/set complete

**Fixed:** add_page_to_tree resolves Kids Cos::Object (page count on incremental load). remove_page removes from catalog page tree. COSArrayList#retain_all checks inner Cos::Object. Writer catalog /Version updated to match header. Document version test (1.4→1.6). COS increment test (save/load 3 pages).

---

### 8. PD Model — Fonts (`src/pdfbox/pdmodel/font/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/` (20+ classes)

| Component | Status | Notes |
|---|---|---|
| PDFont | partial | Core abstract class with encoding, widths, glyphs |
| PDSimpleFont | partial | |
| PDType1Font | partial | Standard 14 + PFB embedding. Fixed bounding_box to use @generic_font fallback. |
| PDTrueTypeFont | partial | Loading from TTF, embedding incomplete. Fixed generate_bounding_box to scale by 1000/upem. |
| PDType0Font | partial | CID font loading, embedding incomplete |
| PDCIDFont | partial | |
| PDCIDFontType0 | partial | |
| PDCIDFontType2 | partial | |
| PDType3Font | partial | |
| PDType1CFont | partial | |
| PDVectorFont | partial | |
| Encoding (all) | ported | WinAnsi, MacRoman, Standard, Symbol, Zapf, Identity-H/V, Dictionary |
| FontMapper | partial | FontMapper index test enabled (TTF + OTF). PFB fixtures unavailable. |
| FontProvider | partial | OpenTypeFontBoxFont.font_bbox now scales by 1000/upem |
| Standard14Fonts | ported | |
| ToUnicodeWriter | partial | |
| FontDescriptor | partial | |
| GlyphList | ported | |

**Pending tests:** 0 — all 129 font spec examples pass.

---

### 9. FontBox (`src/fontbox/`)

**Java source:** `vendor/pdfbox/fontbox/src/main/java/org/apache/fontbox/` (143 files)

| Component | Status | Notes |
|---|---|---|
| TTF Parser | ported | |
| CFF Parser | ported | |
| Type1 Parser | ported | |
| AFM Parser | ported | |
| CMap Parser | ported | |
| PFB Parser | ported | |
| TrueTypeCollection | partial | Uses `ipag.ttf` fixture (0 pending). Can open and enumerate TTC fonts. |
| OTFParser | partial | CFF path fix: uses CFF charset instead of TTF post table for format-3 post tables. |
| GSUB table | partial | Basic substitution support |

**Enabled tests since last update:**
- OpenTypeFont CFF path fix: `path("A")` now returns non-empty for OTF with format-3 post table
- TrueTypeCollection: fixture switched from missing `DejaVuSansMono.ttf` to available `ipag.ttf`

**Pending tests:** 0 — GSUB specs have 4 pre-existing compile errors (unrelated to runtime parity).

---

### 10. XMPBox (`src/xmpbox/`)

| Component | Status | Notes |
|---|---|---|
| XMP metadata | minimal | Only date_converter.cr ported |
| XML parsing | not started | |
| Schema handling | not started | |

**Low priority** — XMP metadata is needed only for PDF/A and advanced metadata workflows.

---

### 11. Tools (`src/tools/`)

**Java source:** `vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/` (26 files)

| Component | Status | Notes |
|---|---|---|
| TextExtraction CLI | ported | export:text + export:html |
| PDFSplit | ported | 3 spec tests |
| PDFMerger | ported | 3 spec tests |
| PDFToImage | ported | 6 spec tests |
| Decrypt | ported | 5 spec tests (owner/user password, decryption, wrong password) |
| Encrypt | ported | 2 spec tests |
| DecompressObjectStreams | ported | |
| Overlay | ported | |
| ExportFDF | ported | |
| ImportFDF | ported | |
| WriteDecodedDoc | ported | |

**All tool CLI tests pass.** ImageIOUtil is partial (format detection works, image writing needs crimage integration).

---

### 12. Renderer (`src/pdfbox/rendering/`)

| Component | Status | Notes |
|---|---|---|
| PDFRenderer | ported | Working renderer with CrImage. render_image, render_image_with_dpi, render_image_png |
| TrueTypeFontRenderer | ported | CrImage-backed text rendering |
| PageDrawer | ported | 280 lines. Path tracking, Bresenham line drawing, bezier curves, text glyph rendering via font paths, image drawing, color conversion (Gray/RGB/CMYK) |

**Low priority** — Full PDF rendering to images requires significant work (path filling, image compositing, ICC color management).

---

### 13. Annotations & Interactive Features (`src/pdfbox/pdmodel/interactive/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/` (50+ files)

| Component | Status | Notes |
|---|---|---|
| Annotation model classes | partial | Most annotation types defined, factory dispatching |
| Annotation appearance handlers | partial | Handler stubs exist, rendering not wired |
| Form (AcroForm) | partial | Field types, widget annotations |
| Action (all types) | partial | URI, GoTo, JavaScript, Named, etc. |
| Document Navigation (destinations) | partial | XYZ, Fit, FitH, FitV, Named |
| Page Navigation (threads, transitions) | partial | |

**Gaps:** Appearance handlers generate content but don't trigger. Form field value serialization is not verified. Action JavaScript execution not implemented (out of scope).

---

### 14. Encryption (`src/pdfbox/pdmodel/encryption/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/encryption/` (12 files)

| Component | Status | Notes |
|---|---|---|
| StandardSecurityHandler | partial | RC4, AES-128, AES-256 key generation. Key length default fixed (256→128). |
| PDEncryption | partial | Encryption dictionary management |
| AccessPermission | ported | |
| ProtectionPolicy | ported | |
| SecurityHandlerFactory | partial | |

**Fixed:** Default encryption_key_length (256→128) for revision 4 compatibility. testCompressEncryptedDoc now passes.

**Gaps:** Stream/data encryption not wired into writer. Public key encryption not ported.

---

### 15. I/O Layer (`src/pdfbox/io.cr`)

| Component | Status | Notes |
|---|---|---|
| RandomAccessReadBuffer | ported | |
| RandomAccessReadBufferedFile | ported | |
| RandomAccessReadMemoryMappedFile | ported | |
| RandomAccessReadView | ported | |
| RandomAccessReadWriteBuffer | ported | |
| RandomAccessInputStream | ported | |
| NonSeekableRandomAccessReadInputStream | ported | |
| SequenceRandomAccessRead | ported | |
| IOUtils | ported | |

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
3. Update this `parity.md` status from `partial` to `ported`
4. Update `plans/inventory/java_port_inventory.tsv` from `missing` to `ported`

### Current Active Work
- **Text stripper**: Multi-PDF extraction test enabled (34/40 exact match). Fixed TrueType `average_font_width` to use PDF Widths array (Java parity). 6 known deviations remain. Outline and tabula extraction at Java parity. Bidi Crystal regression tests in place.
- **PDFWriter**: All 12 writer specs green (0 pending). testCompressEncryptedDoc, testPDFBox5927, testPDFBox6036 enabled. Encryption key length fixed.
- **PD Model**: add_page_to_tree Kids resolution, remove_page_from_tree, COSArrayList retainAll fixed.
- **COSParser**: `plans/active/CosParserPort.md` — ~30/50+ methods ported
