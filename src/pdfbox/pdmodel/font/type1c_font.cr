require "./encoding/standard_encoding"
require "./encoding/type1_encoding"
require "./simple_font"
require "./vector_font"
require "../../../fontbox/cff"
require "../../../fontbox/ttf/otf_parser"

class Pdfbox::Pdmodel::Font::PDType1CFont < Pdfbox::Pdmodel::Font::PDSimpleFont
  include Pdfbox::Pdmodel::Font::PDVectorFont

  Log = ::Log.for(self)

  @glyph_heights = Hash(String, Float32).new
  @cff_font : Fontbox::CFF::CFFType1Font?
  @generic_font : Fontbox::CFF::CFFType1Font | Fontbox::FontBoxFont
  @is_embedded : Bool
  @is_damaged : Bool
  @avg_width : Float32?
  @font_matrix_cache : Matrix?
  @font_bbox_cache : BoundingBox?
  @otf_font : Fontbox::TTF::OpenTypeFont?

  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary)

    font_is_damaged = false
    cff_embedded = nil
    otf_embedded = nil
    if descriptor = font_descriptor
      if font_file3 = descriptor.font_file3
        begin
          bytes = font_file3.to_byte_array
          if bytes.empty?
            Log.error { "Invalid data for embedded Type1C font #{name}" }
            font_is_damaged = true
          else
            begin
              otf_embedded = Fontbox::TTF::OTFParser.new.parse_embedded(::IO::Memory.new(bytes))
            rescue
              otf_embedded = nil
            end
            parsed_font = Fontbox::CFF::CFFParser.new.parse(bytes)[0]?
            if parsed_font.is_a?(Fontbox::CFF::CFFType1Font)
              cff_embedded = parsed_font
            else
              font_is_damaged = true
            end
          end
        rescue ex : ::Exception
          Log.error(exception: ex) { "Can't read the embedded Type1C font #{name}" }
          font_is_damaged = true
        end
      end
    end

    @is_damaged = font_is_damaged
    @cff_font = cff_embedded
    @otf_font = otf_embedded
    if cff_embedded
      @generic_font = cff_embedded
      @is_embedded = true
    else
      mapping = FontMappers.instance.get_font_box_font(base_font, font_descriptor)
      @generic_font = mapping.font
      if mapping.fallback?
        Log.warn { "Using fallback font #{@generic_font.name} for #{base_font}" }
      end
      @is_embedded = false
    end

    read_encoding
  end

  def font_box_font
    @generic_font
  end

  def cff_type1_font
    @cff_font
  end

  def base_font : String
    @dict.get_name_as_string(Pdfbox::Cos::Name::BASE_FONT) || ""
  end

  def name : String
    base_font
  end

  def get_path(name : String)
    return Fontbox::Util::Path.new if name == ".notdef" && !embedded? && !standard14?
    return @generic_font.path("hyphen") if name == "sfthyphen"
    if name == "nbspace"
      return Fontbox::Util::Path.new unless has_glyph?("space")
      return generic_path("space")
    end
    generic_path(name)
  end

  def has_glyph?(name : String) : Bool
    generic_has_glyph?(name)
  end

  def get_path(code : Int32)
    name_in_font = name_in_font(code_to_name(code))
    return get_path("hyphen") if name_in_font == "sfthyphen"
    if name_in_font == "nbspace"
      return Fontbox::Util::Path.new unless has_glyph?("space")
      return get_path("space")
    end
    get_path(name_in_font)
  end

  def get_normalized_path(code : Int32)
    name_in_font = name_in_font(code_to_name(code))
    if name_in_font == "nbspace"
      return Fontbox::Util::Path.new unless has_glyph?("space")
      name_in_font = "space"
    elsif name_in_font == "sfthyphen"
      name_in_font = "hyphen"
    end
    path = get_path(name_in_font)
    path.empty? ? get_path(".notdef") : path
  end

  def has_glyph(code : Int32) : Bool
    name_in_font = name_in_font(code_to_name(code))
    return has_glyph?("hyphen") if name_in_font == "sfthyphen"
    return has_glyph?("space") if name_in_font == "nbspace"
    has_glyph?(name_in_font)
  end

  def bounding_box : BoundingBox
    @font_bbox_cache ||= begin
      descriptor_bbox = font_descriptor.try(&.font_bounding_box)
      if descriptor_bbox && non_zero_bounding_box?(descriptor_bbox)
        BoundingBox.new(
          descriptor_bbox.lower_left_x,
          descriptor_bbox.lower_left_y,
          descriptor_bbox.upper_right_x,
          descriptor_bbox.upper_right_y
        )
      else
        bbox = generic_font_bbox
        BoundingBox.new(bbox.lower_left_x, bbox.lower_left_y, bbox.upper_right_x, bbox.upper_right_y)
      end
    end
  end

  def position_vector(code : Int32) : Vector
    Vector.new
  end

  protected def read_encoding_from_font : Pdfbox::Pdmodel::Font::Encoding::Encoding
    if !embedded? && (afm = get_standard14_afm)
      Pdfbox::Pdmodel::Font::Encoding::Type1Encoding.new(afm)
    elsif cff_font = @cff_font
      if cff_encoding = cff_font.encoding
        Pdfbox::Pdmodel::Font::Encoding::Type1Encoding.from_font_box(cff_encoding)
      else
        Pdfbox::Pdmodel::Font::Encoding::StandardEncoding::INSTANCE
      end
    else
      Pdfbox::Pdmodel::Font::Encoding::StandardEncoding::INSTANCE
    end
  end

  def read_code(input : ::IO) : Int32
    byte = input.read_byte
    byte.nil? ? -1 : byte.to_i32
  end

  def font_matrix : Matrix
    @font_matrix_cache ||= begin
      values = generic_font_matrix
      if values.size == 6
        Matrix.new(
          values[0].to_f32,
          values[1].to_f32,
          values[2].to_f32,
          values[3].to_f32,
          values[4].to_f32,
          values[5].to_f32
        )
      else
        DEFAULT_FONT_MATRIX
      end
    rescue
      DEFAULT_FONT_MATRIX
    end
  end

  def damaged? : Bool
    @is_damaged
  end

  def width_from_font(code : Int32) : Float32
    return 0.0_f32 if damaged?
    name = name_in_font(code_to_name(code))
    width = generic_width(name)
    if width == 0.0_f32
      width = otf_width(code, name)
    end
    matrix = font_matrix
    width * matrix.a * 1000.0_f32 + matrix.e * 1000.0_f32
  end

  def width(code : Int32) : Float32
    return 0.0_f32 if damaged?
    if has_explicit_width?(code)
      first_char = @dict[Pdfbox::Cos::Name::FIRST_CHAR]?.try(&.as_i) || 0
      idx = code - first_char
      if idx >= 0 && idx < widths.size
        return widths[idx]
      end
    end

    if standard14?
      return get_standard14_width(code)
    end

    width_from_font(code)
  end

  def embedded? : Bool
    @is_embedded
  end

  def height(code : Int32) : Float32
    name = code_to_name(code)
    return @glyph_heights[name] if @glyph_heights.has_key?(name)

    cff_font = @cff_font
    unless cff_font
      Log.warn { "No embedded CFF font, returning 0" }
      @glyph_heights[name] = 0.0_f32
      return 0.0_f32
    end

    height = cff_font.type1_char_string(name).path.bounds.height.to_f32
    @glyph_heights[name] = height
    height
  end

  def encode(unicode : Int32) : Bytes
    glyph_name = glyph_list.code_point_to_name(unicode)
    unless encoding.contains(glyph_name)
      raise ArgumentError.new("U+%04X ('%s') is not available in font %s encoding: %s" % [unicode, glyph_name, name, encoding.encoding_name])
    end

    name_in_font = name_in_font(glyph_name)
    unless name_in_font != ".notdef" && generic_has_glyph?(name_in_font)
      raise ArgumentError.new("No glyph for U+%04X in font %s" % [unicode, name])
    end

    code = encoding.name_to_code_map[glyph_name]
    Bytes.new(1, code.to_u8)
  end

  def get_string_width(string : String) : Float32
    cff_font = @cff_font
    unless cff_font
      Log.warn { "No embedded CFF font, returning 0" }
      return 0.0_f32
    end

    width = 0.0_f32
    string.each_codepoint do |code_point|
      glyph_name = glyph_list.code_point_to_name(code_point)
      unless generic_has_glyph?(glyph_name)
        raise ArgumentError.new("U+%04X ('%s') is not available in font %s" % [code_point, glyph_name, name])
      end
      width += cff_font.type1_char_string(glyph_name).width.to_f32
    end
    width
  end

  def average_font_width : Float32
    # Use WIDTHS array from dict if available, matching Java
    if widths = @dict[Pdfbox::Cos::Name::WIDTHS]?.try(&.as?(Pdfbox::Cos::Array))
      total = 0.0_f64; count = 0
      widths.items.each do |base|
        if base.is_a?(Pdfbox::Cos::Number) && base.value.to_f64 > 0
          total += base.value.to_f64; count += 1
        end
      end
      return (total / count).to_f32 if count > 0 && total > 0
    end
    500.0_f32
  end

  private def code_to_name(code : Int32) : String
    encoding.get_name(code)
  end

  private def name_in_font(name : String) : String
    return name if embedded? || generic_has_glyph?(name)

    if unicode = glyph_list.to_unicode(name)
      if unicode.size == 1
        uni_name = uni_name_of_code_point(unicode.codepoints.first)
        return uni_name if generic_has_glyph?(uni_name)
      end
    end

    ".notdef"
  end

  private def generic_path(name : String) : Fontbox::Util::Path
    case font = @generic_font
    in Fontbox::CFF::CFFType1Font
      font.path(name)
    in Fontbox::FontBoxFont
      font.path(name)
    end
  end

  private def generic_has_glyph?(name : String) : Bool
    case font = @generic_font
    in Fontbox::CFF::CFFType1Font
      gid = font.name_to_gid(name)
      gid > 0 || (gid == 0 && name == ".notdef")
    in Fontbox::FontBoxFont
      font.has_glyph?(name)
    end
  end

  private def generic_width(name : String) : Float32
    case font = @generic_font
    in Fontbox::CFF::CFFType1Font
      cs = font.type1_char_string(name)
      w = cs.width.to_f32
      w
    in Fontbox::FontBoxFont
      font.width(name)
    end
  end

  private def generic_font_bbox : Fontbox::Util::BoundingBox
    case font = @generic_font
    in Fontbox::CFF::CFFType1Font
      font.font_b_box || Fontbox::Util::BoundingBox.new
    in Fontbox::FontBoxFont
      font.font_bbox
    end
  end

  private def generic_font_matrix : Array(Float32 | Float64 | Int32)
    case font = @generic_font
    in Fontbox::CFF::CFFType1Font
      matrix = font.font_matrix
      if matrix
        matrix.map { |value| value.as(Float32 | Float64 | Int32) }
      else
        [] of Float32 | Float64 | Int32
      end
    in Fontbox::FontBoxFont
      font.font_matrix.map { |value| value.as(Float32 | Float64 | Int32) }
    end
  end

  private def uni_name_of_code_point(code_point : Int32) : String
    hex = code_point.to_s(16).upcase
    case hex.size
    when 1 then "uni000#{hex}"
    when 2 then "uni00#{hex}"
    when 3 then "uni0#{hex}"
    else        "uni#{hex}"
    end
  end

  private def non_zero_bounding_box?(bbox : Pdfbox::Pdmodel::Common::PDRectangle) : Bool
    bbox.width != 0.0_f32 || bbox.height != 0.0_f32 || bbox.lower_left_x != 0.0_f32 || bbox.lower_left_y != 0.0_f32
  end

  private def otf_width(code : Int32, name : String) : Float32
    otf = @otf_font
    return 0.0_f32 unless otf

    hmtx = otf.horizontal_metrics
    return 0.0_f32 unless hmtx

    gid = otf_gid_for_name(otf, name)
    if gid <= 0
      unicode = glyph_list.to_unicode(code_to_name(code))
      if unicode && unicode.size == 1
        gid = otf_gid_for_code_point(otf, unicode.codepoints.first)
      end
    end
    return 0.0_f32 if gid <= 0

    units_per_em = otf.units_per_em
    width = hmtx.advance_width(gid).to_f32
    return width if units_per_em <= 0
    width * (1000.0_f32 / units_per_em.to_f32)
  end

  private def otf_gid_for_name(otf : Fontbox::TTF::OpenTypeFont, name : String) : Int32
    gid = otf.name_to_gid(name)
    return gid if gid > 0

    unicode = glyph_list.to_unicode(name)
    return 0 unless unicode && unicode.size == 1

    otf_gid_for_code_point(otf, unicode.codepoints.first)
  end

  private def otf_gid_for_code_point(otf : Fontbox::TTF::OpenTypeFont, code_point : Int32) : Int32
    cmap_table = otf.cmap
    return 0 unless cmap_table

    cmap_table.cmaps.each do |cmap|
      platform_id = cmap.platform_id
      platform_encoding_id = cmap.platform_encoding_id
      next unless platform_id == Fontbox::TTF::CmapTable::PLATFORM_WINDOWS && platform_encoding_id == Fontbox::TTF::CmapTable::ENCODING_WIN_UNICODE_BMP ||
                  platform_id == Fontbox::TTF::CmapTable::PLATFORM_UNICODE

      gid = cmap.glyph_id(code_point)
      return gid if gid > 0
    end

    0
  end
end
