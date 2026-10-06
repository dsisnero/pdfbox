require "../../../pdfbox"

module Pdfbox::Examples::Interactive::Form
  # An example of creating an AcroForm and a form field from scratch.
  # Java: org.apache.pdfbox.examples.interactive.form.CreateSimpleForm
  class CreateSimpleForm
    DEFAULT_FILENAME = "target/SimpleForm.pdf"

    def self.main(args : Array(String)? = nil) : Nil
      document = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(595.0, 842.0)
        document.add_page(page)

        font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
        resources = Pdfbox::Pdmodel::PDResources.new
        resources.put(Pdfbox::Cos::Name.new("Helv"), font)

        acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
        # ameba:disable Lint/NotNil
        document.document_catalog.not_nil!.acro_form = acro_form

        acro_form.default_resources = resources

        acro_form.default_appearance = "/Helv 0 Tf 0 g"

        text_box = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form)
        text_box.partial_name = "SampleField"

        text_box.default_appearance = "/Helv 12 Tf 0 0 1 rg"

        acro_form.add_field(text_box)

        widget = text_box.widgets[0]
        rect = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 750.0_f32, 200.0_f32, 50.0_f32)
        widget.rectangle = rect
        widget.page = page

        field_appearance = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
        field_appearance.border_colour = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        field_appearance.background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        widget.appearance_characteristics = field_appearance

        widget.printed = true

        page.annotations.add(widget)

        text_box.q = Pdfbox::Pdmodel::Interactive::Form::PDVariableText::QUADDING_CENTERED

        text_box.value = "Sample field content"

        cs = Pdfbox::Pdmodel::PDPageContentStream.new(document, page)
        begin
          cs.begin_text
          cs.set_font(Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA), 15)
          cs.new_line_at_offset(50, 810)
          cs.show_text("Field:")
          cs.end_text
        ensure
          cs.close
        end

        if args.nil? || args.empty?
          document.save(DEFAULT_FILENAME)
        else
          document.save(args[0])
        end
      ensure
        document.close
      end
    end
  end
end
