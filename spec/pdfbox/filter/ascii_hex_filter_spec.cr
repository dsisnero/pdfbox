require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/ASCIIHexFilter.java
#
# ASCIIHexFilter decodes ASCII hexadecimal data back to binary. Whitespace
# (0x00, 0x09, 0x0A, 0x0C, 0x0D, 0x20) is skipped; '>' marks end-of-data (an odd
# number of hex digits treats the missing low nibble as 0); invalid hex chars
# are logged and skipped. Encode writes each byte as two uppercase hex chars
# (Hex.writeHexByte).

module Pdfbox::Filter
  describe ASCIIHexFilter do
    it "round-trips simple data (TestFilters#testFilters parity)" do
      filter = ASCIIHexFilter.new
      raw = Bytes[0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
      encoded = filter.encode(raw)
      filter.decode(encoded).should eq(raw)
    end

    it "encodes bytes as uppercase hexadecimal" do
      filter = ASCIIHexFilter.new
      filter.encode(Bytes[0x00_u8, 0xFF_u8, 0x10_u8]).should eq("00FF10".to_slice)
    end

    it "decodes skipping whitespace" do
      filter = ASCIIHexFilter.new
      # "0A BC DE" with spaces and newlines between hex digits
      encoded = Bytes['0'.ord.to_u8, 'A'.ord.to_u8, 0x20_u8, 'B'.ord.to_u8, 'C'.ord.to_u8, 0x0A_u8, 'D'.ord.to_u8, 'E'.ord.to_u8]
      filter.decode(encoded).should eq(Bytes[0x0A, 0xBC, 0xDE])
    end

    it "treats an EOD after an odd number of digits as a zero low nibble" do
      filter = ASCIIHexFilter.new
      # "ABC>" -> 0xAB, then 'C' with missing low nibble -> 0xC0
      encoded = "ABC>".to_slice
      filter.decode(encoded).should eq(Bytes[0xAB, 0xC0])
    end

    it "stops at the EOD marker" do
      filter = ASCIIHexFilter.new
      encoded = "ABCD>EF".to_slice
      filter.decode(encoded).should eq(Bytes[0xAB, 0xCD])
    end

    it "uses REVERSE_HEX -1 for invalid hex characters (Java parity)" do
      # Java: 'A' -> 10*16=160, '!' invalid -> REVERSE_HEX='!' is -1, so value
      # becomes 160 + (-1) = 159 (0x9F); then 'B' -> 11*16=176, '>' EOD writes
      # 176 (0xB0). Invalid chars are NOT skipped; their -1 value is added.
      filter = ASCIIHexFilter.new
      encoded = "A!B>C".to_slice
      filter.decode(encoded).should eq(Bytes[0x9F, 0xB0])
    end

    it "decodes via the AHx abbreviation in a stream (FilterFactory registration)" do
      raw = "ascii-hex content \x00\x01\x02".to_slice
      encoded = Pdfbox::Filter::ASCIIHexFilter.new.encode(raw)
      stream = Pdfbox::Cos::Stream.new(entries: {} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, data: encoded)
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("AHx")
      stream.create_input_stream.gets_to_end.to_slice.should eq(raw)
    end
  end
end
