module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDSquigglyAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationSquiggly)
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

      quad_group_count(paths_array).times do |index|
        write_squiggly_quad(content_stream, color, paths_array, index)
      end

      content_stream.close
    end

    private def write_squiggly_quad(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      color : Graphics::Color::PDColor,
      paths_array : Array(Float64),
      index : Int32,
    ) : Nil
      offset = index * 8
      height = (paths_array[offset + 1] - paths_array[offset + 5]).to_f32
      return if height == 0.0_f32

      content_stream.transform(
        Pdfbox::Util::Matrix.new(
          height / 40.0_f32, 0.0_f32,
          0.0_f32, height / 72.0_f32,
          paths_array[offset + 4].to_f32, paths_array[offset + 5].to_f32
        )
      )

      form = Graphics::Form::PDFormXObject.new(create_cos_stream)
      form_width = ((paths_array[offset + 2] - paths_array[offset]) / height) * 40.0_f64 + 1.0_f64
      form.bbox = Common::PDRectangle.new(-0.5_f32, -0.5_f32, form_width.to_f32, 13.5_f32)
      form.resources = Pdfbox::Pdmodel::PDResources.new
      form.matrix = Pdfbox::Util::Matrix.translate(0.5_f32, 0.5_f32)
      content_stream.draw_form(form)

      form_content_stream = Pdfbox::Pdmodel::PDFormContentStream.new(form)
      pattern = Graphics::Pattern::PDTilingPattern.new
      pattern.bbox = Common::PDRectangle.new(0.0_f32, 0.0_f32, 10.0_f32, 12.0_f32)
      pattern.x_step = 10
      pattern.y_step = 13
      pattern.tiling_type = Graphics::Pattern::PDTilingPattern::TILING_CONSTANT_SPACING_FASTER_TILING
      pattern.paint_type = Graphics::Pattern::PDTilingPattern::PAINT_UNCOLORED

      pattern_content_stream = Pdfbox::Pdmodel::PDPatternContentStream.new(pattern)
      pattern_content_stream.line_cap_style(1)
      pattern_content_stream.line_join_style(1)
      pattern_content_stream.line_width(1)
      pattern_content_stream.miter_limit(10)
      pattern_content_stream.move_to(0, 1)
      pattern_content_stream.line_to(5, 11)
      pattern_content_stream.line_to(10, 1)
      pattern_content_stream.stroke
      pattern_content_stream.close

      form_resources = form.resources || raise "Squiggly form resources missing"
      pattern_name = form_resources.add(pattern)
      pattern_color_space = Graphics::Color::PDPattern.new(Graphics::Color::PDDeviceRGB::INSTANCE)
      pattern_color = Graphics::Color::PDColor.new(color.components, pattern_name, pattern_color_space)
      form_content_stream.non_stroking_color = pattern_color
      form_content_stream.add_rect(
        0,
        0,
        ((paths_array[offset + 2] - paths_array[offset]) / height) * 40.0_f64,
        12
      )
      form_content_stream.fill
      form_content_stream.close
    end
  end
end
