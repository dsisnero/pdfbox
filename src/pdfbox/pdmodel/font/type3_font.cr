# Type 3 font implementation
# Corresponds to PDType3Font in Apache PDFBox
require "./simple_font"
require "./type3_char_proc"

module Pdfbox::Pdmodel::Font
  # Placeholder types until pdmodel resources/cache are ported.
  class PDResources
    def initialize(dict : Pdfbox::Cos::Dictionary, resource_cache : ResourceCache? = nil)
    end
  end

  class ResourceCache
  end

  class PDType3Font < PDSimpleFont
    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    @resources : PDResources?
    @char_procs : Pdfbox::Cos::Dictionary?
    @font_matrix : Matrix?
    @font_bbox : BoundingBox?
    @resource_cache : ResourceCache?

    # Constructor.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
      initialize(font_dictionary, nil)
    end

    # Constructor with resource cache.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, resource_cache : ResourceCache?)
      super(font_dictionary)
      @resource_cache = resource_cache
      read_encoding
    end

    # Returns the name of this font (from Name entry, not BaseFont).
    def name : String
      @dict.get_name_as_string(Pdfbox::Cos::Name::NAME) || ""
    end

    # Override read_encoding from PDSimpleFont.
    protected def read_encoding : Nil
      encoding_base = @dict[Pdfbox::Cos::Name::ENCODING]
      if encoding_base.is_a?(Pdfbox::Cos::Name)
        @encoding = Encoding.get_instance(encoding_base)
        if @encoding.nil?
          Log.warn { "Unknown encoding: #{encoding_base}" }
        end
      elsif encoding_base.is_a?(Pdfbox::Cos::Dictionary)
        @encoding = DictionaryEncoding.new(encoding_base, true, nil)
      end
      @glyph_list = GlyphList.adobe_glyph_list
    end

    # Type 3 fonts do not have a built-in encoding.
    protected def read_encoding_from_font : Encoding
      raise "not supported for Type 3 fonts"
    end

    # Type 3 fonts are never symbolic.
    protected def font_symbolic? : Bool?
      false
    end

    # Type 3 fonts do not use vector paths.
    def get_path(name : String)
      raise "not supported for Type 3 fonts"
    end

    # Returns true if the font contains the glyph for the given name.
    def has_glyph?(name : String) : Bool
      cp = char_procs
      !cp.nil? && !cp.get_stream(Pdfbox::Cos::Name.new(name)).nil?
    end

    # Type 3 fonts do not use FontBox fonts.
    def font_box_font
      raise "not supported for Type 3 fonts"
    end

    # Returns the position vector for the given character code.
    def position_vector(code : Int32) : Vector
      width_value = width(code)
      matrix = font_matrix
      Vector.new(
        matrix.a * width_value + matrix.c * 0.0_f32 + matrix.e,
        matrix.b * width_value + matrix.d * 0.0_f32 + matrix.f
      )
    end

    # Returns the width of the given character code.
    def width(code : Int32) : Float32
      first_char = @dict.get_int(Pdfbox::Cos::Name::FIRST_CHAR, -1).to_i32
      last_char = @dict.get_int(Pdfbox::Cos::Name::LAST_CHAR, -1).to_i32
      widths_array = widths

      if !widths_array.empty? && code >= first_char && code <= last_char
        index = code - first_char
        return 0.0_f32 if index >= widths_array.size
        width_value = widths_array[index]?
        return width_value || 0.0_f32
      end

      descriptor = font_descriptor
      return descriptor.missing_width if descriptor
      width_from_font(code)
    end

    # Returns the width from the embedded font file (char proc stream).
    def width_from_font(code : Int32) : Float32
      char_proc = get_char_proc(code)
      return 0.0_f32 if char_proc.nil?
      return 0.0_f32 if char_proc.cos_object.data.empty?
      char_proc.width
    end

    # Type 3 fonts are always embedded by design.
    def embedded? : Bool
      true
    end

    # Returns the height of the given character code.
    def height(code : Int32) : Float32
      descriptor = font_descriptor
      return 0.0_f32 unless descriptor

      bbox = descriptor.font_bounding_box
      if bbox
        value = bbox.height / 2.0_f32
        return value if value != 0.0_f32
      end

      value = descriptor.cap_height
      return value if value != 0.0_f32

      value = descriptor.ascent
      return value if value != 0.0_f32

      value = descriptor.x_height
      if value > 0.0_f32
        value -= descriptor.descent
        return value if value != 0.0_f32
      end

      0.0_f32
    end

    # Encoding not implemented for Type 3 fonts.
    protected def encode(unicode : Int32) : Bytes
      raise "Not implemented: Type3"
    end

    # Simple fonts use 1-byte codes.
    def read_code(input : ::IO) : Int32
      input.read_byte.try(&.to_i) || -1
    end

    # Returns the font matrix from the dictionary or default.
    def font_matrix : Matrix
      if @font_matrix.nil?
        matrix = @dict.get_array(Pdfbox::Cos::Name::FONT_MATRIX)
        if matrix && check_font_matrix_values(matrix)
          @font_matrix = create_matrix(matrix)
        else
          @font_matrix = PDFont::DEFAULT_FONT_MATRIX
        end
      end
      @font_matrix || PDFont::DEFAULT_FONT_MATRIX
    end

    private def check_font_matrix_values(matrix : Pdfbox::Cos::Array?) : Bool
      return false if matrix.nil? || matrix.size != 6
      matrix.items.all?(Pdfbox::Cos::Number)
    end

    private def create_matrix(matrix : Pdfbox::Cos::Array) : Matrix
      Matrix.new(
        to_float32(matrix[0]),
        to_float32(matrix[1]),
        to_float32(matrix[2]),
        to_float32(matrix[3]),
        to_float32(matrix[4]),
        to_float32(matrix[5])
      )
    end

    # Type 3 fonts have no font file to load.
    def damaged? : Bool
      false
    end

    # Type 3 fonts are never Standard 14.
    def standard14? : Bool
      false
    end

    def average_font_width : Float32
      0.0_f32
    end

    # Returns the optional resources of the type3 stream.
    def resources : PDResources?
      if @resources.nil?
        resources_dict = @dict.get_dictionary(Pdfbox::Cos::Name::RESOURCES)
        if resources_dict
          @resources = PDResources.new(resources_dict, @resource_cache)
        end
      end
      @resources
    end

    # Returns the font bounding box from its dictionary.
    def font_bounding_box : Common::PDRectangle?
      bbox = @dict.get_array(Pdfbox::Cos::Name::FONT_BBOX)
      bbox ? Common::PDRectangle.new(bbox) : nil
    end

    # Returns the bounding box for rendering.
    def bounding_box : BoundingBox
      @font_bbox ||= generate_bounding_box
    end

    private def generate_bounding_box : BoundingBox
      rect = font_bounding_box
      if rect.nil?
        Log.warn { "FontBBox missing, returning empty rectangle" }
        return BoundingBox.new
      end

      unless non_zero_bounding_box?(rect)
        char_proc_dict = char_procs
        if char_proc_dict
          char_proc_dict.entries.each_key do |name|
            char_proc_stream = char_proc_dict.get_stream(name)
            next unless char_proc_stream

            char_proc = PDType3CharProc.new(self, char_proc_stream)
            begin
              glyph_bbox = char_proc.glyph_bounding_box
              next unless glyph_bbox

              rect.lower_left_x = Math.min(rect.lower_left_x, glyph_bbox.lower_left_x)
              rect.lower_left_y = Math.min(rect.lower_left_y, glyph_bbox.lower_left_y)
              rect.upper_right_x = Math.max(rect.upper_right_x, glyph_bbox.upper_right_x)
              rect.upper_right_y = Math.max(rect.upper_right_y, glyph_bbox.upper_right_y)
            rescue ex : ::IO::Error
              Log.debug { "error getting the glyph bounding box - font bounding box will be used" }
            end
          end
        end
      end

      BoundingBox.new(
        rect.lower_left_x,
        rect.lower_left_y,
        rect.upper_right_x,
        rect.upper_right_y
      )
    end

    private def non_zero_bounding_box?(bbox : Common::PDRectangle) : Bool
      bbox.lower_left_x != 0.0_f32 ||
        bbox.lower_left_y != 0.0_f32 ||
        bbox.upper_right_x != 0.0_f32 ||
        bbox.upper_right_y != 0.0_f32
    end

    # Returns the dictionary containing all streams used to render glyphs.
    def char_procs : Pdfbox::Cos::Dictionary?
      @char_procs ||= @dict.get_dictionary(Pdfbox::Cos::Name::CHAR_PROCS)
    end

    # Returns the stream of the glyph for the given character code.
    def get_char_proc(code : Int32) : PDType3CharProc?
      cp = char_procs
      return nil unless cp
      name = encoding.get_name(code)
      stream = cp.get_stream(Pdfbox::Cos::Name.new(name))
      stream ? PDType3CharProc.new(self, stream) : nil
    end

    private def to_float32(value : Pdfbox::Cos::Base) : Float32
      case value
      when Pdfbox::Cos::Integer
        value.value.to_f32
      when Pdfbox::Cos::Float
        value.value.to_f32
      else
        0.0_f32
      end
    end
  end
end
