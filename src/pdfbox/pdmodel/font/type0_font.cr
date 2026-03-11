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
require "./cid_font"
require "./cid_font_type0"
require "./cid_font_type2"
require "./font_factory"

class Pdfbox::Pdmodel::Font::PDType0Font < Pdfbox::Pdmodel::Font::PDFont
  include PDVectorFont

  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  class GsubData
    NO_DATA_FOUND = new
  end

  class CmapLookup
  end

  class PDCIDFontType2Embedder
  end

  # Instance variables
  @descendant_font : PDCIDFont?
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
  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary)

    @gsub_data = GsubData::NO_DATA_FOUND
    @cmap_lookup = nil

    descendant_fonts = @dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS)
    if descendant_fonts.nil?
      raise ::IO::Error.new("Missing descendant font array")
    end
    if descendant_fonts.size == 0
      raise ::IO::Error.new("Descendant font array is empty")
    end
    descendant_font_dict_base = descendant_fonts[0]?
    if descendant_font_dict_base.nil? || !descendant_font_dict_base.is_a?(Pdfbox::Cos::Dictionary)
      raise ::IO::Error.new("Missing descendant font dictionary")
    end
    descendant_font_dict = descendant_font_dict_base.as(Pdfbox::Cos::Dictionary)
    type = descendant_font_dict[Pdfbox::Cos::Name::TYPE]?
    if type.nil? || type != Pdfbox::Cos::Name::FONT
      raise ::IO::Error.new("Missing or wrong type in descendant font dictionary")
    end
    @descendant_font = PDFontFactory.create_descendant_font(descendant_font_dict, self)
    read_encoding
    fetch_cmap_ucs2
  end

  # Returns the PostScript name of the font.
  def name : String
    @dict.get_name_as_string(Pdfbox::Cos::Name::BASE_FONT) || ""
  end

  # Reads the encoding from the font dictionary.
  private def read_encoding : Nil
    encoding = @dict[Pdfbox::Cos::Name::ENCODING]?
    if encoding.is_a?(Pdfbox::Cos::Name)
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
    ros = descendant_font.cid_system_info
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
    name = @dict[Pdfbox::Cos::Name::ENCODING]?.as?(Pdfbox::Cos::Name)
    if (@is_cmap_predefined && !(name == Pdfbox::Cos::Name::IDENTITY_H || name == Pdfbox::Cos::Name::IDENTITY_V)) ||
       @is_descendant_cjk
      # a) Map the character code to a CID using the font's CMap
      # b) Obtain the ROS from the font's CIDSystemInfo
      # c) Construct a second CMap name by concatenating the ROS in the format "R-O-UCS2"
      # d) Obtain the CMap with the constructed name
      # e) Map the CID according to the CMap from step d), producing a Unicode value

      # todo: not sure how to interpret the PDF spec here, do we always override? or only when Identity-H/V?
      str_name = nil
      if @is_descendant_cjk
        ros = descendant_font.cid_system_info
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
    descendant_font.encode(unicode)
  end

  def read_code(input : ::IO) : Int32
    if @c_map.nil?
      raise ::IO::Error.new("required cmap is null")
    end
    @c_map.read_code(input)
  end

  def vertical? : Bool
    !@c_map.nil? && @c_map.wmode == 1
  end

  def font_matrix : Matrix
    descendant_font.font_matrix
  end

  def bounding_box : PDFont::BoundingBox
    descendant_font.bounding_box
  end

  def position_vector(code : Int32) : Vector
    # units are always 1/1000 text space, font matrix is not used, see FOP-2252
    vector = descendant_font.position_vector(code)
    Vector.new(vector.x * -0.001_f32, vector.y * -0.001_f32)
  end

  def width(code : Int32) : Float32
    descendant_font.width(code)
  end

  def height(code : Int32) : Float32
    descendant_font.height(code)
  end

  def to_unicode(code : Int32) : String?
    # try to use a ToUnicode CMap
    unicode = super(code)
    return unicode if unicode

    # Use identity mapping if the given ToUnicode CMap doesn't provide any valid mapping
    # a predefined map shall only be used if there isn't any ToUnicode CMap
    # PDFBOX-6022: not when there's a predefined cmap
    if to_unicode_cmap && !cmap_predefined?
      return identity_char_from_code(code)
    end

    if (cmap_predefined? || descendant_cjk?) && (ucs2 = cmap_ucs2)
      # if the font is composite and uses a predefined cmap (excluding Identity-H/V) then
      # or if its descendant font uses Adobe-GB1/CNS1/Japan1/Korea1

      # a) Map the character code to a character identifier (CID) according to the font's CMap
      cid = code_to_cid(code)

      # e) Map the CID according to the CMap from step d), producing a Unicode value
      return ucs2.to_unicode(cid)
    end

    # PDFBOX-5324: try to get unicode from font cmap
    if unicode_from_font = unicode_from_type2_font_cmap(code)
      return unicode_from_font
    end

    if !@no_unicode.includes?(code)
      # if no value has been produced, there is no way to obtain Unicode for the character.
      cid_str = "CID+" + code_to_cid(code).to_s
      Log.warn { "No Unicode mapping for #{cid_str} (#{code}) in font #{name}" }
      # we keep track of which warnings have been issued, so we don't log multiple times
      @no_unicode.add(code)
    end
    nil
  end

  private def unicode_from_type2_font_cmap(code : Int32) : String?
    return nil unless type2 = descendant_font.as?(PDCIDFontType2)
    return nil unless font = type2.true_type_font

    begin
      cmap = font.unicode_cmap_lookup(false)
      gid = if descendant_font.embedded?
              descendant_font.code_to_gid(code)
            else
              descendant_font.code_to_cid(code)
            end
      codes = cmap.char_codes(gid)
      return nil if codes.nil? || codes.empty?

      first_code = codes[0]
      begin
        first_code.chr.to_s
      rescue ex : ArgumentError
        Log.warn { "Invalid Unicode code point #{first_code} from font cmap in #{name}: #{ex.message}" }
        nil
      end
    rescue ex : ::IO::Error
      Log.warn { "get unicode from font cmap fail: #{ex}" }
      nil
    end
  end

  private def identity_char_from_code(code : Int32) : String
    (code & 0xFFFF).chr.to_s
  rescue ArgumentError
    "\uFFFD"
  end

  # PDVectorFont interface implementation

  def get_path(code : Int32)
    descendant_font.get_path(code)
  end

  def get_normalized_path(code : Int32)
    descendant_font.get_normalized_path(code)
  end

  def has_glyph(code : Int32) : Bool
    descendant_font.has_glyph(code)
  end

  # Helper methods

  def descendant_font : PDCIDFont
    @descendant_font || raise "Missing descendant font"
  end

  def embedded? : Bool
    descendant_font.embedded?
  end

  def damaged? : Bool
    descendant_font.damaged?
  end

  def average_font_width : Float32
    descendant_font.average_font_width
  end

  def has_explicit_width?(code : Int32) : Bool
    descendant_font.has_explicit_width?(code)
  end

  def width_from_font(code : Int32) : Float32
    descendant_font.width_from_font(code)
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
    descendant_font.code_to_cid(code)
  end

  def code_to_gid(code : Int32) : Int32
    descendant_font.code_to_gid(code)
  end

  def to_s : String
    descendant_name = @descendant_font.try(&.class.name.split("::").last?) || "nil"
    "#{self.class.name.split("::").last}/#{descendant_name}, PostScript name: #{name}"
  end

  # Returns true if the descendant font is a Type 2 CIDFont (TrueType).
  def cid_font_type2? : Bool
    descendant_font.is_a?(PDCIDFontType2)
  end

  # Returns the TrueType font if the descendant font is Type 2, otherwise nil.
  def true_type_font
    descendant_font.as?(PDCIDFontType2).try(&.true_type_font)
  end

  def cmap : Fontbox::CMap::CMap?
    @c_map
  end

  def cmap_ucs2 : Fontbox::CMap::CMap?
    @c_map_ucs2
  end

  # Returns true if the font uses a predefined CMap (not Identity-H/V).
  def cmap_predefined? : Bool
    @is_cmap_predefined
  end

  # Returns true if the descendant font uses CJK character collection.
  def descendant_cjk? : Bool
    @is_descendant_cjk
  end

  def gsub_data : GsubData
    @gsub_data
  end

  def cmap_lookup : CmapLookup?
    @cmap_lookup
  end

  def encode_glyph_id(glyph_id : Int32) : Bytes
    descendant_font.encode_glyph_id(glyph_id)
  end
end
