module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDCaretAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationCaret)
      color = self.color
      rect = rectangle
      return unless color && rect

      content_stream = normal_appearance_as_content_stream
      content_stream.stroking_color = color
      content_stream.non_stroking_color = color
      set_opacity(content_stream, annot.constant_opacity)

      rect_width = rect.width
      rect_height = rect.height
      bbox = Common::PDRectangle.new(rect_width, rect_height)
      appearance_stream = annot.normal_appearance_stream || raise "Caret appearance stream missing"

      unless annot.cos_object.contains_key?("RD")
        rd = Math.min(rect_height / 10.0_f32, 5.0_f32)
        annot.rect_differences = [rd, rd, rd, rd]
        bbox = Common::PDRectangle.new(-rd, -rd, rect_width + 2.0_f32 * rd, rect_height + 2.0_f32 * rd)
        updated_rect = Common::PDRectangle.new(
          rect.lower_left_x - rd,
          rect.lower_left_y - rd,
          rect_width + 2.0_f32 * rd,
          rect_height + 2.0_f32 * rd
        )
        annot.rectangle = updated_rect
        appearance_stream.matrix = Util::Matrix.translate(-updated_rect.lower_left_x, -updated_rect.lower_left_y)
      end

      appearance_stream.bbox = bbox

      half_x = rect_width / 2.0_f32
      half_y = rect_height / 2.0_f32
      content_stream.move_to(0, 0)
      content_stream.curve_to(half_x, 0, half_x, half_y, half_x, rect_height)
      content_stream.curve_to(half_x, half_y, half_x, 0, rect_width, 0)
      content_stream.close_path
      content_stream.fill
      content_stream.close
    end
  end
end
