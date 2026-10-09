require "../../spec_helper"

describe Fontbox::CMap::CMap do
  describe "#add_char_mapping and #to_unicode" do
    it "maps byte array to unicode string" do
      bytes = [200_u8]
      cmap = Fontbox::CMap::CMap.new
      cmap.add_char_mapping(bytes, "a")
      cmap.to_unicode(bytes).should eq "a"
    end
  end

  # PDFBOX-3997: unicode above the basic multilingual plane (helicopter).
  describe "#testPDFBox3997" do
    it "looks up a glyph id above the basic multilingual plane" do
      path = SpecPaths.resolve("spec/resources/fontbox/cmap/NotoEmoji-Regular.ttf").to_s
      ttf = Fontbox::TTF::TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(path))
      begin
        cmap = ttf.unicode_cmap_lookup(false)
        cmap.glyph_id(0x1F681).should eq(886)
      ensure
        ttf.close
      end
    end
  end
end
