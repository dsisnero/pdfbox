require "../../../pdfbox"

module Pdfbox::Examples::Interactive::Form
  # Example to create a checkbox.
  # Java: org.apache.pdfbox.examples.interactive.form.CreateCheckBox
  class CreateCheckBox
    DEFAULT_FILENAME = "target/CheckBoxSample.pdf"

    def self.main(args : Array(String)? = nil) : Nil
      document = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        document.add_page(page)

        acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
        # ameba:disable Lint/NotNil
        document.document_catalog.not_nil!.acro_form = acro_form

        x = 50.0_f32
        y = ((page.media_box.try(&.upper_right_y) || 792.0_f32) - 50.0_f32).to_f32
        rect = Pdfbox::Pdmodel::Common::PDRectangle.new(x, y, 20.0_f32, 20.0_f32)

        checkbox = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(acro_form)
        checkbox.partial_name = "MyCheckBox"
        widget = checkbox.widgets[0]
        widget.page = page
        widget.rectangle = rect
        widget.printed = true

        appearance_characteristics = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
        appearance_characteristics.border_colour = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        appearance_characteristics.background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
        appearance_characteristics.normal_caption = "4"
        widget.appearance_characteristics = appearance_characteristics

        border_style_dictionary = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
        border_style_dictionary.width = 1
        border_style_dictionary.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary::STYLE_SOLID
        widget.border_style = border_style_dictionary

        ap = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new
        widget.appearance = ap
        normal_appearance = ap.normal_appearance

        # ameba:disable Lint/NotNil
        normal_appearance_dict = normal_appearance.not_nil!.cos_object
        zapf_dingbats = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::ZAPF_DINGBATS)
        normal_appearance_dict[Pdfbox::Cos::Name.new("Off")] = create_appearance_stream(document, widget, false, zapf_dingbats).cos_object
        normal_appearance_dict[Pdfbox::Cos::Name.new("Yes")] = create_appearance_stream(document, widget, true, zapf_dingbats).cos_object

        page.annotations.add(checkbox.widgets[0])
        acro_form.add_field(checkbox)

        checkbox.uncheck

        filename = args.nil? || args.empty? ? DEFAULT_FILENAME : args[0]
        document.save(filename)
      ensure
        document.close
      end
    end

    private def self.create_appearance_stream(document : Pdfbox::Pdmodel::Document, widget : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget, on : Bool, font : Pdfbox::Pdmodel::Font::PDFont) : Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream
      # ameba:disable Lint/NotNil
      rect = widget.rectangle.not_nil!
      yes_ap = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(Pdfbox::Cos::Stream.new)
      yes_ap.bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(rect.width, rect.height)
      yes_ap.resources = Pdfbox::Pdmodel::PDResources.new
      yes_ap_cs = Pdfbox::Pdmodel::PDAppearanceContentStream.new(yes_ap)
      begin
        # ameba:disable Lint/NotNil
        appearance_characteristics = widget.appearance_characteristics.not_nil!
        # ameba:disable Lint/NotNil
        background_color = appearance_characteristics.background.not_nil!
        # ameba:disable Lint/NotNil
        border_color = appearance_characteristics.border_colour.not_nil!
        line_width = get_line_width(widget)
        # ameba:disable Lint/NotNil
        yes_ap_cs.set_border_line(line_width, widget.border_style, widget.border.not_nil!)
        yes_ap_cs.non_stroking_color = background_color
        yes_ap_cs.add_rect(0, 0, rect.width, rect.height)
        yes_ap_cs.fill
        yes_ap_cs.stroking_color = border_color
        yes_ap_cs.add_rect(line_width / 2, line_width / 2, rect.width - line_width, rect.height - line_width)
        yes_ap_cs.stroke
        unless on
          return yes_ap
        end

        yes_ap_cs.add_rect(line_width, line_width, rect.width - line_width * 2, rect.height - line_width * 2)
        yes_ap_cs.clip

        normal_caption = appearance_characteristics.normal_caption || "4"
        if normal_caption == "8"
          yes_ap_cs.stroking_color(0.0_f32)
          yes_ap_cs.move_to(line_width * 2, rect.height - line_width * 2)
          yes_ap_cs.line_to(rect.width - line_width * 2, line_width * 2)
          yes_ap_cs.move_to(rect.width - line_width * 2, rect.height - line_width * 2)
          yes_ap_cs.line_to(line_width * 2, line_width * 2)
          yes_ap_cs.stroke
        else
          afm_path = File.join(__DIR__, "../../../../vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/afm/ZapfDingbats.afm")
          metric = Fontbox::AFM::Parser.new(::File.open(afm_path)).parse
          bounds = nil
          unicode = nil
          metric.char_metrics.each do |char_metric|
            if normal_caption.codepoints[0] == char_metric.character_code
              bb = char_metric.bounding_box
              bounds = bb
              unicode = Pdfbox::Pdmodel::Font::GlyphList.zapf_dingbats.to_unicode(char_metric.name)
              break
            end
          end
          raise ::IO::Error.new("Bounds rectangle for chosen glyph is empty") unless bounds
          size = Math.min(bounds.width, bounds.height) / 1000.0_f32
          font_size = (rect.width - line_width * 2) / size * 0.6666_f32
          x_offset = (rect.width - (bounds.width) / 1000.0_f32 * font_size) / 2.0_f32
          x_offset -= bounds.lower_left_x / 1000.0_f32 * font_size
          y_offset = (rect.height - (bounds.height) / 1000.0_f32 * font_size) / 2.0_f32
          y_offset -= bounds.lower_left_y / 1000.0_f32 * font_size
          yes_ap_cs.non_stroking_color(0.0_f32)
          yes_ap_cs.begin_text
          yes_ap_cs.set_font(font, font_size)
          yes_ap_cs.new_line_at_offset(x_offset, y_offset)
          # ameba:disable Lint/NotNil
          yes_ap_cs.show_text(unicode.not_nil!)
          yes_ap_cs.end_text
        end
      ensure
        yes_ap_cs.close
      end
      yes_ap
    end

    def self.get_line_width(widget : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget) : Float32
      bs = widget.border_style
      bs ? bs.width.to_f32 : 1.0_f32
    end
  end
end
