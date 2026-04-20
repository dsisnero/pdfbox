module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDCircleAppearanceHandler < PDAbstractAppearanceHandler
    MAGIC = 0.55555417_f32

    def generate_normal_appearance : Nil
      line_width = self.line_width
      annot = wrapped_annotation.as(Annotation::PDAnnotationCircle)
      content_stream = normal_appearance_as_content_stream
      has_stroke = (content_stream.stroking_color_on_demand = color)
      has_background = (content_stream.non_stroking_color_on_demand = annot.interior_color)
      set_opacity(content_stream, annot.constant_opacity)
      content_stream.set_border_line(line_width, annot.border_style, annot.border)

      border_box = handle_border_box(annot, line_width)
      x0 = border_box.lower_left_x
      y0 = border_box.lower_left_y
      x1 = border_box.upper_right_x
      y1 = border_box.upper_right_y
      xm = x0 + border_box.width / 2.0_f32
      ym = y0 + border_box.height / 2.0_f32
      v_offset = border_box.height / 2.0_f32 * MAGIC
      h_offset = border_box.width / 2.0_f32 * MAGIC

      content_stream.move_to(xm, y1)
      content_stream.curve_to(xm + h_offset, y1, x1, ym + v_offset, x1, ym)
      content_stream.curve_to(x1, ym - v_offset, xm + h_offset, y0, xm, y0)
      content_stream.curve_to(xm - h_offset, y0, x0, ym - v_offset, x0, ym)
      content_stream.curve_to(x0, ym + v_offset, xm - h_offset, y1, xm, y1)
      content_stream.close_path
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
