# PDFBox Crystal Porting Parity

> Working document tracking broad feature porting status.
> Complements `plans/inventory/java_port_inventory.tsv` (per-method ledger) and `plans/active/` (per-class plans).
> Update this file as features progress.

**Current work:** Text stripper P0 parity. Fixed `Type1CharString.width` lazy render bug (`@path.nil?` → `@rendered` check) — CFF fonts now compute correct glyph widths. Re-enabled 3 previously skipped PDFs (PDFBOX-5920, PDFBOX-5002, sample_fonts_solidconvertor). 5 deviation categories remain.

---

## Overview

| Metric | Value |
|---|---|
| Java source files (vendor) | ~1,289 |
| Crystal source files (ported) | ~415 |
| Passing tests | 1,548 |
| Pending tests | 23 (5 fixture-dependent, 5 feature-gap, 5 text-stripper, 3 writer, 2 bidi, 3 font) |
| Inventory: ported | 85 |
| Inventory: partial | 38 |
| Inventory: missing | 9,543 (mostly debugger/benchmark/examples out of scope) |
| Fixed since last update | Page-tree reconstruction, Names dict indirection, AcroForm Fields indirection. Font height computation (Type1 @generic_font, TTF/Mapped/OpenTypeFontBoxFont upem scaling). Bead/article infrastructure. CFF Type1CharString.width fix (lazy render). Spacing deviation FIXED (3 PDFs re-enabled). |
| Active porting plans | 1 (`plans/active/CosParserPort.md`) |

---

## Feature Roadmap

Each feature area below tracks concrete, actionable tasks. Checkboxes reflect current status.

### P0 — Text Extraction (most visible feature gap)

- [x] Fix font height=0 regression (Type1 @generic_font, TTF/Mapped/OpenType upem scaling)
- [x] Fix CFF Type1CharString.width lazy render bug — unblocks 3 skipped PDFs (PDFBOX-5920, PDFBOX-5002, sample_fonts_solidconvertor)
- [x] Add bead/article infrastructure (PDRectangle.contains, PDPage.thread_beads, fillBeadRectangles)
- [x] Fix spacing deviation (PDFBOX-5920: `@path.nil?` → `@rendered` check)
- [ ] Fix 5 remaining deviations (2 beads ordering, 1 rotation, 1 encoding, 1 Arabic bidi)
- [ ] Enable `with_outline.pdf` extraction parity — text positioning/line break differences
- [ ] Enable `eu-001.pdf` tabula font-height extraction parity — complex formatting
- [ ] Enable BidiSample extraction parity — bidi algorithm differences from Java

### P1 — Font Embedding / Loading (blocks Type0/TrueType/Type1C parity)

- [ ] PDType0Font embedder (`PDCIDFontType2Embedder`) — unblocks 2 pending tests (string width, space width)
- [ ] TrueType font embedding with subsetting — `TTFSubsetter` addGlyph/subsetTable
- [ ] Type1 font PFB constructor — fixture already conditional
- [ ] OpenType/CFF outline extraction through OTFParser — needs `FoglihtenNo07.otf` fixture
- [ ] Fix GSUB specs compile errors (4 pre-existing)

### P2 — PDF Parsing

- [ ] `COSParser.parseObjectStreamObject` — needed for compressed PDFs
- [ ] `COSParser.parseCOSStream` full verification (edge cases)
- [ ] `COSParser` encryption/security methods (`getEncryption`, `getAccessPermission`, `prepareDecryption`)
- [ ] `COSParser` xref/trailer parsing (`retrieveTrailer`, `parseFileObject`, `getObjectOffset`)
- [ ] `COSParser` remaining helper methods (`lastIndexOf`, `isString`, `readObjectMarker`, `readObjectNumber`, `readGenerationNumber`)
- [ ] Port Java COSParser tests for edge-case coverage
- [ ] PDFBOX-5025 test — needs fixture `PDFBox-5025.pdf`

### P3 — PDF Writing

- [ ] Compressed object stream writing (xref stream vs xref table) — unblocks `testPDFBox5927` and `testPDFBox6036`
- [ ] Stream/data encryption wired into writer — unblocks `testCompressEncryptedDoc`
- [ ] Document info writing (title, author, subject, keywords, creator, producer, dates)
- [ ] Incremental update / digital signature support

### P4 — Content Stream Operators

- [ ] `SetGraphicsStateParameters` (gs) — TODO stub, wire into graphics state
- [ ] Color space operators (CS, cs, SC, sc) — TODO stubs, integrate with color space resources
- [ ] Marked content operators (BMC, EMC, MP, DP) — TODO stubs
- [ ] `show_text_strings` (TJ) edge-case verification

