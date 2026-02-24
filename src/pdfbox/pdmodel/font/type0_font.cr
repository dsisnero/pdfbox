# Composite (Type 0) font implementation
# Corresponds to PDType0Font in Apache PDFBox
require "./encoding"
require "./encoding/glyph_list"
require "./simple_font"
require "./vector_font"
require "../../../fontbox/ttf/true_type_font"
require "../../../fontbox/ttf/ttf_tables"
require "../../../fontbox/ttf/ttf_parser"
require "./cmap_manager"

class Pdfbox::Pdmodel::Font::PDType0Font < Pdfbox::Pdmodel::Font::PDFont
  include PDVectorFont

  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  # Placeholder types for missing dependencies
  class PDCIDFont
    class PDCIDSystemInfo
      getter registry : String
      getter ordering : String
      getter supplement : Int32

      def initialize(@registry : String, @ordering : String, @supplement : Int32)
      end
    end

    def initialize(font_dictionary : Cos::Dictionary, parent_font : PDFont)
    end

    def cid_system_info : PDCIDSystemInfo?
      nil
    end

    def font_descriptor : PDFontDescriptor?
      nil
    end

    def cid_font_type2? : Bool
      false
    end

    def true_type_font
      nil
    end

    def font_matrix : Matrix
      Matrix.new
    end

    def get_height(code : Int32) : Float32
      0.0_f32
    end

    def encode(unicode : Int32) : Bytes
      Bytes.new(1, 0_u8)
    end

    def has_explicit_width(code : Int32) : Bool
      false
    end

    def average_font_width : Float32
      0.0_f32
    end

    def get_position_vector(code : Int32) : Vector
      Vector.new
    end

    def get_vertical_displacement_vector_y(code : Int32) : Float32
      0.0_f32
    end

    def get_width(code : Int32) : Float32
      0.0_f32
    end

    def get_width_from_font(code : Int32) : Float32
      0.0_f32
    end

    def embedded? : Bool
      false
    end

    def damaged? : Bool
      false
    end

    def code_to_cid(code : Int32) : Int32
      code
    end

    def code_to_gid(code : Int32) : Int32
      code
    end

    def bounding_box : BoundingBox
      BoundingBox.new
    end

    def get_path(code : Int32)
      nil
    end

    def get_normalized_path(code : Int32)
      nil
    end

    def has_glyph(code : Int32) : Bool
      false
    end

    def encode_glyph_id(glyph_id : Int32) : Bytes
      Bytes.new(1, 0_u8)
    end
  end

  class GsubData
    NO_DATA_FOUND = new
  end

  class CmapLookup
  end

  class PDCIDFontType2Embedder
  end

  # Instance variables
  @descendant_font : PDCIDFont
  @no_unicode = Set(Int32).new
  @gsub_data : GsubData
  @cmap_lookup : CmapLookup?
  @c_map : Fontbox::CMap::CMap?
  @c_map_ucs2 : Fontbox::CMap::CMap?
  @is_cmap_predefined : Bool = false
  @is_descendant_cjk : Bool = false
  @embedder : PDCIDFontType2Embedder?
  @ttf : Fontbox::TTF::TrueTypeFont?

  # Constructor for reading a Type0 font from a PDF file.
  def initialize(font_dictionary : Cos::Dictionary)
    super(font_dictionary)

    @gsub_data = GsubData::NO_DATA_FOUND
    @cmap_lookup = nil

    descendant_fonts = @dict.get_array(Cos::Name::DESCENDANT_FONTS)
    if descendant_fonts.nil?
      raise IO::Error.new("Missing descendant font array")
    end
    if descendant_fonts.empty?
      raise IO::Error.new("Descendant font array is empty")
    end
    descendant_font_dict_base = descendant_fonts[0]?
    if descendant_font_dict_base.nil? || !descendant_font_dict_base.is_a?(Cos::Dictionary)
      raise IO::Error.new("Missing descendant font dictionary")
    end
    descendant_font_dict = descendant_font_dict_base.as(Cos::Dictionary)
    type = descendant_font_dict[Cos::Name::TYPE]?
    if type.nil? || type != Cos::Name::FONT
      raise IO::Error.new("Missing or wrong type in descendant font dictionary")
    end
    # TODO: Implement PDFontFactory.create_descendant_font
    @descendant_font = PDCIDFont.new(descendant_font_dict, self)
    read_encoding
    fetch_cmap_ucs2
  end

  # Returns the PostScript name of the font.
  def name : String
    @dict.get_name_as_string(Cos::Name::BASE_FONT) || ""
  end

  # Reads the encoding from the font dictionary.
  private def read_encoding : Nil
    encoding = @dict.get(Cos::Name::ENCODING)
    if encoding.is_a?(Cos::Name)
      # predefined CMap
      encoding_name = encoding.to_s
      @c_map = CMapManager.get_predefined_cmap(encoding_name)
      @is_cmap_predefined = true
    elsif !encoding.nil?
      c_map = read_cmap(encoding)
      if c_map.nil?
        raise ::IO::Error.new("Missing required CMap")
      elsif !c_map.has_cid_mappings?
        Log.warn { "Invalid Encoding CMap in font #{name}" }
      end
      @c_map = c_map
    end

    # check if the descendant font is CJK
        ros = @descendant_font.cid_system_info
    if ros
      ordering = ros.ordering
      @is_descendant_cjk = ros.registry == "Adobe" &&
                           (ordering == "GB1" || ordering == "CNS1" ||
                            ordering == "Japan1" || ordering == "Korea1")
    end
  end

  # Fetches the UCS-2 CMap for Unicode mapping.
  private def fetch_cmap_ucs2 : Nil
    # if the font is composite and uses a predefined cmap (excluding Identity-H/V)
    # or whose descendant CIDFont uses the Adobe-GB1, Adobe-CNS1, Adobe-Japan1, or
    # Adobe-Korea1 character collection:
    name = @dict.get(Cos::Name::ENCODING).as?(Cos::Name)
    if (@is_cmap_predefined && !(name == Cos::Name::IDENTITY_H || name == Cos::Name::IDENTITY_V)) ||
       @is_descendant_cjk
      # a) Map the character code to a CID using the font's CMap
      # b) Obtain the ROS from the font's CIDSystemInfo
      # c) Construct a second CMap name by concatenating the ROS in the format "R-O-UCS2"
      # d) Obtain the CMap with the constructed name
      # e) Map the CID according to the CMap from step d), producing a Unicode value

      # todo: not sure how to interpret the PDF spec here, do we always override? or only when Identity-H/V?
      str_name = nil
      if @is_descendant_cjk
        ros = @descendant_font.cid_system_info
        if ros
          str_name = "#{ros.registry}-#{ros.ordering}-#{ros.supplement}"
        end
      elsif name
        str_name = name.to_s
      end

      # try to find the corresponding Unicode (UC2) CMap
      if str_name
        begin
          prd_cmap = CMapManager.get_predefined_cmap(str_name)
          ucs2_name = "#{prd_cmap.registry}-#{prd_cmap.ordering}-UCS2"
          @c_map_ucs2 = CMapManager.get_predefined_cmap(ucs2_name)
        rescue ex : ::IO::Error
          Log.warn { "Could not get #{str_name} UC2 map for font #{name}" }
        end
      end
    end
  end

  # PDFont abstract method implementations

  protected def encode(unicode : Int32) : Bytes
    @descendant_font.encode(unicode)
  end

  def read_code(input : IO) : Int32
    if @c_map.nil?
      raise ::IO::Error.new("required cmap is null")
    end
    @c_map.read_code(input)
  end

  def vertical? : Bool
    !@c_map.nil? && @c_map.wmode == 1
  end

  def font_matrix : Matrix
    @descendant_font.font_matrix
  end

  def bounding_box : Util::BoundingBox
    @descendant_font.bounding_box
  end

  def position_vector(code : Int32) : Vector
    # units are always 1/1000 text space, font matrix is not used, see FOP-2252
    @descendant_font.get_position_vector(code) # TODO: scale(-1 / 1000f)
  end

  def width(code : Int32) : Float32
    @descendant_font.get_width(code)
  end

  def height(code : Int32) : Float32
    @descendant_font.get_height(code)
  end

  def to_unicode(code : Int32) : String?
    # try to use a ToUnicode CMap
    unicode = super(code)
    return unicode if unicode

    # Use identity mapping if the given ToUnicode CMap doesn't provide any valid mapping
    # a predefined map shall only be used if there isn't any ToUnicode CMap
    # PDFBOX-6022: not when there's a predefined cmap
    if to_unicode_cmap && !is_cmap_predefined
      return String.new(Bytes[code].map(&.chr))
    end

    if (is_cmap_predefined || is_descendant_cjk) && (ucs2 = cmap_ucs2)
      # if the font is composite and uses a predefined cmap (excluding Identity-H/V) then
      # or if its descendant font uses Adobe-GB1/CNS1/Japan1/Korea1

      # a) Map the character code to a character identifier (CID) according to the font's CMap
      cid = code_to_cid(code)

      # e) Map the CID according to the CMap from step d), producing a Unicode value
      return ucs2.to_unicode(cid)
    end

    # PDFBOX-5324: try to get unicode from font cmap
    # TODO: Implement PDCIDFontType2 check and font cmap lookup
    # if descendant_font.is_a?(PDCIDFontType2)
    #   font = descendant_font.get_true_type_font
    #   if font
    #     begin
    #       cmap = font.get_unicode_cmap_lookup(false)
    #       if cmap
    #         gid = if descendant_font.embedded?
    #                 descendant_font.code_to_gid(code)
    #               else
    #                 descendant_font.code_to_cid(code)
    #               end
    #         codes = cmap.get_char_codes(gid)
    #         if codes && !codes.empty?
    #           return codes[0].chr
    #         end
    #       end
    #     rescue ex : ::IO::Error
    #       Log.warn { "get unicode from font cmap fail: #{ex}" }
    #     end
    #   end
    # end

    if Log.warn? && !@no_unicode.includes?(code)
      # if no value has been produced, there is no way to obtain Unicode for the character.
      cid_str = "CID+" + code_to_cid(code).to_s
      Log.warn { "No Unicode mapping for #{cid_str} (#{code}) in font #{name}" }
      # we keep track of which warnings have been issued, so we don't log multiple times
      @no_unicode.add(code)
    end
    nil
  end

  # PDVectorFont interface implementation

  def get_path(code : Int32)
    @descendant_font.get_path(code)
  end

  def get_normalized_path(code : Int32)
    @descendant_font.get_normalized_path(code)
  end

  def has_glyph(code : Int32) : Bool
    @descendant_font.has_glyph(code)
  end

  # Helper methods

  def descendant_font : PDCIDFont
    @descendant_font
  end

  def embedded? : Bool
    @descendant_font.embedded?
  end

  def damaged? : Bool
    @descendant_font.damaged?
  end

  def average_font_width : Float32
    @descendant_font.average_font_width
  end

  def has_explicit_width?(code : Int32) : Bool
    @descendant_font.has_explicit_width(code)
  end

  def width_from_font(code : Int32) : Float32
    @descendant_font.get_width_from_font(code)
  end

  protected def get_standard14_width(code : Int32) : Float32
    raise "not supported"
  end

  def add_to_subset(code_point : Int32) : Nil
    raise "Subsetting not yet implemented"
  end

  def subset : Nil
    raise "Subsetting not yet implemented"
  end

  def will_be_subset? : Bool
    false
  end

  # Public methods from Java PDType0Font

  def code_to_cid(code : Int32) : Int32
    @descendant_font.code_to_cid(code)
  end

  def code_to_gid(code : Int32) : Int32
    @descendant_font.code_to_gid(code)
  end

  def cmap : Fontbox::CMap::CMap?
    @c_map
  end

  def cmap_ucs2 : Fontbox::CMap::CMap?
    @c_map_ucs2
  end

  # Returns true if the font uses a predefined CMap (not Identity-H/V).
  def is_cmap_predefined : Bool
    @is_cmap_predefined
  end

  # Returns true if the descendant font uses CJK character collection.
  def is_descendant_cjk : Bool
    @is_descendant_cjk
  end

  def gsub_data : GsubData
    @gsub_data
  end

  def cmap_lookup : CmapLookup?
    @cmap_lookup
  end

  def encode_glyph_id(glyph_id : Int32) : Bytes
    @descendant_font.encode_glyph_id(glyph_id)
  end
end
