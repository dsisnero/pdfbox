require "../../spec_helper"

module Fontbox::TTF
  describe WGL4Names do
    it "test_all_names" do
      all_names = WGL4Names.get_all_names
      all_names.should_not be_nil
      all_names.size.should eq WGL4Names::NUMBER_OF_MAC_GLYPHS
    end

    it "test_get_glyph_name" do
      WGL4Names.get_glyph_name(0).should eq ".notdef"
      WGL4Names.get_glyph_name(32).should eq "equal"
      WGL4Names.get_glyph_name(75).should eq "h"
      WGL4Names.get_glyph_name(201).should eq "Aacute"
      WGL4Names.get_glyph_name(209).should eq "Ocircumflex"
      WGL4Names.get_glyph_name(256).should eq "ccaron"
      WGL4Names.get_glyph_name(WGL4Names::NUMBER_OF_MAC_GLYPHS + 1).should be_nil
      WGL4Names.get_glyph_name(-1).should be_nil
    end

    it "test_glyph_indices" do
      WGL4Names.get_glyph_index(".notdef").should eq 0
      WGL4Names.get_glyph_index("equal").should eq 32
      WGL4Names.get_glyph_index("h").should eq 75
      WGL4Names.get_glyph_index("Aacute").should eq 201
      WGL4Names.get_glyph_index("Ocircumflex").should eq 209
      WGL4Names.get_glyph_index("ccaron").should eq 256
      WGL4Names.get_glyph_index("INVALID").should be_nil
    end
  end
end
