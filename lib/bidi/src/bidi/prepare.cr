# 3.3.3 Preparations for Implicit Processing
#
# <http://www.unicode.org/reports/tr9/#Preparations_for_Implicit_Processing>

module Bidi
  # A maximal substring of characters with the same embedding level.
  #
  # Represented as a range of byte indices.
  alias LevelRun = Range(Int32, Int32)

  # Output of `isolating_run_sequences` (steps X9-X10)
  struct IsolatingRunSequence
    property runs : Array(LevelRun)
    property sos : BidiClass # Start-of-sequence type.
    property eos : BidiClass # End-of-sequence type.

    def initialize(@runs : Array(LevelRun), @sos : BidiClass, @eos : BidiClass)
    end

    # Given a text-relative position `pos` and an index of the level run it is in,
    # produce an iterator of all characters after and pos (`pos..`) that are in this
    # run sequence
    def iter_forwards_from(pos : Int32, level_run_index : Int32) : Iterator(Int32)
      ForwardIterator.new(self, pos, level_run_index)
    end

    # Given a text-relative position `pos` and an index of the level run it is in,
    # produce an iterator of all characters before pos (`..pos`) that are in this
    # run sequence
    def iter_backwards_from(pos : Int32, level_run_index : Int32) : Iterator(Int32)
      BackwardIterator.new(self, pos, level_run_index)
    end

    private class ForwardIterator
      include Iterator(Int32)

      @sequence : IsolatingRunSequence
      @pos : Int32
      @run_index : Int32
      @current_run : Range(Int32, Int32)?
      @current_idx : Int32

      def initialize(sequence : IsolatingRunSequence, pos : Int32, run_index : Int32)
        @sequence = sequence
        @pos = pos
        @run_index = run_index
        @current_run = nil
        @current_idx = 0
      end

      def next
        # Get or advance to next run
        unless run = @current_run
          return stop if @run_index >= @sequence.runs.size

          run = @sequence.runs[@run_index]
          start_idx = (run.begin > @pos) ? run.begin : @pos
          @current_run = run
          @current_idx = start_idx
          @run_index += 1
        end

        # Return current index and advance
        if @current_idx < run.end
          value = @current_idx
          @current_idx += 1
          value
        else
          # Move to next run
          @current_run = nil
          self.next
        end
      end
    end

    private class BackwardIterator
      include Iterator(Int32)

      @sequence : IsolatingRunSequence
      @pos : Int32
      @run_index : Int32
      @current_run : Range(Int32, Int32)?
      @current_idx : Int32

      def initialize(sequence : IsolatingRunSequence, pos : Int32, run_index : Int32)
        @sequence = sequence
        @pos = pos
        @run_index = run_index
        @current_run = nil
        @current_idx = 0
      end

      def next
        # Get or advance to next run
        unless run = @current_run
          return stop if @run_index < 0

          run = @sequence.runs[@run_index]
          end_idx = (run.end < @pos) ? run.end : @pos
          @current_run = run
          @current_idx = end_idx - 1
          @run_index -= 1
        end

        # Return current index and advance backward
        if @current_idx >= run.begin
          value = @current_idx
          @current_idx -= 1
          value
        else
          # Move to previous run
          @current_run = nil
          self.next
        end
      end
    end
  end

  # Should this character be ignored in steps after X9?
  #
  # <http://www.unicode.org/reports/tr9/#X9>
  def self.removed_by_x9(bidi_class : BidiClass) : Bool
    bidi_class.removed_by_x9?
  end

  # For use as a predicate for `position` / `rposition`
  def self.not_removed_by_x9(bidi_class : BidiClass) : Bool
    bidi_class.not_removed_by_x9?
  end

  # Find the level runs in a paragraph.
  #
  # This is step X9 of the algorithm.
  def self.level_runs(
    levels : Array(Level),
    original_classes : Array(BidiClass),
  ) : Array(LevelRun)
    raise "Arrays must have same length" unless levels.size == original_classes.size

    runs = [] of LevelRun
    return runs if levels.empty?

    current_run_level = levels[0]
    current_run_start = 0

    (1...levels.size).each do |i|
      if !original_classes[i].removed_by_x9? && levels[i] != current_run_level
        # End the last run and start a new one.
        runs << (current_run_start...i)
        current_run_level = levels[i]
        current_run_start = i
      end
    end

    runs << (current_run_start...levels.size)
    runs
  end

  # Compute the set of isolating run sequences.
  #
  # An isolating run sequence is a maximal sequence of level runs such that for all level runs
  # except the last one in the sequence, the last character of the run is an isolate initiator
  # whose matching PDI is the first character of the next level run in the sequence.
  #
  # Note: This function does *not* return the sequences in order by their first characters.
  def self.isolating_run_sequences(
    para_level : Level,
    original_classes : Array(BidiClass),
    levels : Array(Level),
    runs : Array(LevelRun),
    has_isolate_controls : Bool,
    isolating_run_sequences : Array(IsolatingRunSequence),
    start : Int32 = 0,
  ) : Nil
    isolating_run_sequences.clear

    # Per http://www.unicode.org/reports/tr9/#BD13:
    # "In the absence of isolate initiators, each isolating run sequence in a paragraph
    #  consists of exactly one level run, and each level run constitutes a separate
    #  isolating run sequence."
    # We can take a simplified path to handle this case.
    if !has_isolate_controls
      runs.each do |run|
        next if run.begin >= run.end  # Skip empty runs
        # Determine the `sos` and `eos` class for the sequence.
        # <http://www.unicode.org/reports/tr9/#X10>

        # Find first non-removed character in run (without slicing)
        seq_level_idx = nil
        seq_level = para_level
        (run.begin...run.end).each do |i|
          if original_classes[i].not_removed_by_x9?
            seq_level_idx = i
            seq_level = levels[i]
            break
          end
        end
        seq_level = levels[run.begin] if seq_level_idx.nil? && run.begin < levels.size

        # Find last non-removed character in run (without slicing)
        end_level_idx = nil
        end_level = para_level
        (run.end - 1).downto(run.begin) do |i|
          if original_classes[i].not_removed_by_x9?
            end_level_idx = i
            end_level = levels[i]
            break
          end
        end
        end_level = levels[run.end - 1] if end_level_idx.nil? && run.end > 0 && run.end - 1 < levels.size

        # Get the level of the last non-removed char before the run.
        pred_level = if run.begin > 0
                       idx = nil
                       (run.begin - 1).downto(0) do |i|
                         if original_classes[i].not_removed_by_x9?
                           idx = i
                           break
                         end
                       end
                       idx ? levels[idx] : para_level
                     else
                       para_level
                     end

        # Get the level of the next non-removed char after the run.
        succ_level = if run.end < original_classes.size
                       idx = nil
                       (run.end...original_classes.size).each do |i|
                         if original_classes[i].not_removed_by_x9?
                           idx = i
                           break
                         end
                       end
                       idx ? levels[idx] : para_level
                     else
                       para_level
                     end

        isolating_run_sequences << IsolatingRunSequence.new(
          runs: [run],
          sos: Level.max(seq_level, pred_level).bidi_class,
          eos: Level.max(end_level, succ_level).bidi_class
        )
      end
      return
    end

    # Compute the set of isolating run sequences.
    # <http://www.unicode.org/reports/tr9/#BD13>
    sequences = [] of Array(LevelRun)

    # When we encounter an isolate initiator, we push the current sequence onto the
    # stack so we can resume it after the matching PDI.
    stack = [[] of LevelRun]

    runs.each do |run|
      next if run.begin >= run.end  # Skip empty runs
      raise "Empty stack" if stack.empty?

      start_class = original_classes[run.begin]
      # > In rule X10, [..] skip over any BNs when [..].
      # > Do the same when determining if the last character of the sequence is an isolate initiator.
      #
      # <https://www.unicode.org/reports/tr9/#Retaining_Explicit_Formatting_Characters>
      end_class = start_class
      (run.end - 1).downto(run.begin) do |i|
        if original_classes[i].not_removed_by_x9?
          end_class = original_classes[i]
          break
        end
      end

      sequence = if start_class == BidiClass::PDI && stack.size > 1
                   # Continue a previous sequence interrupted by an isolate.
                   stack.pop
                 else
                   # Start a new sequence.
                   [] of LevelRun
                 end

      sequence << run

      if end_class == BidiClass::RLI || end_class == BidiClass::LRI || end_class == BidiClass::FSI
        # Resume this sequence after the isolate.
        stack << sequence
      else
        # This sequence is finished.
        sequences << sequence
      end
    end

    # Pop any remaining sequences off the stack.
    stack.reverse_each do |seq|
      sequences << seq unless seq.empty?
    end

    # Determine the `sos` and `eos` class for each sequence.
    # <http://www.unicode.org/reports/tr9/#X10>
    sequences.each do |sequence|
      raise "Empty sequence" if sequence.empty?

      start_of_seq = sequence[0].begin
      runs_len = sequence.size
      end_of_seq = sequence[runs_len - 1].end

      # Create a temporary IsolatingRunSequence for iteration
      temp_irs = IsolatingRunSequence.new(sequence, BidiClass::L, BidiClass::L)

      # > (not counting characters removed by X9)
      seq_level_idx = temp_irs.iter_forwards_from(start_of_seq, 0).find do |i|
        original_classes[i].not_removed_by_x9?
      end
      seq_level = if seq_level_idx
                    levels[seq_level_idx]
                  else
                    levels[start_of_seq]
                  end

      # XXXManishearth the spec talks of a start and end level,
      # but for a given IRS the two should be equivalent, yes?
      end_level_idx = temp_irs.iter_backwards_from(end_of_seq, runs_len - 1).find do |i|
        original_classes[i].not_removed_by_x9?
      end
      end_level = if end_level_idx
                    levels[end_level_idx]
                  else
                    levels[end_of_seq - 1]
                  end

      # Get the level of the last non-removed char before the runs.
      pred_level = if start_of_seq > 0
                     idx = nil
                     (start_of_seq - 1).downto(0) do |i|
                       if original_classes[i].not_removed_by_x9?
                         idx = i
                         break
                       end
                     end
                     idx ? levels[idx] : para_level
                   else
                     para_level
                   end

      # Get the last non-removed character to check if it is an isolate initiator.
      # The spec calls for an unmatched one, but matched isolate initiators
      # will never be at the end of a level run (otherwise there would be more to the run).
      # We unwrap_or(BN) because BN marks removed classes and it won't matter for the check.
      last_non_removed = BidiClass::BN
      (end_of_seq - 1).downto(0) do |i|
        if original_classes[i].not_removed_by_x9?
          last_non_removed = original_classes[i]
          break
        end
      end

      # Get the level of the next non-removed char after the runs.
      succ_level = if last_non_removed == BidiClass::RLI || last_non_removed == BidiClass::LRI || last_non_removed == BidiClass::FSI
                     para_level
                   else
                     if end_of_seq < original_classes.size
                       idx = nil
                       (end_of_seq...original_classes.size).each do |i|
                         if original_classes[i].not_removed_by_x9?
                           idx = i
                           break
                         end
                       end
                       idx ? levels[idx] : para_level
                     else
                       para_level
                     end
                   end

      isolating_run_sequences << IsolatingRunSequence.new(
        runs: sequence,
        sos: Level.max(seq_level, pred_level).bidi_class,
        eos: Level.max(end_level, succ_level).bidi_class
      )
    end
  end
end
