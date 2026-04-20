module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDPolygonAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationPolygon)
      rect = annot.rectangle
      return unless rect

      path_array = path_array(annot)
      return unless path_array

      line_width = line_width(annot)

      min_x = Float64::MAX
      min_y = Float64::MAX
      max_x = Float64::MIN
      max_y = Float64::MIN

      path_array.each do |points_array|
        point_count = points_array.size // 2
        point_count.times do |i|
          x = points_array[i * 2]
          y = points_array[i * 2 + 1]
          min_x = Math.min(min_x, x)
          min_y = Math.min(min_y, y)
          max_x = Math.max(max_x, x)
          max_y = Math.max(max_y, y)
        end
      end

      rect.lower_left_x = Math.min((min_x - line_width).to_f32, rect.lower_left_x)
      rect.lower_left_y = Math.min((min_y - line_width).to_f32, rect.lower_left_y)
      rect.upper_right_x = Math.max((max_x + line_width).to_f32, rect.upper_right_x)
      rect.upper_right_y = Math.max((max_y + line_width).to_f32, rect.upper_right_y)
      annot.rectangle = rect

      content_stream = normal_appearance_as_content_stream
      has_stroke = content_stream.stroking_color_on_demand = annot.color
      has_background = content_stream.non_stroking_color_on_demand = annot.interior_color
      set_opacity(content_stream, annot.constant_opacity)
      content_stream.set_border_line(line_width, annot.border_style, annot.border)

      unless cloudy_border?(annot)
        path_array.each_with_index do |points_array, index|
          case points_array.size
          when 2
            if index == 0
              content_stream.move_to(points_array[0], points_array[1])
            else
              content_stream.line_to(points_array[0], points_array[1])
            end
          when 6
            content_stream.curve_to(
              points_array[0], points_array[1],
              points_array[2], points_array[3],
              points_array[4], points_array[5]
            )
          end
        end
        content_stream.close_path
      end

      content_stream.draw_shape(line_width, has_stroke, has_background)
      content_stream.close
    end

    private def path_array(annot : Annotation::PDAnnotationPolygon) : Array(Array(Float64))?
      # PDF 2.0 path takes priority over vertices.
      path = annot.path
      return path unless path.nil?

      vertices_array = annot.vertices
      return unless vertices_array

      points = vertices_array.size // 2
      Array(Array(Float64)).new(points) do |i|
        [vertices_array[i * 2], vertices_array[i * 2 + 1]]
      end
    end

    private def cloudy_border?(annot : Annotation::PDAnnotationPolygon) : Bool
      border_effect = annot.border_effect
      return false unless border_effect

      border_effect.style == Annotation::PDBorderEffectDictionary::STYLE_CLOUDY
    end

    private def line_width(annot : Annotation::PDAnnotationPolygon) : Float32
      if border_style = annot.border_style
        border_style.width.to_f32
      else
        border = annot.border
        if border.size >= 3
          border.get_int(2).to_f32
        else
          1.0_f32
        end
      end
    end
  end
end
