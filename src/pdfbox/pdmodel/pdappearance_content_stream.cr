require "../content_stream/operator_name"

module Pdfbox::Pdmodel
  class PDAppearanceContentStream
    include Pdfbox::ContentStream::OperatorName

    @buffer : ::IO::Memory
    @stream : Interactive::Annotation::PDAppearanceStream
    @resources : PDResources
    @font_name : String?
    @in_text_mode = false
    @closed = false

    def initialize(@stream : Interactive::Annotation::PDAppearanceStream)
      @buffer = ::IO::Memory.new
      @resources = @stream.resources || begin
        created = PDResources.new
        @stream.resources = created
        created
      end
    end

    def stroking_color_on_demand=(color : Graphics::Color::PDColor?) : Bool
      return false unless color

      write_color(color, stroking: true)
      true
    end

    def non_stroking_color_on_demand=(color : Graphics::Color::PDColor?) : Bool
      return false unless color

      write_color(color, stroking: false)
      true
    end

    def line_width(width : Number) : Nil
      write_operands(width)
      write_operator(SET_LINE_WIDTH)
    end

    def line_cap_style(style : Int) : Nil
      write_operands(style)
      write_operator(SET_LINE_CAPSTYLE)
    end

    def line_join_style(style : Int) : Nil
      write_operands(style)
      write_operator(SET_LINE_JOINSTYLE)
    end

    def miter_limit(limit : Number) : Nil
      write_operands(limit)
      write_operator(SET_LINE_MITERLIMIT)
    end

    def stroking_color=(color : Graphics::Color::PDColor) : Graphics::Color::PDColor
      write_color(color, stroking: true)
      color
    end

    def non_stroking_color=(color : Graphics::Color::PDColor) : Graphics::Color::PDColor
      write_color(color, stroking: false)
      color
    end

    def line_dash_pattern(pattern : Enumerable(Number), phase : Number) : Nil
      @buffer << '['
      first = true
      pattern.each do |value|
        @buffer << ' ' unless first
        @buffer << format_number(value)
        first = false
      end
      @buffer << "] " << format_number(phase) << ' ' << SET_LINE_DASHPATTERN << '\n'
    end

    def set_border_line(line_width : Number, border_style : Interactive::Annotation::PDBorderStyleDictionary?, border : Cos::Array) : Nil
      width = line_width.to_f64
      self.line_width(width)

      style = border_style.try(&.style)
      if style == Interactive::Annotation::PDBorderStyleDictionary::STYLE_DASHED
        dash_pattern = border_style.as(Interactive::Annotation::PDBorderStyleDictionary).dash_style
        line_dash_pattern(dash_pattern.dash_array, dash_pattern.phase)
        return
      end

      dash_base = border[3]?
      return unless dash_base.is_a?(Cos::Array)

      dash_pattern = Graphics::PDLineDashPattern.new(dash_base, 0)
      line_dash_pattern(dash_pattern.dash_array, dash_pattern.phase)
    end

    def add_rect(x : Number, y : Number, width : Number, height : Number) : Nil
      write_operands(x, y, width, height)
      write_operator(APPEND_RECT)
    end

    def move_to(x : Number, y : Number) : Nil
      write_operands(x, y)
      write_operator(MOVE_TO)
    end

    def line_to(x : Number, y : Number) : Nil
      write_operands(x, y)
      write_operator(LINE_TO)
    end

    def curve_to(x1 : Number, y1 : Number, x2 : Number, y2 : Number, x3 : Number, y3 : Number) : Nil
      write_operands(x1, y1, x2, y2, x3, y3)
      write_operator(CURVE_TO)
    end

    def close_path : Nil
      write_operator(CLOSE_PATH)
    end

    def stroke : Nil
      write_operator(STROKE_PATH)
    end

    def fill : Nil
      write_operator(FILL_NON_ZERO)
    end

    def fill_and_stroke : Nil
      write_operator(FILL_NON_ZERO_AND_STROKE)
    end

    def close_and_fill_and_stroke : Nil
      write_operator(CLOSE_FILL_NON_ZERO_AND_STROKE)
    end

    def graphics_state_parameters(state : Graphics::State::PDExtendedGraphicsState) : Nil
      resource_name = add_ext_g_state_to_resources(state)
      @buffer << '/' << resource_name.value << ' ' << SET_GRAPHICS_STATE_PARAMS << '\n'
    end

    def transform(matrix : Pdfbox::Util::Matrix) : Nil
      write_operands(
        matrix.get_value(0, 0),
        matrix.get_value(0, 1),
        matrix.get_value(1, 0),
        matrix.get_value(1, 1),
        matrix.get_value(2, 0),
        matrix.get_value(2, 1)
      )
      write_operator(CONCAT)
    end

    def save_graphics_state : Nil
      write_operator(SAVE)
    end

    def restore_graphics_state : Nil
      write_operator(RESTORE)
    end

    def begin_text : Nil
      raise Pdfbox::Pdmodel::IllegalStateError.new("Error: Nested beginText() calls are not allowed.") if @in_text_mode
      @in_text_mode = true
      write_operator(BEGIN_TEXT)
    end

    def end_text : Nil
      raise Pdfbox::Pdmodel::IllegalStateError.new("Error: You must call beginText() before calling endText.") unless @in_text_mode
      @in_text_mode = false
      write_operator(END_TEXT)
    end

    def new_line_at_offset(tx : Number, ty : Number) : Nil
      write_operands(tx, ty)
      write_operator(MOVE_TEXT)
    end

    def set_font(font : Pdfbox::Pdmodel::Font::PDFont, font_size : Number) : Nil
      add_font_to_resources(font)
      @buffer << '/' << @font_name << ' ' << format_number(font_size) << ' ' << SET_FONT_AND_SIZE << '\n'
    end

    def show_text(text : String) : Nil
      font = current_font
      escaped = if font
                  encoded = font.encode(text)
                  String.new(encoded).gsub("\\", "\\\\").gsub("(", "\\(").gsub(")", "\\)")
                else
                  text.gsub("\\", "\\\\").gsub("(", "\\(").gsub(")", "\\)")
                end
      @buffer << '(' << escaped << ") " << SHOW_TEXT << '\n'
    end

    def draw_form(form : Graphics::Form::PDFormXObject) : Nil
      resource_name = @resources.add(form, "Fm")
      @buffer << '/' << resource_name.value << ' ' << DRAW_OBJECT << '\n'
    end

    def draw_shape(_line_width : Number, has_stroke : Bool, has_background : Bool) : Nil
      if has_stroke && has_background
        fill_and_stroke
      elsif has_background
        fill
      elsif has_stroke
        stroke
      end
    end

    def close : Nil
      return if @closed
      @closed = true
      cos_stream = @stream.require_stream_object
      cos_stream.data = @buffer.to_slice
      cos_stream.set_int(Cos::Name::LENGTH, @buffer.size)
    end

    private def write_color(color : Graphics::Color::PDColor, *, stroking : Bool) : Nil
      if pattern_name = color.pattern_name
        color.components.each_with_index do |component, index|
          @buffer << ' ' unless index == 0
          @buffer << format_number(component)
        end
        @buffer << ' ' unless color.components.empty?
        @buffer << '/' << pattern_name.value << ' '
        write_operator(stroking ? STROKING_COLOR_N : NON_STROKING_COLOR_N)
        return
      end

      components = color.components
      case components.size
      when 1
        write_operands(components[0])
        write_operator(stroking ? STROKING_COLOR_GRAY : NON_STROKING_GRAY)
      when 3
        write_operands(components[0], components[1], components[2])
        write_operator(stroking ? STROKING_COLOR_RGB : NON_STROKING_RGB)
      when 4
        write_operands(components[0], components[1], components[2], components[3])
        write_operator(stroking ? STROKING_COLOR_CMYK : NON_STROKING_CMYK)
      end
    end

    private def add_ext_g_state_to_resources(state : Graphics::State::PDExtendedGraphicsState) : Pdfbox::Cos::Name
      dictionary = @resources.cos_object.as(Pdfbox::Cos::Dictionary)
      ext_g_states = dictionary[Pdfbox::Cos::Name.new("ExtGState")]?.as?(Pdfbox::Cos::Dictionary) || begin
        created = Pdfbox::Cos::Dictionary.new
        dictionary[Pdfbox::Cos::Name.new("ExtGState")] = created
        created
      end

      index = 1
      while ext_g_states.has_key?(Pdfbox::Cos::Name.new("gs#{index}"))
        index += 1
      end

      resource_name = Pdfbox::Cos::Name.new("gs#{index}")
      @resources.put(resource_name, state)
      resource_name
    end

    private def add_font_to_resources(font : Pdfbox::Pdmodel::Font::PDFont) : Nil
      return if @font_name

      dictionary = @resources.cos_object.as(Pdfbox::Cos::Dictionary)
      fonts = dictionary[Pdfbox::Cos::Name.new("Font")]?.as?(Pdfbox::Cos::Dictionary) || begin
        created = Pdfbox::Cos::Dictionary.new
        dictionary[Pdfbox::Cos::Name.new("Font")] = created
        created
      end

      font_name = "F#{fonts.size + 1}"
      @font_name = font_name
      fonts[Pdfbox::Cos::Name.new(font_name)] = font.cos_object
    end

    private def current_font : Pdfbox::Pdmodel::Font::PDFont?
      font_name = @font_name
      return unless font_name

      fonts = @resources.cos_object.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Font")]?.as?(Pdfbox::Cos::Dictionary)
      return unless fonts

      font_dict = fonts[Pdfbox::Cos::Name.new(font_name)]?
      return unless font_dict

      font_dict = font_dict.object if font_dict.is_a?(Pdfbox::Cos::Object)
      return unless font_dict.is_a?(Pdfbox::Cos::Dictionary)

      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(font_dict)
    end

    private def write_operands(*values : Number) : Nil
      values.each_with_index do |value, index|
        @buffer << ' ' unless index == 0
        @buffer << format_number(value)
      end
      @buffer << ' '
    end

    private def write_operator(name : String) : Nil
      @buffer << name << '\n'
    end

    private def format_number(value : Number) : String
      case value
      when Int
        value.to_s
      when Float32, Float64
        float_value = value.to_f32
        rounded = float_value.round
        return rounded.to_i.to_s if rounded == float_value

        ascii_buffer = Bytes.new(32, 0_u8)
        used = Pdfbox::Util::NumberFormatUtil.format_float_fast(float_value, 5, ascii_buffer)
        return String.new(ascii_buffer[0, used]) if used >= 0

        formatted = "%.5f" % float_value
        formatted = formatted.gsub(/\.?0+$/, "")
        formatted == "-0" ? "0" : formatted
      else
        value.to_s
      end
    end
  end
end
