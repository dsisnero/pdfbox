require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSDictionary.java
#     getCOSArray(COSName), getCOSName(COSName), getCOSStream(COSName),
#     getKeyForValue(Object). Upstream has no dedicated test; this is a
#     characterization spec.
module Pdfbox
  module Cos
    describe Dictionary do
      it "returns typed values for get_cos_array / get_cos_name / get_cos_stream" do
        dict = Dictionary.new
        arr = Array.new
        stream = Stream.new(entries: {} of Name => Base, data: Bytes[1, 2])

        dict[Name.new("Arr")] = arr
        dict[Name.new("Nm")] = Name.new("Foo")
        dict[Name.new("St")] = stream
        dict[Name.new("Int")] = Integer.new(5)

        dict.get_cos_array(Name.new("Arr")).should eq(arr)
        dict.get_cos_name(Name.new("Nm")).should eq(Name.new("Foo"))
        dict.get_cos_stream(Name.new("St")).should eq(stream)
      end

      it "returns nil when the value is not of the requested type" do
        dict = Dictionary.new
        arr = Array.new
        dict[Name.new("Arr")] = arr
        dict[Name.new("Nm")] = Name.new("Foo")
        dict[Name.new("Int")] = Integer.new(5)

        dict.get_cos_array(Name.new("Nm")).should be_nil
        dict.get_cos_name(Name.new("Arr")).should be_nil
        dict.get_cos_stream(Name.new("Int")).should be_nil
        dict.get_cos_array(Name.new("Missing")).should be_nil
      end

      it "finds the key that holds a given value" do
        dict = Dictionary.new
        dict[Name.new("A")] = Integer.new(1)
        dict[Name.new("B")] = Integer.new(2)

        dict.get_key_for_value(Integer.new(2)).should eq(Name.new("B"))
        dict.get_key_for_value(Integer.new(99)).should be_nil
      end

      it "iterates over name/value entries" do
        dict = Dictionary.new
        dict[Name.new("A")] = Integer.new(1)
        dict[Name.new("B")] = Integer.new(2)

        pairs = [] of Tuple(Name, Base)
        dict.each { |name, base| pairs << {name, base} }

        pairs.map(&.[0]).should eq([Name.new("A"), Name.new("B")])
      end
    end
  end
end
