# Basic parser for Type 4 functions which is used to build up instruction sequences.
require "./parser"
require "./instruction_sequence"

module Pdfbox::Pdmodel::Common::Function::Type4
  class InstructionSequenceBuilder < Parser::AbstractSyntaxHandler
    @main_sequence = InstructionSequence.new
    @seq_stack = [] of InstructionSequence

    def initialize
      @seq_stack.push(@main_sequence)
    end

    # Returns the instruction sequence that has been build from the syntactic elements.
    def instruction_sequence : InstructionSequence
      @main_sequence
    end

    # Parses the given text into an instruction sequence representing a Type 4 function
    # that can be executed.
    def self.parse(text : String) : InstructionSequence
      builder = new
      Parser.parse(text, builder)
      builder.instruction_sequence
    end

    private def get_current_sequence : InstructionSequence
      @seq_stack.last
    end

    def token(text : String) : Nil
      token_internal(text)
    end

    private def token_internal(token : String) : Nil
      if token == "{"
        child = InstructionSequence.new
        get_current_sequence.add_proc(child)
        @seq_stack.push(child)
      elsif token == "}"
        @seq_stack.pop
      else
        if matches_integer?(token)
          get_current_sequence.add_integer(parse_int(token))
          return
        end

        if matches_real?(token)
          get_current_sequence.add_real(parse_real(token))
          return
        end

        # TODO: Maybe implement radix numbers, such as 8#1777 or 16#FFFE

        get_current_sequence.add_name(token)
      end
    end

    private def matches_integer?(token : String) : Bool
      # Pattern: [+-]?\d+
      return false if token.empty?

      i = 0
      if token[0] == '+' || token[0] == '-'
        i += 1
        return false if i >= token.size
      end

      while i < token.size
        return false unless token[i].ascii_number?
        i += 1
      end
      true
    end

    private def matches_real?(token : String) : Bool
      # Pattern: -?\d*\.\d*([Ee]-?\d+)?
      # Simplified implementation for now

      token.to_f32
      true
    rescue
      false
    end

    # Parses a value of type "int".
    def self.parse_int(token : String) : Int32
      token.to_i32
    end

    private def parse_int(token : String) : Int32
      self.class.parse_int(token)
    end

    # Parses a value of type "real".
    def self.parse_real(token : String) : Float32
      token.to_f32
    end

    private def parse_real(token : String) : Float32
      self.class.parse_real(token)
    end
  end
end
