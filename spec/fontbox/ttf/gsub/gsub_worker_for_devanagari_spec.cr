require "../../../spec_helper"

module Fontbox::TTF::Gsub
  LOHIT_DEVANAGARI_TTF = "apache_pdfbox/fontbox/src/test/resources/ttf/Lohit-Devanagari.ttf"

  private def self.with_devanagari_font(&)
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(LOHIT_DEVANAGARI_TTF))
    begin
      yield font
    ensure
      font.close
    end
  end

  private def self.get_devanagari_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.get_glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe GsubWorkerForDevanagari do
    it "testApplyTransforms_locl" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [642]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "प्त"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_nukt" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [400, 396, 393]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "य़ज़क़"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_akhn" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [520, 521]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "क्षज्ञ"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_rphf" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [513]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "र्"))
        result.should eq(glyphs_after_gsub)
      end
    end

    # Disabled in Java source: @Disabled - See PDFBOX-5729 comment
    pending "testApplyTransforms_rkrf" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [588, 597, 595, 602]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "क्रब्रप्रह्र"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_blwf" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [602, 336, 516]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "ह्रट्र"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_half" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [558, 557, 546, 537]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "ह्स्भ्त्"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_vatu" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [517, 593, 601, 665]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "श्रत्रस्रघ्र"))
        result.should eq(glyphs_after_gsub)
      end
    end

    # Disabled in Java source: @Disabled - See PDFBOX-5729 comment
    pending "testApplyTransforms_cjct" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [638, 688, 636, 640, 639]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "द्मद्ध्र्यब्दद्वद्य"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_pres" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [603, 605, 617, 652]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "शृक्तज्जह्ण"))
        result.should eq(glyphs_after_gsub)
      end
    end

    # Disabled in Java source: @Disabled - See PDFBOX-5729 comment
    pending "testApplyTransforms_abvs" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [353, 512, 353, 675, 353, 673]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "र्रैंरौंर्रो"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_blws" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [660, 663, 336, 584, 336, 583]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "दृहृट्रूट्रु"))
        result.should eq(glyphs_after_gsub)
      end
    end

    # Disabled in Java source: @Disabled - See PDFBOX-5729 comment
    pending "testApplyTransforms_psts" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [326, 704, 326, 582, 661, 662]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "किंर्कींरुरू"))
        result.should eq(glyphs_after_gsub)
      end
    end

    it "testApplyTransforms_haln" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [539]
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, "द्"))
        result.should eq(glyphs_after_gsub)
      end
    end

    # Disabled in Java source: @Disabled - See PDFBOX-5729 comment
    pending "testApplyTransforms_calt" do
      with_devanagari_font do |font|
        cmap_lookup = font.get_unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.get_gsub_worker(cmap_lookup, font.get_gsub_data)
        glyphs_after_gsub = [] of Int32
        result = gsub_worker.apply_transforms(get_devanagari_glyph_ids(cmap_lookup, ""))
        result.should eq(glyphs_after_gsub)
      end
    end
  end
end
