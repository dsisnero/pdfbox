require "../../spec_helper"

describe Pdfbox::Pdmodel::Page do
  it "TestPDPage#testAddingPageAfterCreatingAnnotation" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      document.document_catalog.not_nil!.acro_form = acro_form

      text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form)
      text_field.partial_name = "testField"
      widget = text_field.widgets[0]
      widget.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(100.0_f32, 700.0_f32, 200.0_f32, 20.0_f32)
      widget.page = page
      page.annotations.add(widget)
      acro_form.add_field(text_field)

      document.add_page(page)

      io = IO::Memory.new
      document.save(io)
      io.size.should be > 0
    ensure
      document.close
    end
  end
end
