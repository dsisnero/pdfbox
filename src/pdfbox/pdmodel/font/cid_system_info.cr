# CIDSystemInfo for CID fonts
# Corresponds to PDCIDSystemInfo in Apache PDFBox
require "../../cos.cr"

module Pdfbox::Pdmodel::Font
  class PDCIDSystemInfo
    @dictionary : Pdfbox::Cos::Dictionary

    # Creates a CIDSystemInfo with the given registry, ordering, and supplement.
    def initialize(registry : String, ordering : String, supplement : Int32)
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary[Pdfbox::Cos::Name::REGISTRY] = Pdfbox::Cos::Name.get_pdf_name(registry)
      @dictionary[Pdfbox::Cos::Name::ORDERING] = Pdfbox::Cos::Name.get_pdf_name(ordering)
      @dictionary[Pdfbox::Cos::Name::SUPPLEMENT] = Pdfbox::Cos::Integer.get(supplement.to_i64)
    end

    # Creates a CIDSystemInfo from an existing COS dictionary.
    def initialize(dictionary : Pdfbox::Cos::Dictionary)
      @dictionary = dictionary
    end

    # Returns the registry.
    def registry : String
      @dictionary.get_name_as_string(Pdfbox::Cos::Name::REGISTRY) || ""
    end

    # Returns the ordering.
    def ordering : String
      @dictionary.get_name_as_string(Pdfbox::Cos::Name::ORDERING) || ""
    end

    # Returns the supplement.
    def supplement : Int32
      @dictionary.get_int(Pdfbox::Cos::Name::SUPPLEMENT, 0).to_i32
    end

    # Returns the underlying COS dictionary.
    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    def to_s : String
      "#{registry}-#{ordering}-#{supplement}"
    end
  end
end
