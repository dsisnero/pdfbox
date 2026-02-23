# Provides all the supported operators for Type 4 functions
require "./arithmetic_operators"
require "./bitwise_operators"
require "./conditional_operators"
require "./relational_operators"
require "./stack_operators"

module Pdfbox::Pdmodel::Common::Function::Type4
  class Operators
    @operators = {} of String => Operator

    # Creates a new Operators object with the default set of operators
    def initialize
      # Arithmetic operators
      @operators["abs"] = ArithmeticOperators::Abs.new
      @operators["add"] = ArithmeticOperators::Add.new
      @operators["atan"] = ArithmeticOperators::Atan.new
      @operators["ceiling"] = ArithmeticOperators::Ceiling.new
      @operators["cos"] = ArithmeticOperators::Cos.new
      @operators["cvi"] = ArithmeticOperators::Cvi.new
      @operators["cvr"] = ArithmeticOperators::Cvr.new
      @operators["div"] = ArithmeticOperators::Div.new
      @operators["exp"] = ArithmeticOperators::Exp.new
      @operators["floor"] = ArithmeticOperators::Floor.new
      @operators["idiv"] = ArithmeticOperators::IDiv.new
      @operators["ln"] = ArithmeticOperators::Ln.new
      @operators["log"] = ArithmeticOperators::Log.new
      @operators["mod"] = ArithmeticOperators::Mod.new
      @operators["mul"] = ArithmeticOperators::Mul.new
      @operators["neg"] = ArithmeticOperators::Neg.new
      @operators["round"] = ArithmeticOperators::Round.new
      @operators["sin"] = ArithmeticOperators::Sin.new
      @operators["sqrt"] = ArithmeticOperators::Sqrt.new
      @operators["sub"] = ArithmeticOperators::Sub.new
      @operators["truncate"] = ArithmeticOperators::Truncate.new

      # Bitwise operators
      @operators["and"] = BitwiseOperators::And.new
      @operators["bitshift"] = BitwiseOperators::Bitshift.new
      @operators["false"] = BitwiseOperators::False.new
      @operators["not"] = BitwiseOperators::Not.new
      @operators["or"] = BitwiseOperators::Or.new
      @operators["true"] = BitwiseOperators::True.new
      @operators["xor"] = BitwiseOperators::Xor.new

      # Relational operators
      @operators["eq"] = RelationalOperators::Eq.new
      @operators["ge"] = RelationalOperators::Ge.new
      @operators["gt"] = RelationalOperators::Gt.new
      @operators["le"] = RelationalOperators::Le.new
      @operators["lt"] = RelationalOperators::Lt.new
      @operators["ne"] = RelationalOperators::Ne.new

      # Conditional operators
      @operators["if"] = ConditionalOperators::If.new
      @operators["ifelse"] = ConditionalOperators::IfElse.new

      # Stack operators
      @operators["copy"] = StackOperators::Copy.new
      @operators["dup"] = StackOperators::Dup.new
      @operators["exch"] = StackOperators::Exch.new
      @operators["index"] = StackOperators::Index.new
      @operators["pop"] = StackOperators::Pop.new
      @operators["roll"] = StackOperators::Roll.new
    end

    # Returns the operator for the given operator name
    def get_operator(operator_name : String) : Operator?
      @operators[operator_name]?
    end
  end
end
