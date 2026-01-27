require "../spec_helper"

describe Pdfbox::Pdfparser::COSParser do
  describe "#parse_cos_literal_string" do
    it "parses simple literal string (Test)" do
      # (Test) bytes: 40, 84, 101, 115, 116, 41
      bytes = Bytes[40, 84, 101, 115, 116, 41]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("Test")
    end

    it "parses literal string with nested parentheses and LF delimiter" do
      # ((Test) + LF + "/ "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 10, '/'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CR delimiter" do
      # ((Test) + CR + "/ "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, '/'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CRLF delimiter" do
      # ((Test) + CR + LF + "/ "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, 10, '/'.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and LF > delimiter" do
      # ((Test) + LF + "> "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 10, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CR > delimiter" do
      # ((Test) + CR + "> "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CRLF > delimiter" do
      # ((Test) + CR + LF + "> "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, 10, '>'.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end
  end
end

describe Pdfbox::Pdfparser::ObjectParser do
  describe "#parse_object" do
    it "parses COS name" do
      bytes = Bytes['/'.ord, 'F'.ord, 'o'.ord, 'n'.ord, 't'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Name)
      obj.as(Pdfbox::Cos::Name).value.should eq("Font")
    end

    it "parses COS integer" do
      bytes = Bytes['4'.ord, '2'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Integer)
      obj.as(Pdfbox::Cos::Integer).value.should eq(42_i64)
    end

    it "parses COS float" do
      bytes = Bytes['3'.ord, '.'.ord, '1'.ord, '4'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Float)
      obj.as(Pdfbox::Cos::Float).value.should eq(3.14)
    end

    it "parses COS boolean true" do
      bytes = Bytes['t'.ord, 'r'.ord, 'u'.ord, 'e'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Boolean)
      obj.as(Pdfbox::Cos::Boolean).value.should be_true
    end

    it "parses COS boolean false" do
      bytes = Bytes['f'.ord, 'a'.ord, 'l'.ord, 's'.ord, 'e'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Boolean)
      obj.as(Pdfbox::Cos::Boolean).value.should be_false
    end

    it "parses COS null" do
      bytes = Bytes['n'.ord, 'u'.ord, 'l'.ord, 'l'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Null)
    end

    it "parses COS literal string" do
      bytes = Bytes['('.ord, 'H'.ord, 'e'.ord, 'l'.ord, 'l'.ord, 'o'.ord, ')'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::String)
      obj.as(Pdfbox::Cos::String).value.should eq("Hello")
    end

    it "parses COS hexadecimal string" do
      bytes = Bytes['<'.ord, '4'.ord, '8'.ord, '6'.ord, '5'.ord, '6'.ord, 'C'.ord, '6'.ord, 'C'.ord, '6'.ord, 'F'.ord, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::String)
      obj.as(Pdfbox::Cos::String).value.should eq("Hello")
    end

    it "parses COS array" do
      bytes = Bytes['['.ord, '4'.ord, '2'.ord, ']'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Array)
      arr = obj.as(Pdfbox::Cos::Array)
      arr.size.should eq(1)
      arr[0].should be_a(Pdfbox::Cos::Integer)
      arr[0].as(Pdfbox::Cos::Integer).value.should eq(42_i64)
    end

    it "parses COS dictionary" do
      bytes = Bytes['<'.ord, '<'.ord, '/'.ord, 'K'.ord, 'e'.ord, 'y'.ord, ' '.ord, '('.ord, 'v'.ord, 'a'.ord, 'l'.ord, 'u'.ord, 'e'.ord, ')'.ord, '>'.ord, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::ObjectParser.new(source)
      obj = parser.parse_object
      obj.should be_a(Pdfbox::Cos::Dictionary)
      dict = obj.as(Pdfbox::Cos::Dictionary)
      dict.size.should eq(1)
      dict[Pdfbox::Cos::Name.new("Key")].should be_a(Pdfbox::Cos::String)
      dict[Pdfbox::Cos::Name.new("Key")].as(Pdfbox::Cos::String).value.should eq("value")
    end
  end
end

describe Pdfbox::Pdfparser::Parser do
  pending "test PDF parser missing catalog" do
    # Test loading MissingCatalog.pdf
    # pdf_path = File.expand_path("../resources/pdfbox/pdparser/MissingCatalog.pdf", __DIR__)
    # # Should load without raising an exception
    # doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    # doc.should_not be_nil
    # doc.close if doc.responds_to?(:close)
  end

  pending "test PDFBOX-3208" do
    # TODO: Port testPDFBox3208
    # Test /Info dictionary retrieval
  end

  pending "test PDFBOX-3783" do
    # TODO: Port testPDFBox3783
    # Test parsing file with trash after %%EOF
  end

  pending "test PDFBOX-3785" do
    # TODO: Port testPDFBox3785
    # Test truncated file with several revisions has correct page count
  end

  pending "test PDFBOX-3947" do
    # Test parsing file with broken object stream
    # pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3947-670064.pdf", __DIR__)
    # # Should load without raising an exception
    # doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    # doc.should_not be_nil
    # doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3948" do
    # Test parsing file with object stream containing unexpected newlines
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3948-EUWO6SQS5TM4VGOMRD3FLXZHU35V2CP2.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3949" do
    # Test parsing file with incomplete object stream
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3949-MKFYUGZWS3OPXLLVU2Z4LWCTVA5WNOGF.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  pending "test PDFBOX-3950" do
    # TODO: Port testPDFBox3950
    # Test parsing and rendering of truncated file with missing pages
  end

  pending "test PDFBOX-3951" do
    # TODO: Port testPDFBox3951
    # Test parsing of truncated file
  end

  pending "test PDFBOX-3964" do
    # TODO: Port testPDFBox3964
    # Test parsing of broken file
  end

  pending "test PDFBOX-3977" do
    # TODO: Port testPDFBox3977
    # Test /Info dictionary retrieval in brute force search
  end

  pending "test parse genko file" do
    # TODO: Port testParseGenko
  end

  pending "test PDFBOX-4338" do
    # TODO: Port testPDFBox4338
  end

  pending "test PDFBOX-4339" do
    # TODO: Port testPDFBox4339
  end

  pending "test PDFBOX-4153" do
    # TODO: Port testPDFBox4153
    # Test parsing file with outline
  end

  pending "test PDFBOX-4490" do
    # TODO: Port testPDFBox4490
    # Test page count
  end

  pending "test PDFBOX-5025" do
    # TODO: Port testPDFBox5025
    # Test for "74191endobj"
  end
end
