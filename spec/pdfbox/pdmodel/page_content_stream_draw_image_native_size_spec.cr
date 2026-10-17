require "../../spec_helper"

# Port of the native-size drawImage overloads:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#     drawImage(PDImageXObject image, float x, float y) -> drawImage(image, x, y, image.getWidth(), image.getHeight())
#     drawImage(PDInlineImage inlineImage, float x, float y) -> drawImage(inlineImage, x, y, inlineImage.getWidth(), inlineImage.getHeight())
#
# The two-argument form is exercised by upstream TestCOSIncrement#testIncrementallyCreateDocument,
# which calls contentStream.drawImage(image, 15, 20).
private def native_token_numbers(tokens : Array(Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator)) : Array(Float32)
  numbers = [] of Float32
  tokens.each do |token|
    case token
    when Pdfbox::Cos::Integer then numbers << token.value.to_f32
    when Pdfbox::Cos::Float   then numbers << token.value.to_f32
    end
  end
  numbers
end

private def native_inline_image(width : Int32, height : Int32) : Pdfbox::Pdmodel::Graphics::Image::PDInlineImage
  params = Pdfbox::Cos::Dictionary.new
  params.set_int(Pdfbox::Cos::Name.new("W"), width)
  params.set_int(Pdfbox::Cos::Name.new("H"), height)
  params.set_int(Pdfbox::Cos::Name.new("BPC"), 8)
  params.set_name(Pdfbox::Cos::Name.new("CS"), "G")
  Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(params, Bytes[1_u8, 2_u8, 3_u8, 4_u8])
end

describe "PDPageContentStream#draw_image native-size overloads" do
  it "draws an image XObject at its native size (Java drawImage(image, x, y))" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
    image.width = 100
    image.height = 50

    cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    cs.draw_image(image, 10, 20)
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    operators = tokens.compact_map(&.as?(Pdfbox::ContentStream::Operator))
    names = operators.map(&.name)

    names.first.should eq("q")
    names.should contain("cm")
    names.should contain("Do")
    names.last.should eq("Q")

    # 100 0 0 50 10 20 cm - width/height come from the image itself.
    numbers = native_token_numbers(tokens)
    numbers[0].should eq(100.0_f32)
    numbers[1].should eq(0.0_f32)
    numbers[2].should eq(0.0_f32)
    numbers[3].should eq(50.0_f32)
    numbers[4].should eq(10.0_f32)
    numbers[5].should eq(20.0_f32)

    xobjects = page.resources.not_nil!.cos_object.get_dictionary(Pdfbox::Cos::Name.new("XObject"))
    xobjects.should_not be_nil
    xobjects.not_nil!.has_key?(Pdfbox::Cos::Name.new("Im1")).should be_true
  ensure
    doc.try(&.close)
  end

  it "draws an inline image at its native size (Java drawImage(inlineImage, x, y))" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    image = native_inline_image(2, 3)

    cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    cs.draw_image(image, 10, 20)
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    numbers = native_token_numbers(tokens)
    numbers[0].should eq(2.0_f32)
    numbers[1].should eq(0.0_f32)
    numbers[2].should eq(0.0_f32)
    numbers[3].should eq(3.0_f32)
    numbers[4].should eq(10.0_f32)
    numbers[5].should eq(20.0_f32)

    bi = tokens.compact_map(&.as?(Pdfbox::ContentStream::Operator)).find { |op| op.name == "BI" }
    bi.should_not be_nil
    params = bi.not_nil!.image_parameters.not_nil!
    params.get_int(Pdfbox::Cos::Name.new("W"), 0).should eq(2)
    params.get_int(Pdfbox::Cos::Name.new("H"), 0).should eq(3)
  ensure
    doc.try(&.close)
  end

  it "rejects native-size drawing inside a text block" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
    image.width = 1
    image.height = 1

    cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    cs.begin_text

    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { cs.draw_image(image, 0, 0) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { cs.draw_image(native_inline_image(1, 1), 0, 0) }

    cs.end_text
    cs.close
  ensure
    doc.try(&.close)
  end
end
