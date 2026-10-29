# PDFBox Crystal Porting Parity

> Working document tracking broad feature porting status.
> Source of truth for "what did we just do": [`plans/parity/changelog.md`](parity/changelog.md).
> Per-symbol ledgers: [`plans/inventory/`](inventory/). Per-feature plans: [`plans/active/`](active/).
> **How to resume:** read **Where we are** below, open the work file named there,
> then run `make format`, `make lint` and `make test`.

## Where we are

- **Current focus:** the post-roadmap **pdmodel / text / rendering / io / cos / filter / pdfwriter / multipdf / fdf / fontbox / util / XMPBox accessor-completeness** grind — one Java class or small cluster per commit, test-first (red→green). Latest: **`Document#document_information` is never nil** — metadata now works for in-memory documents too (Java lazily adds `/Info` to the trailer and caches the wrapper), closing the long-documented loose end.
- **Next up:** the next genuine gap — a Java symbol under `vendor/pdfbox/` that is `missing` in the inventory with no matching Crystal `def`/`property`/`getter`. Known loose ends that are *not* missing symbols: the writer still emits object numbers for created direct structures where Java inlines them (documented divergence at `Writer#write_incremental`), and the `SignatureInterface` (CMS/BouncyCastle signing) side of `PDDocument#addSignature` is not ported — external signing is the supported path.

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
  feature is chosen from the inventory (see **Next up**).

## Overview

| Metric | Value |
|---|---|
| Java source files (vendor) | ~1,064 (main sources) |
| Crystal source files (ported) | ~520 (`src/` has 563 `.cr` files) |
| Passing tests | 2,813 |
| Pending tests | 0 |
| Failures | 0 |
| Errors | 0 |
| Text extraction: exact match | 40/40 PDFs (100%) |
| Text extraction: known deviations | 0 PDFs (0%) |
| Text extraction: fixed this session | PDFBOX-3127, PDFBOX-3053, PDFBOX-3061, PDFBOX-4532 |
| Inventory: ported | 7,377 source + 1,715 test |
| Inventory: partial | 37 source + 221 test |
| Inventory: missing | 5,015 source (mostly fontbox internals / pdmodel interactive/graphics/font / debugger / examples / xmpbox; test-parity inventory fully reconciled at 0) |
| Active porting plans | 36 (`plans/active/{CosParserPort,AppearanceGeneratorPort,CertificateEncryptionTools,CCITTFaxEncoderPort,CCITTFactoryImagePort,PNGConverterImagePort,OutlineItemModelPort,PredictorDecodePort,ParserXrefDecodePort,StopFilterDecodePort,GraphicsFormXObjectPort,FreeTextAppearancePort,StreamToTextStringPort,GraphicsOperatorNamesPort,ShadingFillPort,InlineImageDrawPort,InlineImageRenderPort,PathOperatorsPort,MarkedContentPort,LayerUtilityPort,PDFCloneUtilityPort,PDFMergerUtilityPort,PDFMergerUtilityMergePort,NamedDestinationsMergePort,OpenActionMergePort,SplitterPhase,StructureTreeMergePort,PDFBoxIORemainderPort,AppendDocumentCatalogMergePort,PDFParserTestsPort,CMapAndFontCleanupPort,TTFSubsetterAndPlaceholderCleanupPort,MarkedContentExtractorPort,ArtifactMarkedContentPort,MarkInfoPort,SubsetFontReusePort}.md`) |
| Fixed since last update | See [`plans/parity/changelog.md`](parity/changelog.md); the newest entry is **`document_information` is never nil (2026-10-29)**. |

---
