require "../encoding"

module Pdfbox::Pdmodel::Font::Encoding
  # A font's built-in encoding.
  # Corresponds to org.apache.pdfbox.pdmodel.font.encoding.BuiltInEncoding.
  class BuiltInEncoding < Encoding
    def initialize(code_to_name : Hash(Int32, String))
      code_to_name.each do |code, glyph_name|
        add(code, glyph_name)
      end
    end

    def cos_object : Cos::Base
      raise NotImplementedError.new("Built-in encodings cannot be serialized")
    end

    def encoding_name : String
      "built-in (TTF)"
    end
  end
end
