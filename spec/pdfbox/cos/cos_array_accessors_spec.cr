require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSArray.java
#     setFloatArray / indexOfObject / isEmpty / of(float...). Upstream has no
#     dedicated test; this is a characterization spec.
module Pdfbox
  module Cos
    describe Array do
      it "set_float_array replaces the elements in place, requiring a matching size" do
        arr = Array.new([Float.new(1.0), Float.new(2.0)])

        arr.set_float_array([10.0, 20.0])
        arr.to_float_array.should eq([10.0, 20.0])
        arr.size.should eq(2)

        expect_raises(ArgumentError, "Array size does not match") do
          arr.set_float_array([1.0])
        end
      end

      it "index_of_object compares by identity while index_of compares by equality" do
        a = Integer.new(5_i64)
        b = Integer.new(5_i64)
        arr = Array.new([a, b])

        arr.index_of(Integer.new(5_i64)).should eq(0)
        arr.index_of_object(Integer.new(5_i64)).should eq(-1)
        arr.index_of_object(a).should eq(0)
        arr.index_of_object(b).should eq(1)
      end

      it "builds an array of COSFloats with of" do
        arr = Array.of([1.5, 2.5])

        arr.size.should eq(2)
        arr.to_float_array.should eq([1.5, 2.5])
      end

      it "reports whether the array is empty" do
        Array.new.empty?.should be_true
        Array.new([Integer.get(1_i64)]).empty?.should be_false
      end
    end
  end
end