### P5 — FontBox Infrastructure

- [ ] TrueTypeCollection: resolve fonts by name, scan headers — needs `DejaVuSansMono.ttf`
- [ ] OTFParser: standalone OpenType/CFF parsing — needs `FoglihtenNo07.otf`
- [ ] GSUB: multiple substitution, alternate substitution, ligature substitution
- [ ] GSUB: Tamil worker adjustments (copied from Gujarati, needs adjustment)
- [ ] Various TTF table TODO logging/warnings (50+ TODO comments)

### P6 — PD Model Completeness

- [ ] `PDPageTree`: nested tree traversal beyond one level of Kids
- [ ] `ResourceCache`: wire into PDPageTree iterator for page resources
- [ ] `PDDocumentCatalog`: complete document catalog methods
- [ ] `PDDocumentInformation`: complete metadata getters/setters
- [ ] Font subsetting wired into save path

### P7 — Annotations & Interactive

- [ ] Annotation appearance handlers: wire rendering triggers
- [ ] Form field value serialization verification
- [ ] Action completion (URI, GoTo, JavaScript stubs → working)

### P8 — Lower Priority / Future

- [ ] PDFRenderer / TrueTypeFontRenderer — path filling, image compositing, ICC color management
- [ ] XMPBox XML parsing and schema handling
- [ ] Encryption: public key encryption porting
- [ ] ImageIOUtil: crimage integration for image writing

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
| COSIncrement | partial | full spec |
| COSUpdateInfo | partial | full spec |
| UnmodifiableCOSDictionary | partial | full spec |

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

**Pending tests:** 1 (`test PDFBOX-5025` --- fixture PDFBox-5025.pdf not found)

---

### 3. PDF Writing (`src/pdfbox/pdfwriter.cr`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/` (3 classes + compression)

| Component | Status | Notes |
|---|---|---|
| COSWriter | partial (v2) | BFS graph traversal, proper indirect refs. Replaced flat hand-construction. |
| COSStandardOutputStream | not started | Not needed directly --- uses Crystal IO |
| COSWriterCompressionPool | partial | Object stream collection implemented |
| CompressParameters | ported | |
| ContentStreamWriter | ported | |

**Known gaps:**
- No compressed object stream writing (xref stream vs xref table)
- No incremental update / digital signature support
- No encryption writing
- Document info writing (title, author, subject, keywords, creator, producer, dates) not implemented

**Pending tests:** 3 --- `testCompressEncryptedDoc`, `testPDFBox5927`, `testPDFBox6036`

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
- `SetGraphicsStateParameters` (gs) operator is a TODO stub
- Color space operators (CS, cs, SC, sc) are TODO stubs
- Marked content operators (BMC, EMC, MP, DP) are TODO stubs

---

### 6. Text Extraction (`src/pdfbox/text/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/` (4 classes)

| Component | Status | Notes |
|---|---|---|
| PDFTextStripper | partial | Core engine with bidi support, word detection, line building |
| TextPosition | ported | |
| LegacyPDFStreamEngine | ported | (in contentstream/) |
| PDFTextStripperByArea | partial | Wraps PDFTextStripper |

**Pending tests:** 4
- `pdf_text_stripper_spec.cr` (2): outline extraction, tabula font-height behavior
- `bidi_text_stripper_spec.cr` (2): BidiSample sorted/unsorted --- bidi algorithm differences from Java

---

### 7. PD Model --- Document Management (`src/pdfbox/pdmodel/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/` (25+ classes)

| Component | Status | Notes |
|---|---|---|
| PDDocument | partial | Create, load, add_page work. save() delegates to Writer. |
| PDPage | partial | MediaBox, CropBox, rotation, annotations, resources |
| PDPageTree | partial | Full traversal, get, add, remove, insert. Missing ResourceCache wiring. |
| ResourceCache | partial | Placeholder class |
| PageLayout / PageMode | ported | |
| PDDocumentCatalog | partial | |
| PDDocumentInformation | partial | |

**Known gaps:**
- `ensure_pages_loaded` only reads one level of Kids (handles flat page trees only --- nested tree nodes not traversed)
- Missing `ResourceCache` for page resources (needed by PDPageTree iterator)
- Font subsetting not wired into save path
- Stream encryption not integrated

**Fixed:** Page-tree reconstruction (Cos::Object deref in Kids). AcroForm Fields array access after reload (Cos::Object deref in fields + kids iteration). Writer spec green.

---

