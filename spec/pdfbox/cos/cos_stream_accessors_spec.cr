require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSStream.java
#     getFilters (raw /Filter), getFilterList (resolved Filter objects),
#     getLength (/Length). Upstream has no dedicated test; this is a
#     characterization spec.
module Pdfbox
  module Cos
    describe Stream do
      it "returns the raw /Filter entry" do
        stream = Stream.new
        stream[Name::FILTER] = Name.new("FlateDecode")

        stream.filters.should eq(Name.new("FlateDecode"))
      end

      it "returns nil filters when /Filter is absent" do
        Stream.new.filters.should be_nil
        Stream.new.filter_list.should be_empty
      end

      it "resolves a single filter name to its Filter object" do
        stream = Stream.new
        stream[Name::FILTER] = Name.new("FlateDecode")

        stream.filter_list.size.should eq(1)
        stream.filter_list.first.should be_a(Pdfbox::Filter::FlateFilter)
      end

      it "resolves a filter array to Filter objects in order" do
        stream = Stream.new
        stream[Name::FILTER] = Array.new([Name.new("ASCIIHexDecode"), Name.new("FlateDecode")])

        stream.filter_list.map(&.class).should eq([
          Pdfbox::Filter::ASCIIHexFilter,
          Pdfbox::Filter::FlateFilter,
        ])
      end

      it "returns the encoded length from /Length" do
        stream = Stream.new
        stream.length.should eq(0_i64)

        stream.set_int(Name::LENGTH, 123)
        stream.length.should eq(123_i64)
      end
    end
  end
end
