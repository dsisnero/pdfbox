# Type 0 CIDFont (CFF)
# Corresponds to PDCIDFontType0 in Apache PDFBox
require "./cid_font"
require "../../../fontbox/cff"

module Pdfbox::Pdmodel::Font
  class PDCIDFontType0 < PDCIDFont
    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    @parent : PDType0Font
    @is_embedded : Bool = false
    @is_damaged : Bool = false
    @font_matrix : PDFont::Matrix = PDFont::Matrix.default_font_matrix
    @font_bbox : PDFont::BoundingBox?
    @cid_font : Fontbox::CFF::CFFCIDFont?
    @t1_font : Fontbox::CFF::CFFType1Font?
    @cid2gid : Array(Int32)?

    # Constructor.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font)
      super(font_dictionary, parent)
      @parent = parent
      parse_embedded_cff
      @cid2gid = read_cid_to_gid_map
    end

    # Abstract method implementations

    def code_to_cid(code : Int32) : Int32
      @parent.cmap.try(&.to_cid(code)) || code
    end

    def code_to_gid(code : Int32) : Int32
      cid = code_to_cid(code)
      if cid_font = @cid_font
        if charset = cid_font.charset
          return charset.gid_for_cid(cid)
        end
      end
      # Type1-equivalent CFF path and fallback path use CID directly as GID.
      cid
    end

    def encode_glyph_id(glyph_id : Int32) : Bytes
      raise NotImplementedError.new("Unsupported operation")
    end

    def encode(unicode : Int32) : Bytes
      raise NotImplementedError.new("Unsupported operation")
    end

    def font_matrix : PDFont::Matrix
      @font_matrix
    end

    def bounding_box : PDFont::BoundingBox
      @font_bbox ||= generate_bounding_box
    end

    private def generate_bounding_box : PDFont::BoundingBox
      if descriptor = font_descriptor
        if bbox = descriptor.font_bounding_box
          if bbox.lower_left_x != 0.0_f32 || bbox.lower_left_y != 0.0_f32 ||
             bbox.upper_right_x != 0.0_f32 || bbox.upper_right_y != 0.0_f32
            return PDFont::BoundingBox.new(
              bbox.lower_left_x,
              bbox.lower_left_y,
              bbox.upper_right_x,
              bbox.upper_right_y
            )
          end
        end
      end

      if cff_bbox = @cid_font.try(&.font_b_box) || @t1_font.try(&.font_b_box)
        return PDFont::BoundingBox.new(
          cff_bbox.lower_left_x,
          cff_bbox.lower_left_y,
          cff_bbox.upper_right_x,
          cff_bbox.upper_right_y
        )
      end

      PDFont::BoundingBox.new
    end

    def width_from_font(code : Int32) : Float32
      cid = code_to_cid(code)
      width = if cid_font = @cid_font
                cid_font.type2_char_string(cid).width.to_f32
              elsif embedded? && (t1_font = @t1_font)
                t1_font.type2_char_string(cid).width.to_f32
              elsif t1_font = @t1_font
                t1_font.type1_char_string(glyph_name(code)).width.to_f32
              else
                return width(code)
              end

      # Match Java normalization: apply CFF FontMatrix then scale to 1000 units.
      transformed = font_matrix.transform(PDFont::Vector.new(width, 0.0_f32))
      transformed.x * 1000.0_f32
    end

    def embedded? : Bool
      @is_embedded
    end

    def damaged? : Bool
      @is_damaged
    end

    # PDVectorFont abstract methods
    def get_path(code : Int32)
      cid = code_to_cid(code)
      if embedded?
        if cid2gid = @cid2gid
          return Fontbox::Util::Path.new if cid < 0 || cid >= cid2gid.size
          cid = cid2gid[cid]
        end
      end

      if cid_font = @cid_font
        return cid_font.path(cid)
      end
      if t1_font = @t1_font
        if embedded?
          return t1_font.type2_char_string(cid).path
        end
        return t1_font.path(glyph_name(code))
      end
      Fontbox::Util::Path.new
    end

    def get_normalized_path(code : Int32)
      get_path(code)
    end

    def has_glyph(code : Int32) : Bool
      cid = code_to_cid(code)
      if cid_font = @cid_font
        return cid_font.type2_char_string(cid).gid != 0
      end
      if t1_font = @t1_font
        if embedded?
          return t1_font.type2_char_string(cid).gid != 0
        end
        return t1_font.name_to_gid(glyph_name(code)) != 0
      end
      code_to_gid(code) != 0
    end

    # Override parent methods for Type 0 specific logic
    def cid_font_type2? : Bool
      false
    end

    def true_type_font
      nil
    end

    private def parse_embedded_cff : Nil
      @is_embedded = false
      @is_damaged = false
      return unless fd = font_descriptor
      return unless font_file3 = fd.font_file3

      begin
        bytes = font_file3.to_byte_array
        return if bytes.empty?

        parser = Fontbox::CFF::CFFParser.new
        cff_font = parser.parse(bytes)[0]?
        return if cff_font.nil?

        case cff_font
        when Fontbox::CFF::CFFCIDFont
          @cid_font = cff_font
        when Fontbox::CFF::CFFType1Font
          @t1_font = cff_font
        end

        @font_matrix = matrix_from_cff(cff_font)
        @is_embedded = true
      rescue ex : Exception
        Log.error { "Can't read the embedded CFF font #{fd.font_name}: #{ex.message}" }
        @is_damaged = true
      end
    end

    private def matrix_from_cff(cff_font : Fontbox::CFF::CFFFont) : PDFont::Matrix
      numbers = cff_font.font_matrix
      return PDFont::Matrix.default_font_matrix if numbers.nil? || numbers.size != 6
      PDFont::Matrix.new(
        cff_number_to_f32(numbers[0]),
        cff_number_to_f32(numbers[1]),
        cff_number_to_f32(numbers[2]),
        cff_number_to_f32(numbers[3]),
        cff_number_to_f32(numbers[4]),
        cff_number_to_f32(numbers[5])
      )
    rescue ex : Exception
      Log.debug { "Couldn't get CFF font matrix - returning default value: #{ex.message}" }
      PDFont::Matrix.default_font_matrix
    end

    private def cff_number_to_f32(value : Fontbox::CFF::CFFNumber) : Float32
      value.is_a?(Int32) ? value.to_f32 : value.to_f32
    end

    private def glyph_name(code : Int32) : String
      unicode = @parent.to_unicode(code)
      return ".notdef" if unicode.nil? || unicode.empty?
      code_point = unicode.char_at(0).ord.to_i32
      "uni#{code_point.to_s(16).upcase.rjust(4, '0')}"
    end
  end
end
