# Port Plan: Missing graphics operator names (SCN/scn/F)

**Goal:** the graphics engine handles `SCN`/`scn` (generic color on
pattern-capable spaces) and `F` (legacy fill non-zero), matching Java.

## Source of truth

- `vendor/pdfbox/.../contentstream/PDFGraphicsStreamEngine.java`
- `contentstream/operator/color/SetStrokingColorN.java`, `SetNonStrokingColorN.java`
- `contentstream/operator/graphics/LegacyFillNonZeroRule.java`

## Problem

Java registers these operator names; the Crystal registry did not, so the
engine silently dropped them (`process_operator` falls through for unhandled
names).

## Steps (red-green)

1. [x] Write `spec/pdfbox/contentstream/graphics_operator_names_spec.cr` first
   (red): `F` fires `fill_path`; `SCN`/`scn` set the color.
2. [x] Add `OperatorLegacyFillNonZeroRule < OperatorFillNonZeroRule` (F),
   `OperatorSetStrokingColorN` (SCN), `OperatorSetNonStrokingColorN` (scn) and
   register them.
3. [x] Gates; parity.md + inventory.
