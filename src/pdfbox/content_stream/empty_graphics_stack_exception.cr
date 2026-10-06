module Pdfbox::ContentStream
  # Throw when restore is executed when the graphics stack is empty.
  # Java: org.apache.pdfbox.contentstream.operator.state.EmptyGraphicsStackException (extends IOException)
  class EmptyGraphicsStackException < ::IO::Error
    def initialize
      super("Cannot execute restore, the graphics stack is empty")
    end
  end
end
