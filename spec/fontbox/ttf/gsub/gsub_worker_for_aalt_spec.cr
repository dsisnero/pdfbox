require "../../../spec_helper"

module Fontbox::TTF::Gsub
  # GSUB worker to test "aalt" (access all alternates), code is copied from the latin worker except for the features.
  #
  # Ported from Apache PDFBox GsubWorkerForAalt.
  # @author Palash Ray
  # @author Tilman Hausherr
  class GsubWorkerForAalt < GsubWorker
    Log = ::Log.for(self)

    FEATURES_IN_ORDER = ["aalt"]

    @gsub_data : ::Fontbox::TTF::Model::GsubData

    def initialize(gsub_data : ::Fontbox::TTF::Model::GsubData)
      @gsub_data = gsub_data
    end

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      intermediate_glyph_ids = original_glyph_ids

      FEATURES_IN_ORDER.each do |feature|
        unless @gsub_data.is_feature_supported(feature)
          Log.debug { "the feature #{feature} was not found" }
          next
        end

        Log.debug { "applying the feature #{feature}" }
        script_feature = @gsub_data.feature(feature)
        intermediate_glyph_ids = apply_gsub_feature(script_feature, intermediate_glyph_ids)
      end

      ImmutableArray.new(intermediate_glyph_ids)
    end

    private def apply_gsub_feature(script_feature : ::Fontbox::TTF::Model::ScriptFeature,
                                   original_glyphs : Array(Int32)) : Array(Int32)
      if script_feature.all_glyph_ids_for_substitution.empty?
        Log.debug { "get_all_glyph_ids_for_substitution() for #{script_feature.name} is empty" }
        return original_glyphs
      end

      glyph_array_splitter = GlyphArraySplitterRegexImpl.new(
        script_feature.all_glyph_ids_for_substitution)

      tokens = glyph_array_splitter.split(original_glyphs)
      gsub_processed_glyphs = [] of Int32

      tokens.each do |chunk|
        if script_feature.can_replace_glyphs(chunk)
          # gsub system kicks in, you get the glyphId directly
          replacement_for_glyphs = script_feature.replacement_for_glyphs(chunk)
          gsub_processed_glyphs.concat(replacement_for_glyphs)
        else
          gsub_processed_glyphs.concat(chunk)
        end
      end

      Log.debug { "originalGlyphs: #{original_glyphs}, gsubProcessedGlyphs: #{gsub_processed_glyphs}" }

      gsub_processed_glyphs
    end
  end

  FOGLIHTEN_NO07_OTF_AALT = "apache_pdfbox/fontbox/src/test/resources/otf/FoglihtenNo07.otf"

  private def self.with_aalt_font(&)
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(FOGLIHTEN_NO07_OTF_AALT))
    begin
      yield font
    ensure
      font.close
    end
  end

  private def self.get_aalt_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe GsubWorkerForAalt do
    it "testApplyLigaturesFoglihtenNo07" do
      with_aalt_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerForAalt.new(font.gsub_data)

        # Values should be the same you get by looking at the GSUB lookup lists 12 or 13 with
        # a font tool
        expected_glyphs = [1139, 1562, 1477]
        result = gsub_worker.apply_transforms(get_aalt_glyph_ids(cmap_lookup, "Abc"))
        result.should eq(expected_glyphs)
      end
    end
  end
end
