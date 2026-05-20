# Bidi Issue 1: reorder_line produces different output from java.text.Bidi

## Summary

The Crystal `bidi` shard (port of Rust `unicode-bidi` v0.3.18) uses the Unicode
Bidirectional Algorithm (UBA) to reorder mixed LTR/RTL text. However,
`java.text.Bidi` (used by Apache PDFBox) produces different visual ordering for
the same input, causing `BidiSample.pdf` text extraction tests to fail.

## Affected Tests

- `spec/pdfbox/text/bidi_text_stripper_spec.cr` (both tests pending)
- `spec/pdfbox/text/pdf_text_stripper_spec.cr`: hello3.pdf text extraction
  (`"Hello محمد World."` vs `"Hello دمحم World."`)

## Specific Differences

### 1. Reordering of isolated Arabic words

In PDFBox Java, `Bidi.requiresBidi()` combined with `Bidi.reorderVisually()`
produces a specific visual order. The Crystal bidi shard's `visual_runs()` may
return runs in a different order because:

- Java's implementation supports `RUN_DIRECTION` flags that affect neutral
  character resolution differently
- The UBA implementation in Rust `unicode-bidi` may resolve neutral characters
  (spaces, punctuation) at LTR/RTL boundaries differently from Java

### 2. Arabic character shaping differences

The Crystal port does not perform Arabic shaping (isolated/initial/medial/final
forms). Java PDFBox relies on the font's GSUB tables for shaping, but the
text extraction output still shows visual-order characters. Some Arabic letters
may appear in different positions.

### 3. Mirror character handling

Java's `Bidi` implementation mirrors certain characters (e.g., parentheses) in
RTL runs. The Crystal bidi shard may not handle mirroring the same way.

## Proposed Fix

Options (in order of preference):

1. **Port java.text.Bidi logic**: Implement the Bidi algorithm directly in
   Crystal matching Java's behavior, using the Unicode Bidi Algorithm spec but
   with Java's specific parameter choices and mirroring logic.

2. **Fix the bidi shard**: Submit patches to the `unicode-bidi` Rust crate or
   the Crystal port to match Java's UBA interpretation.

3. **Accept the difference**: Update tests to accept the Crystal bidi shard's
   output as valid (both outputs are correct per UBA spec, just different
   interpretations).
