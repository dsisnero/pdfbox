require "../../../pdfbox"

module Pdfbox::Examples::Interactive::Form
  # An example of creating an AcroForm with two widgets for one field, visible
  # on two separate pages.
  # Java: org.apache.pdfbox.examples.interactive.form.CreateMultiWidgetsForm
  class CreateMultiWidgetsForm
    DEFAULT_FILENAME = "target/MultiWidgetsForm.pdf"

    def self.main(args : Array(String)? = nil) : Nil
      document = Pdfbox::Pdmodel::Document.create
      begin
        page1 = Pdfbox::Pdmodel::Page.new
        page1.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(595.0, 842.0)
        document.add_page(page1)
        page2 = Pdfbox::Pdmodel::Page.new
        page2.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(595.0, 842.0)
        document.add_page(page2)

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

        widget1 = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
        rect = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 750.0_f32, 250.0_f32, 50.0_f32)
        widget1.rectangle = rect
        widget1.page = page1
        widget1.parent = text_box

        widget2 = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
        rect2 = Pdfbox::Pdmodel::Common::PDRectangle.new(200.0_f32, 650.0_f32, 100.0_f32, 50.0_f32)
        widget2.rectangle = rect2
        widget2.page = page2
        widget2.parent = text_box

        field_appearance1 = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
        field_appearance1.border_colour = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        field_appearance1.background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        widget1.appearance_characteristics = field_appearance1

        field_appearance2 = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
        field_appearance2.border_colour = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        field_appearance2.background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        widget2.appearance_characteristics = field_appearance2

        widgets = [widget1, widget2]
        text_box.set_widgets(widgets)

        widget1.printed = true
        widget2.printed = true

        page1.annotations.add(widget1)
        page2.annotations.add(widget2)

        text_box.value = "Sample field"

        filename = args.nil? || args.empty? ? DEFAULT_FILENAME : args[0]
        document.save(filename)
      ensure
        document.close
      end
    end
  end
end
