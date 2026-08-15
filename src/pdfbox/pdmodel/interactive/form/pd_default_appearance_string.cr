# Represents a default appearance string, as found in the /DA entry of free text
# annotations and variable text fields.
#
# The default appearance string (DA) contains any graphics state or text state
# operators needed to establish the graphics state parameters, such as text size
# and colour, for displaying the field's variable text. Only operators that are
# allowed within text objects shall occur in this string.
module Pdfbox::Pdmodel::Interactive::Form
  class PDDefaultAppearanceString
    # The default font size used by Acrobat.
    DEFAULT_FONT_SIZE = 12.0_f32

    @default_resources : Pdfbox::Pdmodel::PDResources

    @font_name : Pdfbox::Cos::Name?
    @font : Pdfbox::Pdmodel::Font::PDFont?
    @font_size : Float32 = DEFAULT_FONT_SIZE
    @font_color : Pdfbox::Pdmodel::Graphics::Color::PDColor?

    # Constructor for reading an existing DA string.
    def initialize(default_appearance : Pdfbox::Cos::String?, default_resources : Pdfbox::Pdmodel::PDResources?)
      raise ArgumentError.new("/DA is a required entry. Please set a default appearance first.") if default_appearance.nil?
      raise ArgumentError.new("/DR is a required entry") if default_resources.nil?

      @default_resources = default_resources
      process_appearance_string_operators(default_appearance.value)
    end

    # Processes the operators of the given content stream.
    private def process_appearance_string_operators(content : String) : Nil
      arguments = [] of Pdfbox::Cos::Base
      parser = Pdfbox::Pdfparser::PDFStreamParser.new(content.to_slice)
      token = parser.parse_next_token
      while token
        if token.is_a?(Pdfbox::ContentStream::Operator)
          process_operator(token, arguments)
          arguments = [] of Pdfbox::Cos::Base
        else
          arguments << token
        end
        token = parser.parse_next_token
      end
    end

    # This is used to handle an operation.
    private def process_operator(operator : Pdfbox::ContentStream::Operator, operands : Array(Pdfbox::Cos::Base)) : Nil
      case operator.name
      when Pdfbox::ContentStream::OperatorName::SET_FONT_AND_SIZE
        process_set_font(operands)
      when Pdfbox::ContentStream::OperatorName::NON_STROKING_GRAY,
           Pdfbox::ContentStream::OperatorName::NON_STROKING_RGB,
           Pdfbox::ContentStream::OperatorName::NON_STROKING_CMYK
        process_set_font_color(operands)
      else
        # ignore other operators
      end
    end

    # Process the set font and font size operator.
    private def process_set_font(operands : Array(Pdfbox::Cos::Base)) : Nil
      if operands.size < 2
        raise ::IO::Error.new("Missing operands for set font operator #{operands}")
      end

      base0 = operands[0]
      base1 = operands[1]
      return unless base0.is_a?(Pdfbox::Cos::Name)
      return unless base1.is_a?(Pdfbox::Cos::Integer) || base1.is_a?(Pdfbox::Cos::Float)

      font_name = base0

      font = @default_resources.get_font(font_name)
      font_size = base1.to_f32

      if font.nil?
        raise ::IO::Error.new("Could not find font: /#{font_name.value}")
      end
      @font_name = font_name
      @font = font
      @font_size = font_size
    end

    # Process the font color operator. This is assumed to be an RGB color.
    private def process_set_font_color(operands : Array(Pdfbox::Cos::Base)) : Nil
      color_space = case operands.size
                    when 1 then Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
                    when 3 then Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
                    when 4 then Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE
                    else
                      raise ::IO::Error.new("Missing operands for set non stroking color operator #{operands}")
                    end

      array = Pdfbox::Cos::Array.new
      operands.each do |operand|
        array.add(operand)
      end
      @font_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(array, color_space)
    end

    # Get the font name to use for resource lookup.
    getter font_name : Pdfbox::Cos::Name?

    # Returns the font.
    getter font : Pdfbox::Pdmodel::Font::PDFont?

    # Returns the font size.
    getter font_size : Float32

    # Returns the font color.
    getter font_color : Pdfbox::Pdmodel::Graphics::Color::PDColor?

    # Write font name, font size and color from the /DA string to the given
    # content stream.
    #
    # *zero_font_size*: the calculated font size to use if the /DA string has a
    # size 0 (autosize). Otherwise the size from the /DA string is used.
    def write_to(contents : Pdfbox::Pdmodel::PDAppearanceContentStream, zero_font_size : Number) : Nil
      font_size = @font_size
      font_size = zero_font_size.to_f32 if font_size == 0

      font = @font || raise ArgumentError.new("font is null, check whether /DA entry is incomplete or incorrect")
      contents.set_font(font, font_size)

      if font_color = @font_color
        contents.non_stroking_color = font_color
      end
    end

    # Copies any needed resources from the document's DR dictionary into the
    # stream's Resources dictionary. Resources with the same name shall be left
    # intact.
    def copy_needed_resources_to(appearance_stream : Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream) : Nil
      # make sure we have resources
      stream_resources = appearance_stream.resources
      if stream_resources.nil?
        stream_resources = Pdfbox::Pdmodel::PDResources.new
        appearance_stream.resources = stream_resources
      end

      if font_name = @font_name
        if stream_resources.font(font_name).nil? && (font = @font)
          stream_resources.put(font_name, font)
        end
      end

      # todo: other kinds of resource...
    end
  end
end
