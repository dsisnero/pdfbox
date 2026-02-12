# DFLT (Default) script-specific implementation of GSUB system.
#
# According to the OpenType specification, a Script table with the script tag 'DFLT' (default)
# is used in fonts to define features that are not script-specific. Applications should use the
# DFLT script table when no script table exists for the specific script of the text being
# processed, or when text lacks a defined script (containing only symbols or punctuation).
#
# This implementation applies common, script-neutral typographic features that work across
# writing systems. The feature order follows standard OpenType recommendations for universal
# glyph substitutions.
#
# Ported from Apache PDFBox GsubWorkerForDflt.
module Fontbox::TTF::Gsub
  class GsubWorkerForDflt < GsubWorker
    Log = ::Log.for(self)

    # Script-neutral features in recommended processing order.
    #
    # * ccmp - Glyph Composition/Decomposition (must be first)
    # * liga - Standard Ligatures
    # * clig - Contextual Ligatures
    # * calt - Contextual Alternates
    #
    # Note: This feature list focuses on common GSUB (substitution) features.
    # GPOS features like 'kern', 'mark', 'mkmk' are handled separately.
    FEATURES_IN_ORDER = ["ccmp", "liga", "clig", "calt"]

    @gsub_data : ::Fontbox::TTF::Model::GsubData

    def initialize(gsub_data : ::Fontbox::TTF::Model::GsubData)
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
        script_feature = @gsub_data.feature(feature)
        intermediate_glyphs_from_gsub = apply_gsub_feature(script_feature, intermediate_glyphs_from_gsub)
      end

      ImmutableArray.new(intermediate_glyphs_from_gsub)
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

      Log.debug { "originalGlyphs: #{original_glyphs} gsubProcessedGlyphs: #{gsub_processed_glyphs}" }

      gsub_processed_glyphs
    end
  end
end
