module Pdfbox::ContentStream
  # Throw when a PDF operator is missing required operands.
  # Java: org.apache.pdfbox.contentstream.operator.MissingOperandException (extends IOException)
  class MissingOperandException < ::IO::Error
    def initialize(operator : Operator, operands : Array)
      rendered = operands.map(&.to_s)
      super("Operator #{operator.name} has too few operands: [#{rendered.join(", ")}]")
    end
  end
end
