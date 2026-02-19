module Fontbox::TTF
  # Maps Unicode codepoints to OpenType script tags.
  #
  # Ported in spirit from Apache PDFBox OpenTypeScript; this implementation keeps
  # the same public contract used by GSUB substitution.
  module OpenTypeScript
    INHERITED   = "Inherited"
    UNKNOWN     = "Unknown"
    TAG_DEFAULT = "DFLT"

    private SCRIPT_TO_TAGS = {
      "Common"     => [TAG_DEFAULT],
      INHERITED    => [INHERITED],
      UNKNOWN      => [TAG_DEFAULT],
      "Latin"      => ["latn"],
      "Cyrillic"   => ["cyrl"],
      "Greek"      => ["grek"],
      "Han"        => ["hani"],
      "Hiragana"   => ["kana"],
      "Katakana"   => ["kana"],
      "Arabic"     => ["arab"],
      "Hebrew"     => ["hebr"],
      "Devanagari" => ["dev2", "deva"],
      "Bengali"    => ["bng2", "beng"],
      "Gujarati"   => ["gjr2", "gujr"],
      "Tamil"      => ["tml2", "taml"],
    }

    private SCRIPT_RANGES = {
      "Common"     => [{0x0000, 0x0040}, {0x005B, 0x0060}, {0x007B, 0x00BF}, {0x2000, 0x206F}, {0x3000, 0x303F}],
      INHERITED    => [{0x0300, 0x036F}],
      "Latin"      => [{0x0041, 0x005A}, {0x0061, 0x007A}, {0x00C0, 0x024F}],
      "Greek"      => [{0x0370, 0x03FF}],
      "Cyrillic"   => [{0x0400, 0x052F}],
      "Hebrew"     => [{0x0590, 0x05FF}],
      "Arabic"     => [{0x0600, 0x06FF}],
      "Devanagari" => [{0x0900, 0x097F}],
      "Bengali"    => [{0x0980, 0x09FF}],
      "Gujarati"   => [{0x0A80, 0x0AFF}],
      "Tamil"      => [{0x0B80, 0x0BFF}],
      "Hiragana"   => [{0x3040, 0x309F}],
      "Katakana"   => [{0x30A0, 0x30FF}],
      "Han"        => [{0x3400, 0x4DBF}, {0x4E00, 0x9FFF}],
    }

    def self.get_script_tags(code_point : Int32) : Array(String)
      ensure_valid_code_point(code_point)
      unicode_script = unicode_script_name(code_point)
      SCRIPT_TO_TAGS[unicode_script]? || [TAG_DEFAULT]
    end

    private def self.ensure_valid_code_point(code_point : Int32) : Nil
      if code_point < 0 || code_point > 0x10FFFF
        raise ArgumentError.new("Invalid codepoint: #{code_point}")
      end
    end

    private def self.unicode_script_name(code_point : Int32) : String
      SCRIPT_RANGES.each do |script_name, ranges|
        ranges.each do |range|
          if code_point >= range[0] && code_point <= range[1]
            return script_name
          end
        end
      end
      UNKNOWN
    end
  end
end
