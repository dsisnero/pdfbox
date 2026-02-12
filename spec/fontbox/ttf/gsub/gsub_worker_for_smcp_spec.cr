require "../../../spec_helper"

module Fontbox::TTF::Gsub
  # GSUB worker to test "smcp" (small caps), code is copied from the latin worker except for the features.
  #
  # Ported from Apache PDFBox GsubWorkerForSmcp.
  # @author Palash Ray
  # @author Tilman Hausherr
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
      intermediate_glyph_ids = original_glyph_ids

      FEATURES_IN_ORDER.each do |feature|
        unless @gsub_data.is_feature_supported(feature)
          Log.debug { "the feature #{feature} was not found" }
          next
        end

        Log.debug { "applying the feature #{feature}" }
        script_feature = @gsub_data.get_feature(feature)
        intermediate_glyph_ids = apply_gsub_feature(script_feature, intermediate_glyph_ids)
      end

      ImmutableArray.new(intermediate_glyph_ids)
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

  private def self.get_smcp_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.get_glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe GsubWorkerForSmcp do
    calibri_path = "/usr/share/fonts/truetype/msttcorefonts/Calibri.ttf" # Common Linux path
    # Alternative Windows path: "c:/windows/fonts/calibri.ttf"
    if File.exists?(calibri_path)
      it "testCalibri" do
        font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(calibri_path))
        begin
          cmap_lookup = font.unicode_cmap_lookup
          gsub_worker = GsubWorkerForSmcp.new(cmap_lookup, font.gsub_data)

          # Values should be the same you get by looking at the GSUB lookup list 24 with a font tool
          # This one converts "ﬀ" (single-ff-ligature glyph) into "FF" small capitals
          expected_glyphs = [165, 165]
          # Note: \ufb00 is the Unicode character for "ﬀ" (Latin small ligature ff)
          result = gsub_worker.apply_transforms(get_smcp_glyph_ids(cmap_lookup, "\ufb00"))
          result.should eq(expected_glyphs)
        ensure
          font.close
        end
      end
    else
      # Pending due to missing Calibri font (system-dependent)
      pending "testCalibri" do
        # Font not available, test skipped
      end
    end
  end
end
