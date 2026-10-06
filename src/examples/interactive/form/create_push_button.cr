require "../../../pdfbox"

module Pdfbox::Examples::Interactive::Form
  # Example to create a push button with a JavaScript action and image appearance.
  # Java: org.apache.pdfbox.examples.interactive.form.CreatePushButton
  class CreatePushButton
    DEFAULT_FILENAME = "target/PushButtonSample.pdf"

    def self.main(args : Array(String)? = nil) : Nil
      document = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        document.add_page(page)
        acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
        # ameba:disable Lint/NotNil
        document.document_catalog.not_nil!.acro_form = acro_form

        push_button = Pdfbox::Pdmodel::Interactive::Form::PDPushButton.new(acro_form)
        push_button.partial_name = "push"
        acro_form.add_field(push_button)

        widget = push_button.widgets[0]
        page.annotations.add(widget)
        widget.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 500.0_f32, 100.0_f32, 100.0_f32)
        widget.printed = true
        widget.page = page

        javascript_action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
        javascript_action.action = "app.alert(\"button pressed\")"
        actions = Pdfbox::Pdmodel::Interactive::Action::PDAnnotationAdditionalActions.new
        actions.u = javascript_action
        widget.actions = actions

        form = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(document)
        form.resources = Pdfbox::Pdmodel::PDResources.new
        form.bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(100.0_f32, 100.0_f32)
        form.form_type = 1

        appearance_dictionary = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new(Pdfbox::Cos::Dictionary.new)
        widget.appearance = appearance_dictionary
        appearance_stream = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(form.cos_object.as(Pdfbox::Cos::Stream))
        appearance_dictionary.normal_appearance = appearance_stream

        # black 100x100 image
        black = CrImage::RGBA.new(CrImage.rect(0, 0, 100, 100))
        0.upto(99) do |y|
          0.upto(99) do |x|
            black.set(x, y, CrImage::Color::RGBA.new(0_u8, 0_u8, 0_u8, 255_u8))
          end
        end
        image = Pdfbox::Pdmodel::Graphics::Image::LosslessFactory.create_from_image(document, black)
        cs = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream)
        begin
          cs.draw_image(image, 0, 0)
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
