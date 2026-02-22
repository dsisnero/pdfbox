# Provides the stack operators such as "pop", "dup", etc.
require "./operator"
require "./execution_context"

module Pdfbox::Pdmodel::Common::Function::Type4
  module StackOperators
    # Implements the "pop" operator
    class Pop < Operator
      def execute(context : ExecutionContext) : Nil
        context.stack.pop
      end
    end

    # TODO: Implement other stack operators
    # copy, dup, exch, index, roll
  end
end
