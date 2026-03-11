# A file specification that is just a string
module Pdfbox::Pdmodel::Common::Filespecification
  class PDSimpleFileSpecification < PDFileSpecification
    @file : Cos::String

    # Default constructor
    def initialize
      @file = Cos::String.new("")
    end

    # Constructor with COSString
    def initialize(@file : Cos::String)
    end

    # Get the file name
    def file : String
      @file.value
    end

    # Set the file name
    def file=(value : String)
      @file = Cos::String.new(value)
    end

    # Get the underlying COS object
    def cos_object : Cos::String
      @file
    end
  end
end
