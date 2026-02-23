# Provides the arithmetic operators such as "add" and "sub"
require "./operator"
require "./execution_context"

module Pdfbox::Pdmodel::Common::Function::Type4
  module ArithmeticOperators
    # Implements the "abs" operator
    class Abs < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        case num
        when Int32
          context.stack.push(num.abs)
        when Float32
          context.stack.push(num.abs.to_f32)
        end
      end
    end

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

    # Implements the "atan" operator
    class Atan < Operator
      def execute(context : ExecutionContext) : Nil
        den = context.pop_real.to_f64
        num = context.pop_real.to_f64
        atan = Math.atan2(num, den)
        atan = (atan * 180.0 / Math::PI) % 360.0
        if atan < 0
          atan += 360.0
        end
        context.stack.push(atan.to_f32)
      end
    end

    # Implements the "ceiling" operator
    class Ceiling < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        case num
        when Int32
          context.stack.push(num)
        when Float32
          context.stack.push(num.ceil)
        end
      end
    end

    # Implements the "cos" operator
    class Cos < Operator
      def execute(context : ExecutionContext) : Nil
        angle = context.pop_real.to_f64
        cos = Math.cos(angle * Math::PI / 180.0)
        context.stack.push(cos.to_f32)
      end
    end

    # Implements the "cvi" operator (convert to integer)
    class Cvi < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        context.stack.push(num.to_i32)
      end
    end

    # Implements the "cvr" operator (convert to real)
    class Cvr < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        context.stack.push(num.to_f32)
      end
    end

    # Implements the "div" operator
    class Div < Operator
      def execute(context : ExecutionContext) : Nil
        num2 = context.pop_number
        num1 = context.pop_number
        context.stack.push(num1.to_f32 / num2.to_f32)
      end
    end

    # Implements the "exp" operator
    class Exp < Operator
      def execute(context : ExecutionContext) : Nil
        exp = context.pop_number.to_f64
        base = context.pop_number.to_f64
        value = base ** exp
        context.stack.push(value.to_f32)
      end
    end

    # Implements the "floor" operator
    class Floor < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        case num
        when Int32
          context.stack.push(num)
        when Float32
          context.stack.push(num.floor)
        end
      end
    end

    # Implements the "idiv" operator (integer division)
    class IDiv < Operator
      def execute(context : ExecutionContext) : Nil
        num2 = context.pop_int
        num1 = context.pop_int
        context.stack.push(num1.unsafe_div(num2))
      end
    end

    # Implements the "ln" operator (natural logarithm)
    class Ln < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number.to_f64
        value = Math.log(num).to_f32
        context.stack.push(value)
      end
    end

    # Implements the "log" operator (base 10 logarithm)
    class Log < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number.to_f64
        value = Math.log10(num).to_f32
        context.stack.push(value)
      end
    end

    # Implements the "mod" operator
    class Mod < Operator
      def execute(context : ExecutionContext) : Nil
        int2 = context.pop_int
        int1 = context.pop_int
        context.stack.push(int1.remainder(int2))
      end
    end

    # Implements the "mul" operator
    class Mul < Operator
      def execute(context : ExecutionContext) : Nil
        num2 = context.pop_number
        num1 = context.pop_number

        if num1.is_a?(Int32) && num2.is_a?(Int32)
          result = num1.to_i64 * num2.to_i64
          if result >= Int32::MIN && result <= Int32::MAX
            context.stack.push(result.to_i32)
          else
            context.stack.push(result.to_f32)
          end
        else
          result = num1.to_f32 * num2.to_f32
          context.stack.push(result)
        end
      end
    end

    # Implements the "neg" operator
    class Neg < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        case num
        when Int32
          v = num
          if v == Int32::MIN
            context.stack.push(-num.to_f32)
          else
            context.stack.push(-v)
          end
        when Float32
          context.stack.push(-num)
        end
      end
    end

    # Implements the "round" operator
    class Round < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        case num
        when Int32
          context.stack.push(num)
        when Float32
          rounded = (num + 0.5_f32).floor
          context.stack.push(rounded)
        end
      end
    end

    # Implements the "sin" operator
    class Sin < Operator
      def execute(context : ExecutionContext) : Nil
        angle = context.pop_real.to_f64
        sin = Math.sin(angle * Math::PI / 180.0)
        context.stack.push(sin.to_f32)
      end
    end

    # Implements the "sqrt" operator
    class Sqrt < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_real.to_f64
        if num < 0
          raise "argument must be nonnegative"
        end
        context.stack.push(Math.sqrt(num).to_f32)
      end
    end

    # Implements the "sub" operator
    class Sub < Operator
      def execute(context : ExecutionContext) : Nil
        num2 = context.pop_number
        num1 = context.pop_number

        if num1.is_a?(Int32) && num2.is_a?(Int32)
          result = num1.to_i64 - num2.to_i64
          if result < Int32::MIN || result > Int32::MAX
            context.stack.push(result.to_f32)
          else
            context.stack.push(result.to_i32)
          end
        else
          result = num1.to_f32 - num2.to_f32
          context.stack.push(result)
        end
      end
    end

    # Implements the "truncate" operator
    class Truncate < Operator
      def execute(context : ExecutionContext) : Nil
        num = context.pop_number
        case num
        when Int32
          context.stack.push(num)
        when Float32
          context.stack.push(num.trunc.to_f32)
        end
      end
    end
  end
end
