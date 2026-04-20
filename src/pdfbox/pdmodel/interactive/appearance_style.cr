module Pdfbox::Pdmodel::Interactive
  class AppearanceStyle
    @font : Pdfbox::Pdmodel::Font::PDFont?
    @font_size : Float32 = 12.0_f32
    @leading : Float32 = 14.4_f32

    def font : Pdfbox::Pdmodel::Font::PDFont?
      @font
    end

    def font=(value : Pdfbox::Pdmodel::Font::PDFont) : Pdfbox::Pdmodel::Font::PDFont
      @font = value
      value
    end

    def font_size : Float32
      @font_size
    end

    def font_size=(value : Number) : Float32
      @font_size = value.to_f32
      @leading = @font_size * 1.2_f32
    end

    def leading : Float32
      @leading
    end

    def leading=(value : Number) : Float32
      @leading = value.to_f32
    end
  end
end
