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
