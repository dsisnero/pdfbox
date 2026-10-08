# Port Plan: COSStream#toTextString + finish remaining Java tests

**Goal:** port `COSStream#toTextString` and complete the remaining portable Java
test ports (`PDAcroFormFromAnnotsTest`, `TestCMapSubtable`).

## Source of truth

- `vendor/pdfbox/.../cos/COSStream.java#toTextString`
- `vendor/pdfbox/.../pdmodel/interactive/form/PDVariableText.java#getRichTextValue`
- `vendor/pdfbox/.../pdmodel/interactive/form/PDAcroFormFromAnnotsTest.java`
- `vendor/pdfbox/fontbox/.../ttf/TestCMapSubtable.java`

## Steps (red-green)

1. [x] Write `spec/pdfbox/cos/stream_to_text_string_spec.cr` first (red):
   UTF-16BE, PDFDocEncoding, Flate-decoded and failure cases.
2. [x] `Cos::Stream#to_text_string` (decode through filters, `Cos::String`
   text decoding, `""` on error).
3. [x] `PDVariableText#get_string_or_stream` uses it for stream values.
4. [x] Port `PDAcroFormFromAnnotsTest` `4985CorrectionMode`,
   `4985WithoutCorrectionMode`, `3891ValidateFont`; reconcile `TestCMapSubtable`.
5. [x] Gates; parity.md + inventory.
