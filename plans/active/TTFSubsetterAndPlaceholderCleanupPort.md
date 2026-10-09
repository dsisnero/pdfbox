# Phase: TTFSubsetter selected-table assertions + placeholder cleanup

**Goal:** resolve the last stale spec TODO and remove the remaining vacuous
auto-generated porting stubs.

## Source of truth

- `vendor/pdfbox/fontbox/src/test/java/org/apache/fontbox/ttf/TTFSubsetterTest.java#testEmptySubset2`
- `vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/action/PDActionURITest.java`

## Done

- [x] `testEmptySubset2` now asserts every selected table
      (`head`/`hhea`/`loca`/`maxp`/`cvt `/`prep`/`glyf`/`hmtx`/`fpgm`/`gasp`)
      is present in the subset font (replaces the TODO). Green.
- [x] Deleted the last 9 vacuous `spec/porting/pdfbox-*` stubs
      (0wb/1k0/2tl/4i9/4pr/55c/599/7gt/9tt); their directories are covered by
      real specs. Repointed `PDActionURITest` inventory rows to
      `spec/pdfbox/pdmodel/interactive/action/pd_action_uri_test_spec.cr`.

## Notes

- 17 real `spec/porting/pdfbox-*` specs remain (content), plus the source-of-
  truth tracking ones. No vacuous placeholder specs remain.
