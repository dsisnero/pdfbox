# PANOSE classification for font descriptors
# Corresponds to PDPanose and PDPanoseClassification in Apache PDFBox
module Pdfbox::Pdmodel::Font
  # Represents the "Panose" entry of a FontDescriptor's Style dictionary.
  # This is a sequence of 12 bytes which contain both the TTF sFamilyClass
  # and PANOSE classification bytes.
  class PDPanose
    # Length.
    LENGTH = 12

    @bytes : Bytes

    def initialize(@bytes : Bytes)
    end

    # The font family class and subclass ID bytes, given in the sFamilyClass field of the “OS/2” table in a TrueType font.
    def family_class : Int32
      (@bytes[0].to_i32 << 8) | (@bytes[1] & 0xff)
    end

    # Ten bytes for the PANOSE classification number for the font.
    def panose : PDPanoseClassification
      panose_bytes = @bytes[2, 10]
      PDPanoseClassification.new(panose_bytes)
    end
  end

  # Represents a 10-byte PANOSE classification.
  class PDPanoseClassification
    # Length.
    LENGTH = 10

    @bytes : Bytes

    def initialize(@bytes : Bytes)
    end

    def family_kind : Int32
      @bytes[0].to_i32
    end

    def serif_style : Int32
      @bytes[1].to_i32
    end

    def weight : Int32
      @bytes[2].to_i32
    end

    def proportion : Int32
      @bytes[3].to_i32
    end

    def contrast : Int32
      @bytes[4].to_i32
    end

    def stroke_variation : Int32
      @bytes[5].to_i32
    end

    def arm_style : Int32
      @bytes[6].to_i32
    end

    def letterform : Int32
      @bytes[7].to_i32
    end

    def midline : Int32
      @bytes[8].to_i32
    end

    def x_height : Int32
      @bytes[9].to_i32
    end

    def bytes : Bytes
      @bytes
    end

    def to_s : String
      "{ FamilyKind = #{family_kind}, " \
      "SerifStyle = #{serif_style}, " \
      "Weight = #{weight}, " \
      "Proportion = #{proportion}, " \
      "Contrast = #{contrast}, " \
      "StrokeVariation = #{stroke_variation}, " \
      "ArmStyle = #{arm_style}, " \
      "Letterform = #{letterform}, " \
      "Midline = #{midline}, " \
      "XHeight = #{x_height} }"
    end
  end
end
