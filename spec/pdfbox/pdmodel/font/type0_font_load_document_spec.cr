require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDType0Font.java
#     load(PDDocument, InputStream), load(PDDocument, TrueTypeFont), load(PDDocument, File),
#     loadVertical(PDDocument, InputStream)
#
# Java has a single PDDocument type. The Crystal port grew two: the real
# `Pdfbox::Pdmodel::Document` (what `Loader.load_pdf` / `Document.create` return)
# and the legacy `Pdfbox::Pdmodel::PDDocument` stub. `PDType0Font.load` only
# accepted the stub, so embedding a font into the document you are actually
# building required an unrelated throwaway document. This spec pins that the
# real document is accepted, end to end (embed -> save -> reload -> extract).
private LIBERATION_SANS = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

describe "PDType0Font.load(Pdfbox::Pdmodel::Document)" do
  it "embeds a subset font into the document and round-trips the text" do
    doc = Pdfbox::Pdmodel::Document.create
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    font = Pdfbox::Pdmodel::Font::PDType0Font.load(doc, File.open(LIBERATION_SANS))
    font.embedded?.should be_true

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
    Pdfbox::Text::PDFTextStripper.new.get_text(loaded).should contain("Apache PDFBox")

    loaded_page = loaded.get_page(0)
    resources = loaded_page.resources.not_nil!
    font_name = resources.font_names.first
    loaded_font = resources.font(font_name).not_nil!
    loaded_font.embedded?.should be_true
    loaded.close
  end

  it "accepts the legacy PDDocument as before" do
    legacy = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
    font = Pdfbox::Pdmodel::Font::PDType0Font.load(legacy, File.open(LIBERATION_SANS))
    font.embedded?.should be_true
  end
end
