module Fontbox::TTF::Gsub
  LOHIT_TAMIL_TTF = "apache_pdfbox/fontbox/src/test/resources/ttf/Lohit-Tamil.ttf"

  private def self.with_tamil_font(&)
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(LOHIT_TAMIL_TTF))
    begin
      yield font
    ensure
      font.close
    end
  end

  private def self.get_tamil_glyph_ids(cmap_lookup, word : String) : Array(Int32)
    original_glyph_ids = [] of Int32
    word.each_char do |unicode_char|
      glyph_id = cmap_lookup.glyph_id(unicode_char.ord)
      glyph_id.should be > 0
      original_glyph_ids << glyph_id
    end
    original_glyph_ids
  end

  describe "GsubWorkerForTamil" do
    it "testDummy" do
      with_tamil_font do |font|
        cmap_lookup = font.unicode_cmap_lookup
        gsub_worker = GsubWorkerFactory.new.gsub_worker(cmap_lookup, font.gsub_data)

        # Java test expects DefaultGsubWorker because Tamil worker is not fully implemented
        # (has TODO comment in Java source)
        gsub_worker.should be_a(DefaultGsubWorker)
      end
    end
  end
end
