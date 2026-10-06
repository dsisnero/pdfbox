require "../../../spec_helper"
require "../../../helpers/pd_integer_name_tree_node"

describe "Pdfbox::Pdmodel::Common parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/
  #
  # Existing Crystal coverage already present:
  # - TestEmbeddedFiles -> spec/pdfbox/pdmodel/common/embedded_files_spec.cr
  # - TestPDNameTreeNode -> spec/pdfbox/pdmodel/common/pdname_tree_node_spec.cr
  # - TestPDNumberTreeNode -> spec/pdfbox/pdmodel/common/pdnumber_tree_node_spec.cr
  # - COSArrayListTest -> spec/pdfbox/pdmodel/common/cosarray_list_test_spec.cr
  #   (all 11 active test methods; addToList is `// @Test`-disabled in Java)
  #
  # Remaining tests below are blocked by unported APIs (immutable rectangle
  # variant, PDStream API, and PDIntegerNameTreeNode helper types).

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

  it "PDImmutableRectangleTest#testClass" do
    Pdfbox::Pdmodel::Common::PDRectangle.letter.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.a0.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.a1.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.a2.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.a3.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.a4.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.a5.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.a6.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.legal.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle.letter.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
  end

  it "PDImmutableRectangleTest#testSetUpperRightY" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.a4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      rect.upper_right_y = 0.0_f32
    end
  end

  it "PDImmutableRectangleTest#testSetUpperRightX" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.a4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      rect.upper_right_x = 0.0_f32
    end
  end

  it "PDImmutableRectangleTest#testSetLowerLeftY" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.a4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      rect.lower_left_y = 0.0_f32
    end
  end

  it "PDImmutableRectangleTest#testSetLowerLeftX" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.a4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      rect.lower_left_x = 0.0_f32
    end
  end

  it "PDStreamTest#testCreateInputStreamNullFilters" do
    document = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
    input = IO::Memory.new(Bytes[12, 34, 56, 78])
    pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(document, input, nil)
    pd_stream.filters.should be_empty
    stop_filters = ["DCTDecode", "DCT"]
    io = pd_stream.create_input_stream(stop_filters)
    io.read_byte.should eq(12)
    io.read_byte.should eq(34)
    io.read_byte.should eq(56)
    io.read_byte.should eq(78)
    io.read_byte.should be_nil
    document.close
  end

  it "PDStreamTest#testCreateInputStreamEmptyFilters" do
    document = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
    input = IO::Memory.new(Bytes[12, 34, 56, 78])
    pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(document, input, Pdfbox::Cos::Array.new)
    pd_stream.filters.size.should eq(0)
    stop_filters = ["DCTDecode", "DCT"]
    io = pd_stream.create_input_stream(stop_filters)
    io.read_byte.should eq(12)
    io.read_byte.should eq(34)
    io.read_byte.should eq(56)
    io.read_byte.should eq(78)
    io.read_byte.should be_nil
    document.close
  end

  it "PDStreamTest#testCreateInputStreamNullStopFilters" do
    document = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
    input = IO::Memory.new(Bytes[12, 34, 56, 78])
    pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(document, input, Pdfbox::Cos::Array.new)
    pd_stream.filters.size.should eq(0)
    io = pd_stream.create_input_stream(nil)
    io.read_byte.should eq(12)
    io.read_byte.should eq(34)
    io.read_byte.should eq(56)
    io.read_byte.should eq(78)
    io.read_byte.should be_nil
    document.close
  end
end
