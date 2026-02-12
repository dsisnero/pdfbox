# Devanagari-specific implementation of GSUB system
#
# Ported from Apache PDFBox GsubWorkerForDevanagari.
module Fontbox::TTF::Gsub
  class GsubWorkerForDevanagari < GsubWorker
    Log = ::Log.for(self)

    RKRF_FEATURE = "rkrf"
    VATU_FEATURE = "vatu"

    # This sequence is very important. This has been taken from
    # https://docs.microsoft.com/en-us/typography/script-development/devanagari
    FEATURES_IN_ORDER = ["locl", "nukt", "akhn", "rphf", RKRF_FEATURE, "blwf", "half", VATU_FEATURE, "cjct", "pres", "abvs", "blws", "psts", "haln", "calt"]

    # Reph glyphs
    REPH_CHARS = ['\u0930', '\u094D']
    # Glyphs to precede reph
    BEFORE_REPH_CHARS = ['\u093E', '\u0940']
    # Devanagari vowel sign I
    BEFORE_HALF_CHAR = '\u093F'

    @cmap_lookup : CmapLookup
    @gsub_data : ::Fontbox::TTF::Model::GsubData
    @reph_glyph_ids : Array(Int32)
    @before_reph_glyph_ids : Array(Int32)
    @before_half_glyph_ids : Array(Int32)

    def initialize(cmap_lookup : CmapLookup, gsub_data : ::Fontbox::TTF::Model::GsubData)
      @cmap_lookup = cmap_lookup
      @gsub_data = gsub_data
      @before_half_glyph_ids = get_before_half_glyph_ids
      @reph_glyph_ids = get_reph_glyph_ids
      @before_reph_glyph_ids = get_before_reph_glyph_ids
    end

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      intermediate_glyphs_from_gsub = adjust_reph_position(original_glyph_ids)
      intermediate_glyphs_from_gsub = reposition_glyphs(intermediate_glyphs_from_gsub)

      FEATURES_IN_ORDER.each do |feature|
        unless @gsub_data.is_feature_supported(feature)
          if feature == RKRF_FEATURE && @gsub_data.is_feature_supported(VATU_FEATURE)
            # Create your own rkrf feature from vatu feature
            intermediate_glyphs_from_gsub = apply_rkrf_feature(
              @gsub_data.get_feature(VATU_FEATURE),
              intermediate_glyphs_from_gsub)
          end
          Log.debug { "the feature #{feature} was not found" }
          next
        end

        Log.debug { "applying the feature #{feature}" }
        script_feature = @gsub_data.get_feature(feature)
        intermediate_glyphs_from_gsub = apply_gsub_feature(script_feature, intermediate_glyphs_from_gsub)
      end

      ImmutableArray.new(intermediate_glyphs_from_gsub)
    end

    private def apply_rkrf_feature(rkrf_glyphs_for_substitution : ::Fontbox::TTF::Model::ScriptFeature,
                                   original_glyph_ids : Array(Int32)) : Array(Int32)
      rkrf_glyph_ids = rkrf_glyphs_for_substitution.get_all_glyph_ids_for_substitution
      if rkrf_glyph_ids.empty?
        Log.debug { "Glyph substitution list for #{rkrf_glyphs_for_substitution.get_name} is empty." }
        return original_glyph_ids
      end

      # Replace this with better implementation to get second GlyphId from rkrf_glyph_ids
      rkrf_replacement = 0
      rkrf_glyph_ids.each do |first_list|
        if first_list.size > 1
          rkrf_replacement = first_list[1]
          break
        end
      end

      if rkrf_replacement == 0
        Log.debug { "Cannot find rkrf candidate. The rkrf_glyph_ids doesn't contain lists of two elements." }
        return original_glyph_ids
      end

      rkrf_list = original_glyph_ids.dup
      (original_glyph_ids.size - 1).downto(2) do |index|
        ra_glyph = original_glyph_ids[index]
        if ra_glyph == @reph_glyph_ids[0]
          virama_glyph = original_glyph_ids[index - 1]
          if virama_glyph == @reph_glyph_ids[1]
            rkrf_list[index - 1] = rkrf_replacement
            rkrf_list.delete_at(index)
          end
        end
      end
      rkrf_list
    end

    private def adjust_reph_position(original_glyph_ids : Array(Int32)) : Array(Int32)
      reph_adjusted_list = original_glyph_ids.dup

      (0...original_glyph_ids.size - 2).each do |index|
        ra_glyph = original_glyph_ids[index]
        virama_glyph = original_glyph_ids[index + 1]
        if ra_glyph == @reph_glyph_ids[0] && virama_glyph == @reph_glyph_ids[1]
          next_consonant_glyph = original_glyph_ids[index + 2]
          reph_adjusted_list[index] = next_consonant_glyph
          reph_adjusted_list[index + 1] = ra_glyph
          reph_adjusted_list[index + 2] = virama_glyph

          if index + 3 < original_glyph_ids.size
            matra_glyph = original_glyph_ids[index + 3]
            if @before_reph_glyph_ids.includes?(matra_glyph)
              reph_adjusted_list[index + 1] = matra_glyph
              reph_adjusted_list[index + 2] = ra_glyph
              reph_adjusted_list[index + 3] = virama_glyph
            end
          end
        end
      end
      reph_adjusted_list
    end

    private def reposition_glyphs(original_glyph_ids : Array(Int32)) : Array(Int32)
      repositioned_glyph_ids = original_glyph_ids.dup
      list_size = repositioned_glyph_ids.size
      found_index = list_size - 1
      next_index = list_size - 2

      while next_index > -1
        glyph = repositioned_glyph_ids[found_index]
        prev_index = found_index + 1
        if @before_half_glyph_ids.includes?(glyph)
          repositioned_glyph_ids.delete_at(found_index)
          repositioned_glyph_ids.insert(next_index, glyph)
          next_index -= 1
        elsif @reph_glyph_ids[1] == glyph && prev_index < list_size
          prev_glyph = repositioned_glyph_ids[prev_index]
          if @before_half_glyph_ids.includes?(prev_glyph)
            repositioned_glyph_ids.delete_at(prev_index)
            repositioned_glyph_ids.insert(next_index, prev_glyph)
            next_index -= 1
          end
        end
        found_index = next_index
        next_index -= 1
      end
      repositioned_glyph_ids
    end

    private def apply_gsub_feature(script_feature : ::Fontbox::TTF::Model::ScriptFeature,
                                   original_glyphs : Array(Int32)) : Array(Int32)
      all_glyph_ids_for_substitution = script_feature.get_all_glyph_ids_for_substitution
      if all_glyph_ids_for_substitution.empty?
        Log.debug { "get_all_glyph_ids_for_substitution() for #{script_feature.get_name} is empty" }
        return original_glyphs
      end

      glyph_array_splitter = GlyphArraySplitterRegexImpl.new(all_glyph_ids_for_substitution)
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

    private def get_before_half_glyph_ids : Array(Int32)
      [get_glyph_id(BEFORE_HALF_CHAR)]
    end

    private def get_reph_glyph_ids : Array(Int32)
      REPH_CHARS.map { |char| get_glyph_id(char) }
    end

    private def get_before_reph_glyph_ids : Array(Int32)
      BEFORE_REPH_CHARS.map { |char| get_glyph_id(char) }
    end

    private def get_glyph_id(character : Char) : Int32
      @cmap_lookup.get_glyph_id(character.ord)
    end
  end
end
