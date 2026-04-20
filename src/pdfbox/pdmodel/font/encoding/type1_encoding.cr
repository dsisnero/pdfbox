require "../encoding"

module Pdfbox::Pdmodel::Font::Encoding
  # An encoding for a Type 1 font.
  # Corresponds to org.apache.pdfbox.pdmodel.font.encoding.Type1Encoding.
  class Type1Encoding < Encoding
    def initialize
    end

    def self.from_font_box(fontbox_encoding : Fontbox::Encoding) : self
      encoding = new
      fontbox_encoding.code_to_name_map.each do |code, name|
        encoding.add_mapping(code, name)
      end
      encoding
    end

    def initialize(font_metrics : PDFont::FontMetrics)
      # Crystal FontMetrics currently stores widths by glyph name only.
      # Keep constructor parity with Java for call-site compatibility.
    end

    def cos_object : Cos::Base
      raise NotImplementedError.new("Type1Encoding has no COS serialization")
    end

    def encoding_name : String
      "built-in (Type 1)"
    end

    def add_mapping(code : Int32, name : String) : Nil
      add(code, name)
    end
  end
end
