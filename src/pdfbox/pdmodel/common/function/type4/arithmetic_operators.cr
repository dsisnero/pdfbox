# Provides the arithmetic operators such as "add" and "sub"
require "./operator"
require "./execution_context"

module Pdfbox::Pdmodel::Common::Function::Type4
  module ArithmeticOperators
    # Implements the "add" operator
    class Add < Operator
      def execute(context : ExecutionContext) : Nil
        num2 = context.pop_number
        num1 = context.pop_number

        if num1.is_a?(Int32) && num2.is_a?(Int32)
          sum = num1.to_i64 + num2.to_i64
          if sum < Int32::MIN || sum > Int32::MAX
            context.stack.push(sum.to_f32)
          else
            context.stack.push(sum.to_i32)
          end
        else
          sum = num1.to_f32 + num2.to_f32
          context.stack.push(sum)
        end
      end
    end

    # TODO: Implement other arithmetic operators
    # abs, atan, ceiling, cos, cvi, cvr, div, exp, floor, idiv, ln, log, mod, mul, neg, round, sin, sqrt, sub, truncate
  end
end
