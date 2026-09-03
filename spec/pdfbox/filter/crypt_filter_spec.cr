require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/CryptFilter.java
#
# CryptFilter decrypts/encrypts data via a security handler's crypt filter. The
# only supported implementation is the Identity crypt filter: when /Name in the
# DecodeParms dictionary is absent or equals /Identity, decode/encode are
# pass-through (Java: delegates to IdentityFilter). FilterFactory registers the
# "Crypt" COSName (Java COSName.CRYPT).

module Pdfbox::Filter
  describe CryptFilter do
    it "is registered in FilterFactory under the Crypt name" do
      filter = Pdfbox::Filter::FilterFactory::INSTANCE.filter(Pdfbox::Cos::Name.new("Crypt"))
      filter.should be_a(CryptFilter)
    end

    it "passes data through unchanged (Identity crypt filter)" do
      filter = CryptFilter.new
      input = Bytes[12_u8, 34_u8, 56_u8, 78_u8, 0xFF_u8]
      filter.decode(input).should eq(input)
      filter.encode(input).should eq(input)
    end

    it "round-trips arbitrary data" do
      filter = CryptFilter.new
      input = "crypt filter round-trip \x00\x01\xFF".to_slice
      filter.encode(input).should eq(input)
      filter.decode(input).should eq(input)
    end

    it "decodes via a stream with Filter /Crypt (TestFilters#testPDFBOX4517 parity)" do
      raw = "crypt-filter stream content".to_slice
      stream = Pdfbox::Cos::Stream.new(entries: {} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, data: raw)
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("Crypt")
      decode_parms = Pdfbox::Cos::Dictionary.new
      decode_parms[Pdfbox::Cos::Name.new("Name")] = Pdfbox::Cos::Name.new("Identity")
      stream[Pdfbox::Cos::Name.new("DecodeParms")] = decode_parms
      stream.create_input_stream.gets_to_end.to_slice.should eq(raw)
    end
  end
end
