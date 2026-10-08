require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDPageContentStream.java#shadingFill
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java#add(PDShading)
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDShading.java#create
#
# Java shadingFill adds the shading to the page resources (name prefix "sh"),
# writes the resource name and the sh operator.
private def shading_dict(type : Int32) : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict.set_int(Pdfbox::Cos::Name.new("ShadingType"), type)
  dict
end

describe "PDPageContentStream#shading_fill" do
  it "adds the shading to resources and writes the resource name (Java shadingFill)" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    shading = Pdfbox::Pdmodel::Graphics::Shading::PDShadingType1.new(shading_dict(1))
    cs = Pdfbox::Pdmodel::PDPageContentStream.new(
      doc, page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE, true
    )
    cs.shading_fill(shading)
    cs.close

    cos_page = page.cos_object.not_nil!
    resources = cos_page[Pdfbox::Cos::Name.new("Resources")].as(Pdfbox::Cos::Dictionary)
    shadings = resources[Pdfbox::Cos::Name.new("Shading")].as(Pdfbox::Cos::Dictionary)
    shadings[Pdfbox::Cos::Name.new("sh1")].should be(shading.cos_object)

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(page).parse
    tokens[0].as(Pdfbox::Cos::Name).value.should eq("sh1")
    tokens[1].as(Pdfbox::ContentStream::Operator).name.should eq("sh")
  end

  it "raises when in text mode" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    shading = Pdfbox::Pdmodel::Graphics::Shading::PDShadingType1.new(shading_dict(1))
    cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
    cs.begin_text
    expect_raises(Pdfbox::Pdmodel::IllegalStateError) { cs.shading_fill(shading) }
  end
end

describe Pdfbox::Pdmodel::Graphics::Shading::PDShading do
  it "creates type-specific shadings from the ShadingType entry" do
    (1..7).each do |type|
      Pdfbox::Pdmodel::Graphics::Shading::PDShading.create(shading_dict(type)).should_not be_nil
    end
    expect_raises(::ArgumentError) { Pdfbox::Pdmodel::Graphics::Shading::PDShading.create(shading_dict(8)) }
  end
end
