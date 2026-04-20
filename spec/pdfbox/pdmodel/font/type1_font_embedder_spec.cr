require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type1_font_embedder"

describe Pdfbox::Pdmodel::Font::PDType1FontEmbedder do
  it "embeds a PFB stream and exposes the Java helper surface" do
    pfb_path = "spec/resources/fonts/OpenSans-Regular.pfb"

    file = nil
    doc = nil
    begin
      file = ::File.new(pfb_path)
      doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
      dict = Pdfbox::Cos::Dictionary.new
      embedder = Pdfbox::Pdmodel::Font::PDType1FontEmbedder.new(doc, dict, file, nil)

      embedder.font_encoding.should be_a(Pdfbox::Pdmodel::Font::Encoding::Type1Encoding)
      embedder.glyph_list.should eq(Pdfbox::Pdmodel::Font::GlyphList.adobe_glyph_list)
      embedder.type1_font.should be_a(Fontbox::Type1::Type1Font)
      dict.get_name_as_string(Pdfbox::Cos::Name::BASE_FONT).should eq(embedder.type1_font.name)
      descriptor = dict.get_dictionary(Pdfbox::Cos::Name::FONT_DESC)
      descriptor.should_not be_nil
      Pdfbox::Pdmodel::Font::PDFontDescriptor.new(descriptor.as(Pdfbox::Cos::Dictionary)).font_file.should_not be_nil
    ensure
      file.try(&.close)
      doc.try(&.close)
    end
  end
end
