module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDPolylineAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationPolyline)
      rect = annot.rectangle
      return unless rect

      paths_array = annot.vertices
      return unless paths_array
      return if paths_array.size < 4

      annotation_border = AnnotationBorder.annotation_border(annot, annot.border_style)
      color = annot.color
      return unless color
      return if color.components.empty? || annotation_border.width == 0.0_f32

      adjust_polyline_rectangle(annot, rect, paths_array, annotation_border.width)
      start_point_ending_style = annot.start_point_ending_style
      end_point_ending_style = annot.end_point_ending_style

      content_stream = normal_appearance_as_content_stream
      has_background = content_stream.non_stroking_color_on_demand = annot.interior_color
      set_opacity(content_stream, annot.constant_opacity)
      has_stroke = content_stream.stroking_color_on_demand = color

      if dash_array = annotation_border.dash_array
        content_stream.line_dash_pattern(dash_array, 0)
      end
      content_stream.line_width(annotation_border.width)

      draw_polyline_path(content_stream, paths_array, annotation_border.width, start_point_ending_style, end_point_ending_style)
      draw_start_style(content_stream, paths_array, annotation_border.width, start_point_ending_style, has_stroke, has_background)
      draw_end_style(content_stream, paths_array, annotation_border.width, end_point_ending_style, has_stroke, has_background)

      content_stream.close
    end

    private def draw_polyline_path(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      paths_array : Array(Float64),
      line_width : Float32,
      start_point_ending_style : String,
      end_point_ending_style : String,
    ) : Nil
      point_count = paths_array.size // 2
      point_count.times do |i|
        x, y = adjusted_polyline_point(paths_array, i, line_width, start_point_ending_style, end_point_ending_style)
        if i == 0
          content_stream.move_to(x, y)
        else
          content_stream.line_to(x, y)
        end
      end
      content_stream.stroke
    end

    private def adjusted_polyline_point(
      paths_array : Array(Float64),
      index : Int32,
      line_width : Float32,
      start_point_ending_style : String,
      end_point_ending_style : String,
    ) : Tuple(Float32, Float32)
      x = paths_array[index * 2].to_f32
      y = paths_array[index * 2 + 1].to_f32
      point_count = paths_array.size // 2

      if index == 0 && SHORT_STYLES.includes?(start_point_ending_style)
        x1 = paths_array[2]
        y1 = paths_array[3]
        len = line_length(x, y, x1, y1)
        if len != 0.0_f64
          x += ((x1 - x) / len * line_width).to_f32
          y += ((y1 - y) / len * line_width).to_f32
        end
      elsif index == point_count - 1 && SHORT_STYLES.includes?(end_point_ending_style)
        x0 = paths_array[paths_array.size - 4]
        y0 = paths_array[paths_array.size - 3]
        len = line_length(x0, y0, x, y)
        if len != 0.0_f64
          x -= ((x - x0) / len * line_width).to_f32
          y -= ((y - y0) / len * line_width).to_f32
        end
      end

      {x, y}
    end

    private def draw_start_style(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      paths_array : Array(Float64),
      line_width : Float32,
      style : String,
      has_stroke : Bool,
      has_background : Bool,
    ) : Nil
      return if style == Annotation::PDAnnotationLine::LE_NONE

      x1 = paths_array[0].to_f32
      y1 = paths_array[1].to_f32
      x2 = paths_array[2].to_f32
      y2 = paths_array[3].to_f32

      content_stream.save_graphics_state
      if ANGLED_STYLES.includes?(style)
        angle = Math.atan2(y2 - y1, x2 - x1)
        content_stream.transform(Pdfbox::Util::Matrix.get_rotate_instance(angle, x1, y1))
      else
        content_stream.transform(Pdfbox::Util::Matrix.translate(x1, y1))
      end
      draw_style(style, content_stream, 0.0_f32, 0.0_f32, line_width, has_stroke, has_background, false)
      content_stream.restore_graphics_state
    end

    private def draw_end_style(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      paths_array : Array(Float64),
      line_width : Float32,
      style : String,
      has_stroke : Bool,
      has_background : Bool,
    ) : Nil
      return if style == Annotation::PDAnnotationLine::LE_NONE

      x1 = paths_array[paths_array.size - 4].to_f32
      y1 = paths_array[paths_array.size - 3].to_f32
      x2 = paths_array[paths_array.size - 2].to_f32
      y2 = paths_array[paths_array.size - 1].to_f32

      if ANGLED_STYLES.includes?(style)
        angle = Math.atan2(y2 - y1, x2 - x1)
        content_stream.transform(Pdfbox::Util::Matrix.get_rotate_instance(angle, x2, y2))
      else
        content_stream.transform(Pdfbox::Util::Matrix.translate(x2, y2))
      end
      draw_style(style, content_stream, 0.0_f32, 0.0_f32, line_width, has_stroke, has_background, true)
    end

    private def adjust_polyline_rectangle(
      annot : Annotation::PDAnnotationPolyline,
      rect : Common::PDRectangle,
      paths_array : Array(Float64),
      line_width : Float32,
    ) : Nil
      min_x = Float64::MAX
      min_y = Float64::MAX
      max_x = Float64::MIN
      max_y = Float64::MIN

      (paths_array.size // 2).times do |i|
        x = paths_array[i * 2]
        y = paths_array[i * 2 + 1]
        min_x = Math.min(min_x, x)
        min_y = Math.min(min_y, y)
        max_x = Math.max(max_x, x)
        max_y = Math.max(max_y, y)
      end

      padding = line_width * 10.0_f32
      rect.lower_left_x = Math.min((min_x - padding).to_f32, rect.lower_left_x)
      rect.lower_left_y = Math.min((min_y - padding).to_f32, rect.lower_left_y)
      rect.upper_right_x = Math.max((max_x + padding).to_f32, rect.upper_right_x)
      rect.upper_right_y = Math.max((max_y + padding).to_f32, rect.upper_right_y)
      annot.rectangle = rect
    end
  end
end
