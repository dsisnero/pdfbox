require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDTrueTypeFont.java
#     load(PDDocument, File, Encoding), load(PDDocument, InputStream, Encoding),
#     load(PDDocument, TrueTypeFont, Encoding)
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDType1Font.java
#     PDType1Font(PDDocument, InputStream), PDType1Font(PDDocument, InputStream, Encoding)
#
# Java has a single PDDocument type. The Crystal port grew two: the real
# `Pdfbox::Pdmodel::Document` (what `Loader.load_pdf` / `Document.create` return)
# and the legacy `Pdfbox::Pdmodel::PDDocument` stub. These specs pin that the font
# embedders accept the real document, so embedding does not require a throwaway
# document whose COS streams the target document never sees.
private LIBERATION_SANS_TTF = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"
private OPEN_SANS_PFB       = "spec/resources/fonts/OpenSans-Regular.pfb"

private def embedded_text_round_trip(font : Pdfbox::Pdmodel::Font::PDFont) : {String, Pdfbox::Pdmodel::Font::PDFont}
  doc = Pdfbox::Pdmodel::Document.create
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)

  cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
  cs.begin_text
  cs.set_font(font, 12)
  cs.new_line_at_offset(75, 750)
  cs.show_text("Apache PDFBox")
  cs.end_text
  cs.close

  output = IO::Memory.new
  doc.save(output)
  doc.close

  loaded = Pdfbox::Loader.load_pdf(output.to_slice)
  text = Pdfbox::Text::PDFTextStripper.new.get_text(loaded)
  resources = loaded.get_page(0).resources.not_nil!
  loaded_font = resources.font(resources.font_names.first).not_nil!
  {text, loaded_font}
end

describe "font embedding into Pdfbox::Pdmodel::Document" do
  it "PDTrueTypeFont.load embeds into the real document (Java load(PDDocument, File, Encoding))" do
    doc = Pdfbox::Pdmodel::Document.create
    encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
    font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(doc, File.open(LIBERATION_SANS_TTF), encoding)
    font.embedded?.should be_true
    doc.close

    text, loaded_font = embedded_text_round_trip(font)
    text.should contain("Apache PDFBox")
    loaded_font.embedded?.should be_true
  end

  it "PDType1Font embeds into the real document (Java PDType1Font(PDDocument, InputStream))" do
    doc = Pdfbox::Pdmodel::Document.create
    font = Pdfbox::Pdmodel::Font::PDType1Font.new(doc, File.open(OPEN_SANS_PFB))
    font.embedded?.should be_true
    doc.close

    text, loaded_font = embedded_text_round_trip(font)
    text.should contain("Apache PDFBox")
    loaded_font.embedded?.should be_true
  end

  it "still accepts the legacy PDDocument for both loaders" do
    legacy = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
    encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
    Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(legacy, File.open(LIBERATION_SANS_TTF), encoding).embedded?.should be_true
    Pdfbox::Pdmodel::Font::PDType1Font.new(legacy, File.open(OPEN_SANS_PFB)).embedded?.should be_true
  end
end
