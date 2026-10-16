require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/fontbox/src/main/java/org/apache/fontbox/cff/CFFOperator.java
# The operator registry maps a one- or two-byte operator encoding to its name
# (key = (b1 << 8) + b0). Upstream has no dedicated test; this is a
# characterization spec.
describe Fontbox::CFF::CFFOperator do
  it "resolves single-byte DICT operators" do
    Fontbox::CFF::CFFOperator.get_operator(0).should eq("version")
    Fontbox::CFF::CFFOperator.get_operator(1).should eq("Notice")
    Fontbox::CFF::CFFOperator.get_operator(5).should eq("FontBBox")
    Fontbox::CFF::CFFOperator.get_operator(15).should eq("charset")
    Fontbox::CFF::CFFOperator.get_operator(17).should eq("CharStrings")
    Fontbox::CFF::CFFOperator.get_operator(18).should eq("Private")
  end

  it "resolves two-byte (escape 12) operators" do
    Fontbox::CFF::CFFOperator.get_operator(12, 0).should eq("Copyright")
    Fontbox::CFF::CFFOperator.get_operator(12, 7).should eq("FontMatrix")
    Fontbox::CFF::CFFOperator.get_operator(12, 30).should eq("ROS")
    Fontbox::CFF::CFFOperator.get_operator(12, 38).should eq("FontName")
  end

  it "resolves single-byte private DICT operators" do
    Fontbox::CFF::CFFOperator.get_operator(6).should eq("BlueValues")
    Fontbox::CFF::CFFOperator.get_operator(10).should eq("StdHW")
    Fontbox::CFF::CFFOperator.get_operator(19).should eq("Subrs")
    Fontbox::CFF::CFFOperator.get_operator(21).should eq("nominalWidthX")
  end

  it "returns nil for unknown operators" do
    Fontbox::CFF::CFFOperator.get_operator(200).should be_nil
    Fontbox::CFF::CFFOperator.get_operator(12, 99).should be_nil
  end
end
