module Pdfbox::Util
  # Ported from Apache PDFBox StringUtil.
  module StringUtil
    PATTERN_SPACE = /\s/

    # Split on whitespace using Java Pattern.split semantics:
    # keep empty tokens between delimiters, drop trailing empty tokens.
    def self.split_on_space(s : String) : Array(String)
      return [s] if s.empty?

      tokens = [] of String
      current = ""

      s.each_char do |char|
        if char.whitespace?
          tokens << current
          current = ""
        else
          current += char
        end
      end
      tokens << current

      while !tokens.empty? && tokens.last.empty?
        tokens.pop
      end

      tokens
    end

    # Split at whitespace but keep delimiters as individual tokens.
    def self.tokenize_on_space(s : String) : Array(String)
      return [s] if s.empty?

      tokens = [] of String
      current = ""

      s.each_char do |char|
        if char.whitespace?
          tokens << current unless current.empty?
          tokens << char.to_s
          current = ""
        else
          current += char
        end
      end

      tokens << current unless current.empty?
      tokens
    end
  end
end
