# Interface for PostScript operators.
module Pdfbox::Pdmodel::Common::Function::Type4
  abstract class Operator
    # Executes the operator. The method can inspect and manipulate the stack.
    abstract def execute(context : ExecutionContext) : Nil
  end
end
