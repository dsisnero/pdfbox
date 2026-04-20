module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDHighlightAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationHighlight)
      paths_array = annot.quad_points
      color = annot.color
      rect = annot.rectangle
      return unless paths_array && color && rect
      return if color.components.empty?

      annotation_border = AnnotationBorder.annotation_border(annot, annot.border_style)
      max_delta = max_highlight_delta(paths_array).to_f32
      adjust_highlight_rectangle(annot, rect, paths_array, annotation_border.width, max_delta)

      content_stream = normal_appearance_as_content_stream

      opacity_state = Graphics::State::PDExtendedGraphicsState.new
      opacity_state.alpha_source_flag = false
      opacity_state.stroking_alpha_constant = annot.constant_opacity
      opacity_state.non_stroking_alpha_constant = annot.constant_opacity
      content_stream.graphics_state_parameters(opacity_state)

      blend_state = Graphics::State::PDExtendedGraphicsState.new
      blend_state.alpha_source_flag = false
      blend_state.blend_mode = Graphics::Blend::BlendMode.new(Graphics::Blend::BlendMode::Mode::Multiply)
      content_stream.graphics_state_parameters(blend_state)

      form1 = Graphics::Form::PDFormXObject.new(create_cos_stream)
      form2 = Graphics::Form::PDFormXObject.new(create_cos_stream)
      form1.resources = Pdfbox::Pdmodel::PDResources.new

      form1_content_stream = Pdfbox::Pdmodel::PDFormContentStream.new(form1)
      form1_content_stream.draw_form(form2)
      form1_content_stream.close

      form1.bbox = annot.rectangle
      form1.group = Graphics::Form::PDTransparencyGroupAttributes.new
      content_stream.draw_form(form1)

      form2.bbox = annot.rectangle
      form2_content_stream = Pdfbox::Pdmodel::PDFormContentStream.new(form2)
      form2_content_stream.non_stroking_color = color

      quad_group_count(paths_array).times do |index|
        write_highlight_quad(form2_content_stream, paths_array, index)
      end

      form2_content_stream.close
      content_stream.close
    end

    private def write_highlight_quad(content_stream, paths_array : Array(Float64), index : Int32) : Nil
      offset = index * 8
      delta = highlight_delta(paths_array, offset)

      content_stream.move_to(paths_array[offset + 4], paths_array[offset + 5])

      if paths_array[offset] == paths_array[offset + 4]
        content_stream.curve_to(
          paths_array[offset + 4] - delta, paths_array[offset + 5] + delta,
          paths_array[offset] - delta, paths_array[offset + 1] - delta,
          paths_array[offset], paths_array[offset + 1]
        )
      elsif paths_array[offset + 5] == paths_array[offset + 1]
        content_stream.curve_to(
          paths_array[offset + 4] + delta, paths_array[offset + 5] + delta,
          paths_array[offset] - delta, paths_array[offset + 1] + delta,
          paths_array[offset], paths_array[offset + 1]
        )
      else
        content_stream.line_to(paths_array[offset], paths_array[offset + 1])
      end

      content_stream.line_to(paths_array[offset + 2], paths_array[offset + 3])

      if paths_array[offset + 2] == paths_array[offset + 6]
        content_stream.curve_to(
          paths_array[offset + 2] + delta, paths_array[offset + 3] - delta,
          paths_array[offset + 6] + delta, paths_array[offset + 7] + delta,
          paths_array[offset + 6], paths_array[offset + 7]
        )
      elsif paths_array[offset + 3] == paths_array[offset + 7]
        content_stream.curve_to(
          paths_array[offset + 2] - delta, paths_array[offset + 3] - delta,
          paths_array[offset + 6] + delta, paths_array[offset + 7] - delta,
          paths_array[offset + 6], paths_array[offset + 7]
        )
      else
        content_stream.line_to(paths_array[offset + 6], paths_array[offset + 7])
      end

      content_stream.fill
    end

    private def adjust_highlight_rectangle(
      annot : Annotation::PDAnnotationHighlight,
      rect : Common::PDRectangle,
      paths_array : Array(Float64),
      line_width : Float32,
      max_delta : Float32,
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

      rect.lower_left_x = Math.min((min_x - line_width / 2.0_f32 - max_delta).to_f32, rect.lower_left_x)
      rect.lower_left_y = Math.min((min_y - line_width / 2.0_f32 - max_delta).to_f32, rect.lower_left_y)
      rect.upper_right_x = Math.max((max_x + line_width + max_delta).to_f32, rect.upper_right_x)
      rect.upper_right_y = Math.max((max_y + line_width + max_delta).to_f32, rect.upper_right_y)
      annot.rectangle = rect
    end

    private def max_highlight_delta(paths_array : Array(Float64)) : Float64
      max_delta = 0.0_f64
      quad_group_count(paths_array).times do |index|
        max_delta = Math.max(max_delta, highlight_delta(paths_array, index * 8))
      end
      max_delta
    end

    private def highlight_delta(paths_array : Array(Float64), offset : Int32) : Float64
      if paths_array[offset] == paths_array[offset + 4] &&
         paths_array[offset + 1] == paths_array[offset + 3] &&
         paths_array[offset + 2] == paths_array[offset + 6] &&
         paths_array[offset + 5] == paths_array[offset + 7]
        (paths_array[offset + 1] - paths_array[offset + 5]) / 4.0_f64
      elsif paths_array[offset + 1] == paths_array[offset + 5] &&
            paths_array[offset] == paths_array[offset + 2] &&
            paths_array[offset + 3] == paths_array[offset + 7] &&
            paths_array[offset + 4] == paths_array[offset + 6]
        (paths_array[offset] - paths_array[offset + 4]) / 4.0_f64
      else
        0.0_f64
      end
    end
  end
end