### 8. PD Model --- Fonts (`src/pdfbox/pdmodel/font/`)

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
| FontMapper | partial | MappedFontBoxFont.font_bbox now scales by 1000/upem |
| FontProvider | partial | OpenTypeFontBoxFont.font_bbox now scales by 1000/upem |
| Standard14Fonts | ported | |
| ToUnicodeWriter | partial | |
| FontDescriptor | partial | |
| GlyphList | ported | |

**Pending tests:** 7 (fixture-dependent: 4 need `FoglihtenNo07.otf`, 3 need `LiberationSans-Regular.ttf`; 2 need embedder implementation)

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
| TrueTypeCollection | partial | Can open and enumerate TTC fonts |
| OTFParser | partial | Handles CFF-flavored OpenType |
| GSUB table | partial | Basic substitution support |

**Pending tests:** 3
- `parses standalone OpenType/CFF fonts through OTFParser` --- needs FoglihtenNo07.otf
- `processes TTC fonts, resolves fonts by name, and scans headers` --- needs DejaVuSansMono.ttf (Java build artifact)
- GSUB specs: 4 compile errors (pre-existing, unrelated to runtime parity)

---

### 10. XMPBox (`src/xmpbox/`)

**Java source:** `vendor/pdfbox/xmpbox/src/main/java/org/apache/xmpbox/` (73 files)

| Component | Status | Notes |
|---|---|---|
| XMP metadata | minimal | Only date_converter.cr ported |
| XML parsing | not started | |
| Schema handling | not started | |

**Low priority** --- XMP metadata is needed only for PDF/A and advanced metadata workflows.
Covered by 4 auto-generated porting specs.

---

### 11. Tools (`src/tools/`)

**Java source:** `vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/` (26 files)

| Component | Status | Notes |
|---|---|---|
| TextExtraction CLI | ported | |
| PDFSplit | ported | |
| PDFMerger | ported | |
| PDFToImage | ported | |
| Decrypt | ported | |
| Encrypt | ported | |
| DecompressObjectStreams | ported | |
| Overlay | ported | |
| ExportFDF | ported | |
| ImportFDF | ported | |
| WriteDecodedDoc | ported | |

Most tools are ported. ImageIOUtil is partial (format detection works, image writing needs crimage integration).

---

### 12. Renderer (`src/pdfbox/rendering/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/` (2 classes)

| Component | Status | Notes |
|---|---|---|
| PDFRenderer | not started | Stub only |
| TrueTypeFontRenderer | not started | Stub only |

**Low priority** --- Full PDF rendering to images requires significant work (path filling, image compositing, ICC color management). The 3 benchmark test files are not ported.

Covered by 1 auto-generated porting spec (`pdfbox-0wb`).

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
| StandardSecurityHandler | partial | RC4, AES-128, AES-256 key generation |
| PDEncryption | partial | Encryption dictionary management |
| AccessPermission | ported | |
| ProtectionPolicy | ported | |
| SecurityHandlerFactory | partial | |

**Gaps:** Stream/data encryption not wired into writer. Public key encryption not ported.
Covered by porting specs and pending writer test.

---

### 15. I/O Layer (`src/pdfbox/io.cr`)

**Java source:** `vendor/pdfbox/io/src/main/java/org/apache/pdfbox/io/` (18 files)

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

**I/O parity is complete.** Covered by 1 auto-generated porting spec (`pdfbox-6req`).

---

## Not Ported (Out of Scope)

These Java modules are not targeted for Crystal:
- **debugger/** (89 files) --- Swing GUI application, no Crystal equivalent
- **benchmark/** (3 files) --- Java JMH benchmarks, no Crystal equivalent
- **examples/** (93 files + 9 tests) --- Example code, not library features
- **Lucene integration** --- Java-specific search integration

---

## Task Tracking

Each broad feature area above is a TDD-ready work item. When starting work:

1. Create an active plan in `plans/active/<FeatureName>.md` (see `CosParserPort.md` for format)
2. Move corresponding pending tests to active, fix implementation to make them pass
3. Update this `parity.md` status from `partial` to `ported`
4. Update `plans/inventory/java_port_inventory.tsv` from `missing` to `ported`

### Current Active Work
- **Text stripper**: Multi-PDF extraction test enabled (34/40 exact match). Fixed TrueType `average_font_width` to use PDF Widths array (Java parity). 6 known deviations remain.
- **Save+load roundtrip**: All writer specs green (12 ex, 0 fail, 3 pending).
- **COSParser**: `plans/active/CosParserPort.md` --- ~30/50+ methods ported
- **COSWriter**: v2 with BFS traversal complete. Remaining gaps are compressed object streams, incremental update, encryption writing.
