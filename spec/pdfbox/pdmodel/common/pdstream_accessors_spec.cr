require "../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/common/PDStream.java
#
# Characterization spec: upstream does not cover these accessors directly, so
# these assertions are inferred from the Java observable behavior.
describe Pdfbox::Pdmodel::Common::PDStream do
  it "round-trips metadata (/Metadata)" do
    pd = Pdfbox::Pdmodel::Common::PDStream.new(Pdfbox::Cos::Stream.new)
    pd.metadata.should be_nil

    meta_stream = Pdfbox::Cos::Stream.new
    meta = Pdfbox::Pdmodel::Common::PDMetadata.new(meta_stream)
    pd.metadata = meta
    pd.metadata.not_nil!.cos_object.should be(meta_stream)

    pd.metadata = nil
    pd.metadata.should be_nil
  end

  it "round-trips the decoded stream length (/DL)" do
    pd = Pdfbox::Pdmodel::Common::PDStream.new(Pdfbox::Cos::Stream.new)
    pd.decoded_stream_length.should eq(0)
    pd.decoded_stream_length = 42
    pd.decoded_stream_length.should eq(42)
  end

  it "round-trips the file specification (/F)" do
    pd = Pdfbox::Pdmodel::Common::PDStream.new(Pdfbox::Cos::Stream.new)
    pd.file.should be_nil

    fs = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new(Pdfbox::Cos::String.new("file.txt"))
    pd.file = fs
    pd.file.should be_a(Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification)
    pd.file.not_nil!.cos_object.should eq(fs.cos_object)
  end

  it "round-trips the file filters (/F_Filter)" do
    pd = Pdfbox::Pdmodel::Common::PDStream.new(Pdfbox::Cos::Stream.new)
    pd.file_filters.should be_empty

    pd.file_filters = ["FlateDecode", "ASCII85Decode"]
    pd.file_filters.should eq(["FlateDecode", "ASCII85Decode"])

    stream = Pdfbox::Cos::Stream.new
    stream.set_item("F_Filter", Pdfbox::Cos::Name.new("FlateDecode"))
    Pdfbox::Pdmodel::Common::PDStream.new(stream).file_filters.should eq(["FlateDecode"])
  end
end
