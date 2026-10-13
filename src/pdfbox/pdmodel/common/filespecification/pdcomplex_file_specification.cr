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

    # Get the embedded file (/EF /F), or nil (Java getEmbeddedFile).
    def embedded_file : PDEmbeddedFile?
      embedded_file_for("F")
    end

    # Set the embedded file (/EF /F), creating the /EF dictionary if needed
    # (Java setEmbeddedFile).
    def embedded_file=(file : PDEmbeddedFile?) : Nil
      set_embedded_file_entry("F", file)
    end

    # Get the embedded DOS file (/EF /DOS), or nil (Java getEmbeddedFileDos).
    def embedded_file_dos : PDEmbeddedFile?
      embedded_file_for("DOS")
    end

    # Get the embedded Mac file (/EF /Mac), or nil (Java getEmbeddedFileMac).
    def embedded_file_mac : PDEmbeddedFile?
      embedded_file_for("Mac")
    end

    # Get the embedded Unix file (/EF /Unix), or nil (Java getEmbeddedFileUnix).
    def embedded_file_unix : PDEmbeddedFile?
      embedded_file_for("Unix")
    end

    # Get the embedded Unicode file (/EF /UF), or nil (Java getEmbeddedFileUnicode).
    def embedded_file_unicode : PDEmbeddedFile?
      embedded_file_for("UF")
    end

    # Set the embedded Unicode file (/EF /UF), creating the /EF dictionary if needed
    # (Java setEmbeddedFileUnicode).
    def embedded_file_unicode=(file : PDEmbeddedFile?) : Nil
      set_embedded_file_entry("UF", file)
    end

    # The /EF dictionary, or nil (Java PDComplexFileSpecification#getEFDictionary).
    private def ef_dictionary : Cos::Dictionary?
      @fs.get_dictionary(Cos::Name.new("EF"))
    end

    # Java getObjectFromEFDictionary + embedding type check.
    private def embedded_file_for(key : String) : PDEmbeddedFile?
      ef = ef_dictionary
      return nil unless ef
      base = ef.get_dictionary_object(Cos::Name.new(key))
      base.is_a?(Cos::Stream) ? PDEmbeddedFile.new(base) : nil
    end

    # Java setEmbeddedFile/setEmbeddedFileUnicode.
    private def set_embedded_file_entry(key : String, file : PDEmbeddedFile?) : Nil
      ef = ef_dictionary
      if ef.nil? && file
        ef = Cos::Dictionary.new
        @fs.set_item(Cos::Name.new("EF"), ef)
      end
      if ef
        if file
          ef.set_item(Cos::Name.new(key), file.cos_object)
        else
          ef.delete(Cos::Name.new(key))
        end
      end
    end
  end
end
