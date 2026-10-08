# Port Plan: PDPageContentStream path operators write operands

**Goal:** `addRect`/`moveTo`/`lineTo`/`curveTo`/`curveTo1`/`curveTo2` write their
operands before the operator, matching Java `PDAbstractContentStream`.

## Source of truth

- `vendor/pdfbox/.../pdmodel/PDAbstractContentStream.java` (addRect/moveTo/
  lineTo/curveTo/curveTo1/curveTo2)

## Problem

The six path methods wrote only the operator (`re`/`m`/`l`/`c`/`v`/`y`) and
omitted the coordinate operands, producing invalid content (e.g. a bare `re`).

## Steps (red-green)

1. [x] Write `spec/pdfbox/pdmodel/page_content_stream_path_spec.cr` first (red):
   re-parse the generated content and assert `<operands> <operator>`.
2. [x] Call `write_operands(...)` before `write_operator(...)` in each method.
3. [x] Gates; parity.md + inventory.

## Notes

- Java operator mapping (per OperatorName): `curveTo1` -> "y"
  (CURVE_TO_REPLICATE_FINAL_POINT), `curveTo2` -> "v"
  (CURVE_TO_REPLICATE_INITIAL_POINT).
