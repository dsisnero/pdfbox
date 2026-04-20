require "../content_stream/operator_name"
require "../util"

module Pdfbox::Pdmodel
  class IllegalStateError < Exception
  end

  # Minimal PDPageContentStream parity surface for the upstream pdmodel tests.
  class PDPageContentStream
    include Pdfbox::ContentStream::OperatorName

    enum AppendMode
      OVERWRITE
      APPEND
      PREPEND
    end

    @buffer : ::IO::Memory
    @closed = false
    @font_name : String?
    @current_font : Font::PDFont?
    @in_text_mode = false

    def initialize(@document : Document, @page : Page)
      @append_mode = AppendMode::OVERWRITE
      @compress = true
      @buffer = ::IO::Memory.new
    end

    def initialize(@document : Document, @page : Page, @append_mode : AppendMode, @compress : Bool)
      @buffer = ::IO::Memory.new
    end

    def begin_text : Nil
      raise IllegalStateError.new("Error: Nested beginText() calls are not allowed.") if @in_text_mode
      @in_text_mode = true
      write_operator(BEGIN_TEXT)
    end

    def end_text : Nil
      raise IllegalStateError.new("Error: You must call beginText() before calling endText.") unless @in_text_mode
      @in_text_mode = false
      write_operator(END_TEXT)
    end

    def new_line_at_offset(tx : Number, ty : Number) : Nil
      write_operands(tx, ty)
      write_operator(MOVE_TEXT)
    end

    def set_font(font : Font::PDFont, font_size : Number) : Nil
      add_font_to_resources(font)
      @document.register_font_for_save(font)
      @current_font = font
      @buffer << "/#{@font_name} " << format_number(font_size) << ' ' << SET_FONT_AND_SIZE << '\n'
    end

    def show_text(text : String) : Nil
      font = get_current_font
      @buffer << '('
      if font
        write_pdf_literal_string(encode_text(text, font))
      else
        write_pdf_literal_string(text.to_slice)
      end
      @buffer << ") " << SHOW_TEXT << '\n'
    end

    def non_stroking_color(gray : Number) : Nil
      validate_color_component(gray, "g")
      write_operands(gray)
      write_operator(NON_STROKING_GRAY)
    end

    def non_stroking_color(r : Number, g : Number, b : Number) : Nil
      validate_color_component(r, "r")
      validate_color_component(g, "g")
      validate_color_component(b, "b")
      write_operands(r, g, b)
      write_operator(NON_STROKING_RGB)
    end

    def non_stroking_color(c : Number, m : Number, y : Number, k : Number) : Nil
      validate_color_component(c, "c")
      validate_color_component(m, "m")
      validate_color_component(y, "y")
      validate_color_component(k, "k")
      write_operands(c, m, y, k)
      write_operator(NON_STROKING_CMYK)
    end

    def stroking_color(gray : Number) : Nil
      validate_color_component(gray, "g")
      write_operands(gray)
      write_operator(STROKING_COLOR_GRAY)
    end

    def stroking_color(r : Number, g : Number, b : Number) : Nil
      validate_color_component(r, "r")
      validate_color_component(g, "g")
      validate_color_component(b, "b")
      write_operands(r, g, b)
      write_operator(STROKING_COLOR_RGB)
    end

    def stroking_color(c : Number, m : Number, y : Number, k : Number) : Nil
      validate_color_component(c, "c")
      validate_color_component(m, "m")
      validate_color_component(y, "y")
      validate_color_component(k, "k")
      write_operands(c, m, y, k)
      write_operator(STROKING_COLOR_CMYK)
    end

    def draw_image(image : Graphics::Image::PDImageXObject, x : Number, y : Number, width : Number, height : Number) : Nil
      raise_if_in_text_mode("drawImage is not allowed within a text block.")
      write_operator(SAVE)
      write_operands(width, 0, 0, height, x, y)
      write_operator(CONCAT)
      resource_name = add_image_to_xobject_resources(image)
      @buffer << '/' << resource_name << ' ' << DRAW_OBJECT << '\n'
      write_operator(RESTORE)
    end

    def draw_image(image : Graphics::Image::PDImageXObject, matrix : Pdfbox::Util::Matrix) : Nil
      raise_if_in_text_mode("drawImage is not allowed within a text block.")
      write_operator(SAVE)
      write_operands(
        matrix.get_value(0, 0),
        matrix.get_value(0, 1),
        matrix.get_value(1, 0),
        matrix.get_value(1, 1),
        matrix.get_value(2, 0),
        matrix.get_value(2, 1)
      )
      write_operator(CONCAT)
      resource_name = add_image_to_xobject_resources(image)
      @buffer << '/' << resource_name << ' ' << DRAW_OBJECT << '\n'
      write_operator(RESTORE)
    end

    def draw_image(_image : Graphics::Image::PDInlineImage, _x : Number, _y : Number, _width : Number, _height : Number) : Nil
      raise_if_in_text_mode("drawImage is not allowed within a text block.")
    end

    def add_rect(_x : Number, _y : Number, _width : Number, _height : Number) : Nil
      raise_if_in_text_mode("addRect is not allowed within a text block.")
      write_operator(APPEND_RECT)
    end

    def curve_to(_x1 : Number, _y1 : Number, _x2 : Number, _y2 : Number, _x3 : Number, _y3 : Number) : Nil
      raise_if_in_text_mode("curveTo is not allowed within a text block.")
      write_operator(CURVE_TO)
    end

    def curve_to1(_x1 : Number, _y1 : Number, _x3 : Number, _y3 : Number) : Nil
      raise_if_in_text_mode("curveTo1 is not allowed within a text block.")
      write_operator(CURVE_TO_REPLICATE_FINAL_POINT)
    end

    def curve_to2(_x2 : Number, _y2 : Number, _x3 : Number, _y3 : Number) : Nil
      raise_if_in_text_mode("curveTo2 is not allowed within a text block.")
      write_operator(CURVE_TO_REPLICATE_INITIAL_POINT)
    end

    def move_to(_x : Number, _y : Number) : Nil
      raise_if_in_text_mode("moveTo is not allowed within a text block.")
      write_operator(MOVE_TO)
    end

    def line_to(_x : Number, _y : Number) : Nil
      raise_if_in_text_mode("lineTo is not allowed within a text block.")
      write_operator(LINE_TO)
    end

    def shading_fill(_shading : Graphics::Shading::PDShadingType1) : Nil
      raise_if_in_text_mode("shadingFill is not allowed within a text block.")
      write_operator(SHADING_FILL)
    end

    def stroke : Nil
      raise_if_in_text_mode("stroke is not allowed within a text block.")
      write_operator(STROKE_PATH)
    end

    def close_and_stroke : Nil
      raise_if_in_text_mode("closeAndStroke is not allowed within a text block.")
      write_operator(CLOSE_AND_STROKE)
    end

    def close_and_fill_and_stroke : Nil
      raise_if_in_text_mode("closeAndFillAndStroke is not allowed within a text block.")
      write_operator(CLOSE_FILL_NON_ZERO_AND_STROKE)
    end

    def close_and_fill_and_stroke_even_odd : Nil
      raise_if_in_text_mode("closeAndFillAndStrokeEvenOdd is not allowed within a text block.")
      write_operator(CLOSE_FILL_EVEN_ODD_AND_STROKE)
    end

    def fill : Nil
      raise_if_in_text_mode("fill is not allowed within a text block.")
      write_operator(FILL_NON_ZERO)
    end

    def fill_and_stroke : Nil
      raise_if_in_text_mode("fillAndStroke is not allowed within a text block.")
      write_operator(FILL_NON_ZERO_AND_STROKE)
    end

    def fill_and_stroke_even_odd : Nil
      raise_if_in_text_mode("fillAndStrokeEvenOdd is not allowed within a text block.")
      write_operator(FILL_EVEN_ODD_AND_STROKE)
    end

    def fill_even_odd : Nil
      raise_if_in_text_mode("fillEvenOdd is not allowed within a text block.")
      write_operator(FILL_EVEN_ODD)
    end

    def close_path : Nil
      raise_if_in_text_mode("closePath is not allowed within a text block.")
      write_operator(CLOSE_PATH)
    end

    def clip : Nil
      raise_if_in_text_mode("clip is not allowed within a text block.")
      write_operator(CLIP_NON_ZERO)
    end

    def clip_even_odd : Nil
      raise_if_in_text_mode("clipEvenOdd is not allowed within a text block.")
      write_operator(CLIP_EVEN_ODD)
    end

    def line_cap_style(style : Int) : Nil
      write_operands(style)
      write_operator(SET_LINE_CAPSTYLE)
    end

    def line_join_style(style : Int) : Nil
      write_operands(style)
      write_operator(SET_LINE_JOINSTYLE)
    end

    def line_width(width : Number) : Nil
      write_operands(width)
      write_operator(SET_LINE_WIDTH)
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

    def miter_limit(limit : Number) : Nil
      write_operands(limit)
      write_operator(SET_LINE_MITERLIMIT)
    end

    def graphics_state_parameters(state : Graphics::State::PDExtendedGraphicsState) : Nil
      resource_name = add_ext_gstate_to_resources(state)
      @buffer << "/#{resource_name} " << SET_GRAPHICS_STATE_PARAMS << '\n'
    end

    def close : Nil
      return if @closed
      @closed = true

      stream = Cos::Stream.new
      if @compress
        encoded_output = stream.create_output_stream(Cos::Name::FLATE_DECODE)
        encoded_output.write(@buffer.to_slice)
        encoded_output.close
      else
        stream.data = @buffer.to_slice
      end
      assign_stream(stream)
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

    private def raise_if_in_text_mode(message : String) : Nil
      raise IllegalStateError.new("Error: #{message}") if @in_text_mode
    end

    private def validate_color_component(value : Number, component : String) : Nil
      numeric = value.to_f64
      return if 0.0_f64 <= numeric <= 1.0_f64
      raise ArgumentError.new("Parameters must be within 0..1, #{component}=#{numeric}")
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

    private def get_current_font : Font::PDFont?
      @current_font
    end

    private def encode_text(text : String, font : Font::PDFont) : Bytes
      font.encode(text)
    rescue ex : Exception
      offset = 0
      while offset < text.size
        code_point = text.char_at(offset).ord
        char = text.char_at(offset).to_s
        begin
          font.encode(char)
        rescue
          raise IllegalStateError.new(
            "could not find the glyphId for the character: #{char}, codePoint: #{code_point} (0x#{code_point.to_s(16).upcase})"
          )
        end
        offset += 1
      end
      raise ex
    end

    private def write_pdf_literal_string(bytes : Bytes) : Nil
      bytes.each do |byte|
        case byte
        when '('.ord.to_u8, ')'.ord.to_u8, '\\'.ord.to_u8
          @buffer << '\\' << byte.chr
        when 0x20_u8..0x7E_u8
          @buffer << byte.chr
        else
          @buffer << '\\'
          @buffer << ((byte >> 6) & 0x07).to_s
          @buffer << ((byte >> 3) & 0x07).to_s
          @buffer << (byte & 0x07).to_s
        end
      end
    end

    private def add_font_to_resources(font : Font::PDFont) : Nil
      fonts = ensure_resource_subdictionary("Font")
      existing_name = existing_font_resource_name(fonts, font)
      font_name = existing_name || "F#{fonts.size + 1}"
      @font_name = font_name
      fonts[Cos::Name.new(font_name)] = font.cos_object unless existing_name
    end

    private def existing_font_resource_name(fonts : Cos::Dictionary, font : Font::PDFont) : String?
      target_dict = font.cos_object
      target_id = target_dict.object_id

      fonts.entries.each do |key, value|
        value = value.object if value.is_a?(Cos::Object)
        next unless value.is_a?(Cos::Dictionary)
        return key.value if value.object_id == target_id
      end

      nil
    end

    private def add_image_to_xobject_resources(image : Graphics::Image::PDImageXObject) : String
      xobjects = ensure_resource_subdictionary("XObject")
      resource_name = "Im#{xobjects.size + 1}"
      xobjects[Cos::Name.new(resource_name)] = image.cos_object
      resource_name
    end

    private def add_ext_gstate_to_resources(state : Graphics::State::PDExtendedGraphicsState) : String
      ext_gstates = ensure_resource_subdictionary("ExtGState")
      resource_name = "gs#{ext_gstates.size + 1}"
      ext_gstates[Cos::Name.new(resource_name)] = state.cos_object
      resource_name
    end

    private def ensure_resource_subdictionary(name : String) : Cos::Dictionary
      cos_page = @page.cos_object || raise "Page is missing COS dictionary"

      resources = cos_page[Cos::Name.new("Resources")]?
      unless resources
        resources = Cos::Dictionary.new
        cos_page[Cos::Name.new("Resources")] = resources
      end
      resources = resources.object if resources.is_a?(Cos::Object)
      resources = resources.as(Cos::Dictionary)

      subdict = resources[Cos::Name.new(name)]?
      unless subdict
        subdict = Cos::Dictionary.new
        resources[Cos::Name.new(name)] = subdict
      end
      subdict = subdict.object if subdict.is_a?(Cos::Object)
      subdict.as(Cos::Dictionary)
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

    private def assign_stream(stream : Cos::Stream) : Nil
      cos_page = @page.cos_object || raise "Page is missing COS dictionary"
      key = Cos::Name.new("Contents")
      existing = cos_page[key]?

      case @append_mode
      when AppendMode::OVERWRITE
        cos_page[key] = stream
      when AppendMode::PREPEND
        array = contents_array_for(existing)
        array.items.unshift(stream)
        cos_page[key] = array
      when AppendMode::APPEND
        array = contents_array_for(existing)
        array.items << stream
        cos_page[key] = array
      end
    end

    private def contents_array_for(existing : Cos::Base?) : Cos::Array
      return Cos::Array.new unless existing

      if existing.is_a?(Cos::Object)
        existing = existing.object
      end

      case existing
      when Cos::Array
        existing
      when Cos::Stream
        Cos::Array.new([existing])
      else
        Cos::Array.new
      end
    end
  end
end
