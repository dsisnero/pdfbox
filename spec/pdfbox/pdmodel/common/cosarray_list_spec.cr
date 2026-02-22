require "../../../spec_helper"

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
end
