# Bengali-specific implementation of GSUB system
#
# Ported from Apache PDFBox GsubWorkerForBengali.
module Fontbox::TTF::Gsub
  class GsubWorkerForBengali < GsubWorker
    Log = ::Log.for(self)

    INIT_FEATURE = "init"

    # This sequence is very important. This has been taken from
    # https://docs.microsoft.com/en-us/typography/script-development/bengali
    FEATURES_IN_ORDER = ["locl", "nukt", "akhn", "rphf", "blwf", "pstf", "half", "vatu", "cjct", INIT_FEATURE, "pres", "abvs", "blws", "psts", "haln", "calt"]

    BEFORE_HALF_CHARS = ['\u09BF', '\u09C7', '\u09C8']

    private record BeforeAndAfterSpanComponent,
      original_character : Char,
      before_component_character : Char,
      after_component_character : Char

    BEFORE_AND_AFTER_SPAN_CHARS = [
      BeforeAndAfterSpanComponent.new('\u09CB', '\u09C7', '\u09BE'),
      BeforeAndAfterSpanComponent.new('\u09CC', '\u09C7', '\u09D7'),
    ]

    @cmap_lookup : CmapLookup
    @gsub_data : ::Fontbox::TTF::Model::GsubData
    @before_half_glyph_ids : Array(Int32)
    @before_and_after_span_glyph_ids : Hash(Int32, BeforeAndAfterSpanComponent)

    def initialize(cmap_lookup : CmapLookup, gsub_data : ::Fontbox::TTF::Model::GsubData)
      @cmap_lookup = cmap_lookup
      @gsub_data = gsub_data
      @before_half_glyph_ids = get_before_half_glyph_ids
      @before_and_after_span_glyph_ids = get_before_and_after_span_glyph_ids
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

      reposition_glyphs(intermediate_glyphs_from_gsub)
    end

    private def reposition_glyphs(original_glyph_ids : Array(Int32)) : Array(Int32)
      glyphs_repositioned_by_before_half = reposition_before_half_glyph_ids(original_glyph_ids)
      reposition_before_and_after_span_glyph_ids(glyphs_repositioned_by_before_half)
    end

    private def reposition_before_half_glyph_ids(original_glyph_ids : Array(Int32)) : Array(Int32)
      repositioned_glyph_ids = original_glyph_ids.dup

      (1...original_glyph_ids.size).each do |index|
        glyph_id = original_glyph_ids[index]
        if @before_half_glyph_ids.includes?(glyph_id)
          previous_glyph_id = original_glyph_ids[index - 1]
          repositioned_glyph_ids[index] = previous_glyph_id
          repositioned_glyph_ids[index - 1] = glyph_id
        end
      end
      repositioned_glyph_ids
    end

    private def reposition_before_and_after_span_glyph_ids(original_glyph_ids : Array(Int32)) : Array(Int32)
      repositioned_glyph_ids = original_glyph_ids.dup

      (1...original_glyph_ids.size).each do |index|
        glyph_id = original_glyph_ids[index]
        before_and_after_span_component = @before_and_after_span_glyph_ids[glyph_id]?
        if before_and_after_span_component
          previous_glyph_id = original_glyph_ids[index - 1]
          repositioned_glyph_ids[index] = previous_glyph_id
          repositioned_glyph_ids[index - 1] = get_glyph_id(before_and_after_span_component.before_component_character)
          repositioned_glyph_ids.insert(index + 1, get_glyph_id(before_and_after_span_component.after_component_character))
        end
      end
      repositioned_glyph_ids
    end

    private def apply_gsub_feature(script_feature : ::Fontbox::TTF::Model::ScriptFeature,
                                   original_glyphs : Array(Int32)) : Array(Int32)
      all_glyph_ids_for_substitution = script_feature.get_all_glyph_ids_for_substitution
      if all_glyph_ids_for_substitution.empty?
        # not stopping here results in really weird output, the regex goes wild
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
      glyph_ids = BEFORE_HALF_CHARS.map { |char| get_glyph_id(char) }

      if @gsub_data.is_feature_supported(INIT_FEATURE)
        feature = @gsub_data.get_feature(INIT_FEATURE)
        feature.get_all_glyph_ids_for_substitution.each do |glyph_cluster|
          glyph_ids.concat(feature.get_replacement_for_glyphs(glyph_cluster))
        end
      end

      glyph_ids
    end

    private def get_glyph_id(character : Char) : Int32
      @cmap_lookup.get_glyph_id(character.ord)
    end

    private def get_before_and_after_span_glyph_ids : Hash(Int32, BeforeAndAfterSpanComponent)
      result = {} of Int32 => BeforeAndAfterSpanComponent

      BEFORE_AND_AFTER_SPAN_CHARS.each do |component|
        result[get_glyph_id(component.original_character)] = component
      end

      result
    end
  end
end
