module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDInkAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      ink = wrapped_annotation.as(Annotation::PDAnnotationInk)
      color = ink.color
      return unless color
      return if color.components.empty?

      annotation_border = AnnotationBorder.annotation_border(ink, ink.border_style)
      return if annotation_border.width == 0.0_f32

      rect = ink.rectangle
      return unless rect

      ink_list = ink.ink_list
      min_x = Float64::MAX
      min_y = Float64::MAX
      max_x = Float64::MIN
      max_y = Float64::MIN

      ink_list.each do |path_array|
        n_points = path_array.size // 2
        n_points.times do |i|
          x = path_array[i * 2]
          y = path_array[i * 2 + 1]
          min_x = Math.min(min_x, x)
          min_y = Math.min(min_y, y)
          max_x = Math.max(max_x, x)
          max_y = Math.max(max_y, y)
        end
      end

      rect.lower_left_x = Math.min((min_x - annotation_border.width * 2).to_f32, rect.lower_left_x)
      rect.lower_left_y = Math.min((min_y - annotation_border.width * 2).to_f32, rect.lower_left_y)
      rect.upper_right_x = Math.max((max_x + annotation_border.width * 2).to_f32, rect.upper_right_x)
      rect.upper_right_y = Math.max((max_y + annotation_border.width * 2).to_f32, rect.upper_right_y)
      ink.rectangle = rect

      content_stream = normal_appearance_as_content_stream
      set_opacity(content_stream, ink.constant_opacity)
      content_stream.stroking_color = color
      if dash_array = annotation_border.dash_array
        content_stream.line_dash_pattern(dash_array, 0)
      end
      content_stream.line_width(annotation_border.width)

      ink_list.each do |path_array|
        n_points = path_array.size // 2
        n_points.times do |i|
          x = path_array[i * 2]
          y = path_array[i * 2 + 1]
          if i == 0
            content_stream.move_to(x, y)
          else
            content_stream.line_to(x, y)
          end
        end
        content_stream.stroke
      end

      content_stream.close
    end
  end
end
