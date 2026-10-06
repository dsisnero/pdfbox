require "../../../pdfbox"

module Pdfbox::Examples::Interactive::Form
  # Example to create radio buttons.
  # Java: org.apache.pdfbox.examples.interactive.form.CreateRadioButtons
  class CreateRadioButtons
    DEFAULT_FILENAME = "target/RadioButtonsSample.pdf"

    def self.main(args : Array(String)? = nil) : Nil
      document = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(595.0, 842.0)
        document.add_page(page)
        acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
        # ameba:disable Lint/NotNil
        document.document_catalog.not_nil!.acro_form = acro_form

        options = ["a", "b", "c"]
        radio_button = Pdfbox::Pdmodel::Interactive::Form::PDRadioButton.new(acro_form)
        radio_button.partial_name = "MyRadioButton"
        radio_button.set_export_values(options)

        appearance_characteristics = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
        appearance_characteristics.border_colour = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        appearance_characteristics.background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.3_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

        widgets = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget
        options.size.times do |i|
          widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
          widget.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(30.0_f32, (842.0_f32 - 40 - i * 35).to_f32, 30.0_f32, 30.0_f32)
          widget.printed = true
          widget.appearance_characteristics = appearance_characteristics
          border_style_dictionary = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
          border_style_dictionary.width = 2
          border_style_dictionary.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary::STYLE_SOLID
          widget.border_style = border_style_dictionary
          widget.page = page

          ap_n_dict = Pdfbox::Cos::Dictionary.new
          ap_n_dict[Pdfbox::Cos::Name.new("Off")] = create_appearance_stream(document, widget, false).cos_object
          ap_n_dict[Pdfbox::Cos::Name.new(options[i])] = create_appearance_stream(document, widget, true).cos_object

          appearance = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new
          appearance_n_entry = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry.new(ap_n_dict)
          appearance.normal_appearance = appearance_n_entry
          widget.appearance = appearance
          widget.appearance_state = "Off"
          widgets << widget
          page.annotations.add(widget)
        end
        radio_button.set_widgets(widgets)

        acro_form.add_field(radio_button)

        helvetica = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
        contents = Pdfbox::Pdmodel::PDPageContentStream.new(document, page)
        begin
          options.size.times do |i|
            contents.begin_text
            contents.set_font(helvetica, 15)
            contents.new_line_at_offset(70, (842.0_f32 - 30 - i * 35).to_f32)
            contents.show_text(options[i])
            contents.end_text
          end
        ensure
          contents.close
        end

        radio_button.value = "c"

        filename = args.nil? || args.empty? ? DEFAULT_FILENAME : args[0]
        document.save(filename)
      ensure
        document.close
      end
    end

    private def self.create_appearance_stream(document : Pdfbox::Pdmodel::Document, widget : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget, on : Bool) : Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream
      # ameba:disable Lint/NotNil
      rect = widget.rectangle.not_nil!
      on_ap = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(Pdfbox::Cos::Stream.new)
      on_ap.bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(rect.width, rect.height)
      on_ap_cs = Pdfbox::Pdmodel::PDAppearanceContentStream.new(on_ap)
      begin
        # ameba:disable Lint/NotNil
        appearance_characteristics = widget.appearance_characteristics.not_nil!
        # ameba:disable Lint/NotNil
        background_color = appearance_characteristics.background.not_nil!
        # ameba:disable Lint/NotNil
        border_color = appearance_characteristics.border_colour.not_nil!
        line_width = get_line_width(widget)
        on_ap_cs.set_border_line(line_width, widget.border_style, widget.border)
        on_ap_cs.non_stroking_color = background_color
        radius = Math.min(rect.width / 2, rect.height / 2)
        draw_circle(on_ap_cs, rect.width / 2, rect.height / 2, radius)
        on_ap_cs.fill
        on_ap_cs.stroking_color = border_color
        draw_circle(on_ap_cs, rect.width / 2, rect.height / 2, radius - line_width / 2)
        on_ap_cs.stroke
        if on
          on_ap_cs.non_stroking_color(0.0_f32)
          draw_circle(on_ap_cs, rect.width / 2, rect.height / 2, (radius - line_width) / 2)
          on_ap_cs.fill
        end
      ensure
        on_ap_cs.close
      end
      on_ap
    end

    def self.get_line_width(widget : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget) : Float32
      bs = widget.border_style
      bs ? bs.width.to_f32 : 1.0_f32
    end

    def self.draw_circle(cs : Pdfbox::Pdmodel::PDAppearanceContentStream, x : Float32, y : Float32, r : Float32) : Nil
      magic = r * 0.551784_f32
      cs.move_to(x, y + r)
      cs.curve_to(x + magic, y + r, x + r, y + magic, x + r, y)
      cs.curve_to(x + r, y - magic, x + magic, y - r, x, y - r)
      cs.curve_to(x - magic, y - r, x - r, y - magic, x - r, y)
      cs.curve_to(x - r, y + magic, x - magic, y + r, x, y + r)
      cs.close_path
    end
  end
end
