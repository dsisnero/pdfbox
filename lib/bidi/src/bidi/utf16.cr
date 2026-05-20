# UTF-16 text support for the Unicode Bidirectional Algorithm
#
# This module provides UTF-16 variants of the bidi analysis APIs,
# operating on `Array(UInt16)` instead of `String`. It handles
# surrogate pairs (0xD800-0xDFFF) correctly when reversing text.
#
# The API mirrors the UTF-8 APIs in `Bidi` module but with UTF-16
# specific implementations for text processing.
#
# Key components:
# - `UTF16::BidiInfo`: Multi-paragraph analysis for UTF-16 text
# - `UTF16::ParagraphBidiInfo`: Single-paragraph analysis for UTF-16 text
# - `UTF16::TextSource`: Utilities for iterating over UTF-16 arrays
#
# All APIs match the Rust `unicode_bidi::utf16` module exactly.

require "./level"
require "./info"
require "./prepare"
require "./char_data"
require "./data_source"
require "./bidi_info_common"
require "./explicit"
require "./implicit"

module Bidi
  module UTF16
    # Text source utilities for UTF-16 (Array(UInt16))
    #
    # Provides character iteration and access methods for UTF-16 encoded text,
    # with proper handling of surrogate pairs and invalid sequences.
    module TextSource
      # Iterates over characters in a UTF-16 array, handling surrogate pairs
      #
      # Correctly processes:
      # - Single code units (U+0000 to U+D7FF, U+E000 to U+FFFF)
      # - Surrogate pairs (high: 0xD800-0xDBFF, low: 0xDC00-0xDFFF)
      # - Invalid sequences (replaced with U+FFFD REPLACEMENT CHARACTER)
      #
      # Parameters:
      # - `text`: UTF-16 encoded text as `Array(UInt16)`
      # - `&block`: Block to yield each character to
      def self.each_char(text : Array(UInt16), &block : Char ->)
        i = 0
        while i < text.size
          if text[i] < 0xD800 || text[i] > 0xDBFF
            if text[i] < 0xDC00 || text[i] > 0xDFFF
              yield text[i].chr rescue '\uFFFD'
              i += 1
            else
              yield '\uFFFD'
              i += 1
            end
          elsif i + 1 < text.size && text[i + 1] >= 0xDC00 && text[i + 1] <= 0xDFFF
            code = ((text[i].to_i32 - 0xD800) << 10) + (text[i + 1].to_i32 - 0xDC00) + 0x10000
            yield code.chr
            i += 2
          else
            yield '\uFFFD'
            i += 1
          end
        end
      end

      # Get character at index with its length in code units
      def self.char_at(text : Array(UInt16), index : Int32) : Tuple(Char, Int32)?
        return nil if index < 0 || index >= text.size

        # Low surrogate that's part of a valid pair → not a character boundary
        if text[index] >= 0xDC00 && text[index] <= 0xDFFF
          if index > 0 && text[index - 1] >= 0xD800 && text[index - 1] <= 0xDBFF
            return nil
          end
          return {'\uFFFD', 1}
        end

        if text[index] < 0xD800 || text[index] > 0xDBFF
          char = text[index].chr rescue '\uFFFD'
          return {char, 1}
        elsif index + 1 < text.size && text[index + 1] >= 0xDC00 && text[index + 1] <= 0xDFFF
          code = ((text[index].to_i32 - 0xD800) << 10) + (text[index + 1].to_i32 - 0xDC00) + 0x10000
          return {code.chr, 2}
        else
          return {'\uFFFD', 1}
        end
      end

      # Get length in code units (UInt16 elements)
      def self.length(text : Array(UInt16)) : Int32
        text.size
      end

      # Get subrange of UTF-16 array
      def self.subrange(text : Array(UInt16), range : Range(Int32, Int32)) : Array(UInt16)
        text[range]
      end

      # Number of code units a character uses in UTF-16
      def self.char_len(char : Char) : Int32
        char.ord < 0x10000 ? 1 : 2
      end
    end

    # Initial bidi information of the text (UTF-16 version).
    struct InitialInfo
      property text : Array(UInt16)
      property original_classes : Array(BidiClass)
      property paragraphs : Array(ParagraphInfo)

      def initialize(@text : Array(UInt16), @original_classes : Array(BidiClass), @paragraphs : Array(ParagraphInfo))
      end
    end

    private struct ParagraphInfoFlags
      property is_pure_ltr : Bool
      property has_isolate_controls : Bool

      def initialize(@is_pure_ltr : Bool, @has_isolate_controls : Bool)
      end
    end

    struct InitialInfoExt
      property original_classes : Array(BidiClass)
      property paragraphs : Array(ParagraphInfo)
      property flags : Array(ParagraphInfoFlags)

      def initialize(@original_classes : Array(BidiClass), @paragraphs : Array(ParagraphInfo), @flags : Array(ParagraphInfoFlags))
      end

      def self.new_with_data_source(data_source : BidiDataSource, text : Array(UInt16), default_para_level : Level?) : InitialInfoExt
        original_classes = [] of BidiClass
        paragraphs = [] of ParagraphInfo
        flags = [] of ParagraphInfoFlags

        isolate_stack = [] of Int32
        para_start = 0
        para_level = default_para_level
        is_pure_ltr = true
        has_isolate_controls = false

        i = 0
        TextSource.each_char(text) do |c|
          bidi_class = data_source.bidi_class(c)
          char_len = TextSource.char_len(c)

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

        if para_start < text.size
          paragraphs << ParagraphInfo.new(para_start...text.size, para_level || Level.ltr)
          flags << ParagraphInfoFlags.new(is_pure_ltr, has_isolate_controls)
        end

        InitialInfoExt.new(original_classes, paragraphs, flags)
      end
    end

    # Bidi information of the text (UTF-16 version).
    # Main structure for bidirectional analysis of UTF-16 text
    #
    # UTF-16 variant of `Bidi::BidiInfo` that operates on `Array(UInt16)`
    # instead of `String`. Handles surrogate pairs correctly in all operations.
    #
    # Properties:
    # - `text`: The original input text as UTF-16 code units
    # - `original_classes`: BidiClass for each code unit in the text
    # - `levels`: Embedding level for each code unit in the text
    # - `paragraphs`: Information about each paragraph in the text
    #
    # This matches the Rust `BidiInfo<'text>` struct in the `utf16` module.
    struct BidiInfo
      include BidiInfoCommon

      property text : Array(UInt16)
      property original_classes : Array(BidiClass)
      property levels : Array(Level)
      property paragraphs : Array(ParagraphInfo)

      def initialize(@text : Array(UInt16), @original_classes : Array(BidiClass), @levels : Array(Level), @paragraphs : Array(ParagraphInfo))
      end

      # Creates a new `UTF16::BidiInfo` by analyzing UTF-16 text
      #
      # Parameters:
      # - `text`: UTF-16 encoded text as `Array(UInt16)`
      # - `default_para_level`: Optional base paragraph level (nil for auto-detection)
      #
      # Returns: `UTF16::BidiInfo` with analysis results
      def self.new(text : Array(UInt16), default_para_level : Level? = nil) : BidiInfo
        new_with_data_source(HardcodedBidiData.new, text, default_para_level)
      end

      # Creates a new `UTF16::BidiInfo` with a custom data source
      #
      # Lower-level constructor for custom Unicode data sources.
      #
      # Parameters:
      # - `data_source`: Custom `BidiDataSource` for bidi class lookups
      # - `text`: UTF-16 encoded text as `Array(UInt16)`
      # - `default_para_level`: Optional base paragraph level
      #
      # Returns: `UTF16::BidiInfo` with analysis results
      def self.new_with_data_source(data_source : BidiDataSource, text : Array(UInt16), default_para_level : Level? = nil) : BidiInfo
        initial_info = InitialInfoExt.new_with_data_source(data_source, text, default_para_level)

        text_size = text.size
        levels = Array(Level).new(text_size, Level.ltr)
        processing_classes = initial_info.original_classes.dup

        initial_info.paragraphs.each_with_index do |para, idx|
          flags = initial_info.flags[idx]
          compute_bidi_info_for_para_utf16(data_source, para, flags.is_pure_ltr, flags.has_isolate_controls, text, initial_info.original_classes, processing_classes, levels)
        end

        BidiInfo.new(text, initial_info.original_classes, levels, initial_info.paragraphs)
      end

      private def self.compute_bidi_info_for_para_utf16(data_source : BidiDataSource, para : ParagraphInfo, is_pure_ltr : Bool, has_isolate_controls : Bool, text : Array(UInt16), original_classes : Array(BidiClass), processing_classes : Array(BidiClass), levels : Array(Level)) : Nil
        para.range.each do |i|
          levels[i] = para.level
        end

        if para.level.ltr? && is_pure_ltr
          return
        end

        para_text = text[para.range]
        level_runs = [] of LevelRun

        UTF16.compute_explicit_utf16(para_text, para.level, original_classes, levels, processing_classes, level_runs, para.range.begin, para.range.end - para.range.begin)

        sequences = [] of Bidi::IsolatingRunSequence
        Bidi.isolating_run_sequences(para.level, original_classes, levels, level_runs, has_isolate_controls, sequences, para.range.begin)

        sequences.each do |sequence|
          UTF16.resolve_weak_utf16(para_text, sequence, processing_classes, para.range.begin)
          UTF16.resolve_neutral_utf16(data_source, para_text, sequence, levels, original_classes, processing_classes)
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
        para_level = para.level

        # Apply L1 rule: Reset whitespace and some formatting characters to paragraph level
        # http://www.unicode.org/reports/tr9/#L1
        # Match Rust upstream reorder_levels for UTF-16 (utf16.rs:226-238)
        reset_from : Int32? = nil
        reset_to : Int32? = nil
        prev_level = para_level

        # Iterate through code units (each u16 is a code unit)
        i = line.begin
        while i < line.end && i < @text.size
          u16 = @text[i]
          bidi_class = @original_classes[i]

          # Determine code unit length (1 for BMP, 2 for surrogate pairs)
          # Surrogate pairs: high surrogate (0xD800-0xDBFF) followed by low surrogate (0xDC00-0xDFFF)
          is_high_surrogate = u16 >= 0xD800 && u16 <= 0xDBFF
          is_low_surrogate = u16 >= 0xDC00 && u16 <= 0xDFFF
          char_len = is_low_surrogate ? 1 : (is_high_surrogate ? 2 : 1)

          unless is_low_surrogate
            # Process only at character-start positions (skip low surrogates)
            case bidi_class
            when BidiClass::B, BidiClass::S
              reset_to = i + char_len
              reset_from = i if reset_from.nil?
            when BidiClass::WS, BidiClass::FSI, BidiClass::LRI, BidiClass::RLI, BidiClass::PDI
              reset_from = i if reset_from.nil?
            when BidiClass::RLE, BidiClass::LRE, BidiClass::RLO, BidiClass::LRO, BidiClass::PDF, BidiClass::BN
              reset_from = i if reset_from.nil?
              char_len.times do |j|
                level_idx = i + j - line.begin
                line_levels[level_idx] = prev_level if level_idx < line_levels.size
              end
            else
              reset_from = nil
            end

            if !reset_from.nil? && !reset_to.nil?
              (reset_from...reset_to).each do |lidx|
                rel = lidx - line.begin
                line_levels[rel] = para_level if rel >= 0 && rel < line_levels.size
              end
              reset_from = nil
              reset_to = nil
            end

            prev_level = line_levels[i - line.begin] if i - line.begin < line_levels.size
          end

          i += char_len
        end

        if !reset_from.nil?
          (reset_from...line.end).each do |lidx|
            rel = lidx - line.begin
            line_levels[rel] = para_level if rel >= 0 && rel < line_levels.size
          end
        end

        line_levels
      end

      def reordered_levels_per_char(para : ParagraphInfo, line : Range(Int32, Int32)) : Array(Level)
        reordered_levels(para, line)
      end

      # Reorders a line of UTF-16 text for visual display
      #
      # UTF-16 variant of `BidiInfo.reorder_line` that returns `Array(UInt16)`
      # instead of `String`. Handles surrogate pairs correctly when reversing
      # RTL text (preserves high/low surrogate order).
      #
      # Parameters:
      # - `para`: The paragraph containing the line
      # - `line`: Code unit range within the UTF-16 text
      #
      # Returns: Reordered UTF-16 code units as `Array(UInt16)`
      def reorder_line(para : ParagraphInfo, line : Range(Int32, Int32)) : Array(UInt16)
        return [] of UInt16 unless line.begin < line.end
        return @text[line] unless has_rtl?
        levels = reordered_levels(para, line)
        _, runs = visual_runs(para, line)
        do_reorder_line(@text, line, levels, runs)
      end

      def self.reorder_visual(levels : Array(Level)) : Array(Int32)
        BidiInfo.reorder_visual(levels)
      end

      def visual_runs(para : ParagraphInfo, line : Range(Int32, Int32)) : Tuple(Array(Level), Array(Range(Int32, Int32)))
        levels = reordered_levels(para, line)
        compute_visual_runs(levels, line)
      end

      private def compute_visual_runs(levels : Array(Level), line : Range(Int32, Int32)) : Tuple(Array(Level), Array(Range(Int32, Int32)))
        runs = [] of Range(Int32, Int32)
        start = line.begin
        return {levels, runs} if start >= levels.size || start >= line.end

        run_level = levels[start]
        min_level = run_level
        max_level = run_level

        ((start + 1)...line_end).each do |i|
          new_level = levels[i]
          if new_level != run_level
            runs << (start...i)
            start = i
            run_level = new_level
            min_level = Level.new(levels[i].value < min_level.value ? levels[i].value : min_level.value)
            max_level = Level.new(levels[i].value > max_level.value ? levels[i].value : max_level.value)
          end
        end
        runs << (start...line_end)

        {levels, runs}
      end

      private def do_reorder_line(text : Array(UInt16), line : Range(Int32, Int32), levels : Array(Level), runs : Array(Range(Int32, Int32))) : Array(UInt16)
        result = [] of UInt16
        runs.each do |run|
          if l = levels[run.begin]?
            if l.rtl?
              # Reverse the run, handling surrogate pairs correctly
              i = run.end - 1
              while i >= run.begin
                if i > run.begin && text[i] >= 0xDC00 && text[i] <= 0xDFFF &&
                   text[i - 1] >= 0xD800 && text[i - 1] <= 0xDBFF
                  # Surrogate pair: add high then low
                  result << text[i - 1]
                  result << text[i]
                  i -= 2
                else
                  # Single code unit
                  result << text[i]
                  i -= 1
                end
              end
            else
              # LTR: copy as-is
              result.concat(text[run])
            end
          else
            # No level info: copy as-is
            result.concat(text[run])
          end
        end
        result
      end

      private def text_as_string(text : Array(UInt16), line : Range(Int32, Int32)) : String
        String.build do |s|
          i = line.begin
          while i < line.end && i < text.size
            if text[i] < 0xD800 || text[i] > 0xDBFF
              if text[i] < 0xDC00 || text[i] > 0xDFFF
                s << (text[i].chr rescue '\uFFFD')
                i += 1
              else
                s << '\uFFFD'
                i += 1
              end
            elsif i + 1 < line.end && i + 1 < text.size && text[i + 1] >= 0xDC00 && text[i + 1] <= 0xDFFF
              code = ((text[i].to_i32 - 0xD800) << 10) + (text[i + 1].to_i32 - 0xDC00) + 0x10000
              s << code.chr
              i += 2
            else
              s << '\uFFFD'
              i += 1
            end
          end
        end
      end

      private def line_end : Int32
        @levels.size
      end
    end

    struct Paragraph
      property info : BidiInfo
      property para : ParagraphInfo

      def initialize(@info : BidiInfo, @para : ParagraphInfo)
      end

      def direction : Direction
        ltr = false
        rtl = false
        @info.levels[@para.range].each do |level|
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

      def level_at(pos : Int32) : Level
        @info.levels[@para.range.begin + pos]
      end
    end

    # UTF-16 versions of bidi algorithm functions
    def self.compute_explicit_utf16(
      text : Array(UInt16),
      para_level : Level,
      original_classes : Array(BidiClass),
      levels : Array(Level),
      processing_classes : Array(BidiClass),
      runs : Array(LevelRun),
      start : Int32 = 0,
      size : Int32? = nil,
    ) : Nil
      actual_size = size || text.size
      raise "Text length mismatch" unless actual_size == (size || original_classes.size - start)

      # <http://www.unicode.org/reports/tr9/#X1>
      stack = [Status.new(para_level, OverrideStatus::Neutral)]

      overflow_isolate_count = 0_u32
      overflow_embedding_count = 0_u32
      valid_isolate_count = 0_u32

      current_run_level = Level.ltr
      current_run_start = start

      end_pos = start + actual_size
      (start...end_pos).each do |i|
        # Match Rust: use original_classes[i] for the class dispatch
        bidi_class = original_classes[i]

        # X2-X5c: Explicit formatting characters
        # Match Rust explicit.rs:67-123 exactly
        case bidi_class
        when BidiClass::RLE, BidiClass::LRE, BidiClass::RLO, BidiClass::LRO, BidiClass::RLI, BidiClass::LRI, BidiClass::FSI
          # <https://www.unicode.org/reports/tr9/#Retaining_Explicit_Formatting_Characters>
          levels[i] = stack.last.level

          is_isolate = bidi_class == BidiClass::RLI || bidi_class == BidiClass::LRI || bidi_class == BidiClass::FSI
          if is_isolate
            case stack.last.status
            when OverrideStatus::RTL
              processing_classes[i] = BidiClass::R
            when OverrideStatus::LTR
              processing_classes[i] = BidiClass::L
            end
          end

          new_level_result = if bidi_class == BidiClass::RLE || bidi_class == BidiClass::RLO || bidi_class == BidiClass::RLI
                               stack.last.level.new_explicit_next_rtl
                             else
                               stack.last.level.new_explicit_next_ltr
                             end

          if new_level_result.is_a?(Level) && overflow_isolate_count == 0 && overflow_embedding_count == 0
            new_level = new_level_result.as(Level)
            stack << Status.new(new_level,
              case bidi_class
              when BidiClass::RLO       then OverrideStatus::RTL
              when BidiClass::LRO       then OverrideStatus::LTR
              when BidiClass::RLI, BidiClass::LRI, BidiClass::FSI then OverrideStatus::Isolate
              else                           OverrideStatus::Neutral
              end
            )

            if is_isolate
              valid_isolate_count += 1
            else
              levels[i] = new_level
            end
          elsif is_isolate
            overflow_isolate_count += 1
          elsif overflow_isolate_count == 0
            overflow_embedding_count += 1
          end

          unless is_isolate
            processing_classes[i] = BidiClass::BN
          end
        when BidiClass::PDI
          # X6a. PDI — match Rust explicit.rs:126-151
          if overflow_isolate_count > 0
            overflow_isolate_count -= 1
          elsif valid_isolate_count > 0
            overflow_embedding_count = 0
            # Pop until we find the isolate (inclusive)
            loop do
              popped = stack.pop?
              break if popped.nil? || popped.status == OverrideStatus::Isolate
            end
            valid_isolate_count -= 1
          end
          last = stack.last
          levels[i] = last.level
          case last.status
          when OverrideStatus::RTL
            processing_classes[i] = BidiClass::R
          when OverrideStatus::LTR
            processing_classes[i] = BidiClass::L
          end
        when BidiClass::PDF
          # X7. PDF — match Rust explicit.rs:153-167
          if overflow_isolate_count > 0
            # do nothing
          elsif overflow_embedding_count > 0
            overflow_embedding_count -= 1
          elsif stack.last.status != OverrideStatus::Isolate && stack.size >= 2
            stack.pop
          end
          # <https://www.unicode.org/reports/tr9/#Retaining_Explicit_Formatting_Characters>
          levels[i] = stack.last.level
          processing_classes[i] = BidiClass::BN
        when BidiClass::B
          # X8. Nothing for paragraph separator in explicit processing.
          # Paragraphs are split in compute_initial_info.
          # Match Rust explicit.rs:171
        else
          # X6. For all other characters — match Rust explicit.rs:174-186
          levels[i] = stack.last.level
          if original_classes[i] != BidiClass::BN
            case stack.last.status
            when OverrideStatus::RTL
              processing_classes[i] = BidiClass::R
            when OverrideStatus::LTR
              processing_classes[i] = BidiClass::L
            end
          end
        end

        # Track level runs (BD7) — match Rust: skip removed_by_x9 characters
        if i == start
          current_run_level = levels[i]
          current_run_start = i
        elsif !original_classes[i].removed_by_x9? && levels[i] != current_run_level
          runs << (current_run_start...i)
          current_run_level = levels[i]
          current_run_start = i
        end
      end

      # Add final run
      if current_run_start < end_pos
        runs << (current_run_start...end_pos)
      end
    end

    def self.resolve_weak_utf16(
      text : Array(UInt16),
      sequence : Bidi::IsolatingRunSequence,
      processing_classes : Array(BidiClass),
      start : Int32 = 0,
    ) : Nil
      # Same algorithm as Bidi.resolve_weak but with UTF-16 character length semantics.
      # In UTF-16: BMP chars are 1 code unit, surrogate pairs are 2 code units.

      prev_class_before_w4 = sequence.sos
      prev_class_before_w5 = sequence.sos
      prev_class_before_w1 = sequence.sos
      last_strong_is_al = false
      et_run_indices = [] of Int32
      bn_run_indices = [] of Int32

      sequence.runs.each_with_index do |level_run, run_index|
        level_run.each do |i|
          if processing_classes[i] == BidiClass::BN
            bn_run_indices << i
            next
          end

          w2_processing_class = processing_classes[i]

          # W1
          if processing_classes[i] == BidiClass::NSM
            processing_classes[i] = case prev_class_before_w1
                                    when BidiClass::RLI, BidiClass::LRI, BidiClass::FSI, BidiClass::PDI
                                      BidiClass::ON
                                    else
                                      prev_class_before_w1
                                    end
            w2_processing_class = processing_classes[i]
          end

          prev_class_before_w1 = processing_classes[i]

          # W2 and W3
          case processing_classes[i]
          when BidiClass::EN
            if last_strong_is_al
              processing_classes[i] = BidiClass::AN
            end
          when BidiClass::AL
            processing_classes[i] = BidiClass::R
          end

          case w2_processing_class
          when BidiClass::L, BidiClass::R
            last_strong_is_al = w2_processing_class == BidiClass::AL
          end

          # W4/W5/W6 combined (match upstream implicit.rs:116-224)
          class_before_w456 = processing_classes[i]

          case processing_classes[i]
          when BidiClass::EN
            et_run_indices.each { |j| processing_classes[j] = BidiClass::EN }
            et_run_indices.clear
          when BidiClass::ES, BidiClass::CS
            # UTF-16: determine code unit length at position i
            if i < text.size
              u16 = text[i]
              is_high = u16 >= 0xD800 && u16 <= 0xDBFF
              is_low = u16 >= 0xDC00 && u16 <= 0xDFFF
              if is_low
                # Low surrogate — copy from previous code unit
                processing_classes[i] = processing_classes[i - 1]
              else
                char_len = is_high ? 2 : 1
                next_class = sequence.iter_forwards_from(i + char_len, run_index)
                  .map { |j| processing_classes[j] }
                  .find { |c| c.not_removed_by_x9? }
                next_class = next_class || sequence.eos

                if next_class == BidiClass::EN && last_strong_is_al
                  next_class = BidiClass::AN
                end

                processing_classes[i] = case {prev_class_before_w4, processing_classes[i], next_class}
                                        when {BidiClass::EN, BidiClass::ES, BidiClass::EN},
                                             {BidiClass::EN, BidiClass::CS, BidiClass::EN}
                                          BidiClass::EN
                                        when {BidiClass::AN, BidiClass::CS, BidiClass::AN}
                                          BidiClass::AN
                                        else
                                          BidiClass::ON
                                        end

                if processing_classes[i] == BidiClass::ON
                  sequence.iter_backwards_from(i, run_index).each do |idx|
                    break if processing_classes[idx] != BidiClass::BN
                    processing_classes[idx] = BidiClass::ON
                  end
                  sequence.iter_forwards_from(i + char_len, run_index).each do |idx|
                    break if processing_classes[idx] != BidiClass::BN
                    processing_classes[idx] = BidiClass::ON
                  end
                end
              end
            else
              processing_classes[i] = processing_classes[i - 1]
            end
          when BidiClass::ET
            if prev_class_before_w5 == BidiClass::EN
              processing_classes[i] = BidiClass::EN
            else
              et_run_indices.concat(bn_run_indices.dup)
              et_run_indices << i
            end
          end

          bn_run_indices.clear
          prev_class_before_w5 = processing_classes[i]

          if prev_class_before_w5 != BidiClass::ET
            et_run_indices.each { |j| processing_classes[j] = BidiClass::ON }
            et_run_indices.clear
          end

          prev_class_before_w4 = class_before_w456
        end
      end

      # Final W6 check
      et_run_indices.each { |j| processing_classes[j] = BidiClass::ON }
      et_run_indices.clear

      # W7
      last_strong_is_l = sequence.sos == BidiClass::L
      sequence.runs.each do |level_run|
        level_run.each do |i|
          case processing_classes[i]
          when BidiClass::EN
            if last_strong_is_l
              processing_classes[i] = BidiClass::L
            end
          when BidiClass::L
            last_strong_is_l = true
          when BidiClass::R, BidiClass::AL
            last_strong_is_l = false
          end
        end
      end
    end

    def self.resolve_neutral_utf16(
      data_source : BidiDataSource,
      text : Array(UInt16),
      sequence : Bidi::IsolatingRunSequence,
      levels : Array(Level),
      original_classes : Array(BidiClass),
      processing_classes : Array(BidiClass),
    ) : Nil
      # Need UTF-16 specific implementation for bracket matching
      e = levels[sequence.runs[0].begin].bidi_class
      not_e = e == BidiClass::L ? BidiClass::R : BidiClass::L

      # N0. Process bracket pairs.
      bracket_pairs = [] of Bidi::BracketPair
      identify_bracket_pairs_utf16(text, data_source, sequence, processing_classes, bracket_pairs)

      bracket_pairs.each do |pair|
        found_e = false
        found_not_e = false
        class_to_set = nil.as(BidiClass?)

        sequence.iter_forwards_from(pair.start + 1, pair.start_run).each do |enclosed_i|
          break if enclosed_i >= pair.end
          bidi_class = processing_classes[enclosed_i]
          if bidi_class == e
            found_e = true
          elsif bidi_class == not_e
            found_not_e = true
          elsif bidi_class == BidiClass::EN || bidi_class == BidiClass::AN
            if e == BidiClass::L
              found_not_e = true
            else
              found_e = true
            end
          end

          break if found_e
        end

        if found_e
          class_to_set = e
        elsif found_not_e
          class_to_set = not_e
        else
          class_to_set = e
        end

        if class_to_set
          processing_classes[pair.start] = class_to_set
          processing_classes[pair.end] = class_to_set
        end
      end

      # N1-N2: Process neutrals within THIS sequence only
      # Match Rust implicit.rs:429-485 exactly
      index_iter = sequence.runs.flat_map(&.to_a).each
      prev_strong = sequence.sos

      loop do
        i_value = index_iter.next
        break if i_value.is_a?(Iterator::Stop)
        i = i_value.as(Int32)

        bidi_class = processing_classes[i]
        if Bidi.ni?(bidi_class) || bidi_class == BidiClass::BN
          # Collect consecutive NI characters
          ni_run = [i] of Int32
          next_class : BidiClass? = nil

          loop do
            j_value = index_iter.next
            if j_value.is_a?(Iterator::Stop)
              next_class = sequence.eos
              break
            else
              j_idx = j_value.as(Int32)
              next_class = processing_classes[j_idx]
              if Bidi.ni?(next_class) || next_class == BidiClass::BN
                i = j_idx
                ni_run << j_idx
              else
                i = j_idx  # Update i to the non-NI index so outer loop processes it
                break
              end
            end
          end

          # N1-N2 resolution
          new_class = case {prev_strong, next_class}
                      when {BidiClass::L, BidiClass::L}
                        BidiClass::L
                      when {BidiClass::R, BidiClass::R},
                           {BidiClass::R, BidiClass::AN},
                           {BidiClass::R, BidiClass::EN},
                           {BidiClass::AN, BidiClass::R},
                           {BidiClass::AN, BidiClass::AN},
                           {BidiClass::AN, BidiClass::EN},
                           {BidiClass::EN, BidiClass::R},
                           {BidiClass::EN, BidiClass::AN},
                           {BidiClass::EN, BidiClass::EN}
                        BidiClass::R
                      else
                        e
                      end

          ni_run.each { |idx| processing_classes[idx] = new_class }
        end
        prev_strong = processing_classes[i]
      end
    end

    def self.identify_bracket_pairs_utf16(
      text : Array(UInt16),
      data_source : BidiDataSource,
      run_sequence : Bidi::IsolatingRunSequence,
      original_classes : Array(BidiClass),
      bracket_pairs : Array(Bidi::BracketPair),
    ) : Nil
      stack = [] of Tuple(Char, Int32, Int32) # (opening_char, index, run_index)

      run_sequence.runs.each_with_index do |level_run, run_index|
        level_run.each do |i|
          break if i >= text.size

          if original_classes[i] != BidiClass::ON
            next
          end

          # Get character at code unit index i
          char_result = TextSource.char_at(text, i)
          next unless char_result
          ch, _ = char_result

          if matched = data_source.bidi_matched_opening_bracket(ch)
            if matched.is_open
              if stack.size >= 63
                return
              end
              stack.push({matched.opening, i, run_index})
            else
              stack_index = stack.size - 1
              while stack_index >= 0
                element = stack[stack_index]
                if element[0] == matched.opening
                  pair = Bidi::BracketPair.new(
                    element[1],
                    i,
                    element[2],
                    run_index
                  )
                  bracket_pairs.push(pair)
                  stack = stack[0...stack_index]
                  break
                end
                stack_index -= 1
              end
            end
          end
        end
      end

      bracket_pairs.sort_by!(&.start)
    end

    struct ParagraphBidiInfo
      property text : Array(UInt16)
      property original_classes : Array(BidiClass)
      property levels : Array(Level)
      property paragraph_level : Level
      property is_pure_ltr : Bool

      def initialize(@text : Array(UInt16), @original_classes : Array(BidiClass), @levels : Array(Level), @paragraph_level : Level, @is_pure_ltr : Bool)
      end

      def self.new(text : Array(UInt16), default_para_level : Level? = nil) : ParagraphBidiInfo
        new_with_data_source(HardcodedBidiData.new, text, default_para_level)
      end

      def self.new_with_data_source(data_source : BidiDataSource, text : Array(UInt16), default_para_level : Level? = nil) : ParagraphBidiInfo
        original_classes = [] of BidiClass
        para_level = default_para_level
        is_pure_ltr = true
        has_isolate_controls = false

        TextSource.each_char(text) do |c|
          bidi_class = data_source.bidi_class(c)
          char_len = TextSource.char_len(c)

          char_len.times { original_classes << bidi_class }

          case bidi_class
          when BidiClass::L, BidiClass::R, BidiClass::AL
            if bidi_class != BidiClass::L
              is_pure_ltr = false
            end
            para_level = bidi_class == BidiClass::L ? Level.ltr : Level.rtl if para_level.nil?
          when BidiClass::AN, BidiClass::LRE, BidiClass::RLE, BidiClass::LRO, BidiClass::RLO
            is_pure_ltr = false
          when BidiClass::RLI, BidiClass::LRI, BidiClass::FSI
            is_pure_ltr = false
            has_isolate_controls = true
          end
        end

        paragraph_level = para_level || Level.ltr
        levels = Array(Level).new(text.size, paragraph_level)

        if paragraph_level.ltr? && is_pure_ltr
          return ParagraphBidiInfo.new(text, original_classes, levels, paragraph_level, is_pure_ltr)
        end

        ParagraphBidiInfo.new(text, original_classes, levels, paragraph_level, is_pure_ltr)
      end

      def reordered_levels(line : Range(Int32, Int32)) : Array(Level)
        @levels[line]
      end

      def reorder_line(line : Range(Int32, Int32)) : Array(UInt16)
        return @text[line] unless has_rtl?

        levels, runs = visual_runs(line)
        return @text[line] if runs.empty? || runs.all? { |run| level = levels[run.begin - line.begin]?; level && level.ltr? }

        result = [] of UInt16
        runs.each do |run|
          level = levels[run.begin - line.begin]?
          if level && level.rtl?
            # Reverse the run, handling surrogate pairs correctly
            # Collect characters in the run
            chars = [] of Char
            i = run.begin
            while i <= run.end && i < @text.size
              if @text[i] < 0xD800 || @text[i] > 0xDBFF
                if @text[i] < 0xDC00 || @text[i] > 0xDFFF
                  chars << (@text[i].chr rescue '\uFFFD')
                  i += 1
                else
                  chars << '\uFFFD'
                  i += 1
                end
              elsif i + 1 <= run.end && i + 1 < @text.size && @text[i + 1] >= 0xDC00 && @text[i + 1] <= 0xDFFF
                code = ((@text[i].to_i32 - 0xD800) << 10) + (@text[i + 1].to_i32 - 0xDC00) + 0x10000
                chars << code.chr
                i += 2
              else
                chars << '\uFFFD'
                i += 1
              end
            end

            # Add characters in reverse order
            chars.reverse_each do |c|
              if c.ord < 0x10000
                result << c.ord.to_u16
              else
                # Surrogate pair
                code = c.ord - 0x10000
                high = ((code >> 10) & 0x3FF) + 0xD800
                low = (code & 0x3FF) + 0xDC00
                result << high.to_u16
                result << low.to_u16
              end
            end
          else
            result.concat(@text[run])
          end
        end
        result
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
        !@is_pure_ltr
      end

      def direction : Direction
        return Direction::Ltr if @is_pure_ltr
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
    end
  end
end
