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
      type = dictionary[Pdfbox::Cos::Name::TYPE]?
      if type.is_a?(Pdfbox::Cos::Name) && type != Pdfbox::Cos::Name::FONT
        Log.error { "Expected 'Font' dictionary but found '#{type.value}'" }
      end

      subtype = dictionary.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE)
      case subtype
      when "Type0"
        PDType0Font.new(dictionary)
      when "Type1"
        PDType1Font.new(dictionary)
      when "MMType1"
        # TODO: Route to PDMMType1Font when implemented.
        PDType1Font.new(dictionary)
      when "TrueType"
        PDTrueTypeFont.new(dictionary)
      when "Type3"
        PDType3Font.new(dictionary)
      when "CIDFontType0"
        raise ::IO::Error.new("Type 0 descendant font not allowed")
      when "CIDFontType2"
        raise ::IO::Error.new("Type 2 descendant font not allowed")
      else
        # Java fallback is Type1 for unknown subtypes.
        PDType1Font.new(dictionary)
      end
    end

    # Creates a new PDCIDFont instance with the appropriate subclass.
    def self.create_descendant_font(dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font) : PDCIDFont
      # Check type
      type = dictionary[Pdfbox::Cos::Name::TYPE]?
      resolved_type = type.is_a?(Pdfbox::Cos::Name) ? type : Pdfbox::Cos::Name::FONT
      if resolved_type != Pdfbox::Cos::Name::FONT
        raise ::IO::Error.new("Expected 'Font' dictionary but found '#{resolved_type.value}'")
      end

      # Check subtype
      subtype = dictionary[Pdfbox::Cos::Name::SUBTYPE]?
      case subtype
      when Pdfbox::Cos::Name.new("CIDFontType0")
        PDCIDFontType0.new(dictionary, parent)
      when Pdfbox::Cos::Name.new("CIDFontType2")
        PDCIDFontType2.new(dictionary, parent)
      else
        raise ::IO::Error.new("Invalid font type: #{resolved_type.value}")
      end
    end
  end
end
