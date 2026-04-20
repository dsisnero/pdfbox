# Composite (Type 0) font implementation
# Corresponds to PDType0Font in Apache PDFBox
require "./encoding"
require "digest/crc32"
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
require "./to_unicode_writer"
require "../common/pdstream"
require "../common/pdrectangle"
require "../../../fontbox/ttf/ttf_subsetter"

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
  @embed_subset : Bool = false
  @subset_code_points = Set(Int32).new
  @subset_glyph_ids = Set(Int32).new
  @subset_applied = false
  @subset_unicode_to_old_gid = Hash(Int32, Int32).new

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
    if descendant_font_dict_base.is_a?(Pdfbox::Cos::Object)
      descendant_font_dict_base = descendant_font_dict_base.object
    end
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

  # Constructor for creating a Type0 font from a TrueType font (for embedding)
  protected def initialize(doc : Pdfbox::Pdmodel::PDDocument, ttf : Fontbox::TTF::TrueTypeFont, embed_subset : Bool, close_ttf : Bool, vertical : Bool)
    super() # embedding constructor - creates empty dictionary

    if !embed_subset && ttf.from_collection?
      raise ::IO::Error.new("Full embedding of TrueType font collections not supported")
    end

    # Store the TrueType font
    @ttf = ttf
    @embed_subset = embed_subset
    ttf.enable_vertical_substitutions if vertical

    # Initialize other fields
    @gsub_data = GsubData::NO_DATA_FOUND
    @cmap_lookup = nil
    base_font_name = embed_subset ? subset_font_name(ttf.name) : ttf.name

    @dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type0")
    @dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new(base_font_name)
    @dict[Pdfbox::Cos::Name::ENCODING] = vertical ? Pdfbox::Cos::Name::IDENTITY_V : Pdfbox::Cos::Name::IDENTITY_H

    descendant_dict = build_descendant_font_dictionary(doc, ttf, base_font_name, vertical)
    descendants = Pdfbox::Cos::Array.new
    descendants.add(descendant_dict)
    @dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = descendants
    if to_unicode_stream = build_to_unicode_stream(ttf)
      @dict[Pdfbox::Cos::Name::TO_UNICODE] = to_unicode_stream
    end
    @descendant_font = PDCIDFontType2.new(descendant_dict, self, ttf)

    @is_descendant_cjk = false
    @is_cmap_predefined = false
    read_encoding
    fetch_cmap_ucs2

    # Close TTF if requested
    if close_ttf
      ttf.close
    end
  end

  # Returns the PostScript name of the font.
  def base_font : String
    @dict.get_name_as_string(Pdfbox::Cos::Name::BASE_FONT) || ""
  end

  # Returns the PostScript name of the font.
  def name : String
    base_font
  end

  # Reads the encoding from the font dictionary.
  private def read_encoding : Nil
    encoding = @dict[Pdfbox::Cos::Name::ENCODING]?
    if encoding.is_a?(Pdfbox::Cos::Name)
      # predefined CMap
      encoding_name = encoding.value
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
        str_name = name.value
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

  def encode(unicode : Int32) : Bytes
    add_to_subset(unicode) if will_be_subset?
    descendant_font.encode(unicode)
  end

  def read_code(input : ::IO) : Int32
    if @c_map.nil?
      raise ::IO::Error.new("required cmap is null")
    end
    @c_map.as(Fontbox::CMap::CMap).read_code(input)
  end

  def vertical? : Bool
    @c_map.try(&.wmode) == 1
  end

  def font_matrix : Matrix
    descendant_font.font_matrix
  end

  def font_descriptor : PDFontDescriptor?
    descendant_font.font_descriptor
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

  def displacement(code : Int32) : Vector
    if vertical?
      Vector.new(0.0_f32, descendant_font.vertical_displacement_vector_y(code) / 1000.0_f32)
    else
      super(code)
    end
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
    return unless type2 = descendant_font.as?(PDCIDFontType2)
    return unless font = type2.true_type_font

    begin
      cmap = font.unicode_cmap_lookup(false)
      gid = if descendant_font.embedded?
              descendant_font.code_to_gid(code)
            else
              descendant_font.code_to_cid(code)
            end
      codes = cmap.char_codes(gid)
      return if codes.nil? || codes.empty?

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
    raise NotImplementedError.new("not supported")
  end

  def add_to_subset(code_point : Int32) : Nil
    raise "This font was created with subsetting disabled" unless will_be_subset?
    @subset_code_points.add(code_point)
  end

  def add_glyphs_to_subset(glyph_ids : Set(Int32)) : Nil
    raise "This font was created with subsetting disabled" unless will_be_subset?
    @subset_glyph_ids.concat(glyph_ids)
  end

  def subset : Nil
    raise "This font was created with subsetting disabled" unless will_be_subset?
    return if @subset_applied
    ttf = @ttf
    return unless ttf

    subsetter = Fontbox::TTF::TTFSubsetter.new(ttf, subset_table_tags)
    @subset_code_points.each do |code_point|
      subsetter.add(code_point)
    end

    @subset_glyph_ids.each do |glyph_id|
      add_gid_to_subsetter(subsetter, glyph_id)
    end

    # Match the Java embedder's invisible-code-point handling.
    subsetter.force_invisible(0x200B)
    subsetter.force_invisible(0x200C)
    subsetter.force_invisible(0x2060)
    subsetter.force_invisible(0xFEFF)
    @subset_unicode_to_old_gid = subsetter.unicode_to_gid.dup

    subset_bytes_io = ::IO::Memory.new
    subsetter.write_to_stream(subset_bytes_io)
    subset_bytes = subset_bytes_io.to_slice

    cid_to_gid = build_subset_cid_to_gid_map(subsetter.gid_map)
    rebuild_subset_font(subset_bytes, cid_to_gid)
    @subset_applied = true
  end

  def will_be_subset? : Bool
    @embed_subset
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

  def composite_font? : Bool
    true
  end

  def standard14? : Bool
    false
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

  def to_unicode_cmap : Fontbox::CMap::CMap?
    @to_unicode_cmap
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

  # Loads a TTF to be embedded into a document as a Type 0 font.
  #
  # @param doc The PDF document that will hold the embedded font.
  # @param input An input stream of a TrueType font.
  # @param embed_subset True if the font will be subset before embedding.
  # @return A Type0 font with a CIDFontType2 descendant.
  def self.load(doc : Pdfbox::Pdmodel::PDDocument, input : ::IO, embed_subset : Bool = true) : self
    # Convert IO to RandomAccessReadBuffer
    random_access_read = Pdfbox::IO::RandomAccessReadBuffer.new(input)

    # Parse the TrueType font
    parser = Fontbox::TTF::TTFParser.new
    ttf = parser.parse(random_access_read)

    # Create the PDType0Font
    load(doc, ttf, embed_subset)
  end

  # Loads a TTF to be embedded into a document as a Type 0 font.
  #
  # @param doc The PDF document that will hold the embedded font.
  # @param ttf A parsed TrueType font.
  # @param embed_subset True if the font will be subset before embedding.
  # @return A Type0 font with a CIDFontType2 descendant.
  def self.load(doc : Pdfbox::Pdmodel::PDDocument, ttf : Fontbox::TTF::TrueTypeFont, embed_subset : Bool = true) : self
    # Create a new PDType0Font with the TrueType font
    # vertical = false for regular loading
    new(doc, ttf, embed_subset, true, false)
  end

  def self.load(doc : Pdfbox::Pdmodel::PDDocument, file : ::File, embed_subset : Bool = true) : self
    random_access_read = Pdfbox::IO::RandomAccessReadBufferedFile.new(file.path)
    parser = Fontbox::TTF::TTFParser.new
    ttf = parser.parse(random_access_read)
    load(doc, ttf, embed_subset)
  end

  # Loads a TTF to be embedded into a document as a vertical Type 0 font.
  #
  # @param doc The PDF document that will hold the embedded font.
  # @param input An input stream of a TrueType font.
  # @param embed_subset True if the font will be subset before embedding.
  # @return A Type0 font with a CIDFontType2 descendant.
  def self.load_vertical(doc : Pdfbox::Pdmodel::PDDocument, input : ::IO, embed_subset : Bool = true) : self
    parser = Fontbox::TTF::TTFParser.new(true)
    ttf = parser.parse_embedded(input)
    new(doc, ttf, embed_subset, true, true)
  end

  private def build_descendant_font_dictionary(doc : Pdfbox::Pdmodel::PDDocument, ttf : Fontbox::TTF::TrueTypeFont, base_font_name : String, vertical : Bool) : Pdfbox::Cos::Dictionary
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new(base_font_name)
    descendant[Pdfbox::Cos::Name::CIDSYSTEMINFO] = PDCIDSystemInfo.new("Adobe", "Identity", 0).cos_object
    descendant[Pdfbox::Cos::Name.new("CIDToGIDMap")] = Pdfbox::Cos::Name::IDENTITY
    descendant[Pdfbox::Cos::Name.new("DW")] = Pdfbox::Cos::Integer.new(default_width_for(ttf))
    descendant[Pdfbox::Cos::Name.new("W")] = build_widths_array(ttf)
    build_vertical_metrics(descendant, ttf) if vertical

    descriptor = build_font_descriptor(doc, ttf, base_font_name)
    descendant[Pdfbox::Cos::Name::FONT_DESC] = descriptor.cos_object
    descendant
  end

  private def build_font_descriptor(doc : Pdfbox::Pdmodel::PDDocument, ttf : Fontbox::TTF::TrueTypeFont, base_font_name : String) : PDFontDescriptor
    descriptor = PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)
    descriptor.font_name = base_font_name
    descriptor.non_symbolic = true
    descriptor.symbolic = false

    if header = ttf.header
      descriptor.font_bounding_box = Pdfbox::Pdmodel::Common::PDRectangle.new(
        header.x_min.to_f32,
        header.y_min.to_f32,
        (header.x_max - header.x_min).to_f32,
        (header.y_max - header.y_min).to_f32
      )
    end

    if hhea = ttf.horizontal_header
      units_per_em = ttf.units_per_em
      scale = units_per_em > 0 ? 1000.0_f32 / units_per_em.to_f32 : 1.0_f32
      descriptor.ascent = hhea.ascender.to_f32 * scale
      descriptor.descent = hhea.descender.to_f32 * scale
      descriptor.cap_height = hhea.ascender.to_f32 * scale
      descriptor.x_height = (hhea.ascender.to_f32 * scale) / 2.0_f32
    end

    descriptor.stem_v = 80.0_f32
    descriptor.italic_angle = ttf.postscript.try(&.italic_angle) || 0.0_f32

    font_data = ttf.original_data
    descriptor.font_file2 = Pdfbox::Pdmodel::Common::PDStream.new(doc, font_data)
    descriptor
  end

  private def rebuild_subset_font(subset_bytes : Bytes, cid_to_gid : Hash(Int32, Int32)) : Nil
    descendant_dict = descendant_font.cos_object
    base_font_name = base_font
    font_name = base_font_name.includes?('+') ? base_font_name : subset_font_name(base_font_name)

    descriptor = descendant_font.font_descriptor || PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)
    descriptor.font_name = font_name
    descriptor.font_file2 = Pdfbox::Pdmodel::Common::PDStream.new(Pdfbox::Cos::Stream.new(data: subset_bytes))
    descendant_dict[Pdfbox::Cos::Name::FONT_DESC] = descriptor.cos_object

    @dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new(font_name)
    descendant_dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new(font_name)
    descendant_dict[Pdfbox::Cos::Name.new("W")] = build_subset_widths_array(cid_to_gid, subset_bytes)
    descendant_dict[Pdfbox::Cos::Name.new("CIDToGIDMap")] = build_subset_cid_to_gid_stream(cid_to_gid)
    build_subset_vertical_metrics(descendant_dict, cid_to_gid) if vertical?
    if to_unicode_stream = build_subset_to_unicode_stream(cid_to_gid)
      @dict[Pdfbox::Cos::Name::TO_UNICODE] = to_unicode_stream
    end
  end

  private def build_subset_widths_array(cid_to_gid : Hash(Int32, Int32), subset_bytes : Bytes) : Pdfbox::Cos::Array
    parser = Fontbox::TTF::TTFParser.new(true)
    subset_font = parser.parse(Pdfbox::IO::RandomAccessReadBuffer.new(subset_bytes))

    widths = Pdfbox::Cos::Array.new
    sorted_cids = cid_to_gid.keys.to_a.sort!
    segment_start = Int32::MIN
    current_segment = Pdfbox::Cos::Array.new
    previous_cid = Int32::MIN
    hmtx = subset_font.horizontal_metrics
    units_per_em = subset_font.units_per_em
    scale = units_per_em > 0 ? 1000.0_f32 / units_per_em.to_f32 : 1.0_f32

    sorted_cids.each do |cid|
      gid = cid_to_gid[cid]
      width = hmtx ? (hmtx.advance_width(gid).to_f32 * scale).round.to_i : 0

      if segment_start == Int32::MIN || cid != previous_cid + 1
        unless segment_start == Int32::MIN
          widths.add(Pdfbox::Cos::Integer.new(segment_start))
          widths.add(current_segment)
        end
        segment_start = cid
        current_segment = Pdfbox::Cos::Array.new
      end

      current_segment.add(Pdfbox::Cos::Integer.new(width))
      previous_cid = cid
    end

    unless segment_start == Int32::MIN
      widths.add(Pdfbox::Cos::Integer.new(segment_start))
      widths.add(current_segment)
    end

    widths
  end

  private def build_subset_cid_to_gid_stream(cid_to_gid : Hash(Int32, Int32)) : Pdfbox::Cos::Stream
    max_cid = cid_to_gid.keys.max? || 0
    bytes = Bytes.new((max_cid + 1) * 2, 0_u8)
    cid_to_gid.each do |cid, gid|
      offset = cid * 2
      bytes[offset] = ((gid >> 8) & 0xFF).to_u8
      bytes[offset + 1] = (gid & 0xFF).to_u8
    end
    Pdfbox::Cos::Stream.new(data: bytes)
  end

  private def build_subset_to_unicode_stream(cid_to_gid : Hash(Int32, Int32)) : Pdfbox::Cos::Stream?
    writer = ToUnicodeWriter.new

    if @subset_unicode_to_old_gid.empty?
      ttf = @ttf
      return unless ttf
      cmap = ttf.unicode_cmap_lookup(false)
      cid_to_gid.keys.to_a.sort!.each do |cid|
        codes = cmap.char_codes(cid)
        next if codes.nil? || codes.empty?
        begin
          writer.add(cid, codes.first.chr.to_s)
        rescue ArgumentError
        end
      end
    else
      @subset_unicode_to_old_gid.keys.sort!.each do |unicode|
        old_gid = @subset_unicode_to_old_gid[unicode]
        begin
          writer.add(old_gid, unicode.chr.to_s)
        rescue ArgumentError
        end
      end
    end

    io = ::IO::Memory.new
    writer.write_to(io)
    Pdfbox::Cos::Stream.new(data: io.to_slice)
  rescue ex : ::IO::Error
    Log.warn { "Failed to build subset ToUnicode map for #{name}: #{ex.message}" }
    nil
  end

  private def build_subset_cid_to_gid_map(new_gid_to_old_gid : Hash(Int32, Int32)) : Hash(Int32, Int32)
    cid_to_gid = Hash(Int32, Int32).new
    new_gid_to_old_gid.each do |new_gid, old_gid|
      cid_to_gid[old_gid] = new_gid
    end
    cid_to_gid
  end

  private def subset_table_tags : Array(String)
    ["head", "hhea", "loca", "maxp", "cvt ", "prep", "glyf", "hmtx", "fpgm", "gasp", "cmap", "name", "post", "OS/2"]
  end

  private def add_gid_to_subsetter(subsetter : Fontbox::TTF::TTFSubsetter, glyph_id : Int32) : Nil
    subsetter.add_glyph_id(glyph_id)
  end

  private def build_widths_array(ttf : Fontbox::TTF::TrueTypeFont) : Pdfbox::Cos::Array
    widths = Pdfbox::Cos::Array.new
    glyph_widths = Pdfbox::Cos::Array.new

    number_of_glyphs = Math.max(ttf.number_of_glyphs, 0)
    hmtx = ttf.horizontal_metrics
    units_per_em = ttf.units_per_em
    scale = units_per_em > 0 ? 1000.0_f32 / units_per_em.to_f32 : 1.0_f32

    number_of_glyphs.times do |gid|
      advance_width = hmtx ? hmtx.advance_width(gid).to_f32 : 0.0_f32
      glyph_widths.add(Pdfbox::Cos::Integer.new((advance_width * scale).round.to_i))
    end

    widths.add(Pdfbox::Cos::Integer.new(0))
    widths.add(glyph_widths)
    widths
  end

  private def default_width_for(ttf : Fontbox::TTF::TrueTypeFont) : Int32
    hmtx = ttf.horizontal_metrics
    units_per_em = ttf.units_per_em
    return 1000 unless hmtx && units_per_em > 0

    (hmtx.advance_width(0).to_f32 * (1000.0_f32 / units_per_em.to_f32)).round.to_i
  end

  private def build_vertical_metrics(descendant : Pdfbox::Cos::Dictionary, ttf : Fontbox::TTF::TrueTypeFont) : Nil
    default_metrics = apply_default_vertical_metrics(descendant, ttf)
    return unless default_metrics

    v, w1, scale = default_metrics
    heights = build_vertical_metrics_array(ttf, (0...ttf.number_of_glyphs), v, w1, scale)
    descendant[Pdfbox::Cos::Name.new("W2")] = heights
  end

  private def build_subset_vertical_metrics(descendant : Pdfbox::Cos::Dictionary, cid_to_gid : Hash(Int32, Int32)) : Nil
    ttf = @ttf
    return unless ttf

    default_metrics = apply_default_vertical_metrics(descendant, ttf)
    if default_metrics.nil?
      descendant.delete(Pdfbox::Cos::Name.new("DW2"))
      return
    end

    v, w1, scale = default_metrics
    heights = build_vertical_metrics_array(ttf, cid_to_gid.keys.to_a.sort!, v, w1, scale)
    descendant[Pdfbox::Cos::Name.new("W2")] = heights
  end

  private def apply_default_vertical_metrics(descendant : Pdfbox::Cos::Dictionary, ttf : Fontbox::TTF::TrueTypeFont) : Tuple(Int32, Int32, Float32)?
    vhea = ttf.vertical_header
    return unless vhea

    units_per_em = ttf.units_per_em
    scale = units_per_em > 0 ? 1000.0_f32 / units_per_em.to_f32 : 1.0_f32

    v = (vhea.ascender.to_f32 * scale).round.to_i
    w1 = (-vhea.advance_height_max.to_f32 * scale).round.to_i
    if v != 880 || w1 != -1000
      dw2 = Pdfbox::Cos::Array.new
      dw2.add(Pdfbox::Cos::Integer.new(v))
      dw2.add(Pdfbox::Cos::Integer.new(w1))
      descendant[Pdfbox::Cos::Name.new("DW2")] = dw2
    else
      descendant.delete(Pdfbox::Cos::Name.new("DW2"))
    end

    {v, w1, scale}
  end

  private def build_vertical_metrics_array(ttf : Fontbox::TTF::TrueTypeFont, cids : Enumerable(Int32), default_v : Int32, default_w1 : Int32, scale : Float32) : Pdfbox::Cos::Array
    vmtx = ttf.vertical_metrics
    glyf = ttf.glyph
    hmtx = ttf.horizontal_metrics
    return Pdfbox::Cos::Array.new unless vmtx && glyf && hmtx

    heights = Pdfbox::Cos::Array.new
    current = Pdfbox::Cos::Array.new
    previous_cid = Int32::MIN

    cids.each do |cid|
      glyph = glyf.glyph(cid)
      next unless glyph

      height = ((glyph.y_maximum.to_f32 + vmtx.top_side_bearing(cid).to_f32) * scale).round.to_i
      advance = (-vmtx.advance_height(cid).to_f32 * scale).round.to_i
      next if height == default_v && advance == default_w1

      if previous_cid != cid - 1
        current = Pdfbox::Cos::Array.new
        heights.add(Pdfbox::Cos::Integer.new(cid))
        heights.add(current)
      end

      width = (hmtx.advance_width(cid).to_f32 * scale).round.to_i
      current.add(Pdfbox::Cos::Integer.new(advance))
      current.add(Pdfbox::Cos::Integer.new(width // 2))
      current.add(Pdfbox::Cos::Integer.new(height))
      previous_cid = cid
    end

    heights
  end

  private def build_to_unicode_stream(ttf : Fontbox::TTF::TrueTypeFont) : Pdfbox::Cos::Stream?
    cmap = ttf.unicode_cmap_lookup(false)
    writer = ToUnicodeWriter.new

    (0..0xFFFF).each do |unicode|
      gid = cmap.glyph_id(unicode)
      next if gid <= 0
      begin
        writer.add(gid, unicode.chr.to_s)
      rescue ArgumentError
      end
    end

    io = ::IO::Memory.new
    writer.write_to(io)
    stream = Pdfbox::Cos::Stream.new
    stream.data = io.to_slice
    stream
  rescue ex : ::IO::Error
    Log.warn { "Failed to build ToUnicode map for #{ttf.name}: #{ex.message}" }
    nil
  end

  private def subset_font_name(post_script_name : String) : String
    checksum = Digest::CRC32.checksum(post_script_name).to_s(16).upcase.rjust(6, '0')
    tag = checksum[-6, 6].chars.map { |char| ((char.ord % 26) + 'A'.ord).chr }.join
    "#{tag}+#{post_script_name}"
  end
end
