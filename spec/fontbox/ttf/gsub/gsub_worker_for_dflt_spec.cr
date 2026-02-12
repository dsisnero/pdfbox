module Fontbox::TTF::Gsub
  JOSEFIN_SANS_TTF = "apache_pdfbox/fontbox/src/test/resources/ttf/JosefinSans-Italic.ttf"

  private def self.with_dflt_font(&)
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(JOSEFIN_SANS_TTF))
    begin
      yield font
    ensure
      font.close
    end
  end

  private def self.get_dflt_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.get_glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe GsubWorkerForDflt do
    it "testCorrectWorkerType" do
      with_dflt_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        gsub_worker.should be_a(GsubWorkerForDflt)
      end
    end

    it "testApplyTransforms_code" do
      with_dflt_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [229, 293, 235, 237]
        result = gsub_worker.apply_transforms(get_dflt_glyph_ids(cmap_lookup, "code"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_fi" do
      with_dflt_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [407]
        result = gsub_worker.apply_transforms(get_dflt_glyph_ids(cmap_lookup, "fi"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_office" do
      with_dflt_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [293, 257, 407, 229, 237]
        result = gsub_worker.apply_transforms(get_dflt_glyph_ids(cmap_lookup, "office"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_ffl" do
      with_dflt_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [257, 408]
        result = gsub_worker.apply_transforms(get_dflt_glyph_ids(cmap_lookup, "ffl"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_immutableResult" do
      with_dflt_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        result = gsub_worker.apply_transforms(get_dflt_glyph_ids(cmap_lookup, "abc"))

        result.should be_a(ImmutableArray(Int32))

        expect_raises(Exception) do
          result << 999
        end

        expect_raises(Exception) do
          result.delete_at(0)
        end
      end
    end
  end
end
