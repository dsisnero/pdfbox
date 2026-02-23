# Provides the conditional operators such as "if" and "ifelse"
require "./operator"
require "./execution_context"
require "./instruction_sequence"

module Pdfbox::Pdmodel::Common::Function::Type4
  module ConditionalOperators
    # Implements the "if" operator
    class If < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        proc = stack.pop.as(InstructionSequence)
        condition = stack.pop.as(Bool)
        if condition
          proc.execute(context)
        end
      end
    end

    # Implements the "ifelse" operator
    class IfElse < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        proc2 = stack.pop.as(InstructionSequence)
        proc1 = stack.pop.as(InstructionSequence)
        condition = stack.pop.as(Bool)
        if condition
          proc1.execute(context)
        else
          proc2.execute(context)
        end
      end
    end
  end
end
