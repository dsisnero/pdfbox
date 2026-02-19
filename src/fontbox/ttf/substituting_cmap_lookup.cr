module Fontbox::TTF
  # A cmap lookup that performs substitution via the GSUB table.
  #
  # Ported from Apache PDFBox SubstitutingCmapLookup.
  class SubstitutingCmapLookup
    include CmapLookup

    @cmap : CmapSubtable
    @gsub : GlyphSubstitutionTable
    @enabled_features : Array(String)

    def initialize(@cmap : CmapSubtable, @gsub : GlyphSubstitutionTable, @enabled_features : Array(String))
    end

    def glyph_id(character_code : Int32) : Int32
      gid = @cmap.glyph_id(character_code)
      script_tags = OpenTypeScript.get_script_tags(character_code)
      @gsub.substitution(gid, script_tags, @enabled_features)
    end

    def char_codes(gid : Int32) : Array(Int32)?
      @cmap.char_codes(@gsub.unsubstitution(gid))
    end
  end
end
