require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSDictionary.java
#     getObjectFromPath(String) — splits on "/", resolves dictionary keys with
#     getDictionaryObject and array indexes with getObject.
# Upstream has no dedicated test; this is a characterization spec.
module Pdfbox
  module Cos
    describe Dictionary do
      it "get_object_from_path navigates dictionaries and array indexes" do
        inner = Dictionary.new
        inner[Name.new("C")] = Integer.new(42)

        pairs = Array.new
        pairs.add(inner)

        root = Dictionary.new
        root[Name.new("A")] = pairs

        result = root.get_object_from_path("A/0/C")
        result.should be_a(Integer)
        result.as(Integer).value.should eq(42)
      end

      it "get_object_from_path strips escaped brackets from array indexes" do
        inner = Dictionary.new
        inner[Name.new("C")] = Integer.new(7)

        pairs = Array.new
        pairs.add(inner)

        root = Dictionary.new
        root[Name.new("A")] = pairs

        result = root.get_object_from_path("A/\\[0\\]/C")
        result.should be_a(Integer)
        result.as(Integer).value.should eq(7)
      end

      it "get_object_from_path dereferences indirect objects" do
        inner = Dictionary.new
        inner[Name.new("D")] = String.new("hi")

        root = Dictionary.new
        root[Name.new("X")] = Object.new(inner)

        result = root.get_object_from_path("X/D")
        result.should be_a(String)
        result.as(String).value.should eq("hi")
      end

      it "get_object_from_path returns nil for a missing path" do
        Dictionary.new.get_object_from_path("A/B").should be_nil
      end
    end
  end
end
