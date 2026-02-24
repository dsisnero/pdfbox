# Type 0 CIDFont (CFF)
# Corresponds to PDCIDFontType0 in Apache PDFBox
require "./cid_font"

module Pdfbox::Pdmodel::Font
  class PDCIDFontType0 < PDCIDFont
    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    @is_embedded : Bool = false
    @is_damaged : Bool = false
    @font_matrix : PDFont::Matrix = PDFont::Matrix.default_font_matrix
    @font_bbox : PDFont::BoundingBox = PDFont::BoundingBox.new

    # Constructor.
    def initialize(font_dictionary : Cos::Dictionary, parent : PDType0Font)
      super(font_dictionary, parent)
      # TODO: Implement CFF font parsing
      @is_embedded = !font_descriptor.nil? && !font_descriptor.try(&.font_file3).nil?
      @is_damaged = false
    end

    # Abstract method implementations

    def code_to_cid(code : Int32) : Int32
      # For Type 0 CIDFont, code is CID
      code
    end

    def code_to_gid(code : Int32) : Int32
      # For Type 0 CIDFont, GID is same as CID unless CIDToGID mapping exists
      cid = code_to_cid(code)
      cid2gid = read_cid_to_gid_map
      if cid2gid && cid < cid2gid.size
        cid2gid[cid]
      else
        cid
      end
    end

    def encode_glyph_id(glyph_id : Int32) : Bytes
      # Type 0 CIDFont uses CFF encoding
      # For now, return single byte
      Bytes.new(1, glyph_id.to_u8)
    end

    protected def encode(unicode : Int32) : Bytes
      # TODO: Implement proper encoding for Type 0 CIDFont
      Bytes.new(1, 0_u8)
    end

    def font_matrix : PDFont::Matrix
      @font_matrix
    end

    def bounding_box : PDFont::BoundingBox
      @font_bbox
    end

    def width_from_font(code : Int32) : Float32
      # TODO: Get width from CFF font
      0.0_f32
    end

    def embedded? : Bool
      @is_embedded
    end

    def damaged? : Bool
      @is_damaged
    end

    # PDVectorFont abstract methods
    def get_path(code : Int32)
      # TODO: Implement CFF glyph path extraction
      nil
    end

    def get_normalized_path(code : Int32)
      nil
    end

    def has_glyph(code : Int32) : Bool
      true
    end

    # Override parent methods for Type 0 specific logic
    def cid_font_type2? : Bool
      false
    end

    def true_type_font
      nil
    end
  end
end
