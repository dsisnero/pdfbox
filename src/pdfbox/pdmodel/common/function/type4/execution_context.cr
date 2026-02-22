# Makes up the execution context, holding the available operators and the execution stack.
require "./operators"
require "./instruction_sequence"

module Pdfbox::Pdmodel::Common::Function::Type4
  class ExecutionContext
    @stack = [] of String | Int32 | Float32 | Bool | InstructionSequence

    # Creates a new execution context.
    def initialize(@operators : Operators)
    end

    # Returns the stack used by this execution context.
    def stack : Array(String | Int32 | Float32 | Bool | InstructionSequence)
      @stack
    end

    # Returns the operator set used by this execution context.
    def operators : Operators
      @operators
    end

    # Pops a number (int or real) from the stack. If it's neither data type, a
    # TypeCastError is raised.
    def pop_number : Int32 | Float32
      value = @stack.pop
      case value
      when Int32, Float32
        value
      else
        raise "Expected number, got #{value.class}"
      end
    end

    # Pops a value of type int from the stack. If the value is not of type int, a
    # TypeCastError is raised.
    def pop_int : Int32
      value = @stack.pop
      case value
      when Int32
        value
      else
        raise "Expected Int32, got #{value.class}"
      end
    end

    # Pops a number from the stack and returns it as a real value. If the value is not of a
    # numeric type, a TypeCastError is raised.
    def pop_real : Float32
      value = @stack.pop
      case value
      when Int32
        value.to_f32
      when Float32
        value
      else
        raise "Expected numeric, got #{value.class}"
      end
    end
  end
end
