# PDFBox Crystal Porting Parity

> Working document tracking broad feature porting status.
> Source of truth for "what did we just do": [`plans/parity/changelog.md`](parity/changelog.md).
> Per-symbol ledgers: [`plans/inventory/`](inventory/). Per-feature plans: [`plans/active/`](active/).
> **How to resume:** read **Where we are** below, open the work file named there,
> then run `make format`, `make lint` and `make test`.

## Where we are

- **Current focus:** the post-roadmap **pdmodel / text / rendering / io / cos / filter / pdfwriter / multipdf / fdf / fontbox / util / XMPBox accessor-completeness** grind — one Java class or small cluster per commit, test-first (red→green). Latest: **glyph rendering** — `PDFRenderer`/`PageDrawer` now draws text. `PDFStreamEngine#showGlyph` dispatches to `showFontGlyph`/`showType3Glyph` (Java's split), the engine keeps **one** graphics-state stack (`create_graphics_state` factory, `saveGraphicsStack`/`restoreGraphicsStack`), `PageDrawer#showFontGlyph` renders `PDVectorFont#getNormalizedPath` outlines through `Matrix#transformPoint` in the text rendering matrix, and the Type 3 default walks the charproc via `processType3Stream`. The unified stack restored Java's per-stream save/restore, which exposed and fixed three overlay bugs (`createOverlayStream` matrix order, the 90°/270° `createOverlayFormXObject` matrix cases, missing `adjustRotation`) and, through them, a page-tree duplication: `Parser#parse_pages_from_catalog` resolved kids outside the shared `object_from_pool`, so each page dictionary existed twice and page edits were dropped on save (new `resolve_page_tree_node`).
- **Next up:** the next **genuine** gap. The inventory's `missing` rows are mostly classifier noise (it matches `def` names only), so pick a lead below, confirm against `vendor/pdfbox/` that the Crystal behaviour really differs, then write the failing spec first.

### How to find the next gap (the techniques that worked)

1. **Class-vs-Java accessor diff** — for one Java class, list its `public`/`protected` methods and compare against the Crystal class, stripping `get`/`set`/`is`/`has` before snake-casing (`getMediaBox` → `media_box`, `isNodeOpen` → `node_open?`). Anything left is a candidate; then read the Java body — it may be a no-op there too.
2. **Single-literal method scan** — find `def` bodies that are just `nil`/`false`/`true`/`0`/`Vector.new`, then check Java: several were faithful (`PDType3Font#isEmbedded` → true, `PDSimpleFont#willBeSubset` → false), some were not (`PDNonTerminalField#getValueAsString`, `PDPattern#getInitialColor`).
3. **TODO/stub grep** — `grep -rn "TODO\|not supported\|not implemented" src/pdfbox`; the highest-value recent finds were TODO stubs on public accessors (`Pdfparser::Parser#encrypted?/#version/#catalog/#document_information`).
4. **Divergence comments** — `grep -rn "ivergence" src/pdfbox`; these are self-documented differences, some closable (the writer's created-arrays note became a feature).
5. **Vendored-fixture test port** — check whether a `partial` test row's fixture is actually vendored under `spec/resources/` (two `PDButtonTest` cases were wrongly marked "fixture not vendored"); the port sometimes passes immediately, which means the row is just stale.
6. **Object-model diff for inheritance/lookup** — compare Java's `getInheritableAttribute`/`getDictionaryObject` usage with ours (this is how the inherited `/MediaBox`/`/CropBox`/`/Rotate` bug was found).

### Leads for the next session (not yet verified as gaps)

- `PDFStreamEngine` now dispatches glyphs, but the remaining Java rendering hooks are still missing: `processSoftMask`, `processTransparencyGroup`, `processTilingPattern`, `showForm`, `showAnnotation`, `processChildStream`, `clipToRect` (the port handles some of these inline elsewhere — check before porting).
- **Text painting is outline-only**: `PageDrawer#draw_filled` is a bresenham outline (`draw_lines`), so a fill and a stroke look the same and glyph counters are not filled. Java uses `Graphics2D#fill(Shape)`. Making fills real (scanline/even-odd for `fill_path` and `fill_and_stroke_path`) would also fix rectangle fills.
- **The raster has no background**: `CrImage.rgba` starts as transparent black, so a page without content renders transparent instead of white (Java starts from a white `BufferedImage`). Any spec that counts "dark pixels" must check `alpha > 0`; painting the background is still unported.
- **Text rendering mode `Tr 3`/`7` (invisible)** and `Tr 4..7` (clip) are only partly wired: `PageDrawer#show_font_glyph` handles fills/strokes but never adds the glyph to the clip path.
- `PDFStreamEngine` has no `should_process_color_operators`/d1 (marked content) gating, and `show_text_strings` still ignores `PDFont#is_vertical`.
- `PDColorSpace.create` now takes the resources, but only the `/Pattern` forms use them: Java also builds `PDDeviceN`, `PDIndexed`, `PDSeparation` and `PDICCBased` with the resources (`new PDDeviceN(array, resources)` etc.), and the port's constructors take only the COS array. Threading them through is the next step for those four spaces.
- `src/pdfbox/pdf_parser/xref_parser.cr` still has the stubs `setHasHybridXRef`, `setTrailer`, `setIsXRefStream` and "copy xref table to document" — check whether `XrefParser` is still on a live path before wiring them.
- Dead code: `PDSimpleFont#non_zero_bounding_box?` is defined once and never called (Type 1C/Type 3 have their own copies).

### Not ported by design (do not chase)

- `SignatureInterface` / CMS signing (needs BouncyCastle/JCA): external signing via `Document#save_incremental_for_external_signing` is the supported path.
- AWT-only paths: `toRawImage`/`toRGBImage`, `Paint`-based shading classes, `PageDrawer`/`PDFRenderer` Graphics2D methods, `rendering/SoftMask` paints, ImageIO-based image factories.
- The writer numbers created **dictionaries** instead of inlining them (Java inlines a dictionary reachable from one place); the port does it to avoid duplicating a dictionary reachable from two places (see `Writer#write_incremental`).

### Work files

The document is split so this entry point stays small; every part is linked here.

| Work file | Contents | Status |
| --- | --- | --- |
| [`plans/parity/changelog.md`](parity/changelog.md) (+ [`changelog/`](parity/changelog/)) | newest-first feature changelog: one `current.md` plus frozen `archive-<newest>-to-<oldest>.md` parts | **in progress** (append-only) |
| [`plans/parity/phases.md`](parity/phases.md) | Phases 1–13 roadmap, chunk workflow, task tracking | complete (historical) |
| [`plans/parity/upcoming-chunks.md`](parity/upcoming-chunks.md) | Work Chunks A–AW: goal / source of truth / done-when | complete |
| [`plans/parity/naming.md`](parity/naming.md) | Java → Crystal class-name mapping and inventory-matcher notes | reference |
| [`plans/inventory/*.tsv`](inventory/) | per-symbol source / port / test ledgers | **in progress** (updated per feature) |
| [`plans/active/*.md`](active/) | one plan per branch-sized feature cluster | complete (superseded by the changelog) |

- **Working in:** [`plans/parity/changelog/current.md`](parity/changelog/current.md) — add each
  new feature entry at its top, and update the two `plans/inventory/*.tsv` ledgers plus the
  Overview numbers below in the same commit.
- **Next file/phase to start:** `phases.md` and `upcoming-chunks.md` are complete; the next
  feature comes from **Leads for the next session** above (or the search recipe, if that list
  runs dry), verified against `vendor/pdfbox/` before writing the failing spec.

## Overview

| Metric | Value |
|---|---|
| Java source files (vendor) | ~1,064 (main sources) |
| Crystal source files (ported) | ~520 (`src/` has 563 `.cr` files) |
| Passing tests | 2,845 |
| Pending tests | 0 |
| Failures | 0 |
| Errors | 0 |
| Text extraction: exact match | 40/40 PDFs (100%) |
| Text extraction: known deviations | 0 PDFs (0%) |
| Text extraction: fixed this session | PDFBOX-3127, PDFBOX-3053, PDFBOX-3061, PDFBOX-4532 |
| Inventory: ported | 7,395 source + 1,715 test |
| Inventory: partial | 37 source + 221 test |
| Inventory: missing | 4,997 source (mostly fontbox internals / pdmodel interactive/graphics/font / debugger / examples / xmpbox; test-parity inventory fully reconciled at 0) |
| Active porting plans | 36 (`plans/active/{CosParserPort,AppearanceGeneratorPort,CertificateEncryptionTools,CCITTFaxEncoderPort,CCITTFactoryImagePort,PNGConverterImagePort,OutlineItemModelPort,PredictorDecodePort,ParserXrefDecodePort,StopFilterDecodePort,GraphicsFormXObjectPort,FreeTextAppearancePort,StreamToTextStringPort,GraphicsOperatorNamesPort,ShadingFillPort,InlineImageDrawPort,InlineImageRenderPort,PathOperatorsPort,MarkedContentPort,LayerUtilityPort,PDFCloneUtilityPort,PDFMergerUtilityPort,PDFMergerUtilityMergePort,NamedDestinationsMergePort,OpenActionMergePort,SplitterPhase,StructureTreeMergePort,PDFBoxIORemainderPort,AppendDocumentCatalogMergePort,PDFParserTestsPort,CMapAndFontCleanupPort,TTFSubsetterAndPlaceholderCleanupPort,MarkedContentExtractorPort,ArtifactMarkedContentPort,MarkInfoPort,SubsetFontReusePort}.md`) |
| Fixed since last update | See [`plans/parity/changelog.md`](parity/changelog.md); the newest entry is **`PDPattern` owns its resources + `get_pattern` (2026-10-29)**. |

---
