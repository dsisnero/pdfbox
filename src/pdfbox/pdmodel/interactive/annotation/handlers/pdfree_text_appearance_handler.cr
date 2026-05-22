require "./pdabstract_appearance_handler"
require "./cloudy_border"

module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDFreeTextAppearanceHandler < PDAbstractAppearanceHandler
    COLOR_PATTERN = /.*color\s*:\s*#([0-9a-fA-F]{6}).*/

    @font_size : Float32 = 10_f32
    @font_name : Cos::Name = Cos::Name.new("Helv")

    def initialize(@annotation : Annotation::PDAnnotation)
      super
    end

    def initialize(@annotation : Annotation::PDAnnotation, @document : Pdmodel::PDDocument)
      super
    end

    def generate_normal_appearance : Nil
      ann = @annotation.as(Annotation::PDAnnotationFreeText)
      paths_array = if Annotation::PDAnnotationFreeText::IT_FREE_TEXT_CALLOUT == ann.intent
                      c = ann.callout
                      if c && (c.size == 4 || c.size == 6)
                        c
                      else
                        [] of Float32
                      end
                    else
                      [] of Float32
                    end

      ab = AnnotationBorder.annotation_border(ann, ann.border_style)

      cs = normal_appearance_as_content_stream
      begin
        has_background = cs.non_stroking_color_on_demand = ann.color
        set_opacity(cs, ann.constant_opacity)

        stroking_color = extract_non_stroking_color(ann)
        has_stroke = cs.stroking_color_on_demand = stroking_color
        text_color = stroking_color
        default_style_string = ann.default_style_string
        if default_style_string
          m = default_style_string.match(COLOR_PATTERN)
          if m
            color_int = m[1].to_i(16)
            r = ((color_int >> 16) & 0xFF) / 255_f32
            g = ((color_int >> 8) & 0xFF) / 255_f32
            b = (color_int & 0xFF) / 255_f32
            text_color = Graphics::Color::PDColor.new([r, g, b], Graphics::Color::PDDeviceRGB::INSTANCE)
          end
        end

        if da = ab.dash_array
          cs.line_dash_pattern(da, 0)
        end
        cs.line_width(ab.width)

        line_ending_style = ann.line_ending_style

        # Draw callout lines
        (0...(paths_array.size // 2)).each do |i|
          x = paths_array[i * 2]
          y = paths_array[i * 2 + 1]
          if i == 0
            if SHORT_STYLES.includes?(line_ending_style)
              x1 = paths_array[2]
              y1 = paths_array[3]
              len = Math.sqrt((x - x1)**2 + (y - y1)**2)
              unless len == 0
                x += (x1 - x) / len * ab.width
                y += (y1 - y) / len * ab.width
              end
            end
            cs.move_to(x, y)
          else
            cs.line_to(x, y)
          end
        end
        cs.stroke if paths_array.size > 0

        # Paint line ending style
        if Annotation::PDAnnotationFreeText::IT_FREE_TEXT_CALLOUT == ann.intent &&
           !Annotation::PDAnnotationLine::LE_NONE == line_ending_style &&
           paths_array.size >= 4
          x2 = paths_array[2].as(Float32); y2 = paths_array[3].as(Float32)
          x1 = paths_array[0].as(Float32); y1 = paths_array[1].as(Float32)
          cs.save_graphics_state
          if ANGLED_STYLES.includes?(line_ending_style)
            angle = Math.atan2((y2 - y1).to_f64, (x2 - x1).to_f64)
            cs.transform(Util::Matrix.get_rotate_instance(angle, x1.to_f32, y1.to_f32))
          else
            cs.transform(Util::Matrix.translate(x1.to_f32, y1.to_f32))
          end
          draw_style(line_ending_style, cs, 0_f32, 0_f32, ab.width, has_stroke, has_background, false)
          cs.restore_graphics_state
        end

        border_box = Common::PDRectangle.new
        border_effect = ann.border_effect
        if border_effect && border_effect.style == Annotation::PDBorderEffectDictionary::STYLE_CLOUDY
          border_box = apply_rect_differences(rectangle || Common::PDRectangle.new, ann.rect_differences)
          cloudy = CloudyBorder.new(cs, border_effect.intensity.to_f64, ab.width.to_f64, rectangle || Common::PDRectangle.new)
          cloudy.create_cloudy_rectangle(ann.rect_difference)
          ann.rectangle = cloudy.rectangle
          ann.rect_difference = cloudy.rect_difference
          app_stream = ann.normal_appearance_stream
          app_stream.bbox = cloudy.bbox if app_stream
          app_stream.matrix = cloudy.matrix if app_stream
        else
          border_box = apply_rect_differences(rectangle || Common::PDRectangle.new, ann.rect_differences)
          ann.normal_appearance_stream.try(&.bbox = border_box)
          padded = padded_rectangle(border_box, ab.width / 2)
          cs.add_rect(padded.lower_left_x, padded.lower_left_y, padded.width, padded.height)
        end
        cs.draw_shape(ab.width, has_stroke, has_background)

        rotation_value = ann.cos_object[Cos::Name.new("Rotate")]?
        rotation = if rotation_value && rotation_value.is_a?(Cos::Integer)
                     rotation_value.as(Cos::Integer).value.to_i32
                   else
                     0
                   end
        cs.transform(Util::Matrix.get_rotate_instance(Math::PI * rotation / 180.0, 0_f32, 0_f32))

        width = (rotation == 90 || rotation == 270) ? border_box.height : border_box.width
        extract_font_details(ann)
        font = nil
        clip_width = width - ab.width * 4
        clip_height = (rotation == 90 || rotation == 270) ? border_box.width - ab.width * 4 : border_box.height - ab.width * 4

        if doc2 = @document
          acro_form = doc2.document_catalog.try(&.acro_form)
          if acro_form
            default_resources = acro_form.default_resources
            if default_resources
              font = default_resources.font(@font_name)
            end
          end
        end
        font ||= default_font

        y_delta = 0.7896_f32
        x_offset, _y_offset, clip_y = case rotation
                                      when 180
                                        {-border_box.upper_right_x + ab.width * 2,
                                         -border_box.lower_left_y - ab.width * 2 - y_delta * @font_size,
                                         -border_box.upper_right_y + ab.width * 2}
                                      when 90
                                        {border_box.lower_left_y + ab.width * 2,
                                         -border_box.lower_left_x - ab.width * 2 - y_delta * @font_size,
                                         -border_box.upper_right_x + ab.width * 2}
                                      when 270
                                        {-border_box.upper_right_y + ab.width * 2,
                                         border_box.upper_right_x - ab.width * 2 - y_delta * @font_size,
                                         border_box.lower_left_x + ab.width * 2}
                                      else
                                        {border_box.lower_left_x + ab.width * 2,
                                         border_box.upper_right_y - ab.width * 2 - y_delta * @font_size,
                                         border_box.lower_left_y + ab.width * 2}
                                      end

        cs.add_rect(x_offset, clip_y, clip_width, clip_height)
        # Clip not yet implemented on PDAppearanceContentStream
        # cs.clip

        annotation_contents = ann.contents
        if annotation_contents
          cs.begin_text
          cs.set_font(font, @font_size)
          cs.non_stroking_color = text_color
          # PlainTextFormatter not yet ported - text rendering deferred
          # TODO: Port PlainTextFormatter for FreeText annotation
          cs.show_text(annotation_contents)
          cs.end_text
        end

        if paths_array.size > 0 && (bbox_rect = rectangle)
          min_x = Float32::MAX; min_y = Float32::MAX
          max_x = Float32::MIN; max_y = Float32::MIN
          (0...(paths_array.size // 2)).each do |i|
            x = paths_array[i * 2]? || 0.0_f32
            y = paths_array[i * 2 + 1]? || 0.0_f32
            min_x = Math.min(min_x, x); min_y = Math.min(min_y, y)
            max_x = Math.max(max_x, x); max_y = Math.max(max_y, y)
          end
          bbox_rect.lower_left_x = (Math.min(min_x.to_f32 - ab.width * 10, bbox_rect.lower_left_x)).to_f32
          bbox_rect.lower_left_y = (Math.min(min_y.to_f32 - ab.width * 10, bbox_rect.lower_left_y)).to_f32
          bbox_rect.upper_right_x = (Math.max(max_x.to_f32 + ab.width * 10, bbox_rect.upper_right_x)).to_f32
          bbox_rect.upper_right_y = (Math.max(max_y.to_f32 + ab.width * 10, bbox_rect.upper_right_y)).to_f32
          ann.rectangle = bbox_rect
          ann.normal_appearance_stream.try(&.bbox = bbox_rect)
        end
      rescue ex
        # Log error
      ensure
        cs.close
      end
    end

    private def extract_non_stroking_color(app : Annotation::PDAnnotationFreeText) : Graphics::Color::PDColor
      stroking_color = Graphics::Color::PDColor.new([0_f32], Graphics::Color::PDDeviceGray::INSTANCE)
      default_appearance = app.default_appearance
      return stroking_color unless default_appearance

      begin
        parser = Pdfbox::Pdfparser::PDFStreamParser.new(default_appearance.to_slice)
        arguments = Cos::Array.new
        colors = nil
        graphic_op = nil
        loop do
          token = parser.parse_next_token
          break unless token
          if token.is_a?(ContentStream::Operator)
            op = token.as(ContentStream::Operator)
            case op.name
            when ContentStream::OperatorName::NON_STROKING_GRAY,
                 ContentStream::OperatorName::NON_STROKING_RGB,
                 ContentStream::OperatorName::NON_STROKING_CMYK
              graphic_op = op
              colors = arguments
            end
            arguments = Cos::Array.new
          else
            arguments << token.as(Cos::Base)
          end
        end
        if graphic_op
          case graphic_op.name
          when ContentStream::OperatorName::NON_STROKING_GRAY
            stroking_color = Graphics::Color::PDColor.new(colors.as(Cos::Array), Graphics::Color::PDDeviceGray::INSTANCE)
          when ContentStream::OperatorName::NON_STROKING_RGB
            stroking_color = Graphics::Color::PDColor.new(colors.as(Cos::Array), Graphics::Color::PDDeviceRGB::INSTANCE)
          when ContentStream::OperatorName::NON_STROKING_CMYK
            stroking_color = Graphics::Color::PDColor.new(colors.as(Cos::Array), Graphics::Color::PDDeviceCMYK::INSTANCE)
          end
        end
      rescue
      end
      stroking_color
    end

    private def extract_font_details(app : Annotation::PDAnnotationFreeText) : Nil
      default_appearance = app.default_appearance
      if default_appearance.nil? && (doc = @document)
        # Crystal port: PDAcroForm.default_appearance not yet implemented
        doc.document_catalog.try(&.acro_form)
      end
      return unless default_appearance

      begin
        parser = Pdfbox::Pdfparser::PDFStreamParser.new(default_appearance.to_slice)
        arguments = Cos::Array.new
        font_arguments = Cos::Array.new
        loop do
          token = parser.parse_next_token
          break unless token
          if token.is_a?(ContentStream::Operator)
            op = token.as(ContentStream::Operator)
            if op.name == ContentStream::OperatorName::SET_FONT_AND_SIZE
              font_arguments = arguments
            end
            arguments = Cos::Array.new
          else
            arguments << token.as(Cos::Base)
          end
        end
        if font_arguments.size >= 2
          base = font_arguments[0]
          if base.is_a?(Cos::Name)
            @font_name = base.as(Cos::Name)
          end
          base = font_arguments[1]
          if base.is_a?(Cos::Integer)
            @font_size = base.as(Cos::Integer).value.to_f32
          elsif base.is_a?(Cos::Float)
            @font_size = base.as(Cos::Float).value.to_f32
          end
        end
      rescue
      end
    end

    def generate_rollover_appearance : Nil
    end

    def generate_down_appearance : Nil
    end
  end
end
