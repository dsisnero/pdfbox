# PDFBox Crystal Porting Parity

> Working document tracking broad feature porting status.
> Complements `plans/inventory/java_port_inventory.tsv` (per-method ledger) and `plans/active/` (per-class plans).
> Update this file as features progress.

---

## Overview

| Metric | Value |
|---|---|
| Java source files (vendor) | ~1,289 |
| Crystal source files (ported) | ~415 |
| Passing tests | ~1,469 |
| Pending tests | 17 |
| Active porting plans | 1 (`plans/active/CosParserPort.md`) |

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
| COSObject | ported | — |
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

**Pending tests:** 1 (`test PDFBOX-5025` — fixture PDFBox-5025.pdf not found)

---

### 3. PDF Writing (`src/pdfbox/pdfwriter.cr`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/` (3 classes + compression)

| Component | Status | Notes |
|---|---|---|
| COSWriter | partial (v2) | BFS graph traversal, proper indirect refs. Replaced flat hand-construction. |
| COSStandardOutputStream | not started | Not needed directly — uses Crystal IO |
| COSWriterCompressionPool | partial | Object stream collection implemented |
| CompressParameters | ported | |
| ContentStreamWriter | ported | |

**Known gaps:**
- `Document.load` doesn't reconstruct pages from serialized page tree (save+load round-trip broken)
- No compressed object stream writing (xref stream vs xref table)
- No incremental update / digital signature support
- No encryption writing

**Pending tests:** 3 (`testCompressEncryptedDoc`, `testPDFBox5927`, `testPDFBox6036`)

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
- `show_text_strings` (TJ) implementation needs edge-case verification
- `SetGraphicsStateParameters` (gs) operator is a TODO stub
- Color space operators (CS, cs, SC, sc) are TODO stubs
- Marked content operators (BMC, EMC, MP, DP) are TODO stubs

**No pending tests.** (Text stripper pending tests are about text extraction, not content stream operators.)

---

### 6. Text Extraction (`src/pdfbox/text/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/` (4 classes)

| Component | Status | Notes |
|---|---|---|
| PDFTextStripper | partial | Core engine with bidi support, word detection, line building |
| TextPosition | ported | |
| LegacyPDFStreamEngine | ported | (in contentstream/) |
| PDFTextStripperByArea | partial | Wraps PDFTextStripper |

**Pending tests:** 5
- `pdf_text_stripper_spec.cr` (3): outline extraction, tabula font-height behavior, multi-PDF extraction parity
- `bidi_text_stripper_spec.cr` (2): BidiSample sorted/unsorted — bidi algorithm differences from Java

**TDD-ready tasks:**
1. Enable `TestTextStripper#testExtract` — verify against fixture `.txt` files
2. Enable `with_outline.pdf` extraction parity
3. Enable tabula font-height extraction parity
4. Enable BidiSample extraction parity

---

### 7. PD Model — Document Management (`src/pdfbox/pdmodel/`)

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
- `Document.load` → save → load roundtrip broken (page tree not reconstructed)
- Missing `ResourceCache` for page resources (needed by PDPageTree iterator)
- Font subsetting not wired into save path
- Stream encryption not integrated

**No dedicated pending tests** (issues surface in font/text writer tests).

**TDD-ready task:** Fix `Document.load` to reconstruct pages from serialized page tree after save.

---

### 8. PD Model — Fonts (`src/pdfbox/pdmodel/font/`)

**Java source:** `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/` (20+ classes)

| Component | Status | Notes |
|---|---|---|
| PDFont | partial | Core abstract class with encoding, widths, glyphs |
| PDSimpleFont | partial | |
| PDType1Font | partial | Standard 14 + PFB embedding |
| PDTrueTypeFont | partial | Loading from TTF, embedding incomplete |
| PDType0Font | partial | CID font loading, embedding incomplete |
| PDCIDFont | partial | |
| PDCIDFontType0 | partial | |
| PDCIDFontType2 | partial | |
| PDType3Font | partial | |
| PDType1CFont | partial | |
| PDVectorFont | partial | |
| Encoding (all) | ported | WinAnsi, MacRoman, Standard, Symbol, Zapf, Identity-H/V, Dictionary |
| FontMapper | partial | |
| FontProvider | partial | |
| Standard14Fonts | ported | |
| ToUnicodeWriter | partial | |
| FontDescriptor | partial | |
| GlyphList | ported | |

