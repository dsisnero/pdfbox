# Tamil-specific implementation of GSUB system.
#
# Ported from Apache PDFBox GsubWorkerForTamil.
# TODO: The existing code has been copied from Gujarati and needs adjustment.
module Fontbox::TTF::Gsub
  class GsubWorkerForTamil < GsubWorker
    Log = ::Log.for(self)

    # This sequence is very important. This has been taken from
    # https://docs.microsoft.com/en-us/typography/script-development/tamil
    FEATURES_IN_ORDER = ["locl", "nukt", "akhn", "rphf", "pref", "half", "pres", "abvs", "blws", "psts", "haln", "calt"]

    # Reph glyphs
    REPH_CHARS = ['\u0BB0', '\u0BCD']
    # Glyphs to precede reph
    BEFORE_REPH_CHARS = ['\u0BB8', '\u0BCD']
    # Tamil vowel sign I (corrected from Gujarati \u0ABF to Tamil \u0BBF)
    BEFORE_HALF_CHAR = '\u0BBF'

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
          Log.debug { "the feature #{feature} was not found" }
          next
        end

        Log.debug { "applying the feature #{feature}" }
        script_feature = @gsub_data.get_feature(feature)
        intermediate_glyphs_from_gsub = apply_gsub_feature(script_feature, intermediate_glyphs_from_gsub)
      end

      intermediate_glyphs_from_gsub
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

    private def adjust_reph_position(original_glyph_ids : Array(Int32)) : Array(Int32)
      reph_adjusted_list = original_glyph_ids.dup

      (0...original_glyph_ids.size - 2).each do |index|
        ra_glyph = original_glyph_ids[index]
        virama_glyph = original_glyph_ids[index + 1]
        if ra_glyph == @reph_glyph_ids[0] && virama_glyph == @reph_glyph_ids[1]
          # reph virama cons => cons reph virama
          next_consonant_glyph = original_glyph_ids[index + 2]
          reph_adjusted_list[index] = next_consonant_glyph
          reph_adjusted_list[index + 1] = ra_glyph
          reph_adjusted_list[index + 2] = virama_glyph

          if index + 3 < original_glyph_ids.size
            # reph virama cons matra => cons matra reph virama
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
