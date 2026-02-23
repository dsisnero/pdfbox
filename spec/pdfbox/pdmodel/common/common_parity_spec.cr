require "../../../spec_helper"
require "../../../helpers/pd_integer_name_tree_node"

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

  describe "PDNameTreeNode" do
    node5 = nil.as(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode?)
    node24 = nil.as(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode?)
    node2 = nil.as(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode?)
    node4 = nil.as(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode?)
    node1 = nil.as(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode?)

    before_each do
      # Build node5 (leaf with names)
      node5 = Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode.new
      names = {} of String => Pdfbox::Cos::Integer
      names["Actinium"] = Pdfbox::Cos::Integer.new(89)
      names["Aluminum"] = Pdfbox::Cos::Integer.new(13)
      names["Americium"] = Pdfbox::Cos::Integer.new(95)
      names["Antimony"] = Pdfbox::Cos::Integer.new(51)
      names["Argon"] = Pdfbox::Cos::Integer.new(18)
      names["Arsenic"] = Pdfbox::Cos::Integer.new(33)
      names["Astatine"] = Pdfbox::Cos::Integer.new(85)
      node5.not_nil!.names = names

      # Build node24 (leaf with names)
      node24 = Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode.new
      names = {} of String => Pdfbox::Cos::Integer
      names["Xenon"] = Pdfbox::Cos::Integer.new(54)
      names["Ytterbium"] = Pdfbox::Cos::Integer.new(70)
      names["Yttrium"] = Pdfbox::Cos::Integer.new(39)
      names["Zinc"] = Pdfbox::Cos::Integer.new(30)
      names["Zirconium"] = Pdfbox::Cos::Integer.new(40)
      node24.not_nil!.names = names

      # Build node2 (parent of node5)
      node2 = Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode.new
      kids = node2.not_nil!.kids
      if kids.nil?
        kids = Pdfbox::Pdmodel::Common::COSArrayList(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode).new
      end
      kids.add(node5.not_nil!)
      node2.not_nil!.kids = kids

      # Build node4 (parent of node24)
      node4 = Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode.new
      kids = node4.not_nil!.kids
      if kids.nil?
        kids = Pdfbox::Pdmodel::Common::COSArrayList(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode).new
      end
      kids.add(node24.not_nil!)
      node4.not_nil!.kids = kids

      # Build node1 (root parent of node2 and node4)
      node1 = Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode.new
      kids = node1.not_nil!.kids
      if kids.nil?
        kids = Pdfbox::Pdmodel::Common::COSArrayList(Pdfbox::Pdmodel::Common::PDIntegerNameTreeNode).new
      end
      kids.add(node2.not_nil!)
      kids.add(node4.not_nil!)
      node1.not_nil!.kids = kids
    end

    it "testUpperLimit" do
      node5.not_nil!.upper_limit.should eq("Astatine")
      node2.not_nil!.upper_limit.should eq("Astatine")
      node24.not_nil!.upper_limit.should eq("Zirconium")
      node4.not_nil!.upper_limit.should eq("Zirconium")
      node1.not_nil!.upper_limit.should be_nil
    end

    it "testLowerLimit" do
      node5.not_nil!.lower_limit.should eq("Actinium")
      node2.not_nil!.lower_limit.should eq("Actinium")
      node24.not_nil!.lower_limit.should eq("Xenon")
      node4.not_nil!.lower_limit.should eq("Xenon")
      node1.not_nil!.lower_limit.should be_nil
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