**Pending tests:** 6
- `checks has_glyph and get_path for TrueType font` — fixture exists, needs embedding implementation
- `calculates correct string width for Type0 font` — needs PDType0Font embedder
- `calculates correct space width for Type0 font` — needs PDType0Font embedder
- `extracts outlines from OpenType/CFF fonts` — needs FoglihtenNo07.otf fixture
- `uses embedded CFF data for paths, widths, height` — needs FoglihtenNo07.otf fixture
- `indexes TTF, OTF, and PFB entries through the provider` — needs font directory

**TDD-ready tasks:**
1. PDType0Font embedder (PDCIDFontType2Embedder) — unblocks 2 pending tests
2. TrueType font embedding with subsetting — unblocks 2 pending tests
3. Type1 font embedding (PFB constructor) — fixture already conditional

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
- `parses standalone OpenType/CFF fonts through OTFParser` — needs FoglihtenNo07.otf
- `processes TTC fonts, resolves fonts by name, and scans headers` — needs DejaVuSansMono.ttf (Java build artifact)
- GSUB specs: 4 compile errors (pre-existing, unrelated to runtime parity)

---

### 10. XMPBox (`src/xmpbox/`)

**Java source:** `vendor/pdfbox/xmpbox/src/main/java/org/apache/xmpbox/` (73 files)

| Component | Status | Notes |
|---|---|---|
| XMP metadata | minimal | Only date_converter.cr ported |
| XML parsing | not started | |
| Schema handling | not started | |

**Low priority** — XMP metadata is needed only for PDF/A and advanced metadata workflows.
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

**Low priority** — Full PDF rendering to images requires significant work (path filling, image compositing, ICC color management). The 3 benchmark test files are not ported.

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

## Pending Tests by Unblock Priority

| Priority | Test | Area | Blocked By |
|---|---|---|---|
| P0 | testExtract (multi-PDF) | Text | Font height / line-break positioning edge cases |
| P0 | with_outline.pdf extraction | Text | `LegacyPDFStreamEngine` calc differences |
| P0 | tabula font-height extraction | Text | Custom `computeFontHeight` override differences |
| P1 | Type0 string/space width | Font | `PDCIDFontType2Embedder` not implemented |
| P1 | TrueType has_glyph/get_path | Font | TrueType glyph path extraction needs verification |
| P1 | TrueType font embedding | Font | Subsetter / embedder not wired |
| P1 | OpenType/CFF outlines | Font | `OTFParser` CFF path integration |
| P2 | TTC processing | FontBox | Only works with Java build artifacts |
| P2 | OTF standalone parsing | FontBox | Only works with Java build artifacts |
| P2 | Font provider indexing | Font | Only works with font directory |
| P2 | BidiSample sorted/unsorted | Text | Bidi algorithm differences from Java |
| P3 | COS writer object graph | Writer | `Document.load` not reconstructing page tree |
| P3 | Compress encrypted doc | Writer | Encryption not wired into writer |
| P3 | Document compression | Writer | Object stream compression not wired into writer |

P0 = text extraction (most visible feature gap)
P1 = font embedding/loading (blocks Type0/TrueType/Type1C parity)
P2 = font infrastructure (fixture-dependent)
P3 = writer/encryption (requires multiple layers)

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
- **COSParser**: `plans/active/CosParserPort.md` — ~30/50+ methods ported
- **COSWriter**: Just completed (v2 with BFS traversal). Save+load roundtrip needs `Document.load` fix.
