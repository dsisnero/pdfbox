require "crimage"
require "crimage/util/captcha"

module Pdfbox::Rendering
  # CrImage-backed TrueType text renderer used by PDF rendering components.
  class TrueTypeFontRenderer
    getter font_size : Float64
    getter face : CrImage::Font::Face

    def initialize(font_path : String, @font_size : Float64 = 12.0)
      font = FreeType::TrueType.load(font_path)
      @face = FreeType::TrueType.new_face(font, @font_size)
    end

    def line_height : Int32
      face.line_height
    end

    def ascent : Int32
      face.ascent
    end

    def descent : Int32
      face.descent
    end

    def measure_text(text : String) : {Int32, Int32}
      face.text_size(text)
    end

    def render_text(
      text : String,
      foreground : CrImage::Color::Color = CrImage::Color::BLACK,
      background : CrImage::Color::Color = CrImage::Color::WHITE,
      padding : Int32 = 2,
    ) : CrImage::RGBA
      text_width, text_height = measure_text(text)
      content_height = Math.max(text_height, line_height)
      width = Math.max(1, text_width + padding * 2)
      height = Math.max(1, content_height + padding * 2)

      image = CrImage.rgba(width, height, background)
      source = CrImage::Uniform.new(foreground)
      baseline_y = padding + ascent
      dot = CrImage::Math::Fixed::Point26_6.new(
        CrImage::Math::Fixed::Int26_6[padding * 64],
        CrImage::Math::Fixed::Int26_6[baseline_y * 64]
      )

      drawer = CrImage::Font::Drawer.new(image, source, face, dot)
      drawer.draw(text)
      image
    end
  end
end
