# GSUB worker to test "smcp" (small caps), code is copied from the latin worker except for the features.
#
# Ported from Apache PDFBox GsubWorkerForSmcp.
# @author Palash Ray
# @author Tilman Hausherr
module Fontbox::TTF::Gsub
  class GsubWorkerForSmcp < GsubWorker
    Log = ::Log.for(self)

    FEATURES_IN_ORDER = ["smcp"]

    @cmap_lookup : CmapLookup
    @gsub_data : ::Fontbox::TTF::Model::GsubData

    def initialize(cmap_lookup : CmapLookup, gsub_data : ::Fontbox::TTF::Model::GsubData)
      @cmap_lookup = cmap_lookup
      @gsub_data = gsub_data
    end

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      intermediate_glyphs_from_gsub = original_glyph_ids

      FEATURES_IN_ORDER.each do |feature|
        unless @gsub_data.is_feature_supported(feature)
          Log.debug { "the feature #{feature} was not found" }
          next
        end

        Log.debug { "applying the feature #{feature}" }
        script_feature = @gsub_data.get_feature(feature)
        intermediate_glyphs_from_gsub = apply_gsub_feature(script_feature, intermediate_glyphs_from_gsub)
      end

      ImmutableArray.new(intermediate_glyphs_from_gsub)
    end

    private def apply_gsub_feature(script_feature : ::Fontbox::TTF::Model::ScriptFeature,
                                   original_glyphs : Array(Int32)) : Array(Int32)
      if script_feature.get_all_glyph_ids_for_substitution.empty?
        Log.debug { "get_all_glyph_ids_for_substitution() for #{script_feature.get_name} is empty" }
        return original_glyphs
      end

      glyph_array_splitter = GlyphArraySplitterRegexImpl.new(
        script_feature.get_all_glyph_ids_for_substitution)

      tokens = glyph_array_splitter.split(original_glyphs)
      gsub_processed_glyphs = [] of Int32

      tokens.each do |chunk|
        if script_feature.can_replace_glyphs(chunk)
          # gsub system kicks in, you get the glyphId directly
          replacement_for_glyphs = script_feature.get_replacement_for_glyphs(chunk)
          gsub_processed_glyphs.concat(replacement_for_glyphs)
        else
          gsub_processed_glyphs.concat(chunk)
        end
      end

      Log.debug { "originalGlyphs: #{original_glyphs}, gsubProcessedGlyphs: #{gsub_processed_glyphs}" }

      gsub_processed_glyphs
    end
  end
end
