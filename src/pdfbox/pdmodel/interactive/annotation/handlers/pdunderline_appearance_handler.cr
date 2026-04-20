module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDUnderlineAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationUnderline)
      rect = annot.rectangle
      paths_array = annot.quad_points
      color = annot.color
      return unless rect && paths_array && color
      return if color.components.empty?

      annotation_border = AnnotationBorder.annotation_border(annot, annot.border_style)
      annotation_border.width = 1.5_f32 if annotation_border.width == 0.0_f32
      adjust_rectangle(annot, rect, paths_array, annotation_border.width / 2.0_f32)

      content_stream = normal_appearance_as_content_stream
      set_opacity(content_stream, annot.constant_opacity)
      content_stream.stroking_color = color
      if dash_array = annotation_border.dash_array
        content_stream.line_dash_pattern(dash_array, 0)
      end
      content_stream.line_width(annotation_border.width)

      quad_group_count(paths_array).times do |index|
        x0, y0 = underline_start(paths_array, index)
        x1, y1 = underline_end(paths_array, index)
        content_stream.move_to(x0, y0)
        content_stream.line_to(x1, y1)
      end
      content_stream.stroke
      content_stream.close
    end

    private def underline_start(paths_array : Array(Float64), index : Int32) : Tuple(Float64, Float64)
      offset = index * 8
      len = line_length(paths_array[offset], paths_array[offset + 1], paths_array[offset + 4], paths_array[offset + 5])
      return {paths_array[offset + 4], paths_array[offset + 5]} if len == 0.0_f64

      {
        paths_array[offset + 4] + ((paths_array[offset] - paths_array[offset + 4]) / len * len / 7.0_f64),
        paths_array[offset + 5] + ((paths_array[offset + 1] - paths_array[offset + 5]) / len * len / 7.0_f64),
      }
    end

    private def underline_end(paths_array : Array(Float64), index : Int32) : Tuple(Float64, Float64)
      offset = index * 8
      len = line_length(paths_array[offset + 2], paths_array[offset + 3], paths_array[offset + 6], paths_array[offset + 7])
      return {paths_array[offset + 6], paths_array[offset + 7]} if len == 0.0_f64

      {
        paths_array[offset + 6] + ((paths_array[offset + 2] - paths_array[offset + 6]) / len * len / 7.0_f64),
        paths_array[offset + 7] + ((paths_array[offset + 3] - paths_array[offset + 7]) / len * len / 7.0_f64),
      }
    end
  end
end
