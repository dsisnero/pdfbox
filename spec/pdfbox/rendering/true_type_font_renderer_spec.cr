require "../../spec_helper"

describe Pdfbox::Rendering::TrueTypeFontRenderer do
  font_path = "vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf"

  it "loads a TrueType face and reports non-zero text metrics" do
    renderer = Pdfbox::Rendering::TrueTypeFontRenderer.new(font_path, 24.0)

    width, height = renderer.measure_text("PDFBox Crystal")
    width.should be > 0
    height.should be > 0
    renderer.line_height.should be > 0
  end

  it "renders text to an image with non-background pixels" do
    renderer = Pdfbox::Rendering::TrueTypeFontRenderer.new(font_path, 28.0)
    image = renderer.render_text("PDF", CrImage::Color::BLACK, CrImage::Color::WHITE, padding: 4)

    image.bounds.width.should be > 0
    image.bounds.height.should be > 0

    found_ink = false
    bounds = image.bounds
    bounds.min.y.upto(bounds.max.y - 1) do |y|
      bounds.min.x.upto(bounds.max.x - 1) do |x|
        color = image.at(x, y)
        r, g, b, _a = color.rgba
        # Background is white; rendered glyph pixels should introduce non-white samples.
        if r != 0xFFFF_u32 || g != 0xFFFF_u32 || b != 0xFFFF_u32
          found_ink = true
          break
        end
      end
      break if found_ink
    end

    found_ink.should be_true
  end
end
