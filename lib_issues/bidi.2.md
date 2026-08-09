# Bidi Issue 2: Arabic diacritic ordering and BOM handling

## Status: RESOLVED (2026-08-08)

### Diacritic ordering

Hebrew/Arabic text with combining marks (e.g. Hebrew niqqud `אּ`, Arabic
diacritics) is now ordered correctly because `handle_direction` reverses RTL
runs grapheme-aware (using `String#reverse`, which keeps combining marks with
their base character) and then applies bracket mirroring. This matches Java's
`handleDirection` behavior on the PDFBOX-4531-bidi-ligature fixtures.

### BOM handling

Test comparison (`text_stripper_normalize`) strips the leading BOM from
expected fixtures and normalizes with NFKC. No further change needed.

### Whitespace at RTL/LTR boundaries

Java's `writeLine` writes words in extraction order (no word-level
reordering); `render_items` now does the same. Spaces between RTL and LTR
segments therefore match Java output.
