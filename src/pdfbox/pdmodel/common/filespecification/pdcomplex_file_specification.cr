# A complex file specification using a dictionary
module Pdfbox::Pdmodel::Common::Filespecification
  class PDComplexFileSpecification < PDFileSpecification
    @fs : Cos::Dictionary

    # Default constructor
    def initialize
      @fs = Cos::Dictionary.new
      @fs[Cos::Name::TYPE] = Cos::Name::FILESPEC
    end

    # Constructor with COSDictionary
    def initialize(dict : Cos::Dictionary?)
      if dict.nil?
        @fs = Cos::Dictionary.new
        @fs[Cos::Name::TYPE] = Cos::Name::FILESPEC
      else
        @fs = dict
      end
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @fs
    end

    # Get the preferred filename (tries UF, DOS, MAC, UNIX, then F)
    def filename : String?
      file_unicode || file_dos || file_mac || file_unix || file
    end

    # Get the unicode file name
    def file_unicode : String?
      @fs[Cos::Name.new("UF")].as?(Cos::String).try(&.value)
    end

    # Set the unicode file name
    def file_unicode=(file : String)
      @fs[Cos::Name.new("UF")] = Cos::String.new(file)
    end

    # Get the file name
    def file : String?
      @fs[Cos::Name.new("F")].as?(Cos::String).try(&.value)
    end

    # Set the file name
    def file=(value : String)
      @fs[Cos::Name.new("F")] = Cos::String.new(value)
    end

    # Get the DOS file name
    def file_dos : String?
      @fs[Cos::Name.new("DOS")].as?(Cos::String).try(&.value)
    end

    # Get the Mac file name
    def file_mac : String?
      @fs[Cos::Name.new("Mac")].as?(Cos::String).try(&.value)
    end

    # Get the Unix file name
    def file_unix : String?
      @fs[Cos::Name.new("Unix")].as?(Cos::String).try(&.value)
    end

    # Check if file is volatile
    def volatile? : Bool
      @fs[Cos::Name.new("V")].as?(Cos::Boolean).try(&.value) || false
    end

    # Set volatile flag
    def volatile=(value : Bool)
      @fs[Cos::Name.new("V")] = Cos::Boolean.new(value)
    end

    # Get file description
    def file_description : String?
      @fs[Cos::Name.new("Desc")].as?(Cos::String).try(&.value)
    end

    # Set file description
    def file_description=(description : String)
      @fs[Cos::Name.new("Desc")] = Cos::String.new(description)
    end
  end
end
