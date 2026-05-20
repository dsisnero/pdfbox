# Main public API for the Unicode Bidirectional Algorithm
#
# This module implements the Unicode Bidirectional Algorithm (UBA) as defined in
# Unicode Technical Report #9 (https://www.unicode.org/reports/tr9/).
#
# It is a behavior-identical port of the Rust `unicode-bidi` crate v0.3.18,
# providing UTF-8 text analysis and reordering for mixed RTL/LTR text display.
#
# Key components:
# - `BidiInfo`: Multi-paragraph analysis for UTF-8 text
# - `ParagraphBidiInfo`: Single-paragraph analysis for UTF-8 text
# - `Direction`: Paragraph direction (Ltr, Rtl, Mixed)
# - `ParagraphInfo`: Information about a single paragraph within text
#
# All public APIs match the Rust crate exactly, including method signatures,
# return types, and edge case behavior.

require "./bidi_info_common"

module Bidi
  # Paragraph directionality
  #
  # Represents the overall direction of a paragraph after bidi analysis:
  # - `Ltr`: Entirely left-to-right text
  # - `Rtl`: Entirely right-to-left text
  # - `Mixed`: Mixed-direction text containing both LTR and RTL content
  enum Direction
    Ltr
    Rtl
    Mixed
  end

  # Information about a single paragraph within text
  #
  # Contains the byte range and base embedding level for a paragraph.
  # Used with `BidiInfo` for paragraph-level operations.
  struct ParagraphInfo
    property range : Range(Int32, Int32)
    property level : Level

    def initialize(@range : Range(Int32, Int32), @level : Level)
    end

    # Returns the length of the paragraph in bytes
    def length : Int32
      @range.end - @range.begin
    end
  end

  # Combined reference to `BidiInfo` and a specific paragraph within it
  #
  # Provides convenient access to paragraph-level operations without
  # needing to pass both `BidiInfo` and `ParagraphInfo` separately.
  # This matches the Rust `Paragraph<'a, 'text>` struct.
  struct Paragraph
    property info : BidiInfo
    property para : ParagraphInfo

    def initialize(@info : BidiInfo, @para : ParagraphInfo)
    end

    # Returns the overall direction of the paragraph (Ltr, Rtl, or Mixed)
    #
    # Determined by examining the levels of all characters in the paragraph:
    # - All LTR levels → Ltr
    # - All RTL levels → Rtl
    # - Mixed LTR/RTL levels → Mixed
    def direction : Direction
      para_direction(@info.levels[@para.range])
    end

    # Returns the embedding level at a specific character position
    #
    # Parameters:
    # - `pos`: Character position within the paragraph (0-based, in characters)
    #
    # Returns: The `Level` at that position
    def level_at(pos : Int32) : Level
      @info.levels[@para.range.begin + pos]
    end

    private def para_direction(levels : Array(Level)) : Direction
      ltr = false
      rtl = false
      levels.each do |level|
        if level.ltr?
          ltr = true
          return Direction::Mixed if rtl
        end

        if level.rtl?
          rtl = true
          return Direction::Mixed if ltr
        end
      end

      if ltr
        Direction::Ltr
      elsif rtl
        Direction::Rtl
      else
        # Empty paragraph or all neutral characters
        Direction::Ltr
      end
    end
  end

  private struct ParagraphInfoFlags
    property is_pure_ltr : Bool
    property has_isolate_controls : Bool

    def initialize(@is_pure_ltr : Bool, @has_isolate_controls : Bool)
    end
  end

  private struct InitialInfoExt
    property original_classes : Array(BidiClass)
    property paragraphs : Array(ParagraphInfo)
    property flags : Array(ParagraphInfoFlags)

    def initialize(@original_classes : Array(BidiClass), @paragraphs : Array(ParagraphInfo), @flags : Array(ParagraphInfoFlags))
    end

    def self.new_with_data_source(data_source : BidiDataSource, text : String, default_para_level : Level?) : InitialInfoExt
      original_classes = [] of BidiClass
      paragraphs = [] of ParagraphInfo
      flags = [] of ParagraphInfoFlags

      isolate_stack = [] of Int32

      para_start = 0
      para_level = default_para_level
      is_pure_ltr = true
      has_isolate_controls = false

      i = 0
      text.each_char do |c|
        bidi_class = data_source.bidi_class(c)
        char_len = c.bytesize

        char_len.times { original_classes << bidi_class }

        case bidi_class
        when BidiClass::B
          para_end = i + char_len
          paragraphs << ParagraphInfo.new(para_start...para_end, para_level || Level.ltr)
          flags << ParagraphInfoFlags.new(is_pure_ltr, has_isolate_controls)

          para_start = para_end
          para_level = default_para_level
          is_pure_ltr = true
          has_isolate_controls = false
          isolate_stack.clear
        when BidiClass::L, BidiClass::R, BidiClass::AL
          if bidi_class != BidiClass::L
            is_pure_ltr = false
          end

          if !isolate_stack.empty?
            start = isolate_stack.last
            if original_classes[start] == BidiClass::FSI
              fsi_len = 1
              fsi_len.times do |j|
                original_classes[start + j] = bidi_class == BidiClass::L ? BidiClass::LRI : BidiClass::RLI
              end
            end
          elsif para_level.nil?
            para_level = bidi_class == BidiClass::L ? Level.ltr : Level.rtl
          end
        when BidiClass::AN, BidiClass::LRE, BidiClass::RLE, BidiClass::LRO, BidiClass::RLO
          is_pure_ltr = false
        when BidiClass::RLI, BidiClass::LRI, BidiClass::FSI
          is_pure_ltr = false
          has_isolate_controls = true
          isolate_stack << i
        when BidiClass::PDI
          isolate_stack.pop if !isolate_stack.empty?
        end

        i += char_len
      end

      if para_start < text.bytesize
        paragraphs << ParagraphInfo.new(para_start...text.bytesize, para_level || Level.ltr)
        flags << ParagraphInfoFlags.new(is_pure_ltr, has_isolate_controls)
      end

      InitialInfoExt.new(original_classes, paragraphs, flags)
    end
  end

  # Main structure for bidirectional analysis of UTF-8 text
  #
  # Contains the results of bidi analysis for potentially multiple paragraphs.
  # This is the primary entry point for analyzing mixed-direction text.
  #
  # Properties:
  # - `text`: The original input text
  # - `original_classes`: BidiClass for each byte in the text
  # - `levels`: Embedding level for each byte in the text (after resolution)
  # - `paragraphs`: Information about each paragraph in the text
  #
  # This matches the Rust `BidiInfo<'text>` struct.
  struct BidiInfo
    include BidiInfoCommon

    property text : String
    property original_classes : Array(BidiClass)
    property levels : Array(Level)
    property paragraphs : Array(ParagraphInfo)

    def initialize(@text : String, @original_classes : Array(BidiClass), @levels : Array(Level), @paragraphs : Array(ParagraphInfo))
    end

    # Creates a new `BidiInfo` by analyzing text with the default data source
    #
    # Parameters:
    # - `text`: The UTF-8 text to analyze
    # - `default_para_level`: Optional base paragraph level (nil for auto-detection)
    #
    # Returns: `BidiInfo` with analysis results
    def self.new(text : String, default_para_level : Level? = nil) : BidiInfo
      new_with_data_source(HardcodedBidiData.new, text, default_para_level)
    end

    # Creates a new `BidiInfo` with a custom data source for bidi data
    #
    # This is the lower-level constructor that allows customizing the
    # Unicode data source. Most users should use `BidiInfo.new()` instead.
    #
    # Parameters:
    # - `data_source`: Custom `BidiDataSource` for bidi class lookups
    # - `text`: The UTF-8 text to analyze
    # - `default_para_level`: Optional base paragraph level
    #
    # Returns: `BidiInfo` with analysis results
    def self.new_with_data_source(data_source : BidiDataSource, text : String, default_para_level : Level? = nil) : BidiInfo
      initial_info = InitialInfoExt.new_with_data_source(data_source, text, default_para_level)

      levels = Array(Level).new(text.bytesize, Level.ltr)
      processing_classes = initial_info.original_classes.dup

      initial_info.paragraphs.each_with_index do |para, idx|
        flags = initial_info.flags[idx]
        compute_bidi_info_for_para(data_source, para, flags.is_pure_ltr, flags.has_isolate_controls, text, initial_info.original_classes, processing_classes, levels)
      end

      BidiInfo.new(text, initial_info.original_classes, levels, initial_info.paragraphs)
    end

    private def self.compute_bidi_info_for_para(data_source : BidiDataSource, para : ParagraphInfo, is_pure_ltr : Bool, has_isolate_controls : Bool, text : String, original_classes : Array(BidiClass), processing_classes : Array(BidiClass), levels : Array(Level)) : Nil
      para.range.each do |i|
        levels[i] = para.level
      end

      if para.level.ltr? && is_pure_ltr
        return
      end

      para_text = text.byte_slice(para.range.begin, para.range.end - para.range.begin)
      level_runs = [] of LevelRun

      Bidi.compute_explicit(para_text, para.level, original_classes, levels, processing_classes, level_runs, para.range.begin, para.range.end - para.range.begin)

      sequences = [] of Bidi::IsolatingRunSequence
      Bidi.isolating_run_sequences(para.level, original_classes, levels, level_runs, has_isolate_controls, sequences, para.range.begin)

      sequences.each do |sequence|
        Bidi.resolve_weak(para_text, sequence, processing_classes, para.range.begin)
        Bidi.resolve_neutral(data_source, para_text, sequence, levels, original_classes, processing_classes)
      end

      Bidi.resolve_levels(processing_classes, levels, para.range.begin, para.range.end - para.range.begin)
      assign_levels_to_removed_chars(para.level, original_classes, levels, para.range.begin, para.range.end - para.range.begin)
    end

    private def self.assign_levels_to_removed_chars(para_level : Level, original_classes : Array(BidiClass), levels : Array(Level), start : Int32 = 0, size : Int32? = nil) : Nil
      actual_size = size || original_classes.size
      actual_size.times do |rel_i|
        i = start + rel_i
        bidi_class = original_classes[i]
        if bidi_class.removed_by_x9?
          levels[i] = if i > start
                        levels[i - 1]
                      else
                        para_level
                      end
        end
      end
    end

    def reordered_levels(para : ParagraphInfo, line : Range(Int32, Int32)) : Array(Level)
      return @levels[line] if line.begin >= line.end || line.end > @levels.size

      levels = @levels.dup
      line_levels = levels[line]
      line_text = text[line]
      para_level = para.level

      reset_from : Int32? = nil
      reset_to : Int32? = nil
      prev_level = para_level

      char_idx = 0
      line_text.each_char do |c|
        idx = line.begin + char_idx
        char_len = c.bytesize
        bidi_class = original_classes[idx]?

        if bidi_class.nil?
          char_idx += char_len
          next
        end

        case bidi_class
        when BidiClass::B, BidiClass::S
          reset_to = idx + char_len
          reset_from = idx if reset_from.nil?
        when BidiClass::WS, BidiClass::FSI, BidiClass::LRI, BidiClass::RLI, BidiClass::PDI
          reset_from = idx if reset_from.nil?
        when BidiClass::RLE, BidiClass::LRE, BidiClass::RLO, BidiClass::LRO, BidiClass::PDF, BidiClass::BN
          reset_from = idx if reset_from.nil?
          char_len.times do |j|
            level_idx = idx + j
            line_levels[level_idx] = prev_level if level_idx < line_levels.size
          end
        else
          reset_from = nil
        end

        if !reset_from.nil? && !reset_to.nil?
          (reset_from...reset_to).each do |lidx|
            line_levels[lidx] = para_level if lidx < line_levels.size
          end
          reset_from = nil
          reset_to = nil
        end

        prev_level = line_levels[idx]? || para_level
        char_idx += char_len
      end

      if !reset_from.nil?
        (reset_from...line_levels.size).each do |lidx|
          line_levels[lidx] = para_level
        end
      end

      line_levels
    end

    def reordered_levels_per_char(para : ParagraphInfo, line : Range(Int32, Int32)) : Array(Level)
      levels = reordered_levels(para, line)
      result = [] of Level

      # Iterate through byte positions, converting to character indices
      byte_pos = line.begin
      while byte_pos < line.end && byte_pos < @text.bytesize
        char_idx = @text.byte_index_to_char_index(byte_pos)
        if char_idx
          char = @text[char_idx]
          char_len = char.bytesize

          # levels is a line-relative slice; index with line-relative position
          line_rel = byte_pos - line.begin
          result << (levels[line_rel]? || para.level)

          byte_pos += char_len
        else
          # Not at a character boundary, skip to next byte
          byte_pos += 1
        end
      end

      result
    end

    def self.reorder_visual(levels : Array(Level)) : Array(Int32)
      # Implementation matching Rust's reorder_visual
      # This applies only Rule L2 of the Unicode Bidi Algorithm
      return [] of Int32 if levels.empty?

      # Create initial index map (visual index -> logical index)
      # Initially, visual order = logical order
      visual_to_logical = (0...levels.size).to_a

      # Find min and max levels
      min_level = levels.min
      max_level = levels.max

      # Apply L2: From highest level down to lowest odd level
      max_level_val = max_level.value.to_i
      min_rtl = min_level.new_lowest_ge_rtl
      # If there are no RTL levels, no reordering needed
      return visual_to_logical unless min_rtl.is_a?(Level)
      min_rtl_val = min_rtl.value.to_i

      while max_level_val >= min_rtl_val
        # For each level, scan the entire array
        i = 0
        while i < visual_to_logical.size
          # Skip elements below current level
          if levels[visual_to_logical[i]].value.to_i < max_level_val
            i += 1
            next
          end

          # Found start of sequence at level >= current
          j = i + 1
          while j < visual_to_logical.size && levels[visual_to_logical[j]].value.to_i >= max_level_val
            j += 1
          end

          # Reverse the sequence
          k = i
          l = j - 1
          while k < l
            visual_to_logical[k], visual_to_logical[l] = visual_to_logical[l], visual_to_logical[k]
            k += 1
            l -= 1
          end

          # Continue after this sequence
          i = j
        end

        max_level_val -= 1
      end

      visual_to_logical
    end

    # Reorders a line of text for visual display
    #
    # Applies the Unicode Bidirectional Algorithm to reorder text within a line
    # for proper visual display. This is the main method for getting text in
    # the correct order for rendering.
    #
    # Parameters:
    # - `para`: The paragraph containing the line
    # - `line`: Byte range within the text representing the line
    #
    # Returns: The reordered text as a `String`
    #
    # Note: Uses `byte_slice` for correct UTF-8 handling with multi-byte characters.
    def reorder_line(para : ParagraphInfo, line : Range(Int32, Int32)) : String
      return text.byte_slice(line.begin, line.end - line.begin) unless has_rtl?
      levels = reordered_levels(para, line)
      _, runs = visual_runs(para, line)
      do_reorder_line(text, line, levels, runs)
    end

    # Finds visual runs within a line
    #
    # Returns level runs in visual order as required by the Unicode Bidi Algorithm.
    # The first return value is levels after applying L1-L2 rules.
    # The second return value is runs (contiguous same-level ranges) in visual order.
    #
    # Parameters:
    # - `para`: The paragraph containing the line
    # - `line`: Byte range within the text
    #
    # Returns: Tuple of `(Array(Level), Array(Range(Int32, Int32)))`
    def visual_runs(para : ParagraphInfo, line : Range(Int32, Int32)) : Tuple(Array(Level), Array(Range(Int32, Int32)))
      levels = reordered_levels(para, line)
      compute_visual_runs(levels, line)
    end

    private def compute_visual_runs(levels : Array(Level), line : Range(Int32, Int32)) : Tuple(Array(Level), Array(Range(Int32, Int32)))
      runs = [] of Range(Int32, Int32)
      start = line.begin
      # levels is line-relative; use rel(i) = levels[i - line.begin]
      run_level = levels[0]? || Level.ltr
      min_level = run_level
      max_level = run_level

      (1...levels.size).each do |rel_i|
        i = line.begin + rel_i
        new_level = levels[rel_i]
        if new_level != run_level
          runs << (start...i)
          start = i
          run_level = new_level
          min_level = Level.new(new_level.value < min_level.value ? new_level.value : min_level.value)
          max_level = Level.new(new_level.value > max_level.value ? new_level.value : max_level.value)
        end
      end
      runs << (start...line.end)

      run_count = runs.size

      min_rtl = min_level.new_lowest_ge_rtl
      return {levels, runs} unless min_rtl.is_a?(Level)

      min_rtl_val = min_rtl.value
      max_level_val = max_level.value

      while max_level_val >= min_rtl_val
        seq_start = 0
        while seq_start < run_count
          run_begin = runs[seq_start].begin
          level_at_start = levels[run_begin - line.begin]?
          if level_at_start.nil? || level_at_start.value < max_level_val
            seq_start += 1
            next
          end

          seq_end = seq_start + 1
          while seq_end < run_count
            level_at_end = levels[runs[seq_end].begin - line.begin]?
            break if level_at_end.nil? || level_at_end.value < max_level_val
            seq_end += 1
          end

          # Reverse runs in place
          i = seq_start
          j = seq_end - 1
          while i < j
            runs[i], runs[j] = runs[j], runs[i]
            i += 1
            j -= 1
          end
          seq_start = seq_end
        end

        new_max = max_level_val == 0 ? 0 : max_level_val - 1
        max_level_val = new_max
      end

      {levels, runs}
    end

    private def do_reorder_line(text : String, line : Range(Int32, Int32), levels : Array(Level), runs : Array(Range(Int32, Int32))) : String
      parts = [] of String
      runs.each do |run|
        slice = text.byte_slice(run.begin, run.end - run.begin)
        if l = levels[run.begin]?
          if l.rtl?
            parts << slice.chars.reverse!.join
          else
            parts << slice
          end
        else
          parts << slice
        end
      end
      parts.join
    end
  end

  def self.get_base_direction(text : String) : Direction
    get_base_direction_with_data_source(HardcodedBidiData.new, text)
  end

  def self.get_base_direction_full(text : String) : Direction
    get_base_direction_full_with_data_source(HardcodedBidiData.new, text)
  end

  def self.get_base_direction_with_data_source(data_source : BidiDataSource, text : String) : Direction
    get_base_direction_impl(data_source, text, false)
  end

  def self.get_base_direction_full_with_data_source(data_source : BidiDataSource, text : String) : Direction
    get_base_direction_impl(data_source, text, true)
  end

  private def self.get_base_direction_impl(data_source : BidiDataSource, text : String, use_full_text : Bool) : Direction
    return Direction::Ltr if text.empty? # Empty text defaults to LTR

    isolate_level = 0
    text.each_char do |c|
      case data_source.bidi_class(c)
      when BidiClass::LRI, BidiClass::RLI, BidiClass::FSI
        isolate_level += 1
      when BidiClass::PDI
        isolate_level -= 1 if isolate_level > 0
      when BidiClass::L
        return Direction::Ltr if isolate_level == 0
      when BidiClass::R, BidiClass::AL
        return Direction::Rtl if isolate_level == 0
      when BidiClass::B
        return Direction::Mixed unless use_full_text
        isolate_level = 0 if use_full_text
      end
    end
    Direction::Mixed
  end

  # Single-paragraph bidirectional analysis for UTF-8 text
  #
  # Simplified API for text known to contain only one paragraph.
  # Provides the same functionality as `BidiInfo` but with a simpler interface
  # since paragraph handling is not needed.
  #
  # Properties:
  # - `text`: The original input text (single paragraph)
  # - `original_classes`: BidiClass for each byte in the text
  # - `levels`: Embedding level for each byte in the text
  # - `paragraph_level`: Base embedding level for the paragraph
  # - `is_pure_ltr`: Whether the paragraph contains only LTR content
  #
  # This matches the Rust `ParagraphBidiInfo<'text>` struct.
  struct ParagraphBidiInfo
    property text : String
    property original_classes : Array(BidiClass)
    property levels : Array(Level)
    property paragraph_level : Level
    property is_pure_ltr : Bool

    def initialize(@text : String, @original_classes : Array(BidiClass), @levels : Array(Level), @paragraph_level : Level, @is_pure_ltr : Bool)
    end

    # Creates a new `ParagraphBidiInfo` by analyzing single-paragraph text
    #
    # Parameters:
    # - `text`: The UTF-8 text to analyze (should be a single paragraph)
    # - `default_para_level`: Optional base paragraph level (nil for auto-detection)
    #
    # Returns: `ParagraphBidiInfo` with analysis results
    def self.new(text : String, default_para_level : Level? = nil) : ParagraphBidiInfo
      new_with_data_source(HardcodedBidiData.new, text, default_para_level)
    end

    # Creates a new `ParagraphBidiInfo` with a custom data source
    #
    # Lower-level constructor for custom Unicode data sources.
    # Most users should use `ParagraphBidiInfo.new()` instead.
    #
    # Parameters:
    # - `data_source`: Custom `BidiDataSource` for bidi class lookups
    # - `text`: The UTF-8 text to analyze
    # - `default_para_level`: Optional base paragraph level
    #
    # Returns: `ParagraphBidiInfo` with analysis results
    def self.new_with_data_source(data_source : BidiDataSource, text : String, default_para_level : Level? = nil) : ParagraphBidiInfo
      original_classes = [] of BidiClass
      para_level = default_para_level
      is_pure_ltr = true
      has_isolate_controls = false
      i = 0
      text.each_char do |c|
        bidi_class = data_source.bidi_class(c)
        char_len = c.bytesize
        char_len.times { original_classes << bidi_class }

        case bidi_class
        when BidiClass::L, BidiClass::R, BidiClass::AL
          if bidi_class != BidiClass::L
            is_pure_ltr = false
          end
          if para_level.nil?
            para_level = bidi_class == BidiClass::L ? Level.ltr : Level.rtl
          end
        when BidiClass::AN, BidiClass::LRE, BidiClass::RLE, BidiClass::LRO, BidiClass::RLO
          is_pure_ltr = false
        when BidiClass::RLI, BidiClass::LRI, BidiClass::FSI
          is_pure_ltr = false
          has_isolate_controls = true
        end
        i += char_len
      end

      paragraph_level = para_level || Level.ltr
      levels = Array(Level).new(text.bytesize, paragraph_level)

      if paragraph_level.ltr? && is_pure_ltr
        return ParagraphBidiInfo.new(text, original_classes, levels, paragraph_level, is_pure_ltr)
      end

      processing_classes = original_classes.dup

      Bidi.compute_explicit(text, paragraph_level, original_classes, levels, processing_classes, [] of LevelRun, 0, text.bytesize)

      sequences = [] of Bidi::IsolatingRunSequence
      Bidi.isolating_run_sequences(paragraph_level, original_classes, levels, [] of LevelRun, has_isolate_controls, sequences, 0)

      sequences.each do |sequence|
        Bidi.resolve_weak(text, sequence, processing_classes, 0)
        Bidi.resolve_neutral(data_source, text, sequence, levels, original_classes, processing_classes)
      end

      Bidi.resolve_levels(processing_classes, levels, 0, text.bytesize)

      assign_levels_to_removed_chars(paragraph_level, original_classes, levels)

      ParagraphBidiInfo.new(text, original_classes, levels, paragraph_level, is_pure_ltr)
    end

    def reordered_levels(line : Range(Int32, Int32)) : Array(Level)
      # Apply L1-L2 rules to the levels
      reordered_levels_impl(line)
    end

    private def reordered_levels_impl(line : Range(Int32, Int32)) : Array(Level)
      # Create a copy of the levels for the line
      levels = @levels[line].dup

      # Apply L1 rule: Reset whitespace and some formatting characters to paragraph level
      # http://www.unicode.org/reports/tr9/#L1
      reset_from = nil.as(Int32?)
      reset_to = nil.as(Int32?)
      prev_level = @paragraph_level

      # We need to iterate by character, not by byte
      # Track byte position manually
      byte_pos = line.begin
      @text.byte_slice(line.begin, line.end - line.begin).each_char do |char|
        char_len = char.bytesize

        case @original_classes[byte_pos]
        when BidiClass::B, BidiClass::S
          # Segment separator, Paragraph separator
          reset_to = byte_pos + char_len
          reset_from = byte_pos if reset_from.nil?
        when BidiClass::WS, BidiClass::FSI, BidiClass::LRI, BidiClass::RLI, BidiClass::PDI
          # Whitespace, isolate formatting
          reset_from = byte_pos if reset_from.nil?
        when BidiClass::RLE, BidiClass::LRE, BidiClass::RLO, BidiClass::LRO, BidiClass::PDF, BidiClass::BN
          # Explicit formatting characters
          reset_from = byte_pos if reset_from.nil?
          # Set the level to previous level
          char_len.times do |i|
            levels[byte_pos - line.begin + i] = prev_level
          end
        else
          reset_from = nil
        end

        # Apply reset if we have both from and to
        if !reset_from.nil? && !reset_to.nil?
          (reset_from...reset_to).each do |i|
            if i >= line.begin && i < line.end
              levels[i - line.begin] = @paragraph_level
            end
          end
          reset_from = nil
          reset_to = nil
        end

        prev_level = levels[byte_pos - line.begin] if byte_pos - line.begin < levels.size
        byte_pos += char_len
      end

      # Apply any remaining reset
      if !reset_from.nil?
        (reset_from...line.end).each do |i|
          if i < line.end
            levels[i - line.begin] = @paragraph_level
          end
        end
      end

      levels
    end

    def reordered_levels_per_char(line : Range(Int32, Int32)) : Array(Level)
      reordered_levels(line)
    end

    def reorder_line(line : Range(Int32, Int32)) : String
      return text.byte_slice(line.begin, line.end - line.begin) if !has_rtl?
      levels = reordered_levels(line)
      _, runs = visual_runs(line)
      reorder_line_impl(text, line, levels, runs)
    end

    def self.reorder_visual(levels : Array(Level)) : Array(Int32)
      BidiInfo.reorder_visual(levels)
    end

    def visual_runs(line : Range(Int32, Int32)) : Tuple(Array(Level), Array(Range(Int32, Int32)))
      # Get reordered levels for the line
      levels = reordered_levels(line)

      # Find consecutive level runs
      runs = [] of Range(Int32, Int32)
      return {levels, runs} if levels.empty?

      start = line.begin
      run_level = levels[0]
      min_level = run_level
      max_level = run_level

      (line.begin + 1...line.end).each do |i|
        level_idx = i - line.begin
        new_level = levels[level_idx]

        if new_level != run_level
          runs << (start...i)
          start = i
          run_level = new_level
        end

        if new_level.value < min_level.value
          min_level = new_level
        elsif new_level.value > max_level.value
          max_level = new_level
        end
      end

      runs << (start...line.end)

      # Reorder runs according to L2 rule
      max_level_val = max_level.value
      while max_level_val > 0
        seq_start = 0
        while seq_start < runs.size
          # Skip runs at lower levels
          level_at_start = levels[runs[seq_start].begin - line.begin]?
          if level_at_start.nil? || level_at_start.value < max_level_val
            seq_start += 1
            next
          end

          # Find sequence of runs at this level or higher
          seq_end = seq_start + 1
          while seq_end < runs.size
            level_at_end = levels[runs[seq_end].begin - line.begin]?
            break if level_at_end.nil? || level_at_end.value < max_level_val
            seq_end += 1
          end

          # Reverse the sequence
          runs[seq_start...seq_end].reverse!
          seq_start = seq_end
        end

        max_level_val = max_level_val == 0 ? 0 : max_level_val - 1
      end

      {levels, runs}
    end

    def has_rtl? : Bool
      !is_pure_ltr
    end

    def direction : Direction
      return Direction::Ltr if is_pure_ltr

      ltr = false
      rtl = false
      @levels.each do |level|
        if level.ltr?
          ltr = true
          return Direction::Mixed if rtl
        end
        if level.rtl?
          rtl = true
          return Direction::Mixed if ltr
        end
      end
      return Direction::Ltr if ltr
      Direction::Rtl
    end

    private def self.assign_levels_to_removed_chars(para_level : Level, original_classes : Array(BidiClass), levels : Array(Level)) : Nil
      original_classes.size.times do |i|
        bidi_class = original_classes[i]
        if bidi_class.removed_by_x9?
          levels[i] = if i > 0
                        levels[i - 1]
                      else
                        para_level
                      end
        end
      end
    end

    private def assign_levels_to_removed_chars(para_level : Level, original_classes : Array(BidiClass), levels : Array(Level)) : Nil
      self.class.assign_levels_to_removed_chars(para_level, original_classes, levels)
    end

    private def reorder_line_impl(text : String, line : Range(Int32, Int32), levels : Array(Level), runs : Array(Range(Int32, Int32))) : String
      return text.byte_slice(line.begin, line.end - line.begin) if runs.empty? || runs.all? { |run| level = levels[run.begin - line.begin]?; level && level.ltr? }

      String.build(line.end - line.begin) do |result|
        runs.each do |run|
          run_text = text.byte_slice(run.begin, run.end - run.begin)
          level = levels[run.begin - line.begin]?
          if level && level.rtl?
            run_text.chars.reverse_each { |c| result << c }
          else
            result << run_text
          end
        end
      end
    end
  end
end
