require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#     setStrokingColor(PDColor)/setNonStrokingColor(PDColor): emit the color
#     space (CS/cs) only when it changed, then the components and SC/sc.
private def pdcolor_content_text(page : Pdfbox::Pdmodel::Page) : String
  contents = page.cos_object.not_nil![Pdfbox::Cos::Name.new("Contents")]
  contents = contents.object if contents.is_a?(Pdfbox::Cos::Object)
  contents.as(Pdfbox::Cos::Stream).create_input_stream.gets_to_end
end

private def pdcolor_stream : {Pdfbox::Pdmodel::Page, Pdfbox::Pdmodel::PDPageContentStream}
  doc = Pdfbox::Pdmodel::Document.new
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)
  {page, Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)}
end

describe "PDPageContentStream PDColor" do
  it "sets the stroking color and emits the color space once (Java setStrokingColor(PDColor))" do
    page, cs = pdcolor_stream
    rgb = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
    cs.stroking_color(Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], rgb))
    cs.stroking_color(Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], rgb))
    cs.close

    text = pdcolor_content_text(page)
    text.should contain("/DeviceRGB CS")
    text.should contain("1 0 0 SC")
    text.should contain("0 1 0 SC")
    text.scan("/DeviceRGB CS").size.should eq(1)
  end

  it "sets the non-stroking color (Java setNonStrokingColor(PDColor))" do
    page, cs = pdcolor_stream
    gray = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
    cs.non_stroking_color(Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.5_f32], gray))
    cs.close

    text = pdcolor_content_text(page)
    text.should contain("/DeviceGray cs")
    text.should contain("0.5 sc")
  end

  it "does not re-emit the color space after a device-color setter (Java color space stack)" do
    page, cs = pdcolor_stream
    cs.stroking_color(1.0) # G, sets the stack to DeviceGray
    cs.stroking_color(Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.5_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE))
    cs.close

    pdcolor_content_text(page).scan("/DeviceGray CS").size.should eq(0)
  end

  it "restores the device color space after Q (Java saveGraphicsState/restoreGraphicsState)" do
    page, cs = pdcolor_stream
    rgb = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
    gray = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
    cs.stroking_color(Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], rgb))
    cs.save_graphics_state
    cs.stroking_color(Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.5_f32], gray))
    cs.restore_graphics_state
    cs.stroking_color(Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], rgb))
    cs.close

    pdcolor_content_text(page).scan("/DeviceRGB CS").size.should eq(1)
  end
end
