# PDF font base class
# Corresponds to PDFont in Apache PDFBox
require "../../cos.cr"
require "./font_descriptor"
require "./cmap_manager"
require "../../../fontbox/cmap"
require "../../../fontbox/util/bounding_box"

abstract class Pdfbox::Pdmodel::Font::PDFont
  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  # Default font matrix for Type 1 fonts: 0.001, 0, 0, 0.001, 0, 0
  DEFAULT_FONT_MATRIX = Matrix.new(0.001_f32, 0.0_f32, 0.0_f32, 0.001_f32, 0.0_f32, 0.0_f32)

  @afm_standard14 : FontMetrics?
  @widths : Array(Float32)?
  @to_unicode_cmap : Fontbox::CMap::CMap?
  protected getter to_unicode_cmap

  # Placeholder types for missing dependencies
  class Matrix
    getter a : Float32
    getter b : Float32
    getter c : Float32
    getter d : Float32
    getter e : Float32
    getter f : Float32

    def initialize(a : Float32 = 0.0_f32, b : Float32 = 0.0_f32, c : Float32 = 0.0_f32,
                   d : Float32 = 0.0_f32, e : Float32 = 0.0_f32, f : Float32 = 0.0_f32)
      @a = a
      @b = b
      @c = c
      @d = d
      @e = e
      @f = f
    end

    # Default font matrix for Type 1 fonts: 0.001, 0, 0, 0.001, 0, 0
    def self.default_font_matrix : Matrix
      new(0.001_f32, 0.0_f32, 0.0_f32, 0.001_f32, 0.0_f32, 0.0_f32)
    end

    def transform(vector : Vector) : Vector
      Vector.new(
        @a * vector.x + @c * vector.y + @e,
        @b * vector.x + @d * vector.y + @f
      )
    end

    # Transform a point (x, y) using this matrix
    def transform_point(x : Float64, y : Float64) : Vector
      Vector.new(
        (@a * x + @c * y + @e).to_f32,
        (@b * x + @d * y + @f).to_f32
      )
    end

    # Get the X scale factor
    def scale_x : Float32
      @a
    end
  end

  class Vector
    getter x : Float32
    getter y : Float32

    def initialize(@x : Float32 = 0.0_f32, @y : Float32 = 0.0_f32)
    end
  end

  class BoundingBox < Fontbox::Util::BoundingBox
    def initialize
      super()
    end

    def initialize(lower_left_x : Float32, lower_left_y : Float32, upper_right_x : Float32, upper_right_y : Float32)
      super(lower_left_x, lower_left_y, upper_right_x, upper_right_y)
    end
  end

  class FontMetrics
    @widths : Hash(String, Float32)
    @average_character_width : Float32

    def initialize(@widths : Hash(String, Float32), @average_character_width : Float32)
    end

    def character_width(name : String) : Float32
      @widths[name]? || 0.0_f32
    end

    def average_character_width : Float32
      @average_character_width
    end
  end

  module PDType1FontEmbedder
    def self.build_font_descriptor(afm : FontMetrics) : PDFontDescriptor
      raise "Not implemented"
    end
  end

  alias PDFontDescriptor = ::Pdfbox::Pdmodel::Font::PDFontDescriptor

  @dict : Pdfbox::Cos::Dictionary
  @code_to_width_map : Hash(Int32, Float32)
  @font_width_of_space : Float32 = -1.0_f32

  # Constructor for embedding.
  protected def initialize
    @dict = Pdfbox::Cos::Dictionary.new
    @dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    @code_to_width_map = Hash(Int32, Float32).new
    @afm_standard14 = nil
    @widths = nil
    @to_unicode_cmap = nil
  end

  # Constructor for Standard 14.
  protected def initialize(base_font : Standard14Fonts::FontName)
    @dict = Pdfbox::Cos::Dictionary.new
    @dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    @code_to_width_map = Hash(Int32, Float32).new
    @afm_standard14 = Standard14Fonts.get_afm(base_font.to_s)
    if @afm_standard14.nil?
      # This should not happen for valid Standard 14 fonts
      Log.warn { "No AFM found for Standard 14 font: #{base_font}" }
    end
    @widths = nil
    @to_unicode_cmap = nil
  end

  # Constructor.
  protected def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    @dict = font_dictionary
    @code_to_width_map = Hash(Int32, Float32).new
    @afm_standard14 = nil
    @widths = nil
    @to_unicode_cmap = load_unicode_cmap
  end

  # Loads the ToUnicode CMap from the font dictionary.
  private def load_unicode_cmap : Fontbox::CMap::CMap?
    to_unicode = @dict[Pdfbox::Cos::Name.new("ToUnicode")]
    return if to_unicode.nil?

    cmap = read_cmap(to_unicode)
    return if cmap.nil?

    if !cmap.has_unicode_mappings?
      name = self.name
      Log.warn { "Invalid ToUnicode CMap in font #{name}" }

      cmap_name = cmap.name || ""
      ordering = cmap.ordering || ""
      encoding = @dict[Pdfbox::Cos::Name.new("Encoding")]?

      if cmap_name.includes?("Identity") || ordering.includes?("Identity") ||
         (encoding && (encoding == Pdfbox::Cos::Name::IDENTITY_H || encoding == Pdfbox::Cos::Name::IDENTITY_V))
        encoding_dict = @dict[Pdfbox::Cos::Name.new("Encoding")]?
        if encoding_dict.nil? || !encoding_dict.is_a?(Pdfbox::Cos::Dictionary) || !encoding_dict.has_key?(Pdfbox::Cos::Name.new("Differences"))
          cmap = CMapManager.get_predefined_cmap("Identity-H")
          Log.warn { "Using predefined Identity CMap instead for font #{name}" }
        end
      end
    end

    cmap
  end

  # Reads a CMap given a COS Stream or Name. May return nil if a predefined CMap does not exist.
  #
  # @param base COSName or COSStream
  # @return the CMap if present
  # @raises ::IO::Error if the CMap could not be read
  protected def read_cmap(base : Pdfbox::Cos::Base) : Fontbox::CMap::CMap?
    if base.is_a?(Pdfbox::Cos::Object)
      resolved = base.object
      return unless resolved
      return read_cmap(resolved)
    end

    if base.is_a?(Pdfbox::Cos::Name)
      # predefined CMap
      name = base.value
      CMapManager.get_predefined_cmap(name)
    elsif base.is_a?(Pdfbox::Cos::Stream)
      random_access = Pdfbox::IO::RandomAccessReadBuffer.create_buffer_from_stream(base.create_input_stream)
      CMapManager.parse_cmap(random_access)
    else
      raise ::IO::Error.new("Expected Name or Stream")
    end
  end

  # Get the underlying COS dictionary
  def cos_object : Pdfbox::Cos::Dictionary
    @dict
  end

  # Get font descriptor
  def font_descriptor : PDFontDescriptor?
    desc_dict = @dict.get_dictionary(Pdfbox::Cos::Name::FONT_DESC)
    if desc_dict
      PDFontDescriptor.new(desc_dict)
    end
  end

  # Returns the AFM if this is a Standard 14 font.
  protected def get_standard14_afm : FontMetrics?
    @afm_standard14
  end

  # The widths of the characters. This will be nil for the standard 14 fonts.
  protected def widths : Array(Float32)
    if @widths.nil?
      array = @dict[Pdfbox::Cos::Name::WIDTHS]?
      if array.is_a?(Pdfbox::Cos::Array)
        @widths = array.items.map do |item|
          case item
          when Pdfbox::Cos::Integer
            item.value.to_f32
          when Pdfbox::Cos::Float
            item.value.to_f32
          else
            0.0_f32
          end
        end
      else
        @widths = [] of Float32
      end
    end
    @widths.as(Array(Float32))
  end

  # Returns the Unicode string for the given character code.
  def to_unicode(code : Int32) : String?
    # if the font dictionary contains a ToUnicode CMap, use that CMap
    cmap = @to_unicode_cmap
    if cmap
      name = cmap.name
      if name && name.starts_with?("Identity-") &&
         (@dict[Pdfbox::Cos::Name.new("ToUnicode")].is_a?(Pdfbox::Cos::Name) || !cmap.has_unicode_mappings?)
        # handle the undocumented case of using Identity-H/V as a ToUnicode CMap, this
        # isn't actually valid as the Identity-x CMaps are code->CID maps, not
        # code->Unicode maps. See sample_fonts_solidconvertor.pdf for an example.
        # PDFBOX-3123: do this only if the /ToUnicode entry is a name
        # PDFBOX-4322: identity streams are OK too
        return identity_char_from_code(code)
      else
        if code < 256 && !composite_font?
          encoding = @dict[Pdfbox::Cos::Name::ENCODING]
          if encoding.is_a?(Pdfbox::Cos::Name) && !encoding.to_s.starts_with?("Identity")
            # due to the conversion to an int it is no longer possible to determine
            # if the code is based on a one or two byte value. We should consider to
            # refactor that part of the code.
            # However, simple fonts with a predefined encoding are using one byte codes so that
            # we can limit the CMap mappings to one byte codes by passing the origin length
            return cmap.to_unicode(code, 1)
          end
        end
        return cmap.to_unicode(code)
      end
    end

    # if no value has been produced, there is no way to obtain Unicode for the character.
    # this behaviour can be overridden in subclasses, but this method *must* return nil here
    nil
  end

  private def identity_char_from_code(code : Int32) : String
    (code & 0xFFFF).chr.to_s
  rescue ArgumentError
    "\uFFFD"
  end

  # Returns the Unicode string for the given character code using a custom glyph list.
  def to_unicode(code : Int32, custom_glyph_list : GlyphList) : String?
    # Default implementation delegates to to_unicode(code)
    to_unicode(code)
  end

  # Abstract methods from PDFontLike interface and PDFont

  # Returns the name of this font, either the PostScript "BaseName" or the Type 3 "Name".
  abstract def name : String

  # Returns the font matrix, which represents the transformation from glyph space to text space.
  abstract def font_matrix : Matrix

  # Returns the font's bounding box.
  abstract def bounding_box : BoundingBox

  # Returns the position vector (v), in text space, for the given character.
  abstract def position_vector(code : Int32) : Vector

  # Returns the advance width of the given character, in glyph space.
  abstract def width(code : Int32) : Float32

  # Returns the displacement vector (w0, w1) in text space.
  # For horizontal text only the x component is used, for vertical text only the y component.
  def displacement(code : Int32) : Vector
    Vector.new(width(code) / 1000.0_f32, 0.0_f32)
  end

  # Returns true if the Font dictionary specifies an explicit width for the given glyph.
  abstract def has_explicit_width?(code : Int32) : Bool

  # Returns the width of a glyph in the embedded font file.
  abstract def width_from_font(code : Int32) : Float32

  # Returns true if the font file is embedded in the PDF.
  abstract def embedded? : Bool

  # Returns true if the embedded font file is damaged.
  abstract def damaged? : Bool

  # This will get the average font width for all characters.
  abstract def average_font_width : Float32

  # Abstract methods from PDFont abstract class

  # Returns the glyph width from the AFM if this is a Standard 14 font.
  protected abstract def get_standard14_width(code : Int32) : Float32

  # Encodes the given Unicode code point for use in a PDF content stream.
  # Encode a single Unicode code point to bytes.
  #
  # @param unicode Unicode code point.
  # @return Array of PDF content stream bytes.
  abstract def encode(unicode : Int32) : Bytes

  # Reads a character code from a content stream.
  abstract def read_code(input : ::IO) : Int32

  # Returns true if this font is vertical.
  abstract def vertical? : Bool

  # Adds a code point to the subset.
  abstract def add_to_subset(code_point : Int32) : Nil

  # Creates a subset font.
  abstract def subset : Nil

  # Returns true if this font will be subset.
  abstract def will_be_subset? : Bool

  # Returns true if this is a composite font (Type 0).
  def composite_font? : Bool
    false
  end

  # Returns true if this is a Standard 14 font.
  def standard14? : Bool
    false
  end

  # Encodes the given Unicode string for use in a PDF content stream.
  # Content streams use a multi-byte encoding with 1 to 4 bytes.
  #
  # This method is called when embedding text in PDFs and when filling in fields.
  #
  # @param text Unicode string.
  # @return Array of PDF content stream bytes.
  def encode(text : String) : Bytes
    io = ::IO::Memory.new(Math.max(32, text.bytesize))

    offset = 0
    while offset < text.size
      code_point = text.char_at(offset).ord

      # multi-byte encoding with 1 to 4 bytes
      bytes = encode(code_point)
      io.write(bytes)

      offset += 1
    end

    io.to_slice
  end

  # Returns the width of the given Unicode string.
  #
  # @param text The text to get the width of.
  # @return The width of the string in 1/1000 units of text space.
  def get_string_width(text : String) : Float32
    bytes = encode(text)
    io = ::IO::Memory.new(bytes)

    width = 0.0_f32
    while io.pos < bytes.size
      code = read_code(io)
      width += width(code)
    end

    width
  end

  # Returns the width of the space character.
  #
  # @return the width of the space character
  def space_width : Float32
    if @font_width_of_space == -1.0_f32
      begin
        if !@to_unicode_cmap.nil? && @dict.has_key?(Pdfbox::Cos::Name.new("ToUnicode"))
          space_mapping = @to_unicode_cmap.as(Fontbox::CMap::CMap).space_mapping
          if space_mapping > -1
            @font_width_of_space = width(space_mapping)
          end
        else
          begin
            # PDFBOX-5920: try with encoding, which gets the correct code
            @font_width_of_space = get_string_width(" ")
          rescue ex : ArgumentError | NotImplementedError
            # Happens if space is not available in the font
            # or if encoding isn't implemented
            Log.debug { ex.message }
          end
          if @font_width_of_space <= 0
            @font_width_of_space = width(32)
          end
        end

        # try to get it from the font itself
        if @font_width_of_space <= 0
          @font_width_of_space = width_from_font(32)
          # use the average font width as fall back
          if @font_width_of_space <= 0
            @font_width_of_space = average_font_width
          end
        end
      rescue e : Exception
        Log.error { "Can't determine the width of the space character for font #{name}, assuming 250" }
        Log.error { e }
        @font_width_of_space = 250.0_f32
      end
      Log.debug { "Space width for font #{name} is #{@font_width_of_space}" }
    end
    @font_width_of_space
  end
end
