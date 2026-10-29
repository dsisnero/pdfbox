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
    @graphics_stack = [] of GraphicsState | Pdmodel::Graphics::State::PDGraphicsState
    @resources : Pdmodel::Resources?
    @current_page : Pdmodel::Page?
    @is_processing_page : Bool = false
    @initial_matrix : Util::Matrix?
    @level : Int32 = 0
    @default_font : Pdmodel::Font::PDFont?
    @should_process_color_operators : Bool = true

    # Creates a new PDFStreamEngine. Like Java's constructor, an initial graphics
    # state is pushed so that subclasses can query it before a page is processed.
    def initialize
      @graphics_stack << create_graphics_state
    end

    # Creates the graphics state pushed for a page and for the constructor.
    # Java only has PDGraphicsState; the plain engine uses the port's lighter
    # `GraphicsState`, while `PDFGraphicsStreamEngine` overrides this to keep the
    # Java-shaped `PDGraphicsState` (colour, clipping and text state live there).
    protected def create_graphics_state : GraphicsState | Pdmodel::Graphics::State::PDGraphicsState
      GraphicsState.new
    end

    # Adds an operator processor to the engine.
    def add_operator(op : OperatorProcessor) : Nil
      @operators[op.name] = op
    end

    # Initializes the stream engine for the given page.
    private def init_page(page : Pdmodel::Page) : Nil
      @current_page = page
      @graphics_stack.clear
      @graphics_stack << create_graphics_state
      @resources = nil
      @initial_matrix = page.matrix
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
    # The number of graphics states on the stack (Java
    # PDFStreamEngine#getGraphicsStackSize).
    def graphics_stack_size : Int32
      @graphics_stack.size
    end

    # Transforms a point with the current transformation matrix (Java
    # PDFStreamEngine#transformedPoint). Java returns a `Point2D.Float`; the port
    # returns an `{x, y}` tuple instead of using AWT.
    def transformed_point(x : Float64, y : Float64) : Tuple(Float64, Float64)
      matrix = graphics_state.current_transformation_matrix
      {
        (matrix.get_value(0, 0) * x + matrix.get_value(1, 0) * y + matrix.get_value(2, 0)).to_f64,
        (matrix.get_value(0, 1) * x + matrix.get_value(1, 1) * y + matrix.get_value(2, 1)).to_f64,
      }
    end

    # Transforms a width using the current transformation matrix (Java
    # PDFStreamEngine#transformWidth).
    def transform_width(width : Float64) : Float64
      matrix = graphics_state.current_transformation_matrix
      x = matrix.scale_x + matrix.shear_x
      y = matrix.scale_y + matrix.shear_y
      width * Math.sqrt((x * x + y * y) * 0.5)
    end

    # Get the graphics state. Java's engine has a single PDGraphicsState stack;
    # the port also runs a lighter `GraphicsState` for plain engines, so this
    # returns whichever state the engine pushes. Callers address both through the
    # same messages (see the text-state accessors on PDGraphicsState).
    def graphics_state : GraphicsState | Pdmodel::Graphics::State::PDGraphicsState
      @graphics_stack.last
    end

    # Saves the entire graphics stack (Java PDFStreamEngine#saveGraphicsStack).
    # The current state becomes a clone of the previous top of the stack.
    protected def save_graphics_stack : Array(GraphicsState | Pdmodel::Graphics::State::PDGraphicsState)
      snapshot = @graphics_stack
      @graphics_stack = [snapshot.last.clone]
      snapshot
    end

    # Restores the entire graphics stack (Java
    # PDFStreamEngine#restoreGraphicsStack).
    protected def restore_graphics_stack(snapshot : Array(GraphicsState | Pdmodel::Graphics::State::PDGraphicsState)) : Nil
      @graphics_stack = snapshot
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
      parent_resources = @resources
      parent_initial_matrix = @initial_matrix
      saved_stack = save_graphics_stack

      @resources = page.resources || Pdmodel::Resources.new(Cos::Dictionary.new)
      ctm = graphics_state.current_transformation_matrix
      ctm.concatenate(page.matrix)
      graphics_state.current_transformation_matrix = ctm
      @initial_matrix = graphics_state.current_transformation_matrix.clone

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
    ensure
      @initial_matrix = parent_initial_matrix
      @resources = parent_resources
      restore_graphics_stack(saved_stack) if saved_stack
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
            ctm.concatenate(matrix)
            graphics_state.current_transformation_matrix = ctm
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
          font_name = font_name.object if font_name.is_a?(Cos::Object)
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
            self.text_line_matrix = matrix.clone
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
          array = array.object if array.is_a?(Cos::Object)
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
      when "Do"
        if arguments.size >= 1 && arguments[0].is_a?(Cos::Name)
          show_xobject(arguments[0].as(Cos::Name))
        end
      when "BMC"
        begin_marked_content_sequence
      when "BDC"
        raw_tag = arguments[0]?
        raw_tag = raw_tag.object if raw_tag.is_a?(Cos::Object)
        tag = raw_tag.try(&.as?(Cos::Name))
        properties = arguments[1]?
        begin_marked_content_sequence(tag, properties)
      when "EMC"
        end_marked_content_sequence
      when "MP"
        if arguments.size >= 1
          if tag = arguments[0].try(&.as?(Cos::Name))
            marked_content_point(tag, nil)
          end
        end
      when "DP"
        if arguments.size >= 2
          if tag = arguments[0].try(&.as?(Cos::Name))
            properties = arguments[1]?
            marked_content_point(tag, properties)
          end
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
      resources = @resources || @current_page.try(&.resources)
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

    private def show_xobject(name : Cos::Name) : Nil
      resources = @resources
      return unless resources

      xobject = resources.xobject(name)
      return unless xobject.is_a?(Cos::Stream)

      subtype = xobject[Cos::Name.new("Subtype")]
      if subtype.is_a?(Cos::Object)
        subtype = subtype.object
      end

      return unless subtype.is_a?(Cos::Name)
      return if subtype.value == "Image"
      return unless subtype.value == "Form"

      process_form_xobject(xobject)
    end

    # Current recursion level, used to guard form XObject recursion.
    # Java PDFStreamEngine#getLevel.
    def level : Int32
      @level
    end

    # Increase the recursion level (Java PDFStreamEngine#increaseLevel).
    def increase_level : Nil
      @level += 1
    end

    # Decrease the recursion level (Java PDFStreamEngine#decreaseLevel).
    def decrease_level : Nil
      @level -= 1
      Log.warn { "level is below 0, this indicates that decreaseLevel() was called too often" } if @level < 0
    end

    # Processes a Form XObject's content stream, temporarily switching to the
    # form's resources and applying its /Matrix. Java PDFStreamEngine#showForm.
    def process_form_xobject(stream : Cos::Stream) : Nil
      parent_resources = @resources
      parent_initial_matrix = @initial_matrix
      saved_stack = save_graphics_stack

      form_resources = stream[Cos::Name.new("Resources")]
      if form_resources.is_a?(Cos::Object)
        form_resources = form_resources.object
      end
      @resources = form_resources.is_a?(Cos::Dictionary) ? Pdmodel::Resources.new(form_resources) : parent_resources

      form_matrix = matrix_from_cos_array(stream[Cos::Name.new("Matrix")])
      if form_matrix
        ctm = graphics_state.current_transformation_matrix
        ctm.concatenate(form_matrix)
        graphics_state.current_transformation_matrix = ctm
      end
      @initial_matrix = graphics_state.current_transformation_matrix.clone

      input = stream.create_input_stream
      process_stream_operators(input.getb_to_end)
    ensure
      @initial_matrix = parent_initial_matrix
      @resources = parent_resources
      restore_graphics_stack(saved_stack) if saved_stack
    end

    # Processes a Type 3 character stream (Java PDFStreamEngine#processType3Stream).
    # The text rendering matrix replaces the CTM, concatenated with the charproc's
    # matrix (the font matrix), and text starts from an empty matrix. The bounding
    # box is deliberately not clipped: it is often wrong (PDFBOX-1917).
    def process_type3_stream(char_proc : Pdmodel::Font::PDType3CharProc, text_rendering_matrix : Util::Matrix) : Nil
      unless @current_page
        raise Exception.new("No current page, call #process_child_stream(PDContentStream, PDPage) instead")
      end

      parent_resources = @resources
      saved_stack = save_graphics_stack

      begin
        char_proc_resources = char_proc.resources
        if char_proc_resources
          resources_object = char_proc_resources.cos_object
          if resources_object.is_a?(Cos::Dictionary)
            @resources = Pdmodel::Resources.new(resources_object)
          end
        end

        state = graphics_state
        # replace the CTM with the TRM, then transform it using the stream's
        # matrix (this is the FontMatrix)
        ctm = text_rendering_matrix.clone
        font_matrix = char_proc.matrix
        ctm.concatenate(Util::Matrix.new(
          font_matrix.a, font_matrix.b, font_matrix.c,
          font_matrix.d, font_matrix.e, font_matrix.f
        ))
        state.current_transformation_matrix = ctm
        state.text_matrix = Util::Matrix.new
        state.text_line_matrix = Util::Matrix.new

        process_stream_operators(char_proc.cos_object.create_input_stream.getb_to_end)
      ensure
        restore_graphics_stack(saved_stack) if saved_stack
        @resources = parent_resources
      end
    end

    private def matrix_from_cos_array(base : Cos::Base?) : Util::Matrix?
      return unless base
      if base.is_a?(Cos::Object)
        base = base.object
      end
      return unless base.is_a?(Cos::Array)
      return unless base.size >= 6

      values = base.items[0, 6].map { |item| to_float(item) }
      return unless values.all?

      Util::Matrix.new(
        values[0].as(Float64).to_f32,
        values[1].as(Float64).to_f32,
        values[2].as(Float64).to_f32,
        values[3].as(Float64).to_f32,
        values[4].as(Float64).to_f32,
        values[5].as(Float64).to_f32
      )
    end

    # Move text position
    def move_text(tx : Float64, ty : Float64) : Nil
      matrix = Util::Matrix.translate(tx.to_f32, ty.to_f32)
      text_line = text_line_matrix
      text_line.concatenate(matrix)
      new_matrix = text_line
      self.text_matrix = new_matrix.clone
      self.text_line_matrix = new_matrix
    end

    # Show text string
    def show_text_string(obj : Cos::Base) : Nil
      resolved = obj.is_a?(Cos::Object) ? obj.object : obj
      if resolved.is_a?(Cos::String)
        show_text(resolved.bytes)
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
        # Resolve indirect references
        resolved = item.is_a?(Cos::Object) ? item.object : item
        if resolved.is_a?(Cos::Number)
          tj = to_float(resolved) || 0.0

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
        elsif resolved.is_a?(Cos::String)
          show_text(resolved.bytes)
        end
      end
    end

    # Apply text position adjustment from TJ operator
    def apply_text_adjustment(tx : Float64, ty : Float64) : Nil
      text_matrix.translate(tx.to_f32, ty.to_f32)
    end

    # Show text bytes
    def show_text(bytes : Bytes) : Nil
      font = graphics_state.font
      return unless font

      state = graphics_state
      font_size = state.font_size
      horizontal_scaling = state.horizontal_scaling / 100.0
      char_spacing = state.character_spacing
      parameters = Util::Matrix.new(
        (font_size * horizontal_scaling).to_f32, 0.0_f32,
        0.0_f32, font_size.to_f32,
        0.0_f32, state.text_rise.to_f32
      )
      input = ::IO::Memory.new(bytes)

      until input.pos >= input.size
        before = input.pos
        code = font.read_code(input)
        break if code < 0

        code_length = (input.pos - before).to_i32
        word_spacing = code_length == 1 && code == 32 ? state.word_spacing : 0.0
        ctm = state.current_transformation_matrix
        text_rendering_matrix = parameters.multiply(text_matrix).multiply(ctm)

        if font.vertical?
          text_rendering_matrix.translate(font.position_vector(code).x, font.position_vector(code).y)
        end

        displacement = font.displacement(code)

        show_glyph(text_rendering_matrix, font, code, displacement)

        tx : Float64
        ty : Float64
        if font.vertical?
          tx = 0.0
          ty = displacement.y.to_f64 * font_size + char_spacing + word_spacing
        else
          tx = (displacement.x.to_f64 * font_size + char_spacing + word_spacing) * horizontal_scaling
          ty = 0.0
        end
        text_matrix.translate(tx.to_f32, ty.to_f32)
      end
    end

    # Called when a glyph is to be processed (Java PDFStreamEngine#showGlyph).
    # Type 3 fonts go to show_type3_glyph, everything else to show_font_glyph.
    def show_glyph(text_rendering_matrix : Util::Matrix, font : Pdmodel::Font::PDFont, code : Int32, displacement : Pdmodel::Font::PDFont::Vector) : Nil
      if font.is_a?(Pdmodel::Font::PDType3Font)
        show_type3_glyph(text_rendering_matrix, font, code, displacement)
      else
        show_font_glyph(text_rendering_matrix, font, code, displacement)
      end
    end

    # Called when a glyph of a simple or composite font is to be processed. The
    # default implementation does nothing; subclasses override it.
    def show_font_glyph(text_rendering_matrix : Util::Matrix, font : Pdmodel::Font::PDFont, code : Int32, displacement : Pdmodel::Font::PDFont::Vector) : Nil
    end

    # Called when a Type 3 glyph is to be processed. The default implementation
    # processes the character procedure stream, like Java.
    def show_type3_glyph(text_rendering_matrix : Util::Matrix, font : Pdmodel::Font::PDType3Font, code : Int32, displacement : Pdmodel::Font::PDFont::Vector) : Nil
      char_proc = font.get_char_proc(code)
      process_type3_stream(char_proc, text_rendering_matrix) if char_proc
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
      resolved = obj.is_a?(Cos::Object) ? obj.object : obj
      case resolved
      when Cos::Integer
        resolved.value.to_f64
      when Cos::Float
        resolved.value
      end
    end

    private def to_int(obj : Cos::Base) : Int32?
      resolved = obj.is_a?(Cos::Object) ? obj.object : obj
      case resolved
      when Cos::Integer
        resolved.value.to_i32
      when Cos::Float
        resolved.value.to_i32
      end
    end

    # Begin a marked-content sequence.
    # Port of Java PDFStreamEngine.beginMarkedContentSequence.
    def begin_marked_content_sequence(tag : Cos::Name? = nil, properties : Cos::Base? = nil) : Nil
      @marked_content_stack ||= [] of {Cos::Name?, Cos::Base?}
      if stack = @marked_content_stack
        stack << {tag, properties}
      end
    end

    # End a marked-content sequence.
    # Port of Java PDFStreamEngine.endMarkedContentSequence.
    def end_marked_content_sequence : Nil
      if stack = @marked_content_stack
        stack.pop? unless stack.empty?
      end
    end

    # Mark a marked-content point.
    # Port of Java PDFStreamEngine.markedContentPoint.
    def marked_content_point(tag : Cos::Name, properties : Cos::Base?) : Nil
      # Record as a point (not pushed onto stack since it has no duration)
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
      state.current_transformation_matrix = @current_transformation_matrix.clone
      state.text_matrix = @text_matrix.clone
      state.text_line_matrix = @text_line_matrix.clone
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
