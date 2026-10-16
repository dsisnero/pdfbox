require "../../../../spec_helper"
require "../../../../../src/pdfbox"

module Pdfbox::Pdmodel::Interactive::Form
  # Characterization spec for FieldUtils.java (a package-private helper used by
  # PDChoice; upstream has no dedicated test).
  describe FieldUtils do
    it "builds key/value pairs and stringifies them" do
      pairs = FieldUtils.to_key_value_list(["a", "b"], ["1", "2"])
      pairs.size.should eq(2)
      pairs[0].key.should eq("a")
      pairs[0].value.should eq("1")
      pairs[0].to_s.should eq("(a, 1)")
    end

    it "sorts pairs by key and by value" do
      pairs = FieldUtils.to_key_value_list(["b", "a", "c"], ["2", "3", "1"])
      FieldUtils.sort_by_key(pairs)
      pairs.map(&.key).should eq(["a", "b", "c"])
      FieldUtils.sort_by_value(pairs)
      pairs.map(&.value).should eq(["1", "2", "3"])
    end

    it "returns pairable items from a COSString for either index" do
      items = Pdfbox::Cos::String.new("only")
      FieldUtils.get_pairable_items(items, 0).should eq(["only"])
      FieldUtils.get_pairable_items(items, 1).should eq(["only"])
    end

    it "returns pairable items from a COSArray of strings and two-element arrays" do
      arr = Pdfbox::Cos::Array.new
      arr.add(Pdfbox::Cos::String.new("s1"))
      pair = Pdfbox::Cos::Array.new
      pair.add(Pdfbox::Cos::String.new("disp"))
      pair.add(Pdfbox::Cos::String.new("exp"))
      arr.add(pair)

      FieldUtils.get_pairable_items(arr, 0).should eq(["s1", "disp"])
      FieldUtils.get_pairable_items(arr, 1).should eq(["s1", "exp"])
    end

    it "returns empty for nil/other input and raises on a bad pair index" do
      FieldUtils.get_pairable_items(nil, 0).should eq([] of String)
      expect_raises(ArgumentError) do
        FieldUtils.get_pairable_items(Pdfbox::Cos::String.new("x"), 2)
      end
    end
  end
end
