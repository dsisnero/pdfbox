require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#
# The path operators must write their operands before the operator, e.g.
# addRect(1,2,3,4) -> "1 2 3 4 re", moveTo(5,6) -> "5 6 m".
private def new_content_stream : {Pdfbox::Pdmodel::Document, Pdfbox::Pdmodel::Page, Pdfbox::Pdmodel::PDPageContentStream}
  doc = Pdfbox::Pdmodel::Document.new
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)
  cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
  {doc, page, cs}
end

private def content_tokens(page : Pdfbox::Pdmodel::Page) : Array(Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator)
  Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
end

describe "PDPageContentStream path operators" do
  it "writes addRect operands" do
    _, page, cs = new_content_stream
    cs.add_rect(1, 2, 3, 4)
    cs.close

    tokens = content_tokens(page)
    tokens[0..3].map(&.as(Pdfbox::Cos::Number).to_f32).should eq([1.0_f32, 2.0_f32, 3.0_f32, 4.0_f32])
    tokens[4].as(Pdfbox::ContentStream::Operator).name.should eq("re")
  end

  it "writes moveTo and lineTo operands" do
    _, page, cs = new_content_stream
    cs.move_to(5, 6)
    cs.line_to(7, 8)
    cs.close

    tokens = content_tokens(page)
    tokens[0..1].map(&.as(Pdfbox::Cos::Number).to_f32).should eq([5.0_f32, 6.0_f32])
    tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("m")
    tokens[3..4].map(&.as(Pdfbox::Cos::Number).to_f32).should eq([7.0_f32, 8.0_f32])
    tokens[5].as(Pdfbox::ContentStream::Operator).name.should eq("l")
  end

  it "writes curveTo operands (c, v, y)" do
    _, page, cs = new_content_stream
    cs.curve_to(1, 2, 3, 4, 5, 6)
    cs.curve_to1(7, 8, 9, 10)
    cs.curve_to2(11, 12, 13, 14)
    cs.close

    tokens = content_tokens(page)
    tokens[0..5].map(&.as(Pdfbox::Cos::Number).to_f32).should eq([1.0_f32, 2.0_f32, 3.0_f32, 4.0_f32, 5.0_f32, 6.0_f32])
    tokens[6].as(Pdfbox::ContentStream::Operator).name.should eq("c")
    # Java: curveTo1 -> CURVE_TO_REPLICATE_FINAL_POINT ("y");
    #       curveTo2 -> CURVE_TO_REPLICATE_INITIAL_POINT ("v").
    tokens[7..10].map(&.as(Pdfbox::Cos::Number).to_f32).should eq([7.0_f32, 8.0_f32, 9.0_f32, 10.0_f32])
    tokens[11].as(Pdfbox::ContentStream::Operator).name.should eq("y")
    tokens[12..15].map(&.as(Pdfbox::Cos::Number).to_f32).should eq([11.0_f32, 12.0_f32, 13.0_f32, 14.0_f32])
    tokens[16].as(Pdfbox::ContentStream::Operator).name.should eq("v")
  end
end
