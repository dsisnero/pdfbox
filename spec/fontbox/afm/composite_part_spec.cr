require "../../spec_helper"

describe Fontbox::AFM::CompositePart do
  describe "#initialize" do
    it "sets name, x, y" do
      cp = Fontbox::AFM::CompositePart.new("name", 10, 20)
      cp.name.should eq("name")
      cp.x.should eq(10)
      cp.y.should eq(20)
    end
  end
end