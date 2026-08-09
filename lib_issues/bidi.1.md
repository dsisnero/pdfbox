# Bidi Issue 1: reorder_line produces different output from java.text.Bidi

## Status: RESOLVED (2026-08-08)

The divergence between the Crystal bidi shard and `java.text.Bidi` was traced to
the text stripper's `handle_direction`, not the shard itself:

- **Root cause 1**: `handle_direction` indexed `levels` (a per-character array)
  by the run number (`levels[run_index]`), so embedded RTL runs were treated as
  LTR and never reversed. Fixed to `levels[run_start]`.
- **Root cause 2**: RTL run reversal used plain `String#reverse` without
  mirroring bracket characters, so `(يناير)` came out as `)يناير(`. Fixed to a
  grapheme-aware reversal that also mirrors bracket/guillemet characters
  (matching Java's `Character.isMirrored` + `MIRRORING_CHAR_MAP`).
- **Root cause 3**: `render_items` reversed the whole word order for RTL lines,
  but Java's `writeLine` writes words in extraction order. Removed the
  heuristic.

## Verified

- `spec/pdfbox/text/bidi_text_stripper_spec.cr` — BidiSample.pdf sorted and
  unsorted now compare equal to the Java fixtures.
- `spec/pdfbox/text/pdf_text_stripper_spec.cr` — hello3.pdf matches the Java
  fixture exactly.
- PDFBOX-4531-bidi-ligature-1/2 PDFs match their Java fixtures.
