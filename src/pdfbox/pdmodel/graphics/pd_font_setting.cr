module Pdfbox::Pdmodel::Graphics
  # A font setting used for the graphics state: a font and a font size, stored as
  # a two-element COS array [font, size]. Corresponds to PDFontSetting in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/PDFontSetting.java
  class PDFontSetting
    @font_setting : Cos::Array

    # Creates a blank font setting: the font is null and the size is 1.
    def initialize
      @font_setting = Cos::Array.new
      @font_setting.add(Cos::Null::INSTANCE)
      @font_setting.add(Cos::Float.new(1.0))
    end

    def initialize(@font_setting : Cos::Array)
    end

    def cos_object : Cos::Base
      @font_setting
    end

    # The font for this setting, or nil if none was found (Java getFont).
    def font : Pdfbox::Pdmodel::Font::PDFont?
      value = resolve(0)
      value.is_a?(Cos::Dictionary) ? Pdfbox::Pdmodel::Font::PDFontFactory.create_font(value) : nil
    end

    def font=(font : Pdfbox::Pdmodel::Font::PDFont?) : Nil
      @font_setting[0] = font ? font.cos_object : Cos::Null::INSTANCE
    end

    # The size of the font (Java getFontSize).
    def font_size : Float32
      value = @font_setting[1]?
      value.is_a?(Cos::Number) ? value.to_f32 : 0.0_f32
    end

    def font_size=(size : Float32) : Nil
      @font_setting[1] = Cos::Float.new(size.to_f64)
    end

    # Java COSArray#getObject: dereferences an indirect object and maps null to nil.
    private def resolve(index : Int) : Cos::Base?
      value = @font_setting[index]?
      value = value.object if value.is_a?(Cos::Object)
      return nil if value.is_a?(Cos::Null)
      value
    end
  end
end
