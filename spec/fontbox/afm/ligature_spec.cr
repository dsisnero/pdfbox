require "../../spec_helper"

describe Fontbox::AFM::Ligature do
  describe "#initialize" do
    it "sets successor and ligature" do
      lig = Fontbox::AFM::Ligature.new("successor", "ligature")
      lig.successor.should eq("successor")
      lig.ligature.should eq("ligature")
    end
  end
end