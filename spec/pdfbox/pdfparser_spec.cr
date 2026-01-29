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
  it "test PDF parser missing catalog" do
    # PDFBOX-3060
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/MissingCatalog.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3208" do
    # Test /Info dictionary retrieval when rebuilding trailer of corrupt file
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3208-L33MUTT2SVCWGCS6UIYL5TH3PNPXHIS6.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil

    # Check document information if available
    # TODO: Add proper document information checks when implemented
    # Expected values from Apache PDFBox test:
    # Author: "Liquent Enterprise Services"
    # Creator: "Liquent services server"
    # Producer: "Amyuni PDF Converter version 4.0.0.9"
    # Keywords: ""
    # Subject: ""
    # Title: "892B77DE781B4E71A1BEFB81A51A5ABC_20140326022424.docx"

    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3783" do
    # PDFBOX-3783: test parsing of file with trash after %%EOF
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3783-72GLBIGUC6LB46ELZFBARRJTLN4RBSQM.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3785" do
    # PDFBOX-3785: Test whether truncated file with several revisions has correct page count
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3785-202097.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil

    # Check page count if available
    # TODO: Add page count check when implemented
    # Expected: 1 page (from Apache PDFBox test)

    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3947" do
    # Test parsing file with broken object stream
    # Requires brute-force parser implementation (issue pdfbox-m19)
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3947-670064.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path, lenient: true)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
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

  it "test PDFBOX-3940" do
    # Test /Info dictionary retrieval when missing modification date
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3940-079977.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path, lenient: true)
    doc.should_not be_nil

    # Check document information if available
    # TODO: Add proper document information checks when implemented
    # Expected values from Apache PDFBox test:
    # Author: "Unknown"
    # Creator: "C:REGULA~1IREGSFR_EQ_EM.WP"
    # Producer: "Acrobat PDFWriter 3.02 for Windows"
    # Keywords: ""
    # Subject: ""
    # Title: "C:REGULA~1IREGSFR_EQ_EM.PDF"

    doc.close if doc.responds_to?(:close)
  end

  pending "test PDFBOX-3950" do
    # TODO: Port testPDFBox3950
    # Test parsing and rendering of truncated file with missing pages
  end

  it "test PDFBOX-3951" do
    # Test parsing of truncated file
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3951-FIHUZWDDL2VGPOE34N6YHWSIGSH5LVGZ.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    # TODO: Add page count check when implemented
    # Expected: 143 pages
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3964" do
    # Test parsing of broken file
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3964-c687766d68ac766be3f02aaec5e0d713_2.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-3977" do
    # Test /Info dictionary retrieval in brute force search
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-3977-63NGFQRI44HQNPIPEJH5W2TBM6DJZWMI.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    # TODO: Add document information checks when implemented
    doc.close if doc.responds_to?(:close)
  end

  it "test parse genko file" do
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/genko_oc_shiryo1.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path, lenient: true)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-4338" do
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-4338.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-4339" do
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-4339.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-4153" do
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-4153-WXMDXCYRWFDCMOSFQJ5OAJIAFXYRZ5OA.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    # TODO: Add outline check when implemented
    # Expected: First outline item title "Main Menu"
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-4490" do
    # Test that PDFBOX-4490 has 3 pages
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-4490.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    # TODO: Add page count check when implemented
    # Expected: 3 pages
    doc.close if doc.responds_to?(:close)
  end

  it "test PDFBOX-5025" do
    pdf_path = File.expand_path("../resources/pdfbox/pdparser/PDFBOX-5025.pdf", __DIR__)
    # Should load without raising an exception
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil
    doc.close if doc.responds_to?(:close)
  end
end
