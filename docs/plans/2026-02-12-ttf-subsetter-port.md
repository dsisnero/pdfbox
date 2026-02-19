# TTFSubsetter Port Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Port TTFSubsetter.java (1165 lines) and TTFSubsetterTest.java (392 lines) from Apache PDFBox to Crystal, completing the last unported TTF test from fontbox/ttf.

**Architecture:** Follow the Java implementation closely, adapting Java patterns to Crystal idioms. Use TDD approach: port tests first, then implement missing functionality. The TTFSubsetter creates font subsets by selecting specific glyphs and rewriting font tables.

**Tech Stack:** Crystal 1.19.1, existing Fontbox TTF classes (TrueTypeFont, CmapLookup, etc.), Crystal standard library.

---

## Phase 1: Setup and Test Infrastructure

### Task 1: Create test spec file structure

**Files:**
- Create: `spec/fontbox/ttf/ttf_subsetter_spec.cr`
- Modify: `spec/spec_helper.cr` (if needed to include test resources)

**Step 1: Write the failing test skeleton**

```crystal
require "../spec_helper"

module Fontbox::TTF
  describe TTFSubsetter do
    it "test empty subset" do
      pending "Not implemented"
    end

    it "test empty subset with selected tables" do
      pending "Not implemented"
    end

    it "test non-empty subset with one glyph" do
      pending "Not implemented"
    end

    it "test PDFBox-3319: widths and left side bearings in partially monospaced font" do
      pending "Not implemented"
    end

    it "test PDFBox-3379: left side bearings in partially monospaced font" do
      pending "Not implemented"
    end

    it "test PDFBox-3757: PostScript names not in WGL4Names don't get shuffled" do
      pending "Not implemented"
    end

    it "test PDFBox-5728: font with v3 PostScript table format and no glyph names" do
      pending "Not implemented"
    end

    it "test PDFBox-6015: font with 0/1 cmap" do
      pending "Not implemented"
    end
  end
end
```

**Step 2: Run test to verify it compiles**

Run: `crystal spec spec/fontbox/ttf/ttf_subsetter_spec.cr -v`
Expected: PASS (all tests pending)

**Step 3: Add test resource helper**

Add to spec file before describe block:

```crystal
private def liberation_sans_path
  File.join(__DIR__, "../../../../apache_pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")
end

private def load_liberation_sans
  TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(liberation_sans_path))
end
```

**Step 4: Run test to verify it still compiles**

Run: `crystal spec spec/fontbox/ttf/ttf_subsetter_spec.cr -v`
Expected: PASS

**Step 5: Commit**

```bash
git add spec/fontbox/ttf/ttf_subsetter_spec.cr
git commit -m "test: add TTFSubsetter spec skeleton with pending tests"
```

### Task 2: Implement testEmptySubset (first test)

**Files:**
- Modify: `spec/fontbox/ttf/ttf_subsetter_spec.cr`

**Step 1: Write the failing test**

Replace the first pending test with:

```crystal
it "test empty subset" do
  font = load_liberation_sans
  subsetter = TTFSubsetter.new(font)

  output = IO::Memory.new
  subsetter.write_to_stream(output)

  # Parse the subset font
  subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
  subset_font = TTFParser.new(true).parse(subset_io)

  subset_font.number_of_glyphs.should eq(1)
  subset_font.name_to_gid(".notdef").should eq(0)
  subset_font.glyph.glyph(0).should_not be_nil
end
```

**Step 2: Run test to verify it fails**

Run: `crystal spec spec/fontbox/ttf/ttf_subsetter_spec.cr:5 -v`
Expected: FAIL with "uninitialized constant Fontbox::TTF::TTFSubsetter"

**Step 3: Create minimal TTFSubsetter class**

Create: `src/fontbox/ttf/ttf_subsetter.cr`

```crystal
module Fontbox::TTF
  class TTFSubsetter
    def initialize(font : TrueTypeFont)
    end

    def write_to_stream(io : IO)
    end
  end
end
```

Add to `src/fontbox/ttf.cr`:
```crystal
require "./ttf/ttf_subsetter"
```

**Step 4: Run test to verify it still fails (but different error)**

Run: `crystal spec spec/fontbox/ttf/ttf_subsetter_spec.cr:5 -v`
Expected: FAIL with runtime error (no glyphs written, etc.)

**Step 5: Commit**

```bash
git add src/fontbox/ttf/ttf_subsetter.cr src/fontbox/ttf.cr
git commit -m "feat: add TTFSubsetter skeleton"
```

## Phase 2: Core TTFSubsetter Implementation

### Task 3: Study Java TTFSubsetter implementation

**Files:**
- Read: `apache_pdfbox/fontbox/src/main/java/org/apache/fontbox/ttf/TTFSubsetter.java`
- Read: `apache_pdfbox/fontbox/src/test/java/org/apache/fontbox/ttf/TTFSubsetterTest.java`

