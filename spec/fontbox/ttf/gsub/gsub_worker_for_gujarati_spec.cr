require "../../../spec_helper"

module Fontbox::TTF::Gsub
  LOHIT_GUJARATI_TTF = "apache_pdfbox/fontbox/src/test/resources/ttf/Lohit-Gujarati.ttf"

  private def self.with_gujarati_font(&)
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(LOHIT_GUJARATI_TTF))
    begin
      yield font
    ensure
      font.close
    end
  end

  private def self.get_gujarati_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe GsubWorkerForGujarati do
    it "testApplyTransforms_akhn" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [330, 331, 304, 251]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "ક્ષજ્ઞત્તશ્ર"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_rphf" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [98, 335]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "ર્સ"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_rkrf" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [242, 228, 250]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "પ્રક્રવ્ર"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_blwf" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [76, 332]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "ટ્ર"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_half" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [205, 195, 206]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "ત્ચ્થ્"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_vatu" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [237, 245, 233]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "ત્રભ્રજ્ર"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_cjct" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [309, 312, 305]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "દ્ધદ્નદ્ય"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_pres" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [284, 294, 314, 315]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "ગ્નટ્ટપ્તલ્લ"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_abvs" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [92, 255, 92, 258, 91, 102, 336]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "રેંરૈંર્યાં"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_blws" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [278, 76, 333, 337, 276]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "હૃટ્રુણુરુ"))
        result.should eq(glyphs_after_gsub)
      end
    end

    # Disabled in Java source: @Disabled
    pending "testApplyTransforms_psts" do
      with_gujarati_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)
        glyphs_after_gsub = [280, 273, 92, 261]
        result = gsub_worker.apply_transforms(get_gujarati_glyph_ids(cmap_lookup, "જીઈંરીં"))
        result.should eq(glyphs_after_gsub)
      end
    end
  end
end
