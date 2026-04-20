module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  abstract class PDAbstractAppearanceHandler
    include PDAppearanceHandler

    ARROW_ANGLE  = Math::PI / 6.0
    SHORT_STYLES = {
      Annotation::PDAnnotationLine::LE_OPEN_ARROW,
      Annotation::PDAnnotationLine::LE_CLOSED_ARROW,
      Annotation::PDAnnotationLine::LE_SQUARE,
      Annotation::PDAnnotationLine::LE_CIRCLE,
      Annotation::PDAnnotationLine::LE_DIAMOND,
    }
    INTERIOR_COLOR_STYLES = {
      Annotation::PDAnnotationLine::LE_CLOSED_ARROW,
      Annotation::PDAnnotationLine::LE_CIRCLE,
      Annotation::PDAnnotationLine::LE_DIAMOND,
      Annotation::PDAnnotationLine::LE_R_CLOSED_ARROW,
      Annotation::PDAnnotationLine::LE_SQUARE,
    }
    ANGLED_STYLES = {
      Annotation::PDAnnotationLine::LE_CLOSED_ARROW,
      Annotation::PDAnnotationLine::LE_OPEN_ARROW,
      Annotation::PDAnnotationLine::LE_R_CLOSED_ARROW,
      Annotation::PDAnnotationLine::LE_R_OPEN_ARROW,
      Annotation::PDAnnotationLine::LE_BUTT,
      Annotation::PDAnnotationLine::LE_SLASH,
    }

    @annotation : Annotation::PDAnnotation
    @document : Pdfbox::Pdmodel::Document?

    def initialize(@annotation : Annotation::PDAnnotation, @document : Pdfbox::Pdmodel::Document? = nil)
    end

    protected def wrapped_annotation : Annotation::PDAnnotation
      @annotation
    end

    protected def document : Pdfbox::Pdmodel::Document?
      @document
    end

    protected def color : Graphics::Color::PDColor?
      wrapped_annotation.color
    end

    protected def rectangle : Common::PDRectangle?
      wrapped_annotation.rectangle
    end

    protected def appearance : Annotation::PDAppearanceDictionary
      wrapped_annotation.appearance || begin
        created = Annotation::PDAppearanceDictionary.new
        wrapped_annotation.appearance = created
        created
      end
    end

    protected def normal_appearance : Annotation::PDAppearanceEntry
      current = appearance.normal_appearance
      if current && current.stream?
        current
      else
        entry = Annotation::PDAppearanceEntry.new(Cos::Stream.new)
        appearance.normal_appearance = entry
        entry
      end
    end

    protected def normal_appearance_as_content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream
      appearance_entry = normal_appearance
      stream = appearance_entry.appearance_stream
      rectangle = self.rectangle || Common::PDRectangle.new
      stream.bbox = rectangle
      stream.matrix = Util::Matrix.translate(-rectangle.lower_left_x, -rectangle.lower_left_y)
      Pdfbox::Pdmodel::PDAppearanceContentStream.new(stream)
    end

    protected def padded_rectangle(rectangle : Common::PDRectangle, padding : Float32) : Common::PDRectangle
      Common::PDRectangle.new(
        rectangle.lower_left_x + padding,
        rectangle.lower_left_y + padding,
        rectangle.width - 2 * padding,
        rectangle.height - 2 * padding
      )
    end

    protected def add_rect_differences(rectangle : Common::PDRectangle, differences : Array(Float64)) : Common::PDRectangle
      return rectangle unless differences.size == 4

      Common::PDRectangle.new(
        rectangle.lower_left_x - differences[0].to_f32,
        rectangle.lower_left_y - differences[1].to_f32,
        rectangle.width + differences[0].to_f32 + differences[2].to_f32,
        rectangle.height + differences[1].to_f32 + differences[3].to_f32
      )
    end

    protected def apply_rect_differences(rectangle : Common::PDRectangle, differences : Array(Float64)) : Common::PDRectangle
      return rectangle unless differences.size == 4

      Common::PDRectangle.new(
        rectangle.lower_left_x + differences[0].to_f32,
        rectangle.lower_left_y + differences[1].to_f32,
        rectangle.width - differences[0].to_f32 - differences[2].to_f32,
        rectangle.height - differences[1].to_f32 - differences[3].to_f32
      )
    end

    protected def handle_border_box(square_circle : Annotation::PDAnnotationSquareCircle, line_width : Float32) : Common::PDRectangle
      rect_differences = square_circle.rect_differences
      if rect_differences.empty?
        border_box = padded_rectangle(square_circle.rectangle || Common::PDRectangle.new, line_width)
        square_circle.rect_differences = [line_width, line_width, line_width, line_width]
        border_box
      else
        border_box = apply_rect_differences(square_circle.rectangle || Common::PDRectangle.new, rect_differences)
        padded_rectangle(border_box, line_width / 2.0_f32)
      end
    end

    protected def set_opacity(_content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream, _opacity : Float64) : Nil
    end

    protected def create_cos_stream : Cos::Stream
      Cos::Stream.new
    end

    protected def default_font : Pdfbox::Pdmodel::Font::PDFont
      @default_font ||= Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
    end

    protected def quad_group_count(paths_array : Array(Float64)) : Int32
      (paths_array.size // 8).to_i32
    end

    protected def line_length(x0 : Float64, y0 : Float64, x1 : Float64, y1 : Float64) : Float64
      Math.sqrt((x0 - x1)**2 + (y0 - y1)**2)
    end

    protected def adjust_rectangle(
      annot : Annotation::PDAnnotationTextMarkup,
      rect : Common::PDRectangle,
      paths_array : Array(Float64),
      padding : Float32,
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

      rect.lower_left_x = Math.min((min_x - padding).to_f32, rect.lower_left_x)
      rect.lower_left_y = Math.min((min_y - padding).to_f32, rect.lower_left_y)
      rect.upper_right_x = Math.max((max_x + padding).to_f32, rect.upper_right_x)
      rect.upper_right_y = Math.max((max_y + padding).to_f32, rect.upper_right_y)
      annot.rectangle = rect
    end

    protected def draw_style(
      style : String,
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      x : Float32,
      y : Float32,
      width : Float32,
      has_stroke : Bool,
      has_background : Bool,
      ending : Bool,
    ) : Nil
      sign = ending ? -1 : 1

      case style
      when Annotation::PDAnnotationLine::LE_OPEN_ARROW, Annotation::PDAnnotationLine::LE_CLOSED_ARROW
        draw_arrow(content_stream, x + sign * width, y, sign * width * 9)
      when Annotation::PDAnnotationLine::LE_BUTT
        content_stream.move_to(x, y - width * 3)
        content_stream.line_to(x, y + width * 3)
      when Annotation::PDAnnotationLine::LE_DIAMOND
        draw_diamond(content_stream, x, y, width * 3)
      when Annotation::PDAnnotationLine::LE_SQUARE
        content_stream.add_rect(x - width * 3, y - width * 3, width * 6, width * 6)
      when Annotation::PDAnnotationLine::LE_CIRCLE
        draw_circle(content_stream, x, y, width * 3)
      when Annotation::PDAnnotationLine::LE_R_OPEN_ARROW, Annotation::PDAnnotationLine::LE_R_CLOSED_ARROW
        draw_arrow(content_stream, x - sign * width, y, -sign * width * 9)
      when Annotation::PDAnnotationLine::LE_SLASH
        width9 = width * 9
        content_stream.move_to(
          x + (Math.cos(Math::PI / 3).to_f32 * width9),
          y + (Math.sin(Math::PI / 3).to_f32 * width9)
        )
        content_stream.line_to(
          x + (Math.cos(4 * Math::PI / 3).to_f32 * width9),
          y + (Math.sin(4 * Math::PI / 3).to_f32 * width9)
        )
      else
        return
      end

      if style == Annotation::PDAnnotationLine::LE_R_CLOSED_ARROW ||
         style == Annotation::PDAnnotationLine::LE_CLOSED_ARROW
        content_stream.close_path
      end

      content_stream.draw_shape(width, has_stroke, INTERIOR_COLOR_STYLES.includes?(style) && has_background)
    end

    protected def draw_arrow(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      x : Float32,
      y : Float32,
      len : Float32,
    ) : Nil
      arm_x = x + (Math.cos(ARROW_ANGLE).to_f32 * len)
      arm_y_delta = Math.sin(ARROW_ANGLE).to_f32 * len
      content_stream.move_to(arm_x, y + arm_y_delta)
      content_stream.line_to(x, y)
      content_stream.line_to(arm_x, y - arm_y_delta)
    end

    protected def draw_diamond(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      x : Float32,
      y : Float32,
      radius : Float32,
    ) : Nil
      content_stream.move_to(x - radius, y)
      content_stream.line_to(x, y + radius)
      content_stream.line_to(x + radius, y)
      content_stream.line_to(x, y - radius)
      content_stream.close_path
    end

    protected def draw_circle(
      content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream,
      x : Float32,
      y : Float32,
      radius : Float32,
    ) : Nil
      magic = radius * 0.551784_f32
      content_stream.move_to(x, y + radius)
      content_stream.curve_to(x + magic, y + radius, x + radius, y + magic, x + radius, y)
      content_stream.curve_to(x + radius, y - magic, x + magic, y - radius, x, y - radius)
      content_stream.curve_to(x - magic, y - radius, x - radius, y - magic, x - radius, y)
      content_stream.curve_to(x - radius, y + magic, x - magic, y + radius, x, y + radius)
      content_stream.close_path
    end
  end
end
