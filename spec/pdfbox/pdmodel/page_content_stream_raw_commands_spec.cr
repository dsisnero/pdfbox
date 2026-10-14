require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDPageContentStream.java
#
# Characterization spec: upstream has no dedicated test for these helpers, so
# these assertions are inferred from the Java observable behavior.
private def raw_commands_stream : {Pdfbox::Pdmodel::Document, Pdfbox::Pdmodel::Page, Pdfbox::Pdmodel::PDPageContentStream}
  doc = Pdfbox::Pdmodel::Document.new
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)
  cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
  {doc, page, cs}
end

describe Pdfbox::Pdmodel::PDPageContentStream do
  it "reports the append-mode helpers" do
    Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE.overwrite?.should be_true
    Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE.prepend?.should be_false
    Pdfbox::Pdmodel::PDPageContentStream::AppendMode::PREPEND.prepend?.should be_true
    Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND.overwrite?.should be_false
  end

  it "appends raw string/byte commands" do
    _, page, cs = raw_commands_stream
    cs.append_raw_commands("q\n")
    cs.append_raw_commands("1 0 0 RG\n")
    cs.append_raw_commands("Q\n".to_slice)
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    tokens[0].as(Pdfbox::ContentStream::Operator).name.should eq("q")
    tokens[1].as(Pdfbox::Cos::Number).to_f32.should eq(1.0_f32)
    tokens[4].as(Pdfbox::ContentStream::Operator).name.should eq("RG")
    tokens[5].as(Pdfbox::ContentStream::Operator).name.should eq("Q")
  end
end
