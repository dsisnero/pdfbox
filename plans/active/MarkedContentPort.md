# Port Plan: Marked content generation (beginMarkedContent/endMarkedContent)

**Goal:** `PDPageContentStream` writes `BMC`/`BDC`/`EMC`, adding property
lists (OCGs) to `/Resources /Properties`, matching Java `PDAbstractContentStream`
and the content-generation half of `TestOptionalContentGroups#testOCGGeneration`.

## Source of truth

- `vendor/pdfbox/.../pdmodel/PDAbstractContentStream.java` (`beginMarkedContent`
  x3, `endMarkedContent`)
- `vendor/pdfbox/.../pdmodel/PDResources.java#add(PDPropertyList)`
- `TestOptionalContentGroups#testOCGGeneration`

## Problem

`beginMarkedContent`/`endMarkedContent` were missing, so OCG-marked content
could not be generated (the existing optional-content spec covered only the
model).

## Steps (red-green)

1. [x] Write `spec/pdfbox/pdmodel/page_content_stream_marked_content_spec.cr`
   first (red): BMC, BDC with an OCG resource (`/OC /oc1 BDC`), BDC with an
   MCID, negative-MCID guard.
2. [x] `begin_marked_content` (tag; tag+mcid; tag+property list) and
   `end_marked_content`.
3. [x] `PDResources#add(PDPropertyList)` (prefix "oc"/"Prop"); make
   `PDOptionalContentGroup < PDPropertyList`.
4. [x] Gates; parity.md + inventory.
