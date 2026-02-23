# Provides the relational operators such as "eq" and "le"
require "./operator"
require "./execution_context"

module Pdfbox::Pdmodel::Common::Function::Type4
  module RelationalOperators
    # Implements the "eq" operator
    class Eq < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        op2 = stack.pop
        op1 = stack.pop
        result = equal?(op1, op2)
        stack.push(result)
      end

      protected def equal?(op1, op2) : Bool
        if op1.is_a?(Number) && op2.is_a?(Number)
          num1 = op1.as(Number)
          num2 = op2.as(Number)
          num1.to_f32 == num2.to_f32
        else
          op1 == op2
        end
      end
    end

    # Abstract base class for number comparison operators
    private abstract class AbstractNumberComparisonOperator < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        op2 = stack.pop
        op1 = stack.pop

        num1 = op1.as(Number)
        num2 = op2.as(Number)
        result = compare(num1, num2)
        stack.push(result)
      end

      protected abstract def compare(num1 : Number, num2 : Number) : Bool
    end

    # Implements the "ge" operator
    class Ge < AbstractNumberComparisonOperator
      def compare(num1 : Number, num2 : Number) : Bool
        num1.to_f32 >= num2.to_f32
      end
    end

    # Implements the "gt" operator
    class Gt < AbstractNumberComparisonOperator
      def compare(num1 : Number, num2 : Number) : Bool
        num1.to_f32 > num2.to_f32
      end
    end

    # Implements the "le" operator
    class Le < AbstractNumberComparisonOperator
      def compare(num1 : Number, num2 : Number) : Bool
        num1.to_f32 <= num2.to_f32
      end
    end

    # Implements the "lt" operator
    class Lt < AbstractNumberComparisonOperator
      def compare(num1 : Number, num2 : Number) : Bool
        num1.to_f32 < num2.to_f32
      end
    end

    # Implements the "ne" operator
    class Ne < Eq
      def equal?(op1, op2) : Bool
        !super
      end
    end
  end
end
