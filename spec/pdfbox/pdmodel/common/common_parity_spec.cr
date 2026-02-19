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

  pending "TestPDNameTreeNode#testUpperLimit" do
  end

  pending "TestPDNameTreeNode#testLowerLimit" do
  end

  pending "PDImmutableRectangleTest#testClass" do
  end

  pending "PDImmutableRectangleTest#testSetUpperRightY" do
  end

  pending "PDImmutableRectangleTest#testSetUpperRightX" do
  end

  pending "PDImmutableRectangleTest#testSetLowerLeftY" do
  end

  pending "PDImmutableRectangleTest#testSetLowerLeftX" do
  end

  pending "PDStreamTest#testCreateInputStreamNullFilters" do
  end

  pending "PDStreamTest#testCreateInputStreamEmptyFilters" do
  end

  pending "PDStreamTest#testCreateInputStreamNullStopFilters" do
  end

  pending "COSArrayListTest#getFromList" do
  end

  pending "COSArrayListTest#removeFromListByIndex" do
  end

  pending "COSArrayListTest#removeUniqueFromListByObject" do
  end

  pending "COSArrayListTest#removeAllUniqueFromListByObject" do
  end

  pending "COSArrayListTest#removeMultipleFromListByObject" do
  end

  pending "COSArrayListTest#removeAllMultipleFromListByObject" do
  end

  pending "COSArrayListTest#removeFromFilteredListByIndex" do
  end

  pending "COSArrayListTest#removeFromFilteredListByObject" do
  end

  pending "COSArrayListTest#removeSingleDirectObject" do
  end

  pending "COSArrayListTest#removeSingleIndirectObject" do
  end

  pending "COSArrayListTest#retainIndirectObject" do
  end
end
