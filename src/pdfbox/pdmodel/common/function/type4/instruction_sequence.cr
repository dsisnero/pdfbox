# Represents an instruction sequence, a combination of values, operands and nested procedures.
require "./execution_context"
require "./operators"

module Pdfbox::Pdmodel::Common::Function::Type4
  class InstructionSequence
    @instructions = [] of String | Int32 | Float32 | Bool | InstructionSequence

    # Add a name (ex. an operator)
    def add_name(name : String) : Nil
      @instructions << name
    end

    # Adds an int value.
    def add_integer(value : Int32) : Nil
      @instructions << value
    end

    # Adds a real value.
    def add_real(value : Float32) : Nil
      @instructions << value
    end

    # Adds a bool value.
    def add_boolean(value : Bool) : Nil
      @instructions << value
    end

    # Adds a proc (sub-sequence of instructions).
    def add_proc(child : InstructionSequence) : Nil
      @instructions << child
    end

    # Executes the instruction sequence.
    def execute(context : ExecutionContext) : Nil
      stack = context.stack
      @instructions.each do |obj|
        case obj
        when String
          name = obj
          cmd = context.operators.get_operator(name)
          if cmd
            cmd.execute(context)
          else
            raise "Unknown operator or name: #{name}"
          end
        else
          stack.push(obj)
        end
      end

      # Handles top-level procs that simply need to be executed
      while !stack.empty? && stack.last.is_a?(InstructionSequence)
        nested = stack.pop.as(InstructionSequence)
        nested.execute(context)
      end
    end
  end
end
