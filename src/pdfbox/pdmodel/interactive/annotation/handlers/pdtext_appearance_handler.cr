module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDTextAppearanceHandler < PDAbstractAppearanceHandler
    SUPPORTED_NAMES = {
      Annotation::PDAnnotationText::NAME_NOTE,
      Annotation::PDAnnotationText::NAME_INSERT,
      Annotation::PDAnnotationText::NAME_CROSS,
      Annotation::PDAnnotationText::NAME_HELP,
      Annotation::PDAnnotationText::NAME_CIRCLE,
      Annotation::PDAnnotationText::NAME_PARAGRAPH,
      Annotation::PDAnnotationText::NAME_NEW_PARAGRAPH,
      Annotation::PDAnnotationText::NAME_CHECK,
      Annotation::PDAnnotationText::NAME_STAR,
      Annotation::PDAnnotationText::NAME_RIGHT_ARROW,
      Annotation::PDAnnotationText::NAME_RIGHT_POINTER,
      Annotation::PDAnnotationText::NAME_CROSS_HAIRS,
      Annotation::PDAnnotationText::NAME_UP_ARROW,
      Annotation::PDAnnotationText::NAME_UP_LEFT_ARROW,
      Annotation::PDAnnotationText::NAME_COMMENT,
      Annotation::PDAnnotationText::NAME_KEY,
    }

    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationText)
      return unless SUPPORTED_NAMES.includes?(annot.name)

      content_stream = normal_appearance_as_content_stream
      bg_color = color || Graphics::Color::PDColor.new([1.0_f32], Graphics::Color::PDDeviceGray::INSTANCE)
      content_stream.non_stroking_color = bg_color
      set_opacity(content_stream, annot.constant_opacity)
      draw_supported_icon(annot, content_stream)
      content_stream.close
    end

    private def draw_supported_icon(
      annot : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      if {
           Annotation::PDAnnotationText::NAME_NOTE,
           Annotation::PDAnnotationText::NAME_INSERT,
           Annotation::PDAnnotationText::NAME_CROSS,
           Annotation::PDAnnotationText::NAME_HELP,
           Annotation::PDAnnotationText::NAME_CIRCLE,
           Annotation::PDAnnotationText::NAME_PARAGRAPH,
           Annotation::PDAnnotationText::NAME_NEW_PARAGRAPH,
           Annotation::PDAnnotationText::NAME_CHECK,
         }.includes?(annot.name)
        draw_primary_icon(annot, content_stream)
      else
        draw_secondary_icon(annot, content_stream)
      end
    end

    private def draw_primary_icon(
      annot : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      case annot.name
      when Annotation::PDAnnotationText::NAME_NOTE
        draw_note(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_INSERT
        draw_insert(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_CROSS
        draw_cross(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_HELP
        draw_help(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_CIRCLE
        draw_circles(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_PARAGRAPH
        draw_paragraph(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_NEW_PARAGRAPH
        draw_new_paragraph(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_CHECK
        draw_check(annot, content_stream)
      end
    end

    private def draw_secondary_icon(
      annot : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      case annot.name
      when Annotation::PDAnnotationText::NAME_STAR
        draw_star(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_RIGHT_ARROW
        draw_right_arrow(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_RIGHT_POINTER
        draw_right_pointer(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_CROSS_HAIRS
        draw_cross_hairs(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_UP_ARROW
        draw_up_arrow(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_UP_LEFT_ARROW
        draw_up_left_arrow(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_COMMENT
        draw_comment(annot, content_stream)
      when Annotation::PDAnnotationText::NAME_KEY
        draw_key(annot, content_stream)
      end
    end

    private def adjust_rect_and_bbox(
      text_annotation : Annotation::PDAnnotationText,
      width : Float32,
      height : Float32,
    ) : Common::PDRectangle
      rect = rectangle || Common::PDRectangle.new
      unless text_annotation.no_zoom?
        rect.upper_right_x = rect.lower_left_x + width
        rect.lower_left_y = rect.upper_right_y - height
        text_annotation.rectangle = rect
      end
      unless text_annotation.cos_object.contains_key?("F")
        text_annotation.no_rotate = true
        text_annotation.no_zoom = true
      end
      bbox = Common::PDRectangle.new(width, height)
      text_annotation.normal_appearance_stream.try(&.bbox = bbox)
      bbox
    end

    private def draw_note(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 18.0_f32, 20.0_f32)
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.61_f32)
      width = bbox.width
      height = bbox.height
      content_stream.add_rect(1, 1, width - 2, height - 2)
      content_stream.move_to(width / 4.0_f32, height / 7.0_f32 * 2.0_f32)
      content_stream.line_to(width * 3.0_f32 / 4.0_f32 - 1.0_f32, height / 7.0_f32 * 2.0_f32)
      content_stream.move_to(width / 4.0_f32, height / 7.0_f32 * 3.0_f32)
      content_stream.line_to(width * 3.0_f32 / 4.0_f32 - 1.0_f32, height / 7.0_f32 * 3.0_f32)
      content_stream.move_to(width / 4.0_f32, height / 7.0_f32 * 4.0_f32)
      content_stream.line_to(width * 3.0_f32 / 4.0_f32 - 1.0_f32, height / 7.0_f32 * 4.0_f32)
      content_stream.move_to(width / 4.0_f32, height / 7.0_f32 * 5.0_f32)
      content_stream.line_to(width * 3.0_f32 / 4.0_f32 - 1.0_f32, height / 7.0_f32 * 5.0_f32)
      content_stream.fill_and_stroke
    end

    private def draw_insert(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 17.0_f32, 20.0_f32)
      content_stream.miter_limit(4)
      content_stream.line_join_style(0)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.59_f32)
      content_stream.move_to(bbox.width / 2.0_f32 - 1.0_f32, bbox.height - 2.0_f32)
      content_stream.line_to(1.0_f32, 1.0_f32)
      content_stream.line_to(bbox.width - 2.0_f32, 1.0_f32)
      content_stream.close_and_fill_and_stroke
    end

    private def draw_cross(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      draw_zapf(text_annotation, content_stream, 19.0_f32, 0.0_f32, "a22")
    end

    private def draw_help(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 20.0_f32, 20.0_f32)
      min = Math.min(bbox.width, bbox.height)
      setup_icon_circle(content_stream, min)
      content_stream.save_graphics_state
      content_stream.transform(Pdfbox::Util::Matrix.new(0.001_f32 * min / 2.25_f32, 0.0_f32, 0.0_f32, 0.001_f32 * min / 2.25_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(500.0_f32, 375.0_f32))
      add_path(content_stream, Pdfbox::Pdmodel::Font::Standard14Fonts.get_glyph_path(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD, "question"))
      content_stream.restore_graphics_state
      draw_circle_counter_clockwise(content_stream, min / 2.0_f32, min / 2.0_f32, min / 2.0_f32 - 1.0_f32)
      content_stream.fill_and_stroke
    end

    private def draw_circles(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 20.0_f32, 20.0_f32)
      small_r = 6.36_f32
      large_r = 9.756_f32
      content_stream.transform(Pdfbox::Util::Matrix.new(0.95_f32, 0.0_f32, 0.0_f32, 0.95_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(0.0_f32, 0.5_f32))
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.save_graphics_state
      content_stream.line_width(1)
      gs = Graphics::State::PDExtendedGraphicsState.new
      gs.alpha_source_flag = false
      gs.stroking_alpha_constant = 0.6_f32
      gs.non_stroking_alpha_constant = 0.6_f32
      gs.blend_mode = Graphics::Blend::BlendMode.new(Graphics::Blend::BlendMode::Mode::Normal)
      content_stream.graphics_state_parameters(gs)
      content_stream.non_stroking_color = Graphics::Color::PDColor.new([1.0_f32], Graphics::Color::PDDeviceGray::INSTANCE)
      center_x = bbox.width / 2.0_f32
      center_y = bbox.height / 2.0_f32
      draw_circle(content_stream, center_x, center_y, small_r)
      content_stream.fill
      content_stream.restore_graphics_state
      content_stream.line_width(0.59_f32)
      draw_circle(content_stream, center_x, center_y, small_r)
      draw_circle_counter_clockwise(content_stream, center_x, center_y, large_r)
      content_stream.fill_and_stroke
    end

    private def draw_paragraph(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 20.0_f32, 20.0_f32)
      min = Math.min(bbox.width, bbox.height)
      setup_icon_circle(content_stream, min)
      content_stream.save_graphics_state
      content_stream.transform(Pdfbox::Util::Matrix.new(0.001_f32 * min / 3.0_f32, 0.0_f32, 0.0_f32, 0.001_f32 * min / 3.0_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(850.0_f32, 900.0_f32))
      add_path(content_stream, Pdfbox::Pdmodel::Font::Standard14Fonts.get_glyph_path(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA, "paragraph"))
      content_stream.restore_graphics_state
      content_stream.fill_and_stroke
      draw_circle(content_stream, min / 2.0_f32, min / 2.0_f32, min / 2.0_f32 - 1.0_f32)
      content_stream.stroke
    end

    private def draw_new_paragraph(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      adjust_rect_and_bbox(text_annotation, 13.0_f32, 20.0_f32)
      content_stream.miter_limit(4)
      content_stream.line_join_style(0)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.59_f32)
      content_stream.move_to(6.4995_f32, 20.0_f32)
      content_stream.line_to(0.295_f32, 7.287_f32)
      content_stream.line_to(12.705_f32, 7.287_f32)
      content_stream.close_and_fill_and_stroke
      content_stream.transform(Pdfbox::Util::Matrix.new(0.004_f32, 0.0_f32, 0.0_f32, 0.004_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(200.0_f32, 0.0_f32))
      add_path(content_stream, Pdfbox::Pdmodel::Font::Standard14Fonts.get_glyph_path(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD, "N"))
      content_stream.transform(Pdfbox::Util::Matrix.translate(1300.0_f32, 0.0_f32))
      add_path(content_stream, Pdfbox::Pdmodel::Font::Standard14Fonts.get_glyph_path(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD, "P"))
      content_stream.fill
    end

    private def draw_check(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      draw_zapf(text_annotation, content_stream, 19.0_f32, 50.0_f32, "a20")
    end

    private def draw_star(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      draw_zapf(text_annotation, content_stream, 19.0_f32, 0.0_f32, "a35")
    end

    private def draw_right_arrow(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 20.0_f32, 20.0_f32)
      min = Math.min(bbox.width, bbox.height)
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.59_f32)
      setup_icon_backdrop(content_stream, min)

      content_stream.save_graphics_state
      content_stream.move_to(8.0_f32, 17.5_f32)
      content_stream.line_to(8.0_f32, 13.5_f32)
      content_stream.line_to(3.0_f32, 13.5_f32)
      content_stream.line_to(3.0_f32, 6.5_f32)
      content_stream.line_to(8.0_f32, 6.5_f32)
      content_stream.line_to(8.0_f32, 2.5_f32)
      content_stream.line_to(18.0_f32, 10.0_f32)
      content_stream.close_path
      content_stream.restore_graphics_state

      draw_circle(content_stream, min / 2.0_f32, min / 2.0_f32, min / 2.0_f32 - 1.0_f32)
      content_stream.fill_and_stroke
    end

    private def draw_right_pointer(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      draw_zapf(text_annotation, content_stream, 17.0_f32, 50.0_f32, "a174")
    end

    private def draw_cross_hairs(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 20.0_f32, 20.0_f32)
      min = Math.min(bbox.width, bbox.height)
      content_stream.miter_limit(4)
      content_stream.line_join_style(0)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.61_f32)
      font_matrix = Pdfbox::Pdmodel::Font::Standard14Fonts.get_font_matrix(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::SYMBOL)
      content_stream.transform(Pdfbox::Util::Matrix.new(font_matrix[0] * min * 1.3333_f32, 0.0_f32, 0.0_f32, font_matrix[3] * min * 1.3333_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(0.0_f32, 50.0_f32))
      add_path(content_stream, Pdfbox::Pdmodel::Font::Standard14Fonts.get_glyph_path(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::SYMBOL, "circleplus"))
      content_stream.fill_and_stroke
    end

    private def draw_up_arrow(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      adjust_rect_and_bbox(text_annotation, 17.0_f32, 20.0_f32)
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.59_f32)
      content_stream.move_to(1.0_f32, 7.0_f32)
      content_stream.line_to(5.0_f32, 7.0_f32)
      content_stream.line_to(5.0_f32, 1.0_f32)
      content_stream.line_to(12.0_f32, 1.0_f32)
      content_stream.line_to(12.0_f32, 7.0_f32)
      content_stream.line_to(16.0_f32, 7.0_f32)
      content_stream.line_to(8.5_f32, 19.0_f32)
      content_stream.close_and_fill_and_stroke
    end

    private def draw_up_left_arrow(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      adjust_rect_and_bbox(text_annotation, 17.0_f32, 17.0_f32)
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.59_f32)
      content_stream.transform(Pdfbox::Util::Matrix.get_rotate_instance(Math::PI / 4.0, 8.0_f32, -4.0_f32))
      content_stream.move_to(1.0_f32, 7.0_f32)
      content_stream.line_to(5.0_f32, 7.0_f32)
      content_stream.line_to(5.0_f32, 1.0_f32)
      content_stream.line_to(12.0_f32, 1.0_f32)
      content_stream.line_to(12.0_f32, 7.0_f32)
      content_stream.line_to(16.0_f32, 7.0_f32)
      content_stream.line_to(8.5_f32, 19.0_f32)
      content_stream.close_and_fill_and_stroke
    end

    private def draw_comment(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      adjust_rect_and_bbox(text_annotation, 18.0_f32, 18.0_f32)
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(200)

      content_stream.save_graphics_state
      content_stream.line_width(1)
      gs = Graphics::State::PDExtendedGraphicsState.new
      gs.alpha_source_flag = false
      gs.stroking_alpha_constant = 0.6_f32
      gs.non_stroking_alpha_constant = 0.6_f32
      gs.blend_mode = Graphics::Blend::BlendMode.new(Graphics::Blend::BlendMode::Mode::Normal)
      content_stream.graphics_state_parameters(gs)
      content_stream.non_stroking_color = Graphics::Color::PDColor.new([1.0_f32], Graphics::Color::PDDeviceGray::INSTANCE)
      content_stream.add_rect(0.3_f32, 0.3_f32, 17.4_f32, 17.4_f32)
      content_stream.fill
      content_stream.restore_graphics_state

      content_stream.transform(Pdfbox::Util::Matrix.new(0.003_f32, 0.0_f32, 0.0_f32, 0.003_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(500.0_f32, -300.0_f32))

      content_stream.move_to(2549.0_f32, 5269.0_f32)
      content_stream.curve_to(1307.0_f32, 5269.0_f32, 300.0_f32, 4451.0_f32, 300.0_f32, 3441.0_f32)
      content_stream.curve_to(300.0_f32, 3023.0_f32, 474.0_f32, 2640.0_f32, 764.0_f32, 2331.0_f32)
      content_stream.curve_to(633.0_f32, 1985.0_f32, 361.0_f32, 1691.0_f32, 357.0_f32, 1688.0_f32)
      content_stream.curve_to(299.0_f32, 1626.0_f32, 283.0_f32, 1537.0_f32, 316.0_f32, 1459.0_f32)
      content_stream.curve_to(350.0_f32, 1382.0_f32, 426.0_f32, 1332.0_f32, 510.0_f32, 1332.0_f32)
      content_stream.curve_to(1051.0_f32, 1332.0_f32, 1477.0_f32, 1558.0_f32, 1733.0_f32, 1739.0_f32)
      content_stream.curve_to(1987.0_f32, 1659.0_f32, 2261.0_f32, 1613.0_f32, 2549.0_f32, 1613.0_f32)
      content_stream.curve_to(3792.0_f32, 1613.0_f32, 4799.0_f32, 2431.0_f32, 4799.0_f32, 3441.0_f32)
      content_stream.curve_to(4799.0_f32, 4451.0_f32, 3792.0_f32, 5269.0_f32, 2549.0_f32, 5269.0_f32)
      content_stream.close_path

      content_stream.move_to(0.3_f32 / 0.003_f32 - 500.0_f32, 0.3_f32 / 0.003_f32 + 300.0_f32)
      content_stream.line_to(0.3_f32 / 0.003_f32 - 500.0_f32, 0.3_f32 / 0.003_f32 + 300.0_f32 + 17.4_f32 / 0.003_f32)
      content_stream.line_to(0.3_f32 / 0.003_f32 - 500.0_f32 + 17.4_f32 / 0.003_f32, 0.3_f32 / 0.003_f32 + 300.0_f32 + 17.4_f32 / 0.003_f32)
      content_stream.line_to(0.3_f32 / 0.003_f32 - 500.0_f32 + 17.4_f32 / 0.003_f32, 0.3_f32 / 0.003_f32 + 300.0_f32)
      content_stream.close_and_fill_and_stroke
    end

    private def draw_key(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
    ) : Nil
      adjust_rect_and_bbox(text_annotation, 13.0_f32, 18.0_f32)
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(200)
      content_stream.transform(Pdfbox::Util::Matrix.new(0.003_f32, 0.0_f32, 0.0_f32, 0.003_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.get_rotate_instance(Math::PI / 4.0, 2500.0_f32, -800.0_f32))
      content_stream.move_to(4799.0_f32, 4004.0_f32)
      content_stream.curve_to(4799.0_f32, 3149.0_f32, 4107.0_f32, 2457.0_f32, 3253.0_f32, 2457.0_f32)
      content_stream.curve_to(3154.0_f32, 2457.0_f32, 3058.0_f32, 2466.0_f32, 2964.0_f32, 2484.0_f32)
      content_stream.line_to(2753.0_f32, 2246.0_f32)
      content_stream.curve_to(2713.0_f32, 2201.0_f32, 2656.0_f32, 2175.0_f32, 2595.0_f32, 2175.0_f32)
      content_stream.line_to(2268.0_f32, 2175.0_f32)
      content_stream.line_to(2268.0_f32, 1824.0_f32)
      content_stream.curve_to(2268.0_f32, 1707.0_f32, 2174.0_f32, 1613.0_f32, 2057.0_f32, 1613.0_f32)
      content_stream.line_to(1706.0_f32, 1613.0_f32)
      content_stream.line_to(1706.0_f32, 1261.0_f32)
      content_stream.curve_to(1706.0_f32, 1145.0_f32, 1611.0_f32, 1050.0_f32, 1495.0_f32, 1050.0_f32)
      content_stream.line_to(510.0_f32, 1050.0_f32)
      content_stream.curve_to(394.0_f32, 1050.0_f32, 300.0_f32, 1145.0_f32, 300.0_f32, 1261.0_f32)
      content_stream.line_to(300.0_f32, 1947.0_f32)
      content_stream.curve_to(300.0_f32, 2003.0_f32, 322.0_f32, 2057.0_f32, 361.0_f32, 2097.0_f32)
      content_stream.line_to(1783.0_f32, 3519.0_f32)
      content_stream.curve_to(1733.0_f32, 3671.0_f32, 1706.0_f32, 3834.0_f32, 1706.0_f32, 4004.0_f32)
      content_stream.curve_to(1706.0_f32, 4858.0_f32, 2398.0_f32, 5550.0_f32, 3253.0_f32, 5550.0_f32)
      content_stream.curve_to(4109.0_f32, 5550.0_f32, 4799.0_f32, 4860.0_f32, 4799.0_f32, 4004.0_f32)
      content_stream.close_path
      content_stream.move_to(3253.0_f32, 4425.0_f32)
      content_stream.curve_to(3253.0_f32, 4192.0_f32, 3441.0_f32, 4004.0_f32, 3674.0_f32, 4004.0_f32)
      content_stream.curve_to(3907.0_f32, 4004.0_f32, 4096.0_f32, 4192.0_f32, 4096.0_f32, 4425.0_f32)
      content_stream.curve_to(4096.0_f32, 4658.0_f32, 3907.0_f32, 4847.0_f32, 3674.0_f32, 4847.0_f32)
      content_stream.curve_to(3441.0_f32, 4847.0_f32, 3253.0_f32, 4658.0_f32, 3253.0_f32, 4425.0_f32)
      content_stream.fill_and_stroke
    end

    private def setup_icon_circle(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      min : Float32,
    ) : Nil
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.59_f32)
      setup_icon_backdrop(content_stream, min)
    end

    private def setup_icon_backdrop(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      min : Float32,
    ) : Nil
      content_stream.save_graphics_state
      content_stream.line_width(1)
      gs = Graphics::State::PDExtendedGraphicsState.new
      gs.alpha_source_flag = false
      gs.stroking_alpha_constant = 0.6_f32
      gs.non_stroking_alpha_constant = 0.6_f32
      gs.blend_mode = Graphics::Blend::BlendMode.new(Graphics::Blend::BlendMode::Mode::Normal)
      content_stream.graphics_state_parameters(gs)
      content_stream.non_stroking_color = Graphics::Color::PDColor.new([1.0_f32], Graphics::Color::PDDeviceGray::INSTANCE)
      draw_circle_counter_clockwise(content_stream, min / 2.0_f32, min / 2.0_f32, min / 2.0_f32 - 1.0_f32)
      content_stream.fill
      content_stream.restore_graphics_state
    end

    private def draw_zapf(
      text_annotation : Annotation::PDAnnotationText,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      by : Float32,
      ty : Float32,
      glyph_name : String,
    ) : Nil
      bbox = adjust_rect_and_bbox(text_annotation, 20.0_f32, by)
      min = Math.min(bbox.width, bbox.height)
      content_stream.miter_limit(4)
      content_stream.line_join_style(1)
      content_stream.line_cap_style(0)
      content_stream.line_width(0.59_f32)
      font_matrix = Pdfbox::Pdmodel::Font::Standard14Fonts.get_font_matrix(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::ZAPF_DINGBATS)
      content_stream.transform(Pdfbox::Util::Matrix.new(font_matrix[0] * min / 0.8_f32, 0.0_f32, 0.0_f32, font_matrix[3] * min / 0.8_f32, 0.0_f32, 0.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(0.0_f32, ty))
      add_path(content_stream, Pdfbox::Pdmodel::Font::Standard14Fonts.get_glyph_path(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::ZAPF_DINGBATS, glyph_name))
      content_stream.fill_and_stroke
    end

    private def add_path(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      path : Fontbox::Util::Path,
    ) : Nil
      path.each_command do |command, coords|
        case command
        when :move_to
          content_stream.move_to(coords[0].to_f32, coords[1].to_f32)
        when :line_to
          content_stream.line_to(coords[0].to_f32, coords[1].to_f32)
        when :curve_to
          content_stream.curve_to(
            coords[0].to_f32, coords[1].to_f32,
            coords[2].to_f32, coords[3].to_f32,
            coords[4].to_f32, coords[5].to_f32
          )
        when :close_path
          content_stream.close_path
        end
      end
    end

    private def draw_circle_counter_clockwise(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      x : Float32,
      y : Float32,
      radius : Float32,
    ) : Nil
      magic = radius * 0.551784_f32
      content_stream.move_to(x, y + radius)
      content_stream.curve_to(x - magic, y + radius, x - radius, y + magic, x - radius, y)
      content_stream.curve_to(x - radius, y - magic, x - magic, y - radius, x, y - radius)
      content_stream.curve_to(x + magic, y - radius, x + radius, y - magic, x + radius, y)
      content_stream.curve_to(x + radius, y + magic, x + magic, y + radius, x, y + radius)
      content_stream.close_path
    end
  end
end
