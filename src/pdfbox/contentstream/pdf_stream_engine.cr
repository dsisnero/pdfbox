# PDF Stream Engine for PDFBox Crystal
#
# This module provides the base class for processing PDF content streams.
# Corresponds to org.apache.pdfbox.contentstream.PDFStreamEngine in Apache PDFBox.

require "../cos"
require "../pdmodel"
require "../pdmodel/resources"
require "../pdmodel/font"
require "../util"
require "../pdf_parser/pdf_stream_parser"
require "../content_stream/operator"
require "log"

module Pdfbox::Contentstream
  # Base class for processing PDF content streams.
  # Provides a callback interface for clients that want to do things with the stream.
  abstract class PDFStreamEngine
    Log = ::Log.for(self)

    @operators = {} of String => OperatorProcessor
    @graphics_stack = [] of GraphicsState
    @resources : Pdmodel::Resources?
    @current_page : Pdmodel::Page?
    @is_processing_page : Bool = false
    @initial_matrix : Util::Matrix?
    @level : Int32 = 0
    @default_font : Pdmodel::Font::PDFont?
    @should_process_color_operators : Bool = true

    # Creates a new PDFStreamEngine.
    def initialize
    end

    # Adds an operator processor to the engine.
    def add_operator(op : OperatorProcessor) : Nil
      @operators[op.name] = op
    end

    # Initializes the stream engine for the given page.
    private def init_page(page : Pdmodel::Page) : Nil
      @current_page = page
      @graphics_stack.clear
      @graphics_stack << GraphicsState.new
      @resources = nil
      @initial_matrix = Util::Matrix.identity
    end

    # This will initialize and process the contents of the stream.
    def process_page(page : Pdmodel::Page) : Nil
      init_page(page)
      if page.has_contents?
        @is_processing_page = true
        process_stream(page)
        @is_processing_page = false
      end
    end

    # Get the graphics state
    def graphics_state : GraphicsState
      @graphics_stack.last
    end

    # Get the text matrix
    def text_matrix : Util::Matrix
      graphics_state.text_matrix
    end

    # Set the text matrix
    def text_matrix=(matrix : Util::Matrix) : Nil
      graphics_state.text_matrix = matrix
    end

    # Get the text line matrix
    def text_line_matrix : Util::Matrix
      graphics_state.text_line_matrix
    end

    # Set the text line matrix
    def text_line_matrix=(matrix : Util::Matrix) : Nil
      graphics_state.text_line_matrix = matrix
    end

    # Save the graphics state
    def save_graphics_state : Nil
      @graphics_stack << graphics_state.clone
    end

    # Restore the graphics state
    def restore_graphics_state : Nil
      if @graphics_stack.size > 1
        @graphics_stack.pop
      end
    end

    # Get current resources
    def resources : Pdmodel::Resources?
      @resources
    end

    # Set resources
    def resources=(resources : Pdmodel::Resources?) : Nil
      @resources = resources
    end

    # Get current page
    def current_page : Pdmodel::Page?
      @current_page
    end

    # Get initial matrix
    def initial_matrix : Util::Matrix
      @initial_matrix || Util::Matrix.identity
    end

    # Set initial matrix
    def initial_matrix=(matrix : Util::Matrix) : Nil
      @initial_matrix = matrix
    end

    # Process a content stream
    private def process_stream(page : Pdmodel::Page) : Nil
      # Get the page's content stream
      cos_page = page.cos_object
      return unless cos_page

      contents = cos_page[Cos::Name.new("Contents")]
      return unless contents

      # Dereference if it's an indirect reference
      if contents.is_a?(Cos::Object)
        contents = contents.object
      end

      # Handle array of content streams
      if contents.is_a?(Cos::Array)
        contents.items.each do |item|
          stream = item
          if stream.is_a?(Cos::Object)
            stream = stream.object
          end
          if stream.is_a?(Cos::Stream)
            # Use create_input_stream to get decompressed data
            input = stream.create_input_stream
            bytes = input.getb_to_end
            process_stream_operators(bytes)
          end
        end
      elsif contents.is_a?(Cos::Stream)
        # Use create_input_stream to get decompressed data
        input = contents.create_input_stream
        bytes = input.getb_to_end
        process_stream_operators(bytes)
      end
    end

    # Process operators from content stream bytes
    private def process_stream_operators(bytes : Bytes) : Nil
      arguments = [] of Cos::Base
      parser = Pdfparser::PDFStreamParser.new(bytes)

      while token = parser.parse_next_token
        if token.is_a?(ContentStream::Operator)
          process_operator(token, arguments)
          arguments.clear
        else
          arguments << token.as(Cos::Base)
        end
      end
    end

    # Process an operator with arguments
    def process_operator(operator : ContentStream::Operator, arguments : Array(Cos::Base)) : Nil
      op_name = operator.name

      # Check if we have a registered operator processor
      if processor = @operators[op_name]?
        processor.process(arguments)
        return
      end

      # Handle built-in operators
      case op_name
      when "q"
        save_graphics_state
      when "Q"
        restore_graphics_state
      when "cm"
        # Concatenate matrix
        if arguments.size >= 6
          a = to_float(arguments[0])
          b = to_float(arguments[1])
          c = to_float(arguments[2])
          d = to_float(arguments[3])
          e = to_float(arguments[4])
          f = to_float(arguments[5])
          if a && b && c && d && e && f
            matrix = Util::Matrix.new(a.to_f32, b.to_f32, c.to_f32, d.to_f32, e.to_f32, f.to_f32)
            ctm = graphics_state.current_transformation_matrix
            graphics_state.current_transformation_matrix = ctm.multiply(matrix)
          end
        end
      when "BT"
        begin_text
      when "ET"
        end_text
      when "Tc"
        # Set character spacing
        if arguments.size >= 1
          spacing = to_float(arguments[0])
          graphics_state.character_spacing = spacing if spacing
        end
      when "Tw"
        # Set word spacing
        if arguments.size >= 1
          spacing = to_float(arguments[0])
          graphics_state.word_spacing = spacing if spacing
        end
      when "Tz"
        # Set horizontal scaling
        if arguments.size >= 1
          scaling = to_float(arguments[0])
          graphics_state.horizontal_scaling = scaling if scaling
        end
      when "TL"
        # Set text leading
        if arguments.size >= 1
          leading = to_float(arguments[0])
          graphics_state.text_leading = leading if leading
        end
      when "Tf"
        # Set font and size
        if arguments.size >= 2
          font_name = arguments[0]
          font_size = to_float(arguments[1])
          if font_name.is_a?(Cos::Name) && font_size
            set_font(font_name.value, font_size)
          end
        end
      when "Tr"
        # Set text rendering mode
        if arguments.size >= 1
          mode = to_int(arguments[0])
          graphics_state.text_rendering_mode = mode if mode
        end
      when "Ts"
        # Set text rise
        if arguments.size >= 1
          rise = to_float(arguments[0])
          graphics_state.text_rise = rise if rise
        end
      when "Td"
        # Move text position
        if arguments.size >= 2
          tx = to_float(arguments[0])
          ty = to_float(arguments[1])
          if tx && ty
            move_text(tx, ty)
          end
        end
      when "TD"
        # Move text and set leading
        if arguments.size >= 2
          tx = to_float(arguments[0])
          ty = to_float(arguments[1])
          if tx && ty
            move_text(tx, ty)
            graphics_state.text_leading = -ty
          end
        end
      when "Tm"
        # Set text matrix
        if arguments.size >= 6
          a = to_float(arguments[0])
          b = to_float(arguments[1])
          c = to_float(arguments[2])
          d = to_float(arguments[3])
          e = to_float(arguments[4])
          f = to_float(arguments[5])
          if a && b && c && d && e && f
            matrix = Util::Matrix.new(a.to_f32, b.to_f32, c.to_f32, d.to_f32, e.to_f32, f.to_f32)
            self.text_matrix = matrix
            self.text_line_matrix = matrix
          end
        end
      when "T*"
        # Move to next line
        leading = graphics_state.text_leading
        move_text(0, -leading)
      when "Tj"
        # Show text
        if arguments.size >= 1
          show_text_string(arguments[0])
        end
      when "TJ"
        # Show text with adjustments
        if arguments.size >= 1
          array = arguments[0]
          if array.is_a?(Cos::Array)
            show_text_strings(array)
          end
        end
      when "'"
        # Move to next line and show text
        leading = graphics_state.text_leading
        move_text(0, -leading)
        if arguments.size >= 1
          show_text_string(arguments[0])
        end
      when "\""
        # Set word spacing, move to next line, and show text
        if arguments.size >= 3
          word_spacing = to_float(arguments[0])
          char_spacing = to_float(arguments[1])
          graphics_state.word_spacing = word_spacing if word_spacing
          graphics_state.character_spacing = char_spacing if char_spacing
          leading = graphics_state.text_leading
          move_text(0, -leading)
          show_text_string(arguments[2])
        end
      else
        # Unknown operator - ignore
        Log.debug { "Unknown operator: #{op_name}" }
      end
    end

    # Called when the BT operator is encountered
    def begin_text : Nil
      self.text_matrix = Util::Matrix.identity
      self.text_line_matrix = Util::Matrix.identity
    end

    # Called when the ET operator is encountered
    def end_text : Nil
      # Default implementation does nothing
    end

    # Set font and size
    def set_font(font_name : String, font_size : Float64) : Nil
      page = @current_page
      return unless page

      resources = page.resources
      return unless resources

      # Get font from resources dictionary
      cos_resources = resources.cos_object
      return unless cos_resources

      fonts = cos_resources[Cos::Name.new("Fonts")] || cos_resources[Cos::Name.new("Font")]
      return unless fonts

      if fonts.is_a?(Cos::Object)
        fonts = fonts.object
      end

      return unless fonts.is_a?(Cos::Dictionary)

      font_dict = fonts[Cos::Name.new(font_name)]
      return unless font_dict

      if font_dict.is_a?(Cos::Object)
        font_dict = font_dict.object
      end

      return unless font_dict.is_a?(Cos::Dictionary)

      # Create font from dictionary
      font = Pdmodel::Font::PDFontFactory.create_font(font_dict)
      if font
        graphics_state.font = font
        graphics_state.font_size = font_size
      end
    end

    # Move text position
    def move_text(tx : Float64, ty : Float64) : Nil
      matrix = Util::Matrix.translate(tx.to_f32, ty.to_f32)
      new_matrix = text_line_matrix.multiply(matrix)
      self.text_matrix = new_matrix
      self.text_line_matrix = new_matrix
    end

    # Show text string
    def show_text_string(obj : Cos::Base) : Nil
      if obj.is_a?(Cos::String)
        show_text(obj.bytes)
      end
    end

    # Show text strings with adjustments
    def show_text_strings(array : Cos::Array) : Nil
      font = graphics_state.font
      return unless font

      is_vertical = font.vertical?
      font_size = graphics_state.font_size
      horizontal_scaling = graphics_state.horizontal_scaling / 100.0

      array.items.each do |item|
        if item.is_a?(Cos::Integer) || item.is_a?(Cos::Float)
          tj = to_float(item) || 0.0

          # Calculate the combined displacements
          tx : Float64
          ty : Float64
          if is_vertical
            tx = 0
            ty = -tj / 1000 * font_size
          else
            tx = -tj / 1000 * font_size * horizontal_scaling
            ty = 0
          end

          apply_text_adjustment(tx, ty)
        elsif item.is_a?(Cos::String)
          show_text(item.value.to_slice)
        end
      end
    end

    # Apply text position adjustment from TJ operator
    def apply_text_adjustment(tx : Float64, ty : Float64) : Nil
      matrix = Util::Matrix.translate(tx.to_f32, ty.to_f32)
      self.text_matrix = text_matrix.multiply(matrix)
    end

    # Show text bytes
    def show_text(bytes : Bytes) : Nil
      font = graphics_state.font
      return unless font

      font_size = graphics_state.font_size
      horizontal_scaling = graphics_state.horizontal_scaling / 100.0
      char_spacing = graphics_state.character_spacing
      input = ::IO::Memory.new(bytes)

      until input.pos >= input.size
        before = input.pos
        code = font.read_code(input)
        break if code < 0

        code_length = (input.pos - before).to_i32
        displacement = font.displacement(code)
        width = displacement.x * font_size * horizontal_scaling + char_spacing

        # Add word spacing for space character
        if code_length == 1 && code == 32
          width += graphics_state.word_spacing
        end

        # Calculate text rendering matrix
        td = Util::Matrix.translate(width.to_f32, 0.0_f32)
        text_rendering_matrix = td.multiply(text_matrix).multiply(graphics_state.current_transformation_matrix)

        # Call show_glyph for the character
        show_glyph(text_rendering_matrix, font, code, displacement)

        # Update text matrix
        self.text_matrix = text_matrix.multiply(td)
      end
    end

    # Called when a glyph is to be processed.
    # Subclasses should override this method.
    def show_glyph(text_rendering_matrix : Util::Matrix, font : Pdmodel::Font::PDFont, code : Int32, displacement : Pdmodel::Font::PDFont::Vector) : Nil
      # Default implementation does nothing
    end

    # Called when text position is processed.
    # Subclasses should override this method.
    def process_text_position(text_position : Text::TextPosition) : Nil
      # Default implementation does nothing
    end

    # Compute font height
    def compute_font_height(font : Pdmodel::Font::PDFont) : Float64
      bbox = font.bounding_box
      if bbox.lower_left_y < -32768
        # PDFBOX-2158 and PDFBOX-3130
        bbox = Pdmodel::Font::BoundingBox.new(
          bbox.lower_left_x,
          -(bbox.lower_left_y + 65536),
          bbox.upper_right_x,
          bbox.upper_right_y
        )
      end

      # 1/2 the bbox is used as the height
      glyph_height = bbox.height / 2.0

      # Sometimes the bbox has very high values, but CapHeight is OK
      font_descriptor = font.font_descriptor
      if font_descriptor
        cap_height = font_descriptor.cap_height
        if cap_height != 0 && (cap_height < glyph_height || glyph_height == 0)
          glyph_height = cap_height.to_f
        end

        # PDFBOX-3464, PDFBOX-4480, PDFBOX-4553:
        # Sometimes even CapHeight has very high value, but Ascent and Descent are ok
        ascent = font_descriptor.ascent
        descent = font_descriptor.descent
        if cap_height > ascent && ascent > 0 && descent < 0 &&
           ((ascent - descent) / 2 < glyph_height || glyph_height == 0)
          glyph_height = (ascent - descent) / 2
        end
      end

      # TransformPoint from glyph space -> text space
      height = if font.is_a?(Pdmodel::Font::Type3Font)
                 font.font_matrix.transform_point(0, glyph_height).y
               else
                 glyph_height / 1000.0
               end

      height
    end

    private def to_float(obj : Cos::Base) : Float64?
      case obj
      when Cos::Integer
        obj.value.to_f64
      when Cos::Float
        obj.value
      end
    end

    private def to_int(obj : Cos::Base) : Int32?
      case obj
      when Cos::Integer
        obj.value.to_i32
      when Cos::Float
        obj.value.to_i32
      end
    end
  end

  # Graphics state for the PDF stream engine
  class GraphicsState
    property current_transformation_matrix : Util::Matrix
    property text_matrix : Util::Matrix
    property text_line_matrix : Util::Matrix
    property font_size : Float64
    property horizontal_scaling : Float64
    property character_spacing : Float64
    property word_spacing : Float64
    property text_leading : Float64
    property text_rendering_mode : Int32
    property text_rise : Float64
    property font : Pdmodel::Font::PDFont?

    def initialize
      @current_transformation_matrix = Util::Matrix.identity
      @text_matrix = Util::Matrix.identity
      @text_line_matrix = Util::Matrix.identity
      @font_size = 1.0
      @horizontal_scaling = 100.0
      @character_spacing = 0.0
      @word_spacing = 0.0
      @text_leading = 0.0
      @text_rendering_mode = 0
      @text_rise = 0.0
      @font = nil
    end

    def clone : GraphicsState
      state = GraphicsState.new
      state.current_transformation_matrix = @current_transformation_matrix
      state.text_matrix = @text_matrix
      state.text_line_matrix = @text_line_matrix
      state.font_size = @font_size
      state.horizontal_scaling = @horizontal_scaling
      state.character_spacing = @character_spacing
      state.word_spacing = @word_spacing
      state.text_leading = @text_leading
      state.text_rendering_mode = @text_rendering_mode
      state.text_rise = @text_rise
      state.font = @font
      state
    end
  end

  # Base class for operator processors
  abstract class OperatorProcessor
    @engine : PDFStreamEngine

    def initialize(@engine : PDFStreamEngine)
    end

    # Get the operator name
    abstract def name : String

    # Process the operator with the given arguments
    abstract def process(arguments : Array(Cos::Base)) : Nil
  end
end
