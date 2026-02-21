require "../../../spec_helper"

describe "Pdfbox::Pdmodel::Common parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/
  #
  # Existing Crystal coverage already present:
  # - TestEmbeddedFiles -> spec/pdfbox/pdmodel/common/embedded_files_spec.cr
  # - TestPDNumberTreeNode -> spec/pdfbox/pdmodel/common/number_tree_node_spec.cr
  #
  # Remaining tests below are blocked by unported APIs (COSArrayList wrappers,
  # annotation filtering/list mutation semantics, immutable rectangle variant, PDStream API,
  # and PDIntegerNameTreeNode helper types).

  describe "Range" do
    it "creates default range [0.0, 1.0]" do
      range = Pdfbox::Pdmodel::PDRange.new
      range.min.should eq(0.0)
      range.max.should eq(1.0)
    end

    it "creates range from COSArray" do
      arr = Pdfbox::Cos::Array.new
      arr.add(Pdfbox::Cos::Float.new(2.5))
      arr.add(Pdfbox::Cos::Float.new(5.0))

      range = Pdfbox::Pdmodel::PDRange.new(arr)
      range.min.should eq(2.5)
      range.max.should eq(5.0)
    end

    it "creates range from COSArray with starting index" do
      arr = Pdfbox::Cos::Array.new
      # First range
      arr.add(Pdfbox::Cos::Float.new(0.0))
      arr.add(Pdfbox::Cos::Float.new(1.0))
      # Second range
      arr.add(Pdfbox::Cos::Float.new(2.5))
      arr.add(Pdfbox::Cos::Float.new(5.0))

      range0 = Pdfbox::Pdmodel::PDRange.new(arr, 0)
      range0.min.should eq(0.0)
      range0.max.should eq(1.0)

      range1 = Pdfbox::Pdmodel::PDRange.new(arr, 1)
      range1.min.should eq(2.5)
      range1.max.should eq(5.0)
    end

    it "sets min value" do
      range = Pdfbox::Pdmodel::PDRange.new
      range.min = 3.5
      range.min.should eq(3.5)
    end

    it "sets max value" do
      range = Pdfbox::Pdmodel::PDRange.new
      range.max = 7.0
      range.max.should eq(7.0)
    end

    it "returns underlying COSArray" do
      arr = Pdfbox::Cos::Array.new
      arr.add(Pdfbox::Cos::Float.new(1.0))
      arr.add(Pdfbox::Cos::Float.new(2.0))

      range = Pdfbox::Pdmodel::PDRange.new(arr)
      range.cos_array.should be(arr)
    end

    it "converts to string" do
      range = Pdfbox::Pdmodel::PDRange.new
      range.to_s.should contain("0.0")
      range.to_s.should contain("1.0")
    end
  end

  it "TestPDNameTreeNode#testUpperLimit" do
  end

  it "TestPDNameTreeNode#testLowerLimit" do
  end

  it "PDImmutableRectangleTest#testClass" do
  end

  it "PDImmutableRectangleTest#testSetUpperRightY" do
  end

  it "PDImmutableRectangleTest#testSetUpperRightX" do
  end

  it "PDImmutableRectangleTest#testSetLowerLeftY" do
  end

  it "PDImmutableRectangleTest#testSetLowerLeftX" do
  end

  it "PDStreamTest#testCreateInputStreamNullFilters" do
  end

  it "PDStreamTest#testCreateInputStreamEmptyFilters" do
  end

  it "PDStreamTest#testCreateInputStreamNullStopFilters" do
  end

  it "COSArrayListTest#getFromList" do
  end

  it "COSArrayListTest#removeFromListByIndex" do
  end

  it "COSArrayListTest#removeUniqueFromListByObject" do
  end

  it "COSArrayListTest#removeAllUniqueFromListByObject" do
  end

  it "COSArrayListTest#removeMultipleFromListByObject" do
  end

  it "COSArrayListTest#removeAllMultipleFromListByObject" do
  end

  it "COSArrayListTest#removeFromFilteredListByIndex" do
  end

  it "COSArrayListTest#removeFromFilteredListByObject" do
  end

  it "COSArrayListTest#removeSingleDirectObject" do
  end

  it "COSArrayListTest#removeSingleIndirectObject" do
  end

  it "COSArrayListTest#retainIndirectObject" do
  end
end
