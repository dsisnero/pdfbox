module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDLinkAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationLink)
      rect = annot.rectangle
      return unless rect

      width = resolved_line_width(annot)
      content_stream = normal_appearance_as_content_stream

      color = annot.color || Graphics::Color::PDColor.new([0.0_f32], Graphics::Color::PDDeviceGray::INSTANCE)
      has_stroke = content_stream.stroking_color_on_demand = color
      content_stream.set_border_line(width, annot.border_style, annot.border)

      border_edge = padded_rectangle(rect, (width / 2.0_f64).to_f32)
      paths_array = valid_quad_points(annot.quad_points, rect) || rectangle_quad_points(border_edge)

      underlined = paths_array.size >= 8 &&
                   annot.border_style.try(&.style) == Annotation::PDBorderStyleDictionary::STYLE_UNDERLINE

      offset = 0
      while offset + 7 < paths_array.size
        content_stream.move_to(paths_array[offset], paths_array[offset + 1])
        content_stream.line_to(paths_array[offset + 2], paths_array[offset + 3])
        unless underlined
          content_stream.line_to(paths_array[offset + 4], paths_array[offset + 5])
          content_stream.line_to(paths_array[offset + 6], paths_array[offset + 7])
          content_stream.close_path
        end
        offset += 8
      end

      content_stream.draw_shape(width, has_stroke, false)
      content_stream.close
    end

    private def resolved_line_width(link_annotation : Annotation::PDAnnotationLink) : Float64
      border_style = link_annotation.border_style
      return border_style.width if border_style

      border_characteristics = link_annotation.border
      if border_characteristics.size >= 3
        base = border_characteristics[2]?
        case base
        when Cos::Integer
          return base.value.to_f64
        when Cos::Float
          return base.value.to_f64
        end
      end

      1.0_f64
    end

    private def valid_quad_points(quad_points : Array(Float64)?, rect : Common::PDRectangle) : Array(Float64)?
      return unless quad_points

      (quad_points.size // 2).times do |index|
        x = quad_points[index * 2].to_f32
        y = quad_points[index * 2 + 1].to_f32
        return unless contains_point?(rect, x, y)
      end

      quad_points
    end

    private def rectangle_quad_points(rect : Common::PDRectangle) : Array(Float64)
      [
        rect.lower_left_x.to_f64,
        rect.lower_left_y.to_f64,
        rect.upper_right_x.to_f64,
        rect.lower_left_y.to_f64,
        rect.upper_right_x.to_f64,
        rect.upper_right_y.to_f64,
        rect.lower_left_x.to_f64,
        rect.upper_right_y.to_f64,
      ]
    end

    private def contains_point?(rect : Common::PDRectangle, x : Float32, y : Float32) : Bool
      x >= rect.lower_left_x &&
        x <= rect.upper_right_x &&
        y >= rect.lower_left_y &&
        y <= rect.upper_right_y
    end
  end
end
