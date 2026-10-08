require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java#drawImage(PDInlineImage,...)
#
# Java writes the inline image directly into the content stream as
# q <matrix> cm BI /W .. /H .. /CS .. /BPC .. ID <data> EI Q.
private def inline_image(params_setup : Proc(Pdfbox::Cos::Dictionary, Nil)) : Pdfbox::Pdmodel::Graphics::Image::PDInlineImage
  params = Pdfbox::Cos::Dictionary.new
  params_setup.call(params)
  Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(params, Bytes[1_u8, 2_u8, 3_u8, 4_u8])
end

describe "PDPageContentStream#draw_image(PDInlineImage)" do
  it "writes BI ... ID ... EI inline image content (Java drawImage)" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    image = inline_image(->(p : Pdfbox::Cos::Dictionary) do
      p.set_int(Pdfbox::Cos::Name.new("W"), 2)
      p.set_int(Pdfbox::Cos::Name.new("H"), 2)
      p.set_int(Pdfbox::Cos::Name.new("BPC"), 8)
      p.set_name(Pdfbox::Cos::Name.new("CS"), "G")
    end)

    cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    cs.draw_image(image, 10, 20, 30, 40)
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    operators = tokens.compact_map(&.as?(Pdfbox::ContentStream::Operator))
    names = operators.map(&.name)

    names.should contain("q")
    names.should contain("cm")
    names.should contain("BI")
    names.should contain("Q")

    bi = operators.find { |op| op.name == "BI" }
    bi.should_not be_nil
    params = bi.not_nil!.image_parameters
    params.should_not be_nil
    params.not_nil!.get_int(Pdfbox::Cos::Name.new("W"), 0).should eq(2)
    params.not_nil!.get_int(Pdfbox::Cos::Name.new("H"), 0).should eq(2)
    params.not_nil!.get_int(Pdfbox::Cos::Name.new("BPC"), 0).should eq(8)
    # Java writes data then a line separator before EI; the (Java-identical)
    # parser includes that separator in the image data.
    bi.not_nil!.image_data.should eq(Bytes[1_u8, 2_u8, 3_u8, 4_u8, 0x0A_u8])
  end

  it "writes a Decode array and stencil flag when present" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    image = inline_image(->(p : Pdfbox::Cos::Dictionary) do
      p.set_int(Pdfbox::Cos::Name.new("W"), 1)
      p.set_int(Pdfbox::Cos::Name.new("H"), 1)
      p.set_int(Pdfbox::Cos::Name.new("BPC"), 1)
      p.set_name(Pdfbox::Cos::Name.new("CS"), "G")
      decode = Pdfbox::Cos::Array.new
      decode.add(Pdfbox::Cos::Integer.new(1))
      decode.add(Pdfbox::Cos::Integer.new(0))
      p[Pdfbox::Cos::Name.new("D")] = decode
      p[Pdfbox::Cos::Name.new("IM")] = Pdfbox::Cos::Boolean::TRUE
    end)

    cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    cs.draw_image(image, 0, 0, 1, 1)
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    bi = tokens.compact_map(&.as?(Pdfbox::ContentStream::Operator)).find { |op| op.name == "BI" }
    bi.should_not be_nil
    params = bi.not_nil!.image_parameters.not_nil!
    params.get_int(Pdfbox::Cos::Name.new("BPC"), 0).should eq(1)
    params[Pdfbox::Cos::Name.new("D")].should_not be_nil
    params[Pdfbox::Cos::Name.new("IM")].should_not be_nil
  end
end
