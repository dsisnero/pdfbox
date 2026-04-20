require "../../src/pdfbox/pdmodel/common/function/type4/instruction_sequence_builder"
require "../../src/pdfbox/pdmodel/common/function/type4/execution_context"
require "../../src/pdfbox/pdmodel/common/function/type4/operators"

module Spec::Helpers
  # Testing helper class for testing type 4 functions from the PDF specification.
  # Ported from Apache PDFBox's Type4Tester.java.
  class Type4Tester
    @context : Pdfbox::Pdmodel::Common::Function::Type4::ExecutionContext

    # Creates a new instance for the given type 4 function.
    # @param text the text of the type 4 function
    # @return the tester instance
    def self.create(text : String) : Type4Tester
      instructions = Pdfbox::Pdmodel::Common::Function::Type4::InstructionSequenceBuilder.parse(text)
      operators = Pdfbox::Pdmodel::Common::Function::Type4::Operators.new
      context = Pdfbox::Pdmodel::Common::Function::Type4::ExecutionContext.new(operators)
      instructions.execute(context)
      new(context)
    end

    private def initialize(context : Pdfbox::Pdmodel::Common::Function::Type4::ExecutionContext)
      @context = context
    end

    # Pops a bool value from the stack and checks it against the expected result.
    # @param expected the expected bool value
    # @return this instance
    def pop(expected : Bool) : Type4Tester
      value = @context.stack.pop
      unless value.is_a?(Bool)
        raise "Expected Bool, got #{value.class}"
      end
      value.should eq expected
      self
    end

    # Pops a real value from the stack and checks it against the expected result.
    # @param expected the expected real value
    # @return this instance
    def pop_real(expected : Float32) : Type4Tester
      pop_real(expected, 0.0000001_f32)
    end

    # Pops a real value from the stack and checks it against the expected result.
    # @param expected the expected real value
    # @param delta the allowed deviation of the value from the expected result
    # @return this instance
    def pop_real(expected : Float32, delta : Float32) : Type4Tester
      value = @context.stack.pop
      unless value.is_a?(Float32)
        raise "Expected Float32, got #{value.class}"
      end
      value.should be_close(expected, delta)
      self
    end

    # Pops an int value from the stack and checks it against the expected result.
    # @param expected the expected int value
    # @return this instance
    def pop(expected : Int32) : Type4Tester
      value = @context.stack.pop
      unless value.is_a?(Int32)
        raise "Expected Int32, got #{value.class}"
      end
      value.should eq expected
      self
    end

    # Pops a numeric value from the stack and checks it against the expected result.
    # @param expected the expected numeric value (Float32)
    # @return this instance
    def pop(expected : Float32) : Type4Tester
      pop(expected, 0.0000001_f32)
    end

    # Pops a numeric value from the stack and checks it against the expected result.
    # @param expected the expected numeric value (Float32)
    # @param delta the allowed deviation of the value from the expected result
    # @return this instance
    def pop(expected : Float32, delta : Float32) : Type4Tester
      value = @context.stack.pop
      case value
      when Int32
        value.to_f32.should be_close(expected, delta)
      when Float32
        value.should be_close(expected, delta)
      else
        raise "Expected numeric (Int32 or Float32), got #{value.class}"
      end
      self
    end

    # Checks that the stack is empty at this point.
    # @return this instance
    def empty? : Type4Tester
      @context.stack.empty?.should be_true
      self
    end

    # Alias for empty?
    def empty : Type4Tester
      empty?
    end

    # Returns the execution context so some custom checks can be performed.
    # @return the associated execution context
    def to_execution_context : Pdfbox::Pdmodel::Common::Function::Type4::ExecutionContext
      @context
    end
  end
end
