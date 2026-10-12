require "../../common/cos_objectable"
require "../../graphics/color/pdcolor"
require "../../graphics/color/pddevice_rgb"
require "../../graphics/pd_line_dash_pattern"

module Pdfbox::Pdmodel::DocumentInterchange::Prepress
  # The Box Style specifies visual characteristics for displaying box areas.
  # Corresponds to PDBoxStyle in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/prepress/PDBoxStyle.java
  class PDBoxStyle
    include Pdfbox::Pdmodel::Common::COSObjectable

    GUIDELINE_STYLE_SOLID  = "S"
    GUIDELINE_STYLE_DASHED = "D"

    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    # Java getGuidelineColor: the RGB guideline colour, default [0, 0, 0],
    # guaranteed non-nil.
    def guideline_color : Pdfbox::Pdmodel::Graphics::Color::PDColor
      color_values = @dictionary.get_array(Cos::Name.new("C"))
      unless color_values
        color_values = Cos::Array.new([Cos::Integer.new(0), Cos::Integer.new(0), Cos::Integer.new(0)])
        @dictionary[Cos::Name.new("C")] = color_values
      end
      Pdfbox::Pdmodel::Graphics::Color::PDColor.new(
        color_values, Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    end

    # Java setGuideLineColor.
    def guide_line_color=(color : Pdfbox::Pdmodel::Graphics::Color::PDColor?) : Nil
      key = Cos::Name.new("C")
      if color
        @dictionary[key] = color.to_cos_array
      else
        @dictionary.delete(key)
      end
    end

    # Java getGuidelineWidth: the guideline width, default 1.
    def guideline_width : Float32
      @dictionary.get_float(Cos::Name.new("W"), 1.0).to_f32
    end

    # Java setGuidelineWidth.
    def guideline_width=(width : Float32) : Nil
      @dictionary.set_float(Cos::Name.new("W"), width.to_f64)
    end

    # Java getGuidelineStyle: /S, default "S" (solid).
    def guideline_style : String
      @dictionary.get_name_as_string(Cos::Name.new("S")) || GUIDELINE_STYLE_SOLID
    end

    # Java setGuidelineStyle.
    def guideline_style=(style : String) : Nil
      @dictionary.set_name(Cos::Name.new("S"), style)
    end

    # Java getLineDashPattern: the /D dash pattern, default [3], phase 0,
    # guaranteed non-nil.
    def line_dash_pattern : Pdfbox::Pdmodel::Graphics::PDLineDashPattern
      d = @dictionary.get_array(Cos::Name.new("D"))
      unless d
        d = Cos::Array.new([Cos::Integer.new(3)])
        @dictionary[Cos::Name.new("D")] = d
      end
      # Java copies the array (new COSArray(d)); dash phase is assumed to be 0.
      Pdfbox::Pdmodel::Graphics::PDLineDashPattern.new(Cos::Array.new(d.items), 0)
    end

    # Java setLineDashPattern.
    def line_dash_pattern=(dash_array : Cos::Array?) : Nil
      key = Cos::Name.new("D")
      if dash_array
        @dictionary[key] = dash_array
      else
        @dictionary.delete(key)
      end
    end
  end
end
