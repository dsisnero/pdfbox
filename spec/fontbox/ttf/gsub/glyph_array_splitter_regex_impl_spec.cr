module Fontbox::TTF::Gsub
  describe GlyphArraySplitterRegexImpl do
    it "testSplit_1" do
      matchers = Set{
        [84, 93],
        [102, 82],
        [104, 87],
      }
      splitter = GlyphArraySplitterRegexImpl.new(matchers)
      glyph_ids = [84, 112, 93, 104, 82, 61, 96, 102, 93, 104, 87, 110]

      tokens = splitter.split(glyph_ids)

      tokens.should eq([
        [84, 112, 93, 104, 82, 61, 96, 102, 93],
        [104, 87],
        [110],
      ])
    end

    it "testSplit_2" do
      matchers = Set{
        [67, 112, 96],
        [74, 112, 76],
      }
      splitter = GlyphArraySplitterRegexImpl.new(matchers)
      glyph_ids = [67, 112, 96, 103, 93, 108, 93]

      tokens = splitter.split(glyph_ids)

      tokens.should eq([
        [67, 112, 96],
        [103, 93, 108, 93],
      ])
    end

    it "testSplit_3" do
      matchers = Set{
        [67, 112, 96],
        [74, 112, 76],
      }
      splitter = GlyphArraySplitterRegexImpl.new(matchers)
      glyph_ids = [94, 67, 112, 96, 112, 91, 103]

      tokens = splitter.split(glyph_ids)

      tokens.should eq([
        [94],
        [67, 112, 96],
        [112, 91, 103],
      ])
    end

    it "testSplit_4" do
      matchers = Set{
        [67, 112],
        [76, 112],
      }
      splitter = GlyphArraySplitterRegexImpl.new(matchers)
      glyph_ids = [94, 167, 112, 91, 103]

      tokens = splitter.split(glyph_ids)

      tokens.should eq([
        [94, 167, 112, 91, 103],
      ])
    end
  end
end
