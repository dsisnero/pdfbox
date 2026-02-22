# Type Identity function in a PDF document
# Corresponds to PDFunctionTypeIdentity in Apache PDFBox
module Pdfbox::Pdmodel::Common::Function
  class PDFunctionTypeIdentity < PDFunction
    # Constructor.
    def initialize(function : Cos::Base?)
      # PDFBox passes null; we'll create a dummy dictionary if nil
      super(function || Cos::Dictionary.new)
    end

    # Returns the function type (should not be called)
    def function_type : Int32
      raise "UnsupportedOperationException: function_type should not be called for identity function"
    end

    # Identity evaluation: returns input unchanged
    def eval(input : Array(Float32)) : Array(Float32)
      input
    end

    # Override range values to return nil (as in Java)
    def range_values : Cos::Array?
      nil
    end

    def to_s : String
      "FunctionTypeIdentity"
    end
  end
end
