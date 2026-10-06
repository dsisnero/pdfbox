require "../../../pdfbox"

module Pdfbox::Examples::Interactive::Form
  # An example of creating an AcroForm with a fully embedded font allowing
  # non-WinAnsiEncoding input.
  # Java: org.apache.pdfbox.examples.interactive.form.CreateSimpleFormWithEmbeddedFont
  class CreateSimpleFormWithEmbeddedFont
    DEFAULT_FILENAME = "target/SimpleFormWithEmbeddedFont.pdf"

    def self.main(args : Array(String)? = nil) : Nil
      document = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(595.0, 842.0)
        document.add_page(page)
        acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
        # ameba:disable Lint/NotNil
        document.document_catalog.not_nil!.acro_form = acro_form

        font_path = File.join(__DIR__, "../../../../vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf")
        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        form_font = Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, ::File.open(font_path), false)

        resources = Pdfbox::Pdmodel::PDResources.new
        acro_form.default_resources = resources
        font_name = resources.add(form_font).value

        acro_form.default_resources = resources
        default_appearance_string = "/#{font_name} 0 Tf 0 g"

        text_box = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form)
        text_box.partial_name = "SampleField"
        text_box.default_appearance = default_appearance_string
        acro_form.add_field(text_box)

        widget = text_box.widgets[0]
        rect = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 700.0_f32, 200.0_f32, 50.0_f32)
        widget.rectangle = rect
        widget.page = page
        page.annotations.add(widget)

        field_appearance = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
        field_appearance.border_colour = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        field_appearance.background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        widget.appearance_characteristics = field_appearance

        text_box.value = "Sample field İ"

        cs = Pdfbox::Pdmodel::PDPageContentStream.new(document, page)
        begin
          cs.begin_text
          cs.set_font(Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA), 15)
          cs.new_line_at_offset(50, 760)
          cs.show_text("Field:")
          cs.end_text
        ensure
          cs.close
        end

        filename = args.nil? || args.empty? ? DEFAULT_FILENAME : args[0]
        document.save(filename)
      ensure
        document.close
      end
    end
  end
end
