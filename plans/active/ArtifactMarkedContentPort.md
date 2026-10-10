# Phase: PDArtifactMarkedContent

**Goal:** Close the `/Artifact` deviation documented in Chunk AT by porting
`org.apache.pdfbox.pdmodel.documentinterchange.markedcontent.PDArtifactMarkedContent`
and wiring `PDMarkedContent.create` to dispatch on the `/Artifact` tag.

## Source of truth

- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/markedcontent/PDArtifactMarkedContent.java`
- `.../PDMarkedContent.java#create`

## Done (red-green)

- [x] `PDArtifactMarkedContent < PDMarkedContent`: `type`, `subtype`, `bbox`
      (`Common::PDRectangle`), `top_attached?`/`bottom_attached?`/
      `left_attached?`/`right_attached?` (via `/Attached`).
- [x] `PDMarkedContent.create` returns `PDArtifactMarkedContent` for the
      `/Artifact` tag, otherwise `PDMarkedContent`.
- [x] `Cos::Name::BBOX`/`ATTACHED` constants.
- [x] New spec `spec/pdfbox/pdmodel/document_interchange/marked_content/pd_artifact_marked_content_spec.cr`
      (artifact dispatch + plain tag stays `PDMarkedContent`).

## Notes

- The extractor (`PDFMarkedContentExtractor`) now yields
  `PDArtifactMarkedContent` for `/Artifact` sequences automatically via the
  shared `PDMarkedContent.create`.
