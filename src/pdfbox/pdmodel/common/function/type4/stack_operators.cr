# Provides the stack operators such as "pop", "dup", etc.
require "./operator"
require "./execution_context"

module Pdfbox::Pdmodel::Common::Function::Type4
  module StackOperators
    # Implements the "copy" operator
    class Copy < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        n = stack.pop.as(Number).to_i32
        if n > 0
          size = stack.size
          # Need to copy to a new list to avoid modification issues
          copy = stack[size - n, n]
          copy.each { |item| stack.push(item) }
        end
      end
    end

    # Implements the "dup" operator
    class Dup < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        stack.push(stack.last)
      end
    end

    # Implements the "exch" operator
    class Exch < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        any2 = stack.pop
        any1 = stack.pop
        stack.push(any2)
        stack.push(any1)
      end
    end

    # Implements the "index" operator
    class Index < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        n = stack.pop.as(Number).to_i32
        if n < 0
          raise "rangecheck: #{n}"
        end
        size = stack.size
        stack.push(stack[size - n - 1])
      end
    end

    # Implements the "pop" operator
    class Pop < Operator
      def execute(context : ExecutionContext) : Nil
        context.stack.pop
      end
    end

    # Implements the "roll" operator
    class Roll < Operator
      def execute(context : ExecutionContext) : Nil
        stack = context.stack
        j = stack.pop.as(Number).to_i32
        n = stack.pop.as(Number).to_i32

        if j == 0
          return # Nothing to do
        end

        if n < 0
          raise "rangecheck: #{n}"
        end

        if j < 0
          # negative roll
          n1 = n + j
          moved = [] of typeof(stack.first)
          rolled = [] of typeof(stack.first)

          n1.times do
            moved.unshift(stack.pop)
          end

          (-j).times do
            rolled.unshift(stack.pop)
          end

          moved.each { |item| stack.push(item) }
          rolled.each { |item| stack.push(item) }
        else
          # positive roll
          n1 = n - j
          rolled = [] of typeof(stack.first)
          moved = [] of typeof(stack.first)

          j.times do
            rolled.unshift(stack.pop)
          end

          n1.times do
            moved.unshift(stack.pop)
          end

          rolled.each { |item| stack.push(item) }
          moved.each { |item| stack.push(item) }
        end
      end
    end
  end
end
