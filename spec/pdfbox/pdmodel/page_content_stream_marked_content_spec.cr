require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#     beginMarkedContent(COSName), beginMarkedContent(COSName, int),
#     beginMarkedContent(COSName, PDPropertyList), endMarkedContent()
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/optionalcontent/TestOptionalContentGroups.java#testOCGGeneration
#
# Java writes `/Tag BMC`, `/Tag /oc1 BDC` (property list added to page
# /Resources /Properties with prefix "oc") or `/Tag <</MCID n>> BDC`, and EMC.
private def marked_content_stream : {Pdfbox::Pdmodel::Document, Pdfbox::Pdmodel::Page, Pdfbox::Pdmodel::PDPageContentStream}
  doc = Pdfbox::Pdmodel::Document.new
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)
  cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
  {doc, page, cs}
end

describe "PDPageContentStream marked content" do
  it "writes BMC for beginMarkedContent(tag)" do
    _, page, cs = marked_content_stream
    cs.begin_marked_content(Pdfbox::Cos::Name.new("P"))
    cs.end_marked_content
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    tokens[0].as(Pdfbox::Cos::Name).value.should eq("P")
    tokens[1].as(Pdfbox::ContentStream::Operator).name.should eq("BMC")
    tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("EMC")
  end

  it "writes BDC with the property list resource (Java beginMarkedContent(tag, propertyList))" do
    _, page, cs = marked_content_stream
    ocg = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("background")
    cs.begin_marked_content(Pdfbox::Cos::Name.new("OC"), ocg)
    cs.end_marked_content
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    tokens[0].as(Pdfbox::Cos::Name).value.should eq("OC")
    tokens[1].as(Pdfbox::Cos::Name).value.should eq("oc1")
    tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("BDC")
    tokens[3].as(Pdfbox::ContentStream::Operator).name.should eq("EMC")

    resources = page.cos_object.not_nil![Pdfbox::Cos::Name.new("Resources")].as(Pdfbox::Cos::Dictionary)
    properties = resources[Pdfbox::Cos::Name.new("Properties")].as(Pdfbox::Cos::Dictionary)
    properties[Pdfbox::Cos::Name.new("oc1")].should be(ocg.cos_object)
  end

  it "writes BDC with an MCID (Java beginMarkedContent(tag, mcid))" do
    _, page, cs = marked_content_stream
    cs.begin_marked_content(Pdfbox::Cos::Name.new("P"), 5)
    cs.end_marked_content
    cs.close

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    tokens[0].as(Pdfbox::Cos::Name).value.should eq("P")
    tokens[1].as(Pdfbox::Cos::Dictionary).get_int(Pdfbox::Cos::Name.new("MCID"), -1).should eq(5)
    tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("BDC")
  end

  it "rejects a negative MCID" do
    _, _, cs = marked_content_stream
    expect_raises(ArgumentError) { cs.begin_marked_content(Pdfbox::Cos::Name.new("P"), -1) }
  end
end
