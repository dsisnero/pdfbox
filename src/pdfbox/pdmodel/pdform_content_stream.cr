require "../content_stream/operator_name"

module Pdfbox::Pdmodel
  class PDFormContentStream
    include Pdfbox::ContentStream::OperatorName

    @buffer : ::IO::Memory
    @stream : Common::PDStream
    @resources : PDResources?
    @closed = false

    def initialize(form : Graphics::Form::PDFormXObject)
      @stream = form.content_stream
      @resources = form.resources
      @buffer = ::IO::Memory.new
    end

    def non_stroking_color=(color : Graphics::Color::PDColor) : Graphics::Color::PDColor
      write_color(color, stroking: false)
      color
    end

    def stroking_color=(color : Graphics::Color::PDColor) : Graphics::Color::PDColor
      write_color(color, stroking: true)
      color
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

    def miter_limit(limit : Number) : Nil
      write_operands(limit)
      write_operator(SET_LINE_MITERLIMIT)
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

    def add_rect(x : Number, y : Number, width : Number, height : Number) : Nil
      write_operands(x, y, width, height)
      write_operator(APPEND_RECT)
    end

    def fill : Nil
      write_operator(FILL_NON_ZERO)
    end

    def stroke : Nil
      write_operator(STROKE_PATH)
    end

    def draw_form(form : Graphics::Form::PDFormXObject) : Nil
      resources = @resources
      resource_name =
        if resources
          resources.add(form, "Fm")
        else
          Pdfbox::Cos::Name.new("Fm0")
        end
      @buffer << '/' << resource_name.value << ' ' << DRAW_OBJECT << '\n'
    end

    def close : Nil
      return if @closed
      @closed = true
      output = @stream.create_output_stream
      output.write(@buffer.to_slice)
      output.close
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
