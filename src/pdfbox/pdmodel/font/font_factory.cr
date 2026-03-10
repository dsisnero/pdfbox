# Font factory for creating font instances
# Corresponds to PDFontFactory in Apache PDFBox
require "../../cos.cr"
require "./pdfont"
require "./simple_font"
require "./true_type_font"
require "./type0_font"
require "./type3_font"
require "./cid_font"
require "./cid_font_type0"
require "./cid_font_type2"

module Pdfbox::Pdmodel::Font
  class PDFontFactory
    Log = ::Log.for(self)

    private def initialize
      # private constructor
    end

    # Creates a new PDFont instance with the appropriate subclass.
    def self.create_font(dictionary : Pdfbox::Cos::Dictionary) : PDFont
      subtype = dictionary.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE)
      case subtype
      when "Type0"
        PDType0Font.new(dictionary)
      when "Type3"
        PDType3Font.new(dictionary)
      when "Type1", "MMType1", "TrueType"
        # TODO: Map these to concrete implementations as those constructors are ported.
        raise "Font type #{subtype} not yet implemented"
      else
        # TODO: Java defaults unknown subtypes to Type1.
        raise "Invalid font subtype '#{subtype}'"
      end
    end

    # Creates a new PDCIDFont instance with the appropriate subclass.
    def self.create_descendant_font(dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font) : PDCIDFont
      # Check type
      type = dictionary[Pdfbox::Cos::Name::TYPE]?
      if type.nil? || type != Pdfbox::Cos::Name::FONT
        raise ::IO::Error.new("Expected 'Font' dictionary but found '#{type}'")
      end

      # Check subtype
      subtype = dictionary[Pdfbox::Cos::Name::SUBTYPE]?
      case subtype
      when Pdfbox::Cos::Name.new("CIDFontType0")
        PDCIDFontType0.new(dictionary, parent)
      when Pdfbox::Cos::Name.new("CIDFontType2")
        PDCIDFontType2.new(dictionary, parent)
      else
        raise ::IO::Error.new("Invalid CID font type: #{subtype}")
      end
    end
  end
end
