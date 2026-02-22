# Provides all the supported operators for Type 4 functions
require "./arithmetic_operators"
require "./stack_operators"

module Pdfbox::Pdmodel::Common::Function::Type4
  class Operators
    @operators = {} of String => Operator

    # Creates a new Operators object with the default set of operators
    def initialize
      # Arithmetic operators
      @operators["add"] = ArithmeticOperators::Add.new
      @operators["pop"] = StackOperators::Pop.new

      # TODO: Add more operators as needed
      # @operators["abs"] = ArithmeticOperators::Abs.new
      # @operators["sub"] = ArithmeticOperators::Sub.new
      # etc.
    end

    # Returns the operator for the given operator name
    def get_operator(operator_name : String) : Operator?
      @operators[operator_name]?
    end
  end
end
