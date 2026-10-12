require "../../../spec_helper"

alias CosArrayList = Pdfbox::Pdmodel::Common::COSArrayList
alias PDAnnotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation
alias PDHighlight = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight
alias PDLink = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink
alias PDCircle = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle

# Mirrors COSArrayListTest.setUp: four annotations (two of them the same link
# instance) in a working list/COSArray (mutated by COSArrayList, which aliases
# them) and a separate tbc list/COSArray used for expected comparisons.
private def cos_array_list_test_annotations
  txt_mark = PDHighlight.new
  txt_link = PDLink.new
  a_circle = PDCircle.new
  actual = [txt_mark, txt_link, a_circle, txt_link] of PDAnnotation
  tbc = [txt_mark, txt_link, a_circle, txt_link] of PDAnnotation
  array = Pdfbox::Cos::Array.new
  tbc_array = Pdfbox::Cos::Array.new
  actual.each { |annot| array.add(annot.cos_object) }
  tbc.each { |annot| tbc_array.add(annot.cos_object) }
  {actual, array, tbc, tbc_array}
end

describe Pdfbox::Pdmodel::Common::COSArrayList do
  it "creates empty list" do
    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new
    list.size.should eq(0)
    list.empty?.should be_true
  end

  it "adds elements" do
    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new
    list.add("test")
    list.size.should eq(1)
    list.contains?("test").should be_true
  end

  it "gets elements" do
    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new
    list.add("first")
    list.add("second")
    list.get(0).should eq("first")
    list.get(1).should eq("second")
  end

  it "removes elements" do
    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new
    list.add("test")
    list.remove("test").should be_true
    list.size.should eq(0)
  end

  it "returns false when removing non-existent element" do
    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new
    list.remove("nonexistent").should be_false
  end

  it "provides access to underlying COSArray" do
    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new
    list.add("test")
    cos_array = list.to_list
    cos_array.should be_a(Pdfbox::Cos::Array)
    cos_array.size.should eq(1)
  end

  it "creates from existing array and list" do
    arr = Pdfbox::Cos::Array.new
    arr.add(Pdfbox::Cos::String.new("item"))
    actual = ["item"]

    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new(actual, arr)
    list.size.should eq(1)
    list.get(0).should eq("item")
  end

  it "detects filtered state when sizes differ" do
    arr = Pdfbox::Cos::Array.new
    arr.add(Pdfbox::Cos::String.new("item1"))
    arr.add(Pdfbox::Cos::String.new("item2"))
    actual = ["item1"] # Only one item, but array has two

    # This should set is_filtered = true
    list = Pdfbox::Pdmodel::Common::COSArrayList(String).new(actual, arr)
    # When filtered, remove should raise
    expect_raises(Exception) do
      list.remove("item1")
    end
  end

  describe "COSArrayListTest parity" do
    # Source of truth:
    # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/COSArrayListTest.java

    it "getFromList" do
      actual, array, tbc, tbc_array = cos_array_list_test_annotations
      list = CosArrayList(PDAnnotation).new(actual, array)

      list.size.times do |i|
        annot = list.get(i)
        annot.cos_object.should be(array[i])
        annot.cos_object.should be(tbc_array[i])
        annot.cos_object.should be(tbc[i].cos_object)
      end
    end

    it "removeFromListByIndex" do
      actual, array, tbc, tbc_array = cos_array_list_test_annotations
      list = CosArrayList(PDAnnotation).new(actual, array)

      position_to_remove = 2
      to_be_removed = list.get(position_to_remove)

      list.remove(position_to_remove).cos_object.should be(to_be_removed.cos_object)
      list.size.should eq(3)
      array.size.should eq(3)

      list.index_of(tbc[position_to_remove]).should be_nil
      array.index_of(tbc_array[position_to_remove]).should eq(-1)
    end

    it "removeUniqueFromListByObject" do
      actual, array, tbc, tbc_array = cos_array_list_test_annotations
      list = CosArrayList(PDAnnotation).new(actual, array)

      position_to_remove = 2
      to_be_removed = tbc[position_to_remove]

      list.remove(to_be_removed).should be_true
      list.size.should eq(3)
      array.size.should eq(3)

      list.get(2).cos_object.should be(tbc[3].cos_object)
      array[2].should be(tbc_array[3])

      list.index_of(tbc[position_to_remove]).should be_nil
      array.index_of(tbc_array[position_to_remove]).should eq(-1)

      list.remove(to_be_removed).should be_false
    end

    it "removeAllUniqueFromListByObject" do
      actual, array, tbc, _tbc_array = cos_array_list_test_annotations
      list = CosArrayList(PDAnnotation).new(actual, array)

      to_be_removed = tbc[2]
      instances = [to_be_removed]

      list.remove_all(instances).should be_true
      list.size.should eq(3)
      array.size.should eq(3)

      list.remove_all(instances).should be_false
    end

    it "removeMultipleFromListByObject" do
      actual, array, tbc, _tbc_array = cos_array_list_test_annotations
      list = CosArrayList(PDAnnotation).new(actual, array)

      to_be_removed = tbc[1]

      list.remove(to_be_removed).should be_true
      list.size.should eq(3)
      array.size.should eq(3)

      list.remove(to_be_removed).should be_true
      list.size.should eq(2)
      array.size.should eq(2)
    end

    it "removeAllMultipleFromListByObject" do
      actual, array, tbc, _tbc_array = cos_array_list_test_annotations
      list = CosArrayList(PDAnnotation).new(actual, array)

      to_be_removed = tbc[1]
      instances = [to_be_removed]

      list.remove_all(instances).should be_true
      list.size.should eq(2)
      array.size.should eq(2)

      list.remove_all(instances).should be_false
    end

    it "removeFromFilteredListByIndex" do
      actual, _array, _tbc, _tbc_array = cos_array_list_test_annotations
      page = Pdfbox::Pdmodel::Page.new
      page.annotations = actual

      filtered = page.get_annotations { |annot| !annot.is_a?(PDLink) }
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) { filtered.remove(1) }
    end

    it "removeFromFilteredListByObject" do
      actual, _array, _tbc, _tbc_array = cos_array_list_test_annotations
      page = Pdfbox::Pdmodel::Page.new
      page.annotations = actual

      filtered = page.get_annotations { |annot| !annot.is_a?(PDLink) }
      to_be_removed = filtered.get(1)
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) { filtered.remove(to_be_removed) }
    end

    it "removeSingleDirectObject" do
      pdf = Pdfbox::Pdmodel::Document.create
      page = Pdfbox::Pdmodel::Page.new
      pdf.add_page(page)

      txt_mark = PDHighlight.new
      txt_link = PDLink.new
      txt_mark.cos_object.direct = true
      txt_link.cos_object.direct = true

      page.annotations = [txt_mark, txt_mark, txt_mark, txt_link] of PDAnnotation

      output = IO::Memory.new
      pdf.save(output)
      pdf.close

      reloaded = Pdfbox::Pdmodel::Document.load(IO::Memory.new(output.to_slice))
      begin
        ann_list = reloaded.pages[0].annotations
        ann_list.size.should eq(4)
        ann_list.to_list.size.should eq(4)

        ann_list.remove(ann_list.get(0))
        ann_list.size.should eq(3)
        ann_list.to_list.size.should eq(3)
      ensure
        reloaded.close
      end
    end

    it "removeSingleIndirectObject" do
      pdf = Pdfbox::Pdmodel::Document.create
      page = Pdfbox::Pdmodel::Page.new
      pdf.add_page(page)

      txt_mark = PDHighlight.new
      txt_link = PDLink.new

      page.annotations = [txt_mark, txt_mark, txt_mark, txt_link] of PDAnnotation

      output = IO::Memory.new
      pdf.save(output)
      pdf.close

      reloaded = Pdfbox::Pdmodel::Document.load(IO::Memory.new(output.to_slice))
      begin
        ann_list = reloaded.pages[0].annotations
        ann_list.size.should eq(4)
        ann_list.to_list.size.should eq(4)

        ann_list.remove(ann_list.get(0))
        ann_list.size.should eq(3)
        ann_list.to_list.size.should eq(3)
      ensure
        reloaded.close
      end
    end

    it "retainIndirectObject" do
      pdf = Pdfbox::Pdmodel::Document.create
      page = Pdfbox::Pdmodel::Page.new
      pdf.add_page(page)

      txt_mark = PDHighlight.new
      txt_link = PDLink.new

      page.annotations = [txt_mark, txt_mark, txt_mark, txt_link] of PDAnnotation

      output = IO::Memory.new
      pdf.save(output)
      pdf.close

      reloaded = Pdfbox::Pdmodel::Document.load(IO::Memory.new(output.to_slice))
      begin
        ann_list = reloaded.pages[0].annotations
        ann_list.size.should eq(4)
        ann_list.to_list.size.should eq(4)

        ann_list.retain_all([ann_list.get(0)])
        ann_list.size.should eq(3)
        ann_list.to_list.size.should eq(3)
      ensure
        reloaded.close
      end
    end
  end
end