**Step 1: Analyze constructor and fields**

Document the Java class fields and their Crystal equivalents:

```crystal
@ttf : TrueTypeFont
@unicode_cmap : CmapLookup
@uni_to_gid : SortedMap(Int32, Int32)  # TreeMap in Java
@keep_tables : Array(String)?
@glyph_ids : SortedSet(Int32)          # TreeSet in Java
@invisible_glyph_ids : Set(Int32)
@prefix : String?
@has_added_compound_references : Bool
```

**Step 2: Analyze writeToStream method structure**

Note the main flow:
1. Build glyph set (add .notdef glyph 0)
2. Add compound glyph references
3. Build GID map (old GID → new GID)
4. Write font header
5. Write required tables
6. Write directory

**Step 3: Document table writing methods**

Table writing methods in Java TTFSubsetter:
- `buildHeadTable()` - Header table with checksum adjustment
- `buildHheaTable()` - Horizontal header table
- `buildMaxpTable()` - Maximum profile table
- `buildNameTable()` - Naming table (optional)
- `buildOS2Table()` - OS/2 Windows metrics table
- `buildGlyfTable(long[] newLoca)` - Glyph data table
- `buildLocaTable(long[] newLoca)` - Location table
- `buildCmapTable()` - Character mapping table
- `buildHmtxTable()` - Horizontal metrics table
- `buildPostTable()` - PostScript table (optional)

Additional helper methods:
- `writeFileHeader()` - Writes TTF file header
- `writeTableHeader()` - Writes individual table header
- `writeTableBody()` - Writes table data with padding
- `addCompoundReferences()` - Adds compound glyph references
- `getGIDMap()` - Builds old→new GID mapping

Tables are written in optimized order: OS/2, cmap, glyf, head, hhea, hmtx, loca, maxp, name, post plus any other tables from original font if in keepTables list.

**Step 4: Commit documentation**

```bash
git add docs/plans/2026-02-12-ttf-subsetter-port.md
git commit -m "docs: analyze TTFSubsetter Java implementation"
```

### Task 4: Implement basic constructor and glyph tracking

**Files:**
- Modify: `src/fontbox/ttf/ttf_subsetter.cr`

**Step 1: Add fields and constructor**

```crystal
module Fontbox::TTF
  class TTFSubsetter
    @ttf : TrueTypeFont
    @unicode_cmap : CmapLookup
    @uni_to_gid : SortedMap(Int32, Int32)
    @keep_tables : Array(String)?
    @glyph_ids : SortedSet(Int32)
    @invisible_glyph_ids : Set(Int32)
    @prefix : String?
    @has_added_compound_references : Bool

    def initialize(font : TrueTypeFont, tables : Array(String)? = nil)
      @ttf = font
      @keep_tables = tables
      @uni_to_gid = SortedMap(Int32, Int32).new
      @glyph_ids = SortedSet(Int32).new
      @invisible_glyph_ids = Set(Int32).new
      @prefix = nil
      @has_added_compound_references = false

      # Find Unicode cmap
      @unicode_cmap = font.unicode_cmap_lookup

      # Always include glyph 0 (.notdef)
      @glyph_ids.add(0)
    end

    def write_to_stream(io : IO)
      # TODO
    end
  end
end
```

**Step 2: Add add method for characters**

```crystal
def add(char : Char)
  code_point = char.ord
  add(code_point)
end

def add(code_point : Int32)
  gid = @unicode_cmap.glyph_id(code_point)
  if gid > 0
    @glyph_ids.add(gid)
    @uni_to_gid[code_point] = gid
  end
end
```

**Step 3: Run test to verify it compiles**

Run: `crystal spec spec/fontbox/ttf/ttf_subsetter_spec.cr -v`
Expected: PASS (still pending tests)

**Step 4: Update testEmptySubset to use actual implementation**

Modify test to create subsetter but not call write_to_stream yet (still pending).

**Step 5: Commit**

```bash
git add src/fontbox/ttf/ttf_subsetter.cr
git commit -m "feat: add TTFSubsetter constructor and basic glyph tracking"
```

## Phase 3: Font Table Writing

### Task 5: Implement minimal write_to_stream for empty subset

**Files:**
- Modify: `src/fontbox/ttf/ttf_subsetter.cr`

**Step 1: Study Java writeToStream for empty subset**

Look at how Java handles empty subset (just .notdef glyph).

**Step 2: Implement table writing stubs**

Add private methods for each table:
- `write_head_table`
- `write_hhea_table`
- `write_maxp_table`
- `write_name_table`
- `write_os2_table`
- `write_post_table`
- `write_cmap_table`
- `write_loca_table`
- `write_glyf_table`
- `write_hmtx_table`

**Step 3: Implement write_to_stream skeleton**

```crystal
def write_to_stream(io : IO)
  # Build glyph set
  build_glyph_set

  # Build GID map
  build_gid_map

  # Write font header
  write_font_header(io)

  # Write tables
  table_offsets = write_tables(io)

  # Write directory
  write_table_directory(io, table_offsets)
end
```

