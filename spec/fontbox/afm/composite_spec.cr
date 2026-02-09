require "../../spec_helper"

describe Fontbox::AFM::Composite do
  describe "#initialize" do
    it "sets name and empty parts" do
      comp = Fontbox::AFM::Composite.new("name")
      comp.name.should eq("name")
      comp.parts.size.should eq(0)
    end
  end

  describe "#add_part" do
    it "adds a composite part" do
      comp = Fontbox::AFM::Composite.new("name")
      part = Fontbox::AFM::CompositePart.new("part", 10, 20)
      comp.add_part(part)
      parts = comp.parts
      parts.size.should eq(1)
      parts[0].name.should eq("part")
      # In Java, the returned list is unmodifiable; we can test that adding raises an error.
      # For now, skip that check.
    end
  end
end
