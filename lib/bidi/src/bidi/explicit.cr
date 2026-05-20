# 3.3.2 Explicit Levels and Directions
#
# <http://www.unicode.org/reports/tr9/#Explicit_Levels_and_Directions>

module Bidi
  # Status of the directional status stack
  struct Status
    property level : Level
    property status : OverrideStatus

    def initialize(@level : Level, @status : OverrideStatus)
    end
  end

  # Override status for the directional status stack
  enum OverrideStatus
    Neutral
    RTL
    LTR
    Isolate
  end

  # Compute explicit embedding levels for one paragraph of text (X1-X8), and identify
  # level runs (BD7) for use when determining Isolating Run Sequences (X10).
  #
  # `processing_classes[i]` must contain the `BidiClass` of the char at byte index `i`,
  # for each char in `text`.
  #
  # `runs` returns the list of level runs (BD7) of the text.
  def self.compute_explicit(
    text : String,
    para_level : Level,
    original_classes : Array(BidiClass),
    levels : Array(Level),
    processing_classes : Array(BidiClass),
    runs : Array(LevelRun),
    start : Int32 = 0,
    size : Int32? = nil,
  ) : Nil
    actual_size = size || text.bytesize
    raise "Text length mismatch" unless actual_size == (size || original_classes.size - start)

    # <http://www.unicode.org/reports/tr9/#X1>
    stack = [Status.new(para_level, OverrideStatus::Neutral)]

    overflow_isolate_count = 0_u32
    overflow_embedding_count = 0_u32
    valid_isolate_count = 0_u32

    current_run_level = Level.ltr
    current_run_start = 0
    prev_byte_index = 0

    # Iterate through characters with their byte indices
    TextSource.each_char_with_index(text) do |rel_byte_index, _char, char_len|
      abs_byte_index = start + rel_byte_index
      last = stack.last

      case original_classes[abs_byte_index]
      when BidiClass::RLE, BidiClass::LRE, BidiClass::RLO, BidiClass::LRO, BidiClass::RLI, BidiClass::LRI, BidiClass::FSI
        # Rules X2-X5c
        # <https://www.unicode.org/reports/tr9/#Retaining_Explicit_Formatting_Characters>
        levels[abs_byte_index] = last.level

        # X5a-X5c: Isolate initiators get the level of the last entry on the stack.
        is_isolate = original_classes[abs_byte_index] == BidiClass::RLI || original_classes[abs_byte_index] == BidiClass::LRI || original_classes[abs_byte_index] == BidiClass::FSI
        if is_isolate
          case last.status
          when OverrideStatus::RTL
            processing_classes[abs_byte_index] = BidiClass::R
          when OverrideStatus::LTR
            processing_classes[abs_byte_index] = BidiClass::L
          else
            # Keep original
          end
        end

        new_level_result = if Bidi.rtl?(original_classes[abs_byte_index])
                             last.level.new_explicit_next_rtl
                           else
                             last.level.new_explicit_next_ltr
                           end

        if new_level_result.is_a?(Level) && overflow_isolate_count == 0 && overflow_embedding_count == 0
          new_level = new_level_result.as(Level)
          stack << Status.new(
            new_level,
            case original_classes[abs_byte_index]
            when BidiClass::RLO
              OverrideStatus::RTL
            when BidiClass::LRO
              OverrideStatus::LTR
            when BidiClass::RLI, BidiClass::LRI, BidiClass::FSI
              OverrideStatus::Isolate
            else
              OverrideStatus::Neutral
            end
          )

          if is_isolate
            valid_isolate_count += 1
          else
            # The spec doesn't explicitly mention this step, but it is necessary.
            # See the reference implementations for comparison.
            levels[abs_byte_index] = new_level
          end
        elsif is_isolate
          overflow_isolate_count += 1
        elsif overflow_isolate_count == 0
          overflow_embedding_count += 1
        end

        unless is_isolate
          # X9 +
          # <https://www.unicode.org/reports/tr9/#Retaining_Explicit_Formatting_Characters>
          # (PDF handled below)
          processing_classes[abs_byte_index] = BidiClass::BN
        end
      when BidiClass::PDI
        # <http://www.unicode.org/reports/tr9/#X6a>
        if overflow_isolate_count > 0
          overflow_isolate_count -= 1
        elsif valid_isolate_count > 0
          overflow_embedding_count = 0

          # Pop until we find an isolate or empty stack
          loop do
            popped = stack.pop?
            break if popped.nil? || popped.status == OverrideStatus::Isolate
          end

          valid_isolate_count -= 1
        end

        last = stack.last
        levels[abs_byte_index] = last.level

        case last.status
        when OverrideStatus::RTL
          processing_classes[abs_byte_index] = BidiClass::R
        when OverrideStatus::LTR
          processing_classes[abs_byte_index] = BidiClass::L
        else
          # Keep original
        end
      when BidiClass::PDF
        # <http://www.unicode.org/reports/tr9/#X7>
        if overflow_isolate_count > 0
          # do nothing
        elsif overflow_embedding_count > 0
          overflow_embedding_count -= 1
        elsif last.status != OverrideStatus::Isolate && stack.size >= 2
          stack.pop
        end

        # <https://www.unicode.org/reports/tr9/#Retaining_Explicit_Formatting_Characters>
        levels[abs_byte_index] = stack.last.level
        # X9 part of retaining explicit formatting characters.
        processing_classes[abs_byte_index] = BidiClass::BN
      when BidiClass::B
        # Nothing.
        # BN case moved down to X6, see <https://www.unicode.org/reports/tr9/#Retaining_Explicit_Formatting_Characters>

      else
        # <http://www.unicode.org/reports/tr9/#X6>
        levels[abs_byte_index] = last.level

        # This condition is not in the spec, but I am pretty sure that is a spec bug.
        # https://www.unicode.org/L2/L2023/23014-amd-to-uax9.pdf
        if original_classes[abs_byte_index] != BidiClass::BN
          case last.status
          when OverrideStatus::RTL
            processing_classes[abs_byte_index] = BidiClass::R
          when OverrideStatus::LTR
            processing_classes[abs_byte_index] = BidiClass::L
          else
            # Keep original
          end
        end
      end

      # Handle multi-byte characters - copy level and class to remaining bytes
      (1...char_len).each do |j|
        levels[abs_byte_index + j] = levels[abs_byte_index]
        processing_classes[abs_byte_index + j] = processing_classes[abs_byte_index]
      end

      # Track level runs (BD7) - match Rust: only split at non-removed chars
      # <http://www.unicode.org/reports/tr9/#BD7>
      if rel_byte_index == 0
        current_run_level = levels[abs_byte_index]
      elsif !original_classes[abs_byte_index].removed_by_x9? && levels[abs_byte_index] != current_run_level
        if current_run_start < rel_byte_index
          runs << LevelRun.new(start + current_run_start, start + rel_byte_index - 1)
        end
        current_run_level = levels[abs_byte_index]
        current_run_start = rel_byte_index
      end

      prev_byte_index = rel_byte_index
    end

    # Add final run (inclusive end, matching existing pipeline convention)
    if current_run_start < actual_size
      runs << LevelRun.new(start + current_run_start, start + actual_size - 1)
    end
  end
end
