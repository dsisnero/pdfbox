require "../../../spec_helper"

module Fontbox::TTF::Gsub
  LOHIT_BENGALI_TTF = "apache_pdfbox/fontbox/src/test/resources/ttf/Lohit-Bengali.ttf"

  private def self.with_bengali_font(&)
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(LOHIT_BENGALI_TTF))
    begin
      yield font
    ensure
      font.close
    end
  end

  private def self.get_bengali_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.get_glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe GsubWorkerForBengali do
    it "testApplyTransforms_simple_hosshoi_kar" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [56, 102, 91]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "আমি"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_ja_phala" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [89, 156, 101, 97]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "ব্যাস"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_e_kar" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [438, 89, 94, 101]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "বেলা"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_o_kar" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [108, 89, 101, 97]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "বোস"))
        result.should eq(glyphs_after_gsub)
      end
    end

    pending "testApplyTransforms_o_kar_repeated_1_not_working_yet" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [108, 96, 101, 108, 94, 101]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "ষোলো"))
        result.should eq(glyphs_after_gsub)
      end
    end

    pending "testApplyTransforms_o_kar_repeated_2_not_working_yet" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [108, 73, 101, 108, 77, 101]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "ছোটো"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_ou_kar" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [108, 91, 114, 94]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "মৌল"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_oi_kar" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [439, 89, 93]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "বৈর"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_kha_e_murddhana_swa_e_khiwa" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [167, 103, 438, 93, 93]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "ক্ষীরের"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_ra_phala" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [274, 82]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "দ্রুত"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_ref" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [85, 104, 440, 82]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "ধুর্ত"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_ra_e_hosshu" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [352, 108, 87, 101]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "রুপো"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_la_e_la_e" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [67, 108, 369, 101, 94]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "কল্লোল"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_khanda_ta" do
      with_bengali_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [98, 78, 101, 113]
        result = gsub_worker.apply_transforms(get_bengali_glyph_ids(cmap_lookup, "হঠাৎ"))
        result.should eq(glyphs_after_gsub)
      end
    end
  end
end
