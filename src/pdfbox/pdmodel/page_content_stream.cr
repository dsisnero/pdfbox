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
    @gsub_workers = {} of Font::PDType0Font => Fontbox::TTF::Gsub::GsubWorker

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

    # Set the text matrix (Tm). Java PDAbstractContentStream#setTextMatrix.
    # ameba:disable Naming/AccessorMethodName
    def set_text_matrix(matrix : Pdfbox::Util::Matrix) : Nil
      write_operands(
        matrix.get_value(0, 0),
        matrix.get_value(0, 1),
        matrix.get_value(1, 0),
        matrix.get_value(1, 1),
        matrix.get_value(2, 0),
        matrix.get_value(2, 1)
      )
      write_operator(SET_MATRIX)
    end

    # Begin a marked content sequence without properties (BMC).
    # Java PDAbstractContentStream#beginMarkedContent(COSName).
    def begin_marked_content(tag : Cos::Name) : Nil
      @buffer << '/' << tag.value << ' ' << BEGIN_MARKED_CONTENT << '\n'
    end

    # Begin a marked content sequence with an MCID (BDC).
    # Java PDAbstractContentStream#beginMarkedContent(COSName, int).
    def begin_marked_content(tag : Cos::Name, mcid : Int32) : Nil
      raise ArgumentError.new("mcid should not be negative") if mcid < 0
      @buffer << '/' << tag.value << " <</MCID " << mcid << ">> " << BEGIN_MARKED_CONTENT_SEQ << '\n'
    end

    # Begin a marked content sequence referencing a property list (BDC).
    # Java PDAbstractContentStream#beginMarkedContent(COSName, PDPropertyList).
    def begin_marked_content(tag : Cos::Name, property_list : DocumentInterchange::MarkedContent::PDPropertyList) : Nil
      @buffer << '/' << tag.value << ' '

      dict = property_list.cos_object
      mcid = dict.get_int(Cos::Name.new("MCID"), -1_i64)
      if mcid > -1 && dict.entries.size == 1
        # PDFBOX-5890: simplified notation when only an MCID is present.
        @buffer << "<</MCID " << mcid << ">> " << BEGIN_MARKED_CONTENT_SEQ << '\n'
      else
        resource_name = add_property_list_to_resources(property_list)
        @buffer << '/' << resource_name << ' ' << BEGIN_MARKED_CONTENT_SEQ << '\n'
      end
    end

    # End the current marked content sequence (EMC).
    # Java PDAbstractContentStream#endMarkedContent.
    def end_marked_content : Nil
      write_operator(END_MARKED_CONTENT)
    end

    def set_font(font : Font::PDFont, font_size : Number) : Nil
      add_font_to_resources(font)
      @document.register_font_for_save(font)
      @current_font = font
      # complex text layout: create a GsubWorker for Type0 fonts with GSUB data
      if font.is_a?(Font::PDType0Font)
        type0 = font.as(Font::PDType0Font)
        gsub_data = type0.gsub_data
        if gsub_data != Fontbox::TTF::Model::GsubData::NO_DATA_FOUND
          cmap = type0.cmap_lookup
          if cmap
            worker = Fontbox::TTF::Gsub::GsubWorkerFactory.new.gsub_worker(cmap, gsub_data)
            @gsub_workers[type0] = worker
          end
        end
      end
      @buffer << "/#{@font_name} " << format_number(font_size) << ' ' << SET_FONT_AND_SIZE << '\n'
    end

    def show_text(text : String) : Nil
      font = get_current_font
      @buffer << '('
      if font
        encoded = encode_text(text, font)
        # Java PDAbstractContentStream#showText adds every shown code point to
        # the subset (even on the GSUB path, which only records glyph IDs), so
        # the embedded subset keeps a usable cmap for later reuse.
        if font.will_be_subset?
          text.each_char { |char| font.add_to_subset(char.ord) }
        end
        write_pdf_literal_string(encoded)
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

    # Writes an inline image directly into the content stream.
    # Java PDAbstractContentStream#drawImage(PDInlineImage, x, y, width, height).
    def draw_image(image : Graphics::Image::PDInlineImage, x : Number, y : Number, width : Number, height : Number) : Nil
      raise_if_in_text_mode("drawImage is not allowed within a text block.")
      write_operator(SAVE)
      write_operands(width, 0, 0, height, x, y)
      write_operator(CONCAT)

      dict = String.build do |builder|
        builder << BEGIN_INLINE_IMAGE
        builder << "\n /W " << image.width
        builder << "\n /H " << image.height
        if color_space = image.color_space
          builder << "\n /CS /" << color_space.name
        end
        if (decode = image.decode) && !decode.items.empty?
          builder << "\n /D ["
          decode.items.each do |base|
            value = base.is_a?(Cos::Number) ? base.to_i : 0
            builder << value << ' '
          end
          builder << ']'
        end
        builder << "\n /IM true" if image.stencil?
        builder << "\n /BPC " << image.bits_per_component
      end
      @buffer << dict << '\n'

      write_operator(BEGIN_INLINE_IMAGE_DATA)
      @buffer.write(image.data)
      @buffer << '\n'
      write_operator(END_INLINE_IMAGE)
      write_operator(RESTORE)
    end

    def add_rect(x : Number, y : Number, width : Number, height : Number) : Nil
      raise_if_in_text_mode("addRect is not allowed within a text block.")
      write_operands(x, y, width, height)
      write_operator(APPEND_RECT)
    end

    def curve_to(x1 : Number, y1 : Number, x2 : Number, y2 : Number, x3 : Number, y3 : Number) : Nil
      raise_if_in_text_mode("curveTo is not allowed within a text block.")
      write_operands(x1, y1, x2, y2, x3, y3)
      write_operator(CURVE_TO)
    end

    def curve_to1(x1 : Number, y1 : Number, x3 : Number, y3 : Number) : Nil
      raise_if_in_text_mode("curveTo1 is not allowed within a text block.")
      write_operands(x1, y1, x3, y3)
      write_operator(CURVE_TO_REPLICATE_FINAL_POINT)
    end

    def curve_to2(x2 : Number, y2 : Number, x3 : Number, y3 : Number) : Nil
      raise_if_in_text_mode("curveTo2 is not allowed within a text block.")
      write_operands(x2, y2, x3, y3)
      write_operator(CURVE_TO_REPLICATE_INITIAL_POINT)
    end

    def move_to(x : Number, y : Number) : Nil
      raise_if_in_text_mode("moveTo is not allowed within a text block.")
      write_operands(x, y)
      write_operator(MOVE_TO)
    end

    def line_to(x : Number, y : Number) : Nil
      raise_if_in_text_mode("lineTo is not allowed within a text block.")
      write_operands(x, y)
      write_operator(LINE_TO)
    end

    def shading_fill(shading : Graphics::Shading::PDShading) : Nil
      raise_if_in_text_mode("shadingFill is not allowed within a text block.")
      resource_name = add_shading_to_resources(shading)
      @buffer << '/' << resource_name << ' ' << SHADING_FILL << '\n'
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

    def save_graphics_state : Nil
      raise_if_in_text_mode("saveGraphicsState is not allowed within a text block.")
      write_operator(SAVE)
    end

    def restore_graphics_state : Nil
      raise_if_in_text_mode("restoreGraphicsState is not allowed within a text block.")
      write_operator(RESTORE)
    end

    def draw_form(form : Graphics::Form::PDFormXObject) : Nil
      raise_if_in_text_mode("drawForm is not allowed within a text block.")
      resource_name = add_form_to_xobject_resources(form)
      @buffer << '/' << resource_name << ' ' << DRAW_OBJECT << '\n'
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

    # Appends raw command bytes/text directly (Java PDPageContentStream#appendRawCommands).
    def append_raw_commands(commands : String) : Nil
      @buffer.write(commands.to_slice)
    end

    def append_raw_commands(commands : Bytes) : Nil
      @buffer.write(commands)
    end

    def append_raw_commands(data : Number) : Nil
      append_raw_commands(data.to_s)
    end

    private def get_current_font : Font::PDFont?
      @current_font
    end

    private def encode_text(text : String, font : Font::PDFont) : Bytes
      # complex text layout: apply GSUB rules for Type0 fonts
      if font.is_a?(Font::PDType0Font)
        type0 = font.as(Font::PDType0Font)

        if worker = @gsub_workers[type0]?
          glyph_ids = Set(Int32).new
          encoded = encode_for_gsub(worker, glyph_ids, type0, text)

          if type0.will_be_subset?
            type0.add_glyphs_to_subset(glyph_ids)
          end
          return encoded
        end
      end
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

    # Port of Java PDAbstractContentStream.encodeForGsub — tokenize the text on
    # spaces and apply GSUB rules per word, encoding the resulting glyph IDs.
    private def encode_for_gsub(worker : Fontbox::TTF::Gsub::GsubWorker,
                                glyph_ids : Set(Int32),
                                font : Font::PDType0Font,
                                text : String) : Bytes
      output = ::IO::Memory.new
      # Java StringUtil.tokenizeOnSpace keeps whitespace runs as separate tokens.
      tokens = text.split(/(?<=\s)|(?=\s)/).reject(&.empty?)
      tokens.each do |token|
        if token.each_char.all?(&.whitespace?)
          output.write(font.encode(token))
        else
          glyph_ids.concat(apply_gsub_rules(worker, output, font, token))
        end
      end
      output.to_slice
    end

    # Port of Java PDAbstractContentStream.applyGSUBRules — map the word's code
    # points to glyph IDs, apply GSUB transforms, and encode the result.
    private def apply_gsub_rules(worker : Fontbox::TTF::Gsub::GsubWorker,
                                 output : ::IO::Memory,
                                 font : Font::PDType0Font,
                                 word : String) : Set(Int32)
      original_glyph_ids = [] of Int32
      if cmap_lookup = font.cmap_lookup
        word.each_char do |char|
          glyph_id = cmap_lookup.glyph_id(char.ord)
          if glyph_id <= 0
            raise IllegalStateError.new(
              "could not find the glyphId for the character: #{char}, codePoint: #{char.ord} (0x#{char.ord.to_s(16).upcase})")
          end
          original_glyph_ids << glyph_id
        end
      end

      glyph_ids_after_gsub = worker.apply_transforms(original_glyph_ids)

      glyph_ids_after_gsub.each do |glyph_id|
        output.write(font.encode_glyph_id(glyph_id))
      end
      Set.new(glyph_ids_after_gsub)
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

    private def add_form_to_xobject_resources(form : Graphics::Form::PDFormXObject) : String
      xobjects = ensure_resource_subdictionary("XObject")
      resource_name = "Fm#{xobjects.size + 1}"
      xobjects[Cos::Name.new(resource_name)] = form.cos_object
      resource_name
    end

    private def add_shading_to_resources(shading : Graphics::Shading::PDShading) : String
      shadings = ensure_resource_subdictionary("Shading")
      resource_name = "sh#{shadings.size + 1}"
      shadings[Cos::Name.new(resource_name)] = shading.cos_object
      resource_name
    end

    private def add_property_list_to_resources(property_list : DocumentInterchange::MarkedContent::PDPropertyList) : String
      properties = ensure_resource_subdictionary("Properties")
      prefix = property_list.is_a?(Graphics::OptionalContent::PDOptionalContentGroup) ? "oc" : "Prop"
      resource_name = "#{prefix}#{properties.size + 1}"
      properties[Cos::Name.new(resource_name)] = property_list.cos_object
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
