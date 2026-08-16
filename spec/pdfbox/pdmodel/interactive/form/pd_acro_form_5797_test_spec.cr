require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormTest.java#testPDFBox5797
describe Pdfbox::Pdmodel::Interactive::Form::PDTextField do
  it "PDAcroFormTest#testPDFBox5797" do
    file = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/annotation/PDFBOX-5797-SO79271803.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      font_file = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"
      font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
      load_font = File.open(font_file) do |io|
        Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, io, false)
      end

      acro_form = document.document_catalog.not_nil!.acro_form
      resources = acro_form.not_nil!.default_resources.not_nil!
      font_name = resources.add(load_font).value
      default_appearance_string = "/#{font_name} 12 Tf 0 g"

      my_field = acro_form.not_nil!.get_field("Name").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      my_field.default_appearance = default_appearance_string
      my_field.widgets[0].appearance = nil
      my_field.value = "ŞŞ" # Text with the Ş character made it crash

      my_field.value.should eq("ŞŞ")
    ensure
      document.close
    end
  end
end
