# Font factory for creating font instances
# Corresponds to PDFontFactory in Apache PDFBox
require "../../cos"
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
    Cos = Pdfbox::Cos

    private def initialize
      # private constructor
    end

    # Creates a new PDFont instance with the appropriate subclass.
    def self.create_font(dictionary : Cos::Dictionary) : PDFont
      # TODO: Implement full font creation logic
      # For now, just create a placeholder based on subtype
      subtype = dictionary.get_name_as_string(Cos::Name::SUBTYPE)
      case subtype
      when "Type0"
        PDType0Font.new(dictionary)
      when "Type1", "MMType1", "Type3", "TrueType"
        # TODO: Implement proper font creation
        raise "Font type #{subtype} not yet implemented"
      else
        raise "Unknown font subtype: #{subtype}"
      end
    end

    # Creates a new PDCIDFont instance with the appropriate subclass.
    def self.create_descendant_font(dictionary : Cos::Dictionary, parent : PDType0Font) : PDCIDFont
      # Check type
      type = dictionary.get(Cos::Name::TYPE)
      if type.nil? || type != Cos::Name::FONT
        raise ::IO::Error.new("Expected 'Font' dictionary but found '#{type}'")
      end

      # Check subtype
      subtype = dictionary.get(Cos::Name::SUBTYPE)
      case subtype
      when Cos::Name::CID_FONT_TYPE0
        PDCIDFontType0.new(dictionary, parent)
      when Cos::Name::CID_FONT_TYPE2
        PDCIDFontType2.new(dictionary, parent)
      else
        raise ::IO::Error.new("Invalid CID font type: #{subtype}")
      end
    end
  end
end
