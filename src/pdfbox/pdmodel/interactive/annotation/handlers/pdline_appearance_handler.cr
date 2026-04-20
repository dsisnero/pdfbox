module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDLineAppearanceHandler < PDAbstractAppearanceHandler
    FONT_SIZE = 9

    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationLine)
      rect = annot.rectangle
      paths_array = annot.line
      color = annot.color
      return unless rect && paths_array && color
      return if color.components.empty?

      annotation_border = AnnotationBorder.annotation_border(annot, annot.border_style)
      ll = annot.leader_line_length.to_f32
      lle = annot.leader_line_extension_length.to_f32
      llo = annot.leader_line_offset_length.to_f32

      if ll < 0
        llo = -llo
        lle = -lle
      end

      line_ending_size = annotation_border.width < 1e-5 ? 1.0_f32 : annotation_border.width
      adjust_line_rectangle(annot, rect, paths_array, line_ending_size, llo, ll, lle)

      content_stream = normal_appearance_as_content_stream
      set_opacity(content_stream, annot.constant_opacity)
      has_stroke = content_stream.stroking_color_on_demand = color
      if dash_array = annotation_border.dash_array
        content_stream.line_dash_pattern(dash_array, 0)
      end
      content_stream.line_width(annotation_border.width)

      x1 = paths_array[0].to_f32
      y1 = paths_array[1].to_f32
      x2 = paths_array[2].to_f32
      y2 = paths_array[3].to_f32
      baseline_y = llo + ll
      contents = annot.contents || ""
      angle = Math.atan2(y2 - y1, x2 - x1)
      line_length = Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2).to_f32
      start_style = annot.start_point_ending_style
      end_style = annot.end_point_ending_style

      content_stream.save_graphics_state
      content_stream.transform(Pdfbox::Util::Matrix.get_rotate_instance(angle, x1, y1))
      draw_leader_lines(content_stream, line_length, llo, ll, lle)

      if annot.caption? && !contents.empty?
        draw_captioned_line(
          content_stream,
          annot,
          contents,
          line_length,
          baseline_y,
          line_ending_size,
          has_stroke,
          start_style,
          end_style
        )
      else
        draw_plain_line(content_stream, line_length, baseline_y, line_ending_size, has_stroke, start_style, end_style)
      end

      content_stream.restore_graphics_state

      has_background = content_stream.non_stroking_color_on_demand = annot.interior_color
      has_stroke = false if annotation_border.width < 1e-5
      draw_start_line_ending(content_stream, x1, y1, baseline_y, angle, line_ending_size, start_style, has_stroke, has_background)
      draw_end_line_ending(content_stream, x2, y2, baseline_y, angle, line_ending_size, end_style, has_stroke, has_background)
      content_stream.close
    end

    private def draw_leader_lines(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      line_length : Float32,
      llo : Float32,
      ll : Float32,
      lle : Float32,
    ) : Nil
      content_stream.move_to(0, llo)
      content_stream.line_to(0, llo + ll + lle)
      content_stream.move_to(line_length, llo)
      content_stream.line_to(line_length, llo + ll + lle)
    end

    private def draw_plain_line(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      line_length : Float32,
      baseline_y : Float32,
      line_ending_size : Float32,
      has_stroke : Bool,
      start_style : String,
      end_style : String,
    ) : Nil
      content_stream.move_to(SHORT_STYLES.includes?(start_style) ? line_ending_size : 0.0_f32, baseline_y)
      content_stream.line_to(SHORT_STYLES.includes?(end_style) ? line_length - line_ending_size : line_length, baseline_y)
      content_stream.draw_shape(line_ending_size, has_stroke, false)
    end

    private def draw_captioned_line(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      annot : Annotation::PDAnnotationLine,
      contents : String,
      line_length : Float32,
      baseline_y : Float32,
      line_ending_size : Float32,
      has_stroke : Bool,
      start_style : String,
      end_style : String,
    ) : Nil
      font = default_font
      content_length = font.get_string_width(contents) / 1000.0_f32 * FONT_SIZE
      x_offset = (line_length - content_length) / 2.0_f32
      y_offset = annot.caption_positioning == "Top" ? 1.908_f32 : -2.6_f32

      content_stream.move_to(SHORT_STYLES.includes?(start_style) ? line_ending_size : 0.0_f32, baseline_y)
      if annot.caption_positioning == "Top"
        content_stream.line_to(SHORT_STYLES.includes?(end_style) ? line_length - line_ending_size : line_length, baseline_y)
      else
        content_stream.line_to(x_offset - line_ending_size, baseline_y)
        content_stream.move_to(line_length - x_offset + line_ending_size, baseline_y)
        content_stream.line_to(SHORT_STYLES.includes?(end_style) ? line_length - line_ending_size : line_length, baseline_y)
      end
      content_stream.draw_shape(line_ending_size, has_stroke, false)

      caption_horizontal_offset = annot.caption_horizontal_offset.to_f32
      caption_vertical_offset = annot.caption_vertical_offset.to_f32

      if content_length > 0
        content_stream.begin_text
        content_stream.set_font(font, FONT_SIZE)
        content_stream.new_line_at_offset(x_offset + caption_horizontal_offset, baseline_y + y_offset + caption_vertical_offset)
        content_stream.show_text(contents)
        content_stream.end_text
      end

      if caption_vertical_offset != 0.0_f32
        content_stream.move_to(line_length / 2.0_f32, baseline_y)
        content_stream.line_to(line_length / 2.0_f32, baseline_y + caption_vertical_offset)
        content_stream.draw_shape(line_ending_size, has_stroke, false)
      end
    end

    private def draw_start_line_ending(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      x1 : Float32,
      y1 : Float32,
      baseline_y : Float32,
      angle : Float64,
      line_ending_size : Float32,
      style : String,
      has_stroke : Bool,
      has_background : Bool,
    ) : Nil
      return if style == Annotation::PDAnnotationLine::LE_NONE

      content_stream.save_graphics_state
      if ANGLED_STYLES.includes?(style)
        content_stream.transform(Pdfbox::Util::Matrix.get_rotate_instance(angle, x1, y1))
        draw_style(style, content_stream, 0.0_f32, baseline_y, line_ending_size, has_stroke, has_background, false)
      else
        xx1 = x1 - (baseline_y * Math.sin(angle)).to_f32
        yy1 = y1 + (baseline_y * Math.cos(angle)).to_f32
        draw_style(style, content_stream, xx1, yy1, line_ending_size, has_stroke, has_background, false)
      end
      content_stream.restore_graphics_state
    end

    private def draw_end_line_ending(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      x2 : Float32,
      y2 : Float32,
      baseline_y : Float32,
      angle : Float64,
      line_ending_size : Float32,
      style : String,
      has_stroke : Bool,
      has_background : Bool,
    ) : Nil
      return if style == Annotation::PDAnnotationLine::LE_NONE

      if ANGLED_STYLES.includes?(style)
        content_stream.transform(Pdfbox::Util::Matrix.get_rotate_instance(angle, x2, y2))
        draw_style(style, content_stream, 0.0_f32, baseline_y, line_ending_size, has_stroke, has_background, true)
      else
        xx2 = x2 - (baseline_y * Math.sin(angle)).to_f32
        yy2 = y2 + (baseline_y * Math.cos(angle)).to_f32
        draw_style(style, content_stream, xx2, yy2, line_ending_size, has_stroke, has_background, true)
      end
    end

    private def adjust_line_rectangle(
      annot : Annotation::PDAnnotationLine,
      rect : Common::PDRectangle,
      paths_array : Array(Float64),
      line_ending_size : Float32,
      llo : Float32,
      ll : Float32,
      lle : Float32,
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

      padding = Math.max(line_ending_size * 10.0_f32, (llo + ll + lle).abs)
      rect.lower_left_x = Math.min((min_x - padding).to_f32, rect.lower_left_x)
      rect.lower_left_y = Math.min((min_y - padding).to_f32, rect.lower_left_y)
      rect.upper_right_x = Math.max((max_x + padding).to_f32, rect.upper_right_x)
      rect.upper_right_y = Math.max((max_y + padding).to_f32, rect.upper_right_y)
      annot.rectangle = rect
    end
  end
end
