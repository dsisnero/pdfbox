# Port Plan: PDFGraphicsStreamEngine Form XObject handling

**Goal:** the graphics engine processes `Do` of a Form XObject recursively (its
operators reach the graphics callbacks), with Java's 50-level recursion guard.

## Source of truth

- `vendor/pdfbox/.../contentstream/operator/graphics/DrawObject.java`
  (`increaseLevel` -> `getLevel() > 50` -> `decreaseLevel`, `showForm`)
- `vendor/pdfbox/.../contentstream/PDFStreamEngine.java#showForm`
- Fixtures: `input/rendering/tiger-as-form-xobject.pdf`,
  `PDFBOX-4372-...-p4_reduced.pdf` (self-referential form -> guard).

## Problem

`OperatorDrawObject` handled `/Image` and left `/Form` as a no-op, so forms were
dropped in rendering. Also, without the Java recursion guard, a self-referential
form stack-overflowed.

## Steps (red-green)

1. [x] Write `spec/pdfbox/contentstream/graphics_form_xobject_spec.cr` first
   (red): single and nested forms must reach `append_rectangle`/`fill_path`.
2. [x] Expose `PDFStreamEngine#process_form_xobject`; add
   `level`/`increase_level`/`decrease_level`.
3. [x] `OperatorDrawObject`: `/Form` -> `process_form_xobject`, using
   `context.resources || page.resources`, guarded at level 50.
4. [x] Port `JPEGFactoryTest#testPDFBox5137` with the SHA512-verified fixture.
5. [x] Gates; parity.md + inventory.

## Notes

- AWT `getImage`/`checkIdent` assertions in image tests remain out of scope.
