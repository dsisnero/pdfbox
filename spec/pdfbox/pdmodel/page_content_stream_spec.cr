require "../../spec_helper"

private def token_float(token : Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator) : Float32
  token.as(Pdfbox::Cos::Number).to_f32
end

private def token_operator_name(token : Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator) : String
  token.as(Pdfbox::ContentStream::Operator).name
end

describe Pdfbox::Pdmodel::PDPageContentStream do
  it "TestPDPageContentStream#testSetCmykColors" do
    doc = Pdfbox::Pdmodel::Document.new

    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)
    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(
      doc,
      page,
      Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE,
      true
    )
    content_stream.non_stroking_color(0.1, 0.2, 0.3, 0.4)

    expect_raises(ArgumentError) { content_stream.non_stroking_color(1.1, 0, 0, 0) }
    expect_raises(ArgumentError) { content_stream.non_stroking_color(0, 1.1, 0, 0) }
    expect_raises(ArgumentError) { content_stream.non_stroking_color(0, 0, 1.1, 0) }
    expect_raises(ArgumentError) { content_stream.non_stroking_color(0, 0, 0, 1.1) }
    content_stream.close

    page_tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    token_float(page_tokens[0]).should eq(0.1_f32)
    token_float(page_tokens[1]).should eq(0.2_f32)
    token_float(page_tokens[2]).should eq(0.3_f32)
    token_float(page_tokens[3]).should eq(0.4_f32)
    token_operator_name(page_tokens[4]).should eq(Pdfbox::ContentStream::OperatorName::NON_STROKING_CMYK)

    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)
    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(
      doc,
      page,
      Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE,
      false
    )
    content_stream.stroking_color(0.5, 0.6, 0.7, 0.8)

    expect_raises(ArgumentError) { content_stream.stroking_color(1.1, 0, 0, 0) }
    expect_raises(ArgumentError) { content_stream.stroking_color(0, 1.1, 0, 0) }
    expect_raises(ArgumentError) { content_stream.stroking_color(0, 0, 1.1, 0) }
    expect_raises(ArgumentError) { content_stream.stroking_color(0, 0, 0, 1.1) }
    content_stream.close

    page_tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    token_float(page_tokens[0]).should eq(0.5_f32)
    token_float(page_tokens[1]).should eq(0.6_f32)
    token_float(page_tokens[2]).should eq(0.7_f32)
    token_float(page_tokens[3]).should eq(0.8_f32)
    token_operator_name(page_tokens[4]).should eq(Pdfbox::ContentStream::OperatorName::STROKING_COLOR_CMYK)
  ensure
    doc.try(&.close)
  end

  it "TestPDPageContentStream#testSetRGBandGColors" do
    doc = Pdfbox::Pdmodel::Document.new

    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)
    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(
      doc,
      page,
      Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE,
      true
    )
    content_stream.non_stroking_color(0.1, 0.2, 0.3)
    content_stream.non_stroking_color(0.8)

    expect_raises(ArgumentError) { content_stream.non_stroking_color(1.1, 0, 0) }
    expect_raises(ArgumentError) { content_stream.non_stroking_color(0, 1.1, 0) }
    expect_raises(ArgumentError) { content_stream.non_stroking_color(0, 0, 1.1) }
    expect_raises(ArgumentError) { content_stream.non_stroking_color(1.1) }
    content_stream.close

    page_tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    token_float(page_tokens[0]).should eq(0.1_f32)
    token_float(page_tokens[1]).should eq(0.2_f32)
    token_float(page_tokens[2]).should eq(0.3_f32)
    token_operator_name(page_tokens[3]).should eq(Pdfbox::ContentStream::OperatorName::NON_STROKING_RGB)
    token_float(page_tokens[4]).should eq(0.8_f32)
    token_operator_name(page_tokens[5]).should eq(Pdfbox::ContentStream::OperatorName::NON_STROKING_GRAY)

    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)
    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(
      doc,
      page,
      Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE,
      false
    )
    content_stream.stroking_color(0.5, 0.6, 0.7)
    content_stream.stroking_color(0.8)

    expect_raises(ArgumentError) { content_stream.stroking_color(1.1, 0, 0) }
    expect_raises(ArgumentError) { content_stream.stroking_color(0, 1.1, 0) }
    expect_raises(ArgumentError) { content_stream.stroking_color(0, 0, 1.1) }
    expect_raises(ArgumentError) { content_stream.stroking_color(1.1) }
    content_stream.close

    page_tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    token_float(page_tokens[0]).should eq(0.5_f32)
    token_float(page_tokens[1]).should eq(0.6_f32)
    token_float(page_tokens[2]).should eq(0.7_f32)
    token_operator_name(page_tokens[3]).should eq(Pdfbox::ContentStream::OperatorName::STROKING_COLOR_RGB)
    token_float(page_tokens[4]).should eq(0.8_f32)
    token_operator_name(page_tokens[5]).should eq(Pdfbox::ContentStream::OperatorName::STROKING_COLOR_GRAY)
  ensure
    doc.try(&.close)
  end

  it "TestPDPageContentStream#testMissingContentStream" do
    page = Pdfbox::Pdmodel::Page.new
    Pdfbox::Pdfparser::PDFStreamParser.new(page).parse.should be_empty
  end

  it "TestPDPageContentStream#testCloseContract" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(
      doc,
      page,
      Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE,
      true
    )
    content_stream.close
    content_stream.close
  ensure
    doc.try(&.close)
  end

  it "TestPDPageContentStream#testGeneralGraphicStateOperatorTextMode" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)
    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    content_stream.begin_text

    img1 = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
    img2 = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(
      Pdfbox::Cos::Dictionary.new,
      Bytes.empty,
      Pdfbox::Pdmodel::PDResources.new(Pdfbox::Cos::Dictionary.new)
    )

    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.draw_image(img1, 0, 0, 1, 1) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.draw_image(img1, Pdfbox::Util::Matrix.new) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.draw_image(img2, 0, 0, 1, 1) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.add_rect(0, 0, 1, 1) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.curve_to(0, 0, 1, 1, 2, 2) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.curve_to1(0, 0, 1, 1) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.curve_to2(0, 0, 1, 1) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.move_to(0, 0) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.line_to(1, 1) }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) do
      content_stream.shading_fill(Pdfbox::Pdmodel::Graphics::Shading::PDShadingType1.new(Pdfbox::Cos::Dictionary.new))
    end
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.stroke }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.close_and_stroke }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.close_and_fill_and_stroke }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.close_and_fill_and_stroke_even_odd }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.fill }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.fill_and_stroke }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.fill_and_stroke_even_odd }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.fill_even_odd }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.close_path }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.clip }
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { content_stream.clip_even_odd }

    content_stream.line_cap_style(0)
    content_stream.line_join_style(0)
    content_stream.line_width(10)
    content_stream.line_dash_pattern([2.0, 1.0], 0)
    content_stream.miter_limit(1.0)
    content_stream.graphics_state_parameters(Pdfbox::Pdmodel::Graphics::State::PDExtendedGraphicsState.new)
    content_stream.end_text
    content_stream.close
  ensure
    doc.try(&.close)
  end

  it "TestPDPageContentStream#testDrawImage" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
    content_stream.draw_image(image, 10, 20, 100, 200)
    content_stream.close

    page_tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse

    # q (save graphics state)
    token_operator_name(page_tokens[0]).should eq(Pdfbox::ContentStream::OperatorName::SAVE)

    # 100 0 0 200 10 20 cm (concatenate matrix)
    page_tokens[1].as(Pdfbox::Cos::Number).to_f32.should eq(100.0_f32)
    page_tokens[2].as(Pdfbox::Cos::Number).to_f32.should eq(0.0_f32)
    page_tokens[3].as(Pdfbox::Cos::Number).to_f32.should eq(0.0_f32)
    page_tokens[4].as(Pdfbox::Cos::Number).to_f32.should eq(200.0_f32)
    page_tokens[5].as(Pdfbox::Cos::Number).to_f32.should eq(10.0_f32)
    page_tokens[6].as(Pdfbox::Cos::Number).to_f32.should eq(20.0_f32)
    token_operator_name(page_tokens[7]).should eq(Pdfbox::ContentStream::OperatorName::CONCAT)

    # /Im1 Do (draw image object)
    page_tokens[8].as(Pdfbox::Cos::Name).value.should eq("Im1")
    token_operator_name(page_tokens[9]).should eq(Pdfbox::ContentStream::OperatorName::DRAW_OBJECT)

    # Q (restore graphics state)
    token_operator_name(page_tokens[10]).should eq(Pdfbox::ContentStream::OperatorName::RESTORE)
  ensure
    doc.try(&.close)
  end

  it "TestPDPageContentStream#testDrawImageWithMatrix" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
    matrix = Pdfbox::Util::Matrix.new(2.0_f32, 0.0_f32, 0.0_f32, 3.0_f32, 50.0_f32, 60.0_f32)
    content_stream.draw_image(image, matrix)
    content_stream.close

    page_tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse

    # q
    token_operator_name(page_tokens[0]).should eq(Pdfbox::ContentStream::OperatorName::SAVE)

    # 2 0 0 3 50 60 cm
    page_tokens[1].as(Pdfbox::Cos::Number).to_f32.should eq(2.0_f32)
    page_tokens[2].as(Pdfbox::Cos::Number).to_f32.should eq(0.0_f32)
    page_tokens[3].as(Pdfbox::Cos::Number).to_f32.should eq(0.0_f32)
    page_tokens[4].as(Pdfbox::Cos::Number).to_f32.should eq(3.0_f32)
    page_tokens[5].as(Pdfbox::Cos::Number).to_f32.should eq(50.0_f32)
    page_tokens[6].as(Pdfbox::Cos::Number).to_f32.should eq(60.0_f32)
    token_operator_name(page_tokens[7]).should eq(Pdfbox::ContentStream::OperatorName::CONCAT)

    # /Im1 Do
    page_tokens[8].as(Pdfbox::Cos::Name).value.should eq("Im1")
    token_operator_name(page_tokens[9]).should eq(Pdfbox::ContentStream::OperatorName::DRAW_OBJECT)

    # Q
    token_operator_name(page_tokens[10]).should eq(Pdfbox::ContentStream::OperatorName::RESTORE)
  ensure
    doc.try(&.close)
  end
end
