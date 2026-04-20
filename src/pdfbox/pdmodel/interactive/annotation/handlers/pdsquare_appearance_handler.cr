module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDSquareAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      line_width = self.line_width
      annot = wrapped_annotation.as(Annotation::PDAnnotationSquare)
      content_stream = normal_appearance_as_content_stream
      has_stroke = (content_stream.stroking_color_on_demand = color)
      has_background = (content_stream.non_stroking_color_on_demand = annot.interior_color)
      set_opacity(content_stream, annot.constant_opacity)
      content_stream.set_border_line(line_width, annot.border_style, annot.border)
      border_box = handle_border_box(annot, line_width)
      content_stream.add_rect(
        border_box.lower_left_x,
        border_box.lower_left_y,
        border_box.width,
        border_box.height
      )
      content_stream.draw_shape(line_width, has_stroke, has_background)
      content_stream.close
    end

    private def line_width : Float32
      annot = wrapped_annotation.as(Annotation::PDAnnotationMarkup)
      border_style = annot.border_style
      return border_style.width.to_f32 if border_style

      border = annot.border
      base = border[2]?
      case base
      when Cos::Integer then base.value.to_f32
      when Cos::Float   then base.value.to_f32
      else
        1.0_f32
      end
    end
  end
end
