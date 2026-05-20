# Bidi Issue 2: Arabic diacritic ordering and BOM handling

## Summary

Arabic text with combining marks (diacritics) is ordered differently in the
Crystal bidi shard output compared to Java's `java.text.Bidi`. Additionally,
Byte Order Mark (BOM) handling in test fixtures causes comparison failures.

## Affected Tests

- `spec/pdfbox/text/bidi_text_stripper_spec.cr` (both tests pending)
- Text comparison tests that use `text_stripper_compare_fixture`

## Specific Differences

### 1. Arabic diacritic ordering

When Arabic text contains combining marks (e.g., shadda, fatha, kasra), the
Crystal bidi shard may place them at different positions within the visual run
compared to Java's output. This is because:

- The UBA specifies that combining marks follow the base character in logical
  order, but visual rendering order depends on the shaping engine
- Java's `java.text.Bidi` uses ICU's implementation which includes some
  shaping-aware logic
- The Crystal bidi shard uses a strict UBA implementation without shaping

### 2. BOM handling in test fixtures

Some Java test fixture files (expected output) contain a leading BOM (`\uFEFF`).
The Crystal test comparison function (`text_stripper_compare_fixture`) now strips
the BOM from expected files and normalizes both strings with NFKC, but
character-level comparisons may still differ due to:

- Normalization form differences (NFC vs NFKC vs NFD)
- The bidi shard may introduce or remove zero-width characters during reordering

### 3. Whitespace handling at RTL/LTR boundaries

Spaces between RTL and LTR segments may appear in different positions in the
visual output, depending on how the UBA resolves neutral characters at
directional boundaries.

## Proposed Fix

1. **Normalization in comparison**: Apply Unicode normalization (NFKC) before
   comparing expected and actual output (already implemented in
   `text_stripper_normalize`).

2. **Strip BOM**: Strip BOM from both expected and actual before comparison
   (already implemented).

3. **Whitespace-tolerant comparison**: The existing `text_stripper_skip_whitespace`
   function already handles whitespace leniently at the character level. Consider
   applying the same tolerance at the word level for Arabic text.

4. **Document accepted differences**: If the Crystal bidi output is valid per
   the UBA spec but differs from Java, document and accept the difference as
   implementation-specific behavior.
