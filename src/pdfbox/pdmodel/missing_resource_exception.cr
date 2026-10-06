module Pdfbox::Pdmodel
  # Thrown when a named resource is missing.
  # Java: org.apache.pdfbox.pdmodel.MissingResourceException (extends IOException)
  class MissingResourceException < ::IO::Error
    def initialize(message : String)
      super(message)
    end
  end
end
