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

  # TODO: Port PDFBox-3997 test when TTFParser is available
  # describe "#testPDFBox3997" do
  #   it "handles unicode above basic multilingual plane" do
  #   end
  # end
end