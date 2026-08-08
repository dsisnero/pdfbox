require "../../spec_helper"
require "../../../src/pdfbox"

describe Pdfbox::Rendering::PDFRenderer do
  it "renders a page with a square annotation appearance stream" do
    doc = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0_f64, 0.0_f64, 612.0_f64, 792.0_f64)
      doc.add_page(page)

      # Add a square annotation with a generated appearance stream
      square = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare.new
      square.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(100.0_f32, 100.0_f32, 200.0_f32, 200.0_f32)
      color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(
        [1.0_f32, 0.0_f32, 0.0_f32],
        Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
      )
      square.color = color
      square.construct_appearances
      square.normal_appearance_stream.should_not be_nil

      page.annotations = [square]

      renderer = Pdfbox::Rendering::PDFRenderer.new(doc)
      image = renderer.render_image(0)
      image.should_not be_nil
      image.rect.width.should be > 0
      image.rect.height.should be > 0
    ensure
      doc.close
    end
  end

  it "renders a page without annotations" do
    doc = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0_f64, 0.0_f64, 612.0_f64, 792.0_f64)
      doc.add_page(page)

      renderer = Pdfbox::Rendering::PDFRenderer.new(doc)
      image = renderer.render_image(0)
      image.should_not be_nil
      image.rect.width.should be > 0
    ensure
      doc.close
    end
  end
end
