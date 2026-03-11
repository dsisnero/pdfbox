# Type 0 CIDFont (CFF)
# Corresponds to PDCIDFontType0 in Apache PDFBox
require "./cid_font"

module Pdfbox::Pdmodel::Font
  class PDCIDFontType0 < PDCIDFont
    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    @parent : PDType0Font
    @is_embedded : Bool = false
    @is_damaged : Bool = false
    @font_matrix : PDFont::Matrix = PDFont::Matrix.default_font_matrix
    @font_bbox : PDFont::BoundingBox?

    # Constructor.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font)
      super(font_dictionary, parent)
      @parent = parent
      # TODO: Implement CFF font parsing
      @is_embedded = !font_descriptor.nil? && !font_descriptor.try(&.font_file3).nil?
      @is_damaged = false
    end

    # Abstract method implementations

    def code_to_cid(code : Int32) : Int32
      @parent.cmap.try(&.to_cid(code)) || code
    end

    def code_to_gid(code : Int32) : Int32
      # Default Type0 behavior is CID-as-GID unless CFF charset mapping is available.
      code_to_cid(code)
    end

    def encode_glyph_id(glyph_id : Int32) : Bytes
      raise NotImplementedError.new("Unsupported operation")
    end

    protected def encode(unicode : Int32) : Bytes
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

      PDFont::BoundingBox.new
    end

    def width_from_font(code : Int32) : Float32
      # CFF program metrics are not wired yet; fall back to dictionary widths.
      width(code)
    end

    def embedded? : Bool
      @is_embedded
    end

    def damaged? : Bool
      @is_damaged
    end

    # PDVectorFont abstract methods
    def get_path(code : Int32)
      Fontbox::Util::Path.new
    end

    def get_normalized_path(code : Int32)
      get_path(code)
    end

    def has_glyph(code : Int32) : Bool
      code_to_gid(code) != 0
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
