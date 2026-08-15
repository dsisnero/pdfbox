require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/annotation/AppearanceGenerationTest.java#testTinyHorizontalFieldWith0FontSize
describe "AppearanceGenerationTest parity" do
  it "testTinyHorizontalFieldWith0FontSize avoids -Infinity for a tiny field with 0 font size" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      document.add_page(page)

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
      resources = Pdfbox::Pdmodel::PDResources.new
      resources.put(Pdfbox::Cos::Name.new("Helv"), font)
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      document.document_catalog.not_nil!.acro_form = acro_form
      acro_form.default_resources = resources

      default_appearance_string = "/Helv 0 Tf 0 g"
      acro_form.default_appearance = default_appearance_string
      text_box = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form, Pdfbox::Cos::Dictionary.new, nil)
      text_box.partial_name = "SampleField"
      text_box.default_appearance = default_appearance_string
      acro_form.add_field(text_box)

      widget = text_box.widgets[0]
      rect = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 750.0_f32, 1.0_f32, 50.0_f32)
      widget.rectangle = rect
      widget.page = page
      page.annotations.add(widget)

      # PDFBOX-5763: mayhem happened here — a tiny horizontal field with 0
      # (variable) font size and no content must not produce -Infinity.
      text_box.value = ""

      stream = widget.normal_appearance_stream
      stream.should_not be_nil
      content = String.new(stream.not_nil!.require_stream_object.data)
      content.should_not contain("Inf")
      content.should_not contain("inf")
    ensure
      document.close
    end
  end
end
