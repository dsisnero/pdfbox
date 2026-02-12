require "../../../spec_helper"

module Fontbox::TTF::Gsub
  private def self.with_foglihten_font_latin(&)
    font_path = "apache_pdfbox/fontbox/src/test/resources/otf/FoglihtenNo07.otf"
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))
    begin
      yield font
    ensure
      font.close
    end
  end

  private def self.get_latin_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.get_glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe GsubWorkerForLatin do
    calibri_path = "c:/windows/fonts/calibri.ttf"
    if File.exists?(calibri_path)
      it "testApplyLigaturesCalibri" do
        font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(calibri_path))
        begin
          cmap_lookup = font.unicode_cmap_lookup
          gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.gsub_data)

          gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "effective")).should eq([286, 299, 286, 272, 415, 448, 286])
          gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "attitude")).should eq([258, 427, 410, 437, 282, 286])
          gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "affiliate")).should eq([258, 312, 367, 349, 258, 410, 286])
          gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "film")).should eq([302, 367, 373])
          gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "float")).should eq([327, 381, 258, 410])
          gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "platform")).should eq([393, 367, 258, 414, 381, 396, 373])
        ensure
          font.close
        end
      end
    else
      # Pending due to missing Calibri font (system-dependent)
      pending "testApplyLigaturesCalibri" do
        # Font not available, test skipped
      end
    end

    it "testApplyLigaturesFoglihtenNo07" do
      with_foglihten_font_latin do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.gsub_data)

        gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "affine")).should eq([66, 1590, 645, 70])
        gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "attitude")).should eq([538, 633, 85, 86, 69, 70])
        gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "affiliate")).should eq([66, 1590, 525, 74, 683])
        gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "The film")).should eq([542, 1, 1591, 498])
        gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "The Last")).should eq([542, 1, 45, 703, 85])
        gsub_worker.apply_transforms(get_latin_glyph_ids(cmap_lookup, "platform")).should eq([81, 77, 538, 71, 80, 83, 78])
      end
    end
  end
end
