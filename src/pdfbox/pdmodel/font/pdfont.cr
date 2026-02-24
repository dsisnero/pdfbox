# PDF font base class
# Corresponds to PDFont in Apache PDFBox
require "../../cos"
require "./font_descriptor"

abstract class Pdfbox::Pdmodel::Font::PDFont
  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  # Default font matrix for Type 1 fonts: 0.001, 0, 0, 0.001, 0, 0
  DEFAULT_FONT_MATRIX = Matrix.new(0.001_f32, 0.0_f32, 0.0_f32, 0.001_f32, 0.0_f32, 0.0_f32)

  @afm_standard14 : FontMetrics?
  @widths : Array(Float32)?
  @to_unicode_cmap : CMap?

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
  end

  class Vector
    def initialize(*args); end
  end

  class BoundingBox
    def initialize(*args); end
  end

  class CMap
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
    @to_unicode_cmap = nil
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
    else
      nil
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
        # TODO: Implement proper conversion from COS numbers to Float32
        @widths = [] of Float32
      else
        @widths = [] of Float32
      end
    end
    @widths.not_nil!
  end

  # Returns the Unicode string for the given character code.
  def to_unicode(code : Int32) : String?
    # TODO: Implement ToUnicode CMap lookup
    nil
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
  protected abstract def encode(unicode : Int32) : Bytes

  # Reads a character code from a content stream.
  abstract def read_code(input : IO) : Int32

  # Returns true if this font is vertical.
  abstract def vertical? : Bool

  # Adds a code point to the subset.
  abstract def add_to_subset(code_point : Int32) : Nil

  # Creates a subset font.
  abstract def subset : Nil

  # Returns true if this font will be subset.
  abstract def will_be_subset? : Bool

  # Returns true if this is a Standard 14 font.
  def standard14? : Bool
    false
  end
end
