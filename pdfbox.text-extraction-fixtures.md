Title: [bug] text extraction fixture paths fail on Crystal 1.19

Repo: https://github.com/dsisnero/pdfbox
Shard commit used locally: 9a4e6152b63178b3d1176b02354ff58f2ef1760e

Summary

`Pdfbox::Text::PDFTextStripper#get_text` fails on simple fixture PDFs due to a chain of incomplete resource and indirect-object handling:

1. `GlyphList` hardcodes Apache PDFBox Java resource paths that are not shipped in the shard.
2. `PDFont#read_cmap` does not dereference `Cos::Object` wrappers before type checks.
3. Embedded `ToUnicode` CMaps are treated as fatal instead of degrading cleanly.
4. Type 0 descendant font lookup assumes direct dictionaries instead of indirect objects.

Expected

Simple PDFs with embedded `ToUnicode` maps should be readable for text extraction, or at minimum should degrade without aborting the document parse.

Actual

Extraction aborts with exceptions like:

- `GlyphList 'glyphlist.txt' not found`
- `Expected Name or Stream`
- `Missing descendant font dictionary`
- `Could not find referenced cmap stream ...`

Portable repro

From the `pdfbox` shard repo root:

```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache crystal eval '
require "./src/pdfbox"
stripper = Pdfbox::Text::PDFTextStripper.new
doc = Pdfbox::Loader.load_pdf(ARGV[0])
puts stripper.get_text(doc).inspect
' /absolute/path/to/dummy.pdf
```

Parity target

- Source of truth repo: `https://github.com/0xPlaygrounds/rig.git`
- Commit: `f5c4812de02e776d9a68b481a8cf71ed6b572a2d`
- File: `vendor/rig/rig/rig-core/src/loaders/pdf.rs`
- Expected outputs for fixtures:
  - `dummy.pdf` => `"Test\nPDF\nDocument\n"`
  - `pages.pdf` => `"Page\n1\n"`, `"Page\n2\n"`, `"Page\n3\n"`

Local patch applied in host repo

- `lib/pdfbox/src/pdfbox/pdmodel/font/encoding/glyph_list.cr`
  - fallback embedded basic glyph map when Java resource files are absent
- `lib/pdfbox/src/pdfbox/pdmodel/font/pdfont.cr`
  - dereference `Cos::Object` in `read_cmap`
  - degrade embedded CMap handling instead of raising immediately
- `lib/pdfbox/src/pdfbox/pdmodel/font/type0_font.cr`
  - dereference descendant font entries
- `lib/pdfbox/src/pdfbox/pdmodel/font/font_factory.cr`
  - dereference descendant fonts in helper lookup

Notes

The host repo currently works around the still-incomplete high-level text stripper by using `Pdfbox::Loader.load_pdf`, page content streams, and embedded `ToUnicode` streams directly for the upstream fixture-style loader behavior.