**Step 4: Implement build_glyph_set and build_gid_map**

```crystal
private def build_glyph_set
  # Already have @glyph_ids with glyph 0
  # Add compound glyph references if needed
  add_compound_references unless @has_added_compound_references
end

private def build_gid_map
  # Map old GIDs to new sequential GIDs
  @gid_map = {} of Int32 => Int32
  @glyph_ids.each_with_index do |old_gid, index|
    @gid_map[old_gid] = index
  end
end
```

**Step 5: Run test to verify compilation**

Run: `crystal spec spec/fontbox/ttf/ttf_subsetter_spec.cr -v`
Expected: PASS (still pending)

**Step 6: Commit**

```bash
git add src/fontbox/ttf/ttf_subsetter.cr
git commit -m "feat: add TTFSubsetter table writing skeleton"
```

## Phase 4: Complete Empty Subset Implementation

### Task 6: Implement actual table writing for empty subset

**Files:**
- Modify: `src/fontbox/ttf/ttf_subsetter.cr`
- Create: `src/fontbox/ttf/table_writers.cr` (if needed)

**Step 1: Implement write_head_table**

Copy logic from Java TTFSubsetter.writeHeadTable.

**Step 2: Implement write_maxp_table**

For empty subset with 1 glyph.

**Step 3: Implement write_glyf_table**

Write .notdef glyph only.

**Step 4: Implement write_loca_table**

Simple location table for 1 glyph.

**Step 5: Implement remaining tables minimally**

hhea, name, OS/2, post, cmap, hmtx with minimal data.

**Step 6: Run testEmptySubset test**

Run: `crystal spec spec/fontbox/ttf/ttf_subsetter_spec.cr:5 -v`
Expected: FAIL with incorrect output (but closer)

**Step 7: Debug and fix until test passes**

**Step 8: Commit**

```bash
git add src/fontbox/ttf/ttf_subsetter.cr
git commit -m "feat: implement basic table writing for empty subset"
```

## Phase 5: Additional Tests and Features

### Task 7: Implement testEmptySubset2 (selected tables)

**Files:**
- Modify: `spec/fontbox/ttf/ttf_subsetter_spec.cr`
- Modify: `src/fontbox/ttf/ttf_subsetter.cr`

**Step 1: Write failing test for selected tables**

Copy Java testEmptySubset2 logic.

**Step 2: Implement tables parameter handling**

Modify constructor to accept and use @keep_tables.

**Step 3: Modify write_tables to respect selected tables**

Skip tables not in keep_tables list.

**Step 4: Run test and fix until passes**

**Step 5: Commit**

```bash
git add spec/fontbox/ttf/ttf_subsetter_spec.cr src/fontbox/ttf/ttf_subsetter.cr
git commit -m "feat: support selected tables in TTFSubsetter"
```

### Task 8: Implement testNonEmptySubset (one glyph)

**Files:**
- Modify: `spec/fontbox/ttf/ttf_subsetter_spec.cr`
- Modify: `src/fontbox/ttf/ttf_subsetter.cr`

**Step 1: Write failing test for 'a' glyph**

**Step 2: Implement glyph data copying**

Copy glyph data from original font for non-.notdef glyphs.

**Step 3: Update table writers for multiple glyphs**

Update maxp, loca, glyf, hmtx for multiple glyphs.

**Step 4: Run test and fix until passes**

**Step 5: Commit**

```bash
git add spec/fontbox/ttf/ttf_subsetter_spec.cr src/fontbox/ttf/ttf_subsetter.cr
git commit -m "feat: support subsetting with actual glyphs"
```

## Phase 6: Remaining Tests

### Task 9-14: Implement remaining test cases

Repeat pattern for each remaining test:
1. Write failing test
2. Implement missing functionality
3. Fix until test passes
4. Commit

Tests to implement:
- PDFBox-3319 (SimHei font widths)
- PDFBox-3379 (left side bearings)
- PDFBox-3757 (PostScript names)
- PDFBox-5728 (v3 PostScript table)
- PDFBox-6015 (0/1 cmap)

## Phase 7: Cleanup and Integration

### Task 15: Run full test suite

**Step 1: Run all TTF specs**

```bash
crystal spec spec/fontbox/ttf/
```

**Step 2: Fix any regressions**

**Step 3: Run all specs**

```bash
crystal spec
```

**Step 4: Update beads issue status**

Close `pdfbox-z59j` and `pdfbox-63rk`.

### Task 16: Documentation and finalization

**Step 1: Add YARD documentation to TTFSubsetter**

**Step 2: Update README if needed**

**Step 3: Final commit**

```bash
git add .
git commit -m "feat: complete TTFSubsetter port from Apache PDFBox"
```

---

## Execution Options

Plan complete and saved to `docs/plans/2026-02-12-ttf-subsetter-port.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**