# Font factory for creating font instances
# Corresponds to PDFontFactory in Apache PDFBox
require "../../cos.cr"
require "./pdfont"
require "./simple_font"
require "./true_type_font"
require "./type0_font"
require "./type1c_font"
require "./mm_type1_font"
require "./type3_font"
require "./cid_font"
require "./cid_font_type0"
require "./cid_font_type2"

module Pdfbox::Pdmodel::Font
  class PDFontFactory
    Log                 = ::Log.for(self)
    FONT_OPEN_TYPE      = "OTTO"
    FONT_TTF_COLLECTION = "ttcf"
    FONT_TRUE_TYPE      = "true"

    private def initialize
      # private constructor
    end

    # Creates a new PDFont instance with the appropriate subclass.
    def self.create_font(dictionary : Pdfbox::Cos::Dictionary) : PDFont
      create_font(dictionary, nil)
    end

    # Creates a new PDFont instance with an optional resource cache.
    # The resource cache is currently only used by Type3 font construction.
    def self.create_font(dictionary : Pdfbox::Cos::Dictionary, resource_cache : ResourceCache?) : PDFont
      type = dictionary[Pdfbox::Cos::Name::TYPE]?
      if type.is_a?(Pdfbox::Cos::Name) && type != Pdfbox::Cos::Name::FONT
        Log.error { "Expected 'Font' dictionary but found '#{type.value}'" }
      end

      subtype = dictionary.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE)
      if subtype == "Type0"
        font_descriptor = get_font_descriptor(dictionary)
        expected_subtype = get_type0_descendant_subtype_from_font(font_descriptor)
        if expected_subtype
          descendant_font = get_descendant_font(dictionary)
          descendant_subtype = descendant_font.try(&.[]?(Pdfbox::Cos::Name::SUBTYPE)).as?(Pdfbox::Cos::Name)
          if descendant_font && descendant_subtype && descendant_subtype != expected_subtype
            fix_type0_subtype(descendant_font, font_descriptor, expected_subtype)
          end
        end
        PDType0Font.new(dictionary)
      else
        create_non_type0_font(subtype, dictionary, resource_cache)
      end
    end

    private def self.create_non_type0_font(subtype : String?, dictionary : Pdfbox::Cos::Dictionary, resource_cache : ResourceCache?) : PDFont
      case subtype
      when "Type1"
        if font_file3?(dictionary)
          PDType1CFont.new(dictionary)
        else
          PDType1Font.new(dictionary)
        end
      when "MMType1"
        if font_file3?(dictionary)
          PDType1CFont.new(dictionary)
        else
          PDMMType1Font.new(dictionary)
        end
      when "TrueType"
        PDTrueTypeFont.new(dictionary)
      when "Type3"
        PDType3Font.new(dictionary, resource_cache)
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

    private def self.get_font_descriptor(dictionary : Pdfbox::Cos::Dictionary) : Pdfbox::Cos::Dictionary?
      dictionary.get_dictionary(Pdfbox::Cos::Name::FONT_DESC) || get_descendant_font(dictionary).try(&.get_dictionary(Pdfbox::Cos::Name::FONT_DESC))
    end

    private def self.font_file3?(dictionary : Pdfbox::Cos::Dictionary) : Bool
      fd = dictionary.get_dictionary(Pdfbox::Cos::Name::FONT_DESC)
      !fd.nil? && fd.has_key?(Pdfbox::Cos::Name::FONT_FILE3)
    end

    private def self.get_descendant_font(dictionary : Pdfbox::Cos::Dictionary) : Pdfbox::Cos::Dictionary?
      descendant_fonts = dictionary.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS)
      return nil if descendant_fonts.nil? || descendant_fonts.size == 0
      descendant_fonts[0]?.as?(Pdfbox::Cos::Dictionary)
    end

    private def self.get_type0_descendant_subtype_from_font(font_descriptor : Pdfbox::Cos::Dictionary?) : Pdfbox::Cos::Name?
      header = get_font_header(font_descriptor)
      return nil if header.nil?

      if true_type_header?(header) || true_type_collection_header?(header) || open_type_header?(header)
        return Pdfbox::Cos::Name::CID_FONT_TYPE2
      end
      if type1_header?(header) || pfb_header?(header) || cff_header?(header)
        return Pdfbox::Cos::Name::CID_FONT_TYPE0
      end
      nil
    end

    private def self.fix_type0_subtype(descendant_font : Pdfbox::Cos::Dictionary, font_descriptor : Pdfbox::Cos::Dictionary?, new_subtype : Pdfbox::Cos::Name) : Nil
      return if font_descriptor.nil?

      Log.warn { "Try to fix different descendant font types for font #{font_descriptor.get_name_as_string(Pdfbox::Cos::Name::FONT_NAME)}" }

      if new_subtype == Pdfbox::Cos::Name::CID_FONT_TYPE0 &&
         !font_descriptor.has_key?(Pdfbox::Cos::Name::FONT_FILE3) &&
         font_descriptor.has_key?(Pdfbox::Cos::Name::FONT_FILE2)
        font_descriptor[Pdfbox::Cos::Name::FONT_FILE3] = font_descriptor[Pdfbox::Cos::Name::FONT_FILE2].as(Pdfbox::Cos::Base)
        font_descriptor.delete(Pdfbox::Cos::Name::FONT_FILE2)
      end

      if new_subtype == Pdfbox::Cos::Name::CID_FONT_TYPE2 &&
         font_descriptor.has_key?(Pdfbox::Cos::Name::FONT_FILE3) &&
         !font_descriptor.has_key?(Pdfbox::Cos::Name::FONT_FILE2)
        font_descriptor[Pdfbox::Cos::Name::FONT_FILE2] = font_descriptor[Pdfbox::Cos::Name::FONT_FILE3].as(Pdfbox::Cos::Base)
        font_descriptor.delete(Pdfbox::Cos::Name::FONT_FILE3)
      end

      descendant_font[Pdfbox::Cos::Name::SUBTYPE] = new_subtype
    end

    private def self.get_font_header(font_descriptor : Pdfbox::Cos::Dictionary?) : Bytes?
      return nil if font_descriptor.nil?

      font_file = font_descriptor.get_stream(Pdfbox::Cos::Name::FONT_FILE) ||
                  font_descriptor.get_stream(Pdfbox::Cos::Name::FONT_FILE2) ||
                  font_descriptor.get_stream(Pdfbox::Cos::Name::FONT_FILE3)
      return nil if font_file.nil?

      data = font_file.data
      return nil if data.empty?

      header = Bytes.new(4, 0_u8)
      header_size = {data.size, 4}.min
      header.copy_from(data.to_unsafe, header_size)
      header
    end

    private def self.true_type_header?(header : Bytes) : Bool
      (header.size >= 4 && header[0] == 0_u8 && header[1] == 1_u8 && header[2] == 0_u8 && header[3] == 0_u8) ||
        (header.size == 4 && String.new(header) == FONT_TRUE_TYPE)
    end

    private def self.true_type_collection_header?(header : Bytes) : Bool
      header.size == 4 && String.new(header) == FONT_TTF_COLLECTION
    end

    private def self.open_type_header?(header : Bytes) : Bool
      header.size == 4 && String.new(header) == FONT_OPEN_TYPE
    end

    private def self.type1_header?(header : Bytes) : Bool
      header.size >= 2 && header[0] == 0x25_u8 && header[1] == 0x21_u8
    end

    private def self.pfb_header?(header : Bytes) : Bool
      header.size >= 2 && header[0] == 0x80_u8 && (header[1] == 0x01_u8 || header[1] == 0x02_u8)
    end

    private def self.cff_header?(header : Bytes) : Bool
      header.size >= 4 && header[0] >= 1_u8 && header[3] >= 1_u8 && header[3] <= 4_u8
    end
  end
end
