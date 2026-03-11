# Type 2 CIDFont (TrueType)
# Corresponds to PDCIDFontType2 in Apache PDFBox
require "./cid_font"
require "../../../fontbox/ttf/true_type_font"

module Pdfbox::Pdmodel::Font
  class PDCIDFontType2 < PDCIDFont
    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    @ttf : Fontbox::TTF::TrueTypeFont?
    @is_embedded : Bool = false
    @is_damaged : Bool = false
    @font_matrix : PDFont::Matrix = PDFont::Matrix.default_font_matrix
    @font_bbox : PDFont::BoundingBox = PDFont::BoundingBox.new
    @cid2gid : Array(Int32)?

    # Constructor.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font)
      super(font_dictionary, parent)
      # TODO: Implement TrueType font parsing
      @is_embedded = !font_descriptor.nil? && !font_descriptor.try(&.font_file2).nil?
      @is_damaged = false
      @cid2gid = read_cid_to_gid_map
    end

    # Constructor with pre-loaded TrueType font.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font, true_type_font : Fontbox::TTF::TrueTypeFont)
      super(font_dictionary, parent)
      @ttf = true_type_font
      @is_embedded = true
      @is_damaged = false
      @cid2gid = read_cid_to_gid_map
    end

    # Abstract method implementations

    def code_to_cid(code : Int32) : Int32
      # For Type 2 CIDFont, code is CID
      code
    end

    def code_to_gid(code : Int32) : Int32
      cid = code_to_cid(code)
      if cid2gid = @cid2gid
        if cid < cid2gid.size
          return cid2gid[cid]
        end
      end
      # Default: CID maps to GID
      cid
    end

    def encode_glyph_id(glyph_id : Int32) : Bytes
      # Type 2 CIDFont uses TrueType encoding
      # For now, return glyph ID as bytes (1-4 bytes)
      if glyph_id <= 0xFF
        Bytes.new(1, glyph_id.to_u8)
      elsif glyph_id <= 0xFFFF
        Bytes.new(2) { |i| i == 0 ? (glyph_id >> 8).to_u8 : glyph_id.to_u8 }
      else
        Bytes.new(4) { |i| (glyph_id >> (24 - i * 8)).to_u8 & 0xFF }
      end
    end

    protected def encode(unicode : Int32) : Bytes
      # TODO: Implement proper encoding for Type 2 CIDFont
      Bytes.new(1, 0_u8)
    end

    def font_matrix : PDFont::Matrix
      @font_matrix
    end

    def bounding_box : PDFont::BoundingBox
      @font_bbox
    end

    def width_from_font(code : Int32) : Float32
      # TODO: Get width from TrueType font
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
      # TODO: Implement TrueType glyph path extraction
      nil
    end

    def get_normalized_path(code : Int32)
      nil
    end

    def has_glyph(code : Int32) : Bool
      true
    end

    # Additional methods used by PDType0Font
    def cid_font_type2? : Bool
      true
    end

    def true_type_font
      @ttf
    end
  end
end
