require "../../spec_helper"

module Pdfbox::Pdfparser
  describe XrefParser do
    describe "#initialize" do
      it "creates XrefParser with COSParser" do
        source = Pdfbox::IO::MemoryRandomAccessRead.new(Bytes.empty)
        parser = Parser.new(source)
        xref_parser = XrefParser.new(parser)
        xref_parser.should be_a(XrefParser)
      end
    end

    describe "#parse_xref" do
      it "parses simple xref table" do
        # Create a simple PDF with xref table
        pdf_data = <<-PDF
          %PDF-1.4
          1 0 obj
          << /Type /Catalog /Pages 2 0 R >>
          endobj
          2 0 obj
          << /Type /Pages /Kids [] /Count 0 >>
          endobj
          xref
          0 3
          0000000000 65535 f
          0000000010 00000 n
          0000000020 00000 n
          trailer
          << /Size 3 /Root 1 0 R >>
          startxref
          100
          %%EOF
          PDF

        source = Pdfbox::IO::MemoryRandomAccessRead.new(pdf_data.to_slice)
        parser = Parser.new(source)
        xref_parser = XrefParser.new(parser)

        startxref_offset = pdf_data.index!("startxref").to_i64
        trailer = xref_parser.parse_xref(startxref_offset)
        trailer.should be_a(Cos::Dictionary)

        xref_table = xref_parser.xref_table
        # Only in-use entries (objects 1 and 2)
        xref_table.size.should eq(2)

        # Check object 1 offset (actual offset in PDF data)
        key1 = Cos::ObjectKey.new(1_i64, 0_i64)
        xref_table[key1]?.should eq(9_i64)

        # Check object 2 offset (actual offset in PDF data)
        key2 = Cos::ObjectKey.new(2_i64, 0_i64)
        xref_table[key2]?.should eq(58_i64)
      end

      it "handles xref table with multiple subsections" do
        pdf_data = <<-PDF
          %PDF-1.4
          xref
          0 1
          0000000000 65535 f
          3 2
          0000000010 00000 n
          0000000020 00000 n
          trailer
          << /Size 5 >>
          startxref
          0
          %%EOF
          PDF

        source = Pdfbox::IO::MemoryRandomAccessRead.new(pdf_data.to_slice)
        parser = Parser.new(source)
        xref_parser = XrefParser.new(parser)

        startxref_offset = pdf_data.index!("startxref").to_i64
        xref_parser.parse_xref(startxref_offset)

        xref_table = xref_parser.xref_table
        # Invalid offsets are discarded by brute force search, so no valid entries
        xref_table.size.should eq(0)
      end
    end

    describe "#parse_startxref" do
      it "parses startxref keyword and offset" do
        # We need to test the private method parse_startxref
        # Since it's private, we'll test through parse_xref instead
        # by providing data that includes startxref
        pdf_data = <<-PDF
          trailer
          << /Size 0 >>
          startxref
          100
          %%EOF
          PDF

        source = Pdfbox::IO::MemoryRandomAccessRead.new(pdf_data.to_slice)
        parser = Parser.new(source)
        xref_parser = XrefParser.new(parser)

        # parse_xref should handle startxref parsing internally
        # Starting at the beginning of "startxref"
        source.seek(pdf_data.index!("startxref").to_i64)
        trailer = xref_parser.parse_xref(source.position)
        trailer.should be_a(Cos::Dictionary)
      end
    end

    describe "#xref_table" do
      it "returns empty hash when no xref parsed" do
        source = Pdfbox::IO::MemoryRandomAccessRead.new(Bytes.empty)
        parser = Parser.new(source)

        xref_table = XrefParser.new(parser).xref_table
        xref_table.should be_a(Hash(Cos::ObjectKey, Int64))
        xref_table.size.should eq(0)
      end
    end

    describe "#trailer" do
      it "returns nil when no trailer parsed" do
        source = Pdfbox::IO::MemoryRandomAccessRead.new(Bytes.empty)
        parser = Parser.new(source)
        xref_parser = XrefParser.new(parser)

        trailer = xref_parser.trailer
        trailer.should be_nil
      end
    end
  end
end
