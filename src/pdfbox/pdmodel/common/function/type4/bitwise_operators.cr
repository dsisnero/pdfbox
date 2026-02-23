# Provides the bitwise operators such as "and" and "xor"
require "./operator"
require "./execution_context"

module Pdfbox::Pdmodel::Common::Function::Type4
  module BitwiseOperators
    # Abstract base class for logical operators
    private abstract class AbstractLogicalOperator < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        op2 = stack.pop
        op1 = stack.pop

        case {op1, op2}
        when {Bool, Bool}
          bool1 = op1.as(Bool)
          bool2 = op2.as(Bool)
          result = apply_for_boolean(bool1, bool2)
          stack.push(result)
        when {Int32, Int32}
          int1 = op1.as(Int32)
          int2 = op2.as(Int32)
          result = apply_for_integer(int1, int2)
          stack.push(result)
        else
          raise "Operands must be bool/bool or int/int, got #{op1.class}/#{op2.class}"
        end
      end

      protected abstract def apply_for_boolean(bool1 : Bool, bool2 : Bool) : Bool
      protected abstract def apply_for_integer(int1 : Int32, int2 : Int32) : Int32
    end

    # Implements the "and" operator
    class And < AbstractLogicalOperator
      def apply_for_boolean(bool1 : Bool, bool2 : Bool) : Bool
        bool1 && bool2
      end

      def apply_for_integer(int1 : Int32, int2 : Int32) : Int32
        int1 & int2
      end
    end

    # Implements the "bitshift" operator
    class Bitshift < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        shift = stack.pop.as(Int32)
        int1 = stack.pop.as(Int32)

        result = if shift < 0
                   int1 >> shift.abs
                 else
                   int1 << shift
                 end
        stack.push(result)
      end
    end

    # Implements the "false" operator
    class False < Operator
      def execute(context : ExecutionContext) : Nil
        context.stack.push(false)
      end
    end

    # Implements the "not" operator
    class Not < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        op1 = stack.pop

        case op1
        when Bool
          bool1 = op1.as(Bool)
          result = !bool1
          stack.push(result)
        when Int32
          int1 = op1.as(Int32)
          result = -int1 # Bitwise NOT for integers in PostScript
          stack.push(result)
        else
          raise "Operand must be bool or int, got #{op1.class}"
        end
      end
    end

    # Implements the "or" operator
    class Or < AbstractLogicalOperator
      def apply_for_boolean(bool1 : Bool, bool2 : Bool) : Bool
        bool1 || bool2
      end

      def apply_for_integer(int1 : Int32, int2 : Int32) : Int32
        int1 | int2
      end
    end

    # Implements the "true" operator
    class True < Operator
      def execute(context : ExecutionContext) : Nil
        context.stack.push(true)
      end
    end

    # Implements the "xor" operator
    class Xor < AbstractLogicalOperator
      def apply_for_boolean(bool1 : Bool, bool2 : Bool) : Bool
        bool1 ^ bool2
      end

      def apply_for_integer(int1 : Int32, int2 : Int32) : Int32
        int1 ^ int2
      end
    end
  end
end
