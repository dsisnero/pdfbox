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
    # Create Cos::Integer objects (they implement cos_object and return self)
    # Use different values to ensure they're not equal
    int1 = Pdfbox::Cos::Integer.get(1000_i64) # outside cache range
    int2 = Pdfbox::Cos::Integer.get(2000_i64)
    int3 = Pdfbox::Cos::Integer.get(3000_i64)
    # int2 appears twice to test duplicates

    # Create Java-like list and array for comparison
    actual_list = [int1, int2, int3, int2] # int2 appears twice

    # Create COSArray with the objects
    cos_array = Pdfbox::Cos::Array.new
    cos_array.add(int1.cos_object)
    cos_array.add(int2.cos_object)
    cos_array.add(int3.cos_object)
    cos_array.add(int2.cos_object) # int2 appears twice

    # Create array of COSBase objects for comparison
    tbc_array = [] of Pdfbox::Cos::Base
    tbc_array << int1.cos_object
    tbc_array << int2.cos_object
    tbc_array << int3.cos_object
    tbc_array << int2.cos_object

    # Create COSArrayList
    cos_array_list = Pdfbox::Pdmodel::Common::COSArrayList(Pdfbox::Cos::Integer).new(actual_list, cos_array)

    position_to_remove = 1
    to_be_removed = actual_list[position_to_remove]

    # Remove first occurrence
    removed = cos_array_list.remove(to_be_removed)
    removed.should be_true

    # List size shall be 3
    cos_array_list.size.should eq(3)

    # COSArray size shall be 3
    cos_array.size.should eq(3)

    # Remove second occurrence
    removed = cos_array_list.remove(to_be_removed)
    removed.should be_true

    # List size shall be 2
    cos_array_list.size.should eq(2)

    # COSArray size shall be 2
    cos_array.size.should eq(2)
  end

  it "COSArrayListTest#removeAllMultipleFromListByObject" do
    # Create Cos::Integer objects (they implement cos_object and return self)
    # Use different values to ensure they're not equal
    int1 = Pdfbox::Cos::Integer.get(1000_i64) # outside cache range
    int2 = Pdfbox::Cos::Integer.get(2000_i64)
    int3 = Pdfbox::Cos::Integer.get(3000_i64)
    # int2 appears twice to test duplicates

    # Create Java-like list and array for comparison
    actual_list = [int1, int2, int3, int2] # int2 appears twice

    # Create COSArray with the objects
    cos_array = Pdfbox::Cos::Array.new
    cos_array.add(int1.cos_object)
    cos_array.add(int2.cos_object)
    cos_array.add(int3.cos_object)
    cos_array.add(int2.cos_object) # int2 appears twice

    # Create array of COSBase objects for comparison
    tbc_array = [] of Pdfbox::Cos::Base
    tbc_array << int1.cos_object
    tbc_array << int2.cos_object
    tbc_array << int3.cos_object
    tbc_array << int2.cos_object

    # Create COSArrayList
    cos_array_list = Pdfbox::Pdmodel::Common::COSArrayList(Pdfbox::Cos::Integer).new(actual_list, cos_array)

    position_to_remove = 1
    to_be_removed = actual_list[position_to_remove]

    # Remove element by object using removeAll with singleton list
    to_be_removed_instances = [to_be_removed]
    removed = cos_array_list.remove_all(to_be_removed_instances)

    # Remove operation shall return true
    removed.should be_true

    # List size shall be 2
    cos_array_list.size.should eq(2)

    # COSArray size shall be 2
    cos_array.size.should eq(2)

    # Remove shall not remove any object (already removed)
    cos_array_list.remove_all(to_be_removed_instances).should be_false
  end

  it "COSArrayListTest#removeFromFilteredListByIndex" do
    # Create annotation objects (matching Java test setup)
    highlight = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight.new
    link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new
    circle = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle.new

    # Create filtered actual list (excluding link annotations)
    # Java test filter excludes PDAnnotationLink, so actual_list contains highlight and circle
    # Note: Java setup adds highlight, link, circle, link (duplicate link)
    # Filtered list excludes both link entries, leaving highlight and circle
    actual_list = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation
    actual_list << highlight
    actual_list << circle
    # Backing array includes all objects: highlight, link, circle, link
    cos_array = Pdfbox::Cos::Array.new
    cos_array.add(highlight.cos_object)
    cos_array.add(link.cos_object)
    cos_array.add(circle.cos_object)
    cos_array.add(link.cos_object)

    # Create COSArrayList - sizes differ (2 vs 4), so it will be marked as filtered
    cos_array_list = Pdfbox::Pdmodel::Common::COSArrayList(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation).new(actual_list, cos_array)

    # Attempt to remove by index should raise UnsupportedOperationError
    expect_raises(Pdfbox::Cos::UnsupportedOperationError, "removing entries from a filtered List is not permitted") do
      cos_array_list.remove(1)
    end
  end

  it "COSArrayListTest#removeFromFilteredListByObject" do
    # Create annotation objects (matching Java test setup)
    highlight = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight.new
    link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new
    circle = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle.new

    # Create filtered actual list (excluding link annotations)
    actual_list = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation
    actual_list << highlight
    actual_list << circle
    # Backing array includes all objects: highlight, link, circle, link
    cos_array = Pdfbox::Cos::Array.new
    cos_array.add(highlight.cos_object)
    cos_array.add(link.cos_object)
    cos_array.add(circle.cos_object)
    cos_array.add(link.cos_object)

    # Create COSArrayList - sizes differ (2 vs 4), so it will be marked as filtered
    cos_array_list = Pdfbox::Pdmodel::Common::COSArrayList(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation).new(actual_list, cos_array)

    # Attempt to remove object that exists in filtered list should raise UnsupportedOperationError
    expect_raises(Pdfbox::Cos::UnsupportedOperationError, "removing entries from a filtered List is not permitted") do
      cos_array_list.remove(circle)
    end
  end

  it "COSArrayListTest#removeSingleDirectObject" do
    temp_dir = "./temp"
    Dir.mkdir_p(temp_dir)
    temp_file = File.join(temp_dir, "removeSingleDirectObjectTest.pdf")

    # generate test file
    pdf = Pdfbox::Pdmodel::Document.create
    page = Pdfbox::Pdmodel::Page.new
    pdf.add_page(page)

    page_annots = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation
    txt_mark = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight.new
    txt_link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new

    # enforce the COSDictionaries to be written directly into the COSArray
    txt_mark.cos_object.direct = true
    txt_link.cos_object.direct = true

    page_annots << txt_mark
    page_annots << txt_mark
    page_annots << txt_mark
    page_annots << txt_link
    page_annots.size.should eq(4) # There shall be 4 annotations generated

    page.annotations = page_annots

    pdf.save(temp_file)

    # load and verify
    loaded_pdf = Pdfbox::Loader.load_pdf(temp_file)
    loaded_page = loaded_pdf.page(0).as(Pdfbox::Pdmodel::Page)

    annotations = loaded_page.annotations
    annotations.size.should eq(4)         # There shall be 4 annotations retrieved
    annotations.to_list.size.should eq(4) # The size of the internal COSArray shall be 4

    to_be_removed = annotations.get(0)
    annotations.remove(to_be_removed)

    annotations.size.should eq(3)         # There shall be 3 annotations left
    annotations.to_list.size.should eq(3) # The size of the internal COSArray shall be 3
  end

  it "COSArrayListTest#removeSingleIndirectObject" do
    temp_dir = "./temp"
    Dir.mkdir_p(temp_dir)
    temp_file = File.join(temp_dir, "removeSingleIndirectObjectTest.pdf")

    # generate test file
    pdf = Pdfbox::Pdmodel::Document.create
    page = Pdfbox::Pdmodel::Page.new
    pdf.add_page(page)

    page_annots = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation
    txt_mark = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight.new
    txt_link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new

    page_annots << txt_mark
    page_annots << txt_mark
    page_annots << txt_mark
    page_annots << txt_link
    page_annots.size.should eq(4) # There shall be 4 annotations generated

    page.annotations = page_annots

    pdf.save(temp_file)

    # load and verify
    loaded_pdf = Pdfbox::Loader.load_pdf(temp_file)
    loaded_page = loaded_pdf.page(0).as(Pdfbox::Pdmodel::Page)

    annotations = loaded_page.annotations
    annotations.size.should eq(4)         # There shall be 4 annotations retrieved
    annotations.to_list.size.should eq(4) # The size of the internal COSArray shall be 4

    to_be_removed = annotations.get(0)
    annotations.remove(to_be_removed)

    annotations.size.should eq(3)         # There shall be 3 annotations left
    annotations.to_list.size.should eq(3) # The size of the internal COSArray shall be 3
  end

  it "COSArrayListTest#retainIndirectObject" do
    temp_dir = "./temp"
    Dir.mkdir_p(temp_dir)
    temp_file = File.join(temp_dir, "removeIndirectObjectTest.pdf")

    # generate test file
    pdf = Pdfbox::Pdmodel::Document.create
    page = Pdfbox::Pdmodel::Page.new
    pdf.add_page(page)

    page_annots = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation
    txt_mark = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight.new
    txt_link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new

    page_annots << txt_mark
    page_annots << txt_mark
    page_annots << txt_mark
    page_annots << txt_link
    page_annots.size.should eq(4) # There shall be 4 annotations generated

    page.annotations = page_annots

    pdf.save(temp_file)

    # load and verify
    loaded_pdf = Pdfbox::Loader.load_pdf(temp_file)
    loaded_page = loaded_pdf.page(0).as(Pdfbox::Pdmodel::Page)

    annotations = loaded_page.annotations
    annotations.size.should eq(4)         # There shall be 4 annotations retrieved
    annotations.to_list.size.should eq(4) # The size of the internal COSArray shall be 4

    to_be_retained = [annotations.get(0)]
    annotations.retain_all(to_be_retained)

    annotations.size.should eq(3)         # There shall be 3 annotations left
    annotations.to_list.size.should eq(3) # The size of the internal COSArray shall be 3
  end
end
