require "../../spec_helper"

module Pdfbox::Pdfparser
  module PDFStreamParserSpecHelpers
    # Helper to parse string and return list of tokens
    def self.parse_token_string(s : String) : Array(Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator)
      parser = PDFStreamParser.new(s)
      parser.parse
    end

    # Checks whether there are two operators, one inline image and the named operator
    def self.test_inline_image_2ops(s : String, image_data_string : String, op_name : String) : Nil
      tokens = parse_token_string(s)
      tokens.size.should eq(2)

      op1 = tokens[0]
      op1.should be_a(Pdfbox::ContentStream::Operator)
      op1 = op1.as(Pdfbox::ContentStream::Operator)
      op1.name.should eq(Pdfbox::ContentStream::OperatorName::BEGIN_INLINE_IMAGE_DATA)
      image_data = op1.image_data || raise "Expected image data"
      image_data.size.should eq(image_data_string.bytesize)
      String.new(image_data).should eq(image_data_string)

      op2 = tokens[1]
      op2.should be_a(Pdfbox::ContentStream::Operator)
      op2 = op2.as(Pdfbox::ContentStream::Operator)
      op2.name.should eq(op_name)
    end

    # Checks whether there is one operator, one inline image
    def self.test_inline_image_1op(s : String, image_data_string : String) : Nil
      tokens = parse_token_string(s)
      tokens.size.should eq(1)

      op = tokens[0]
      op.should be_a(Pdfbox::ContentStream::Operator)
      op = op.as(Pdfbox::ContentStream::Operator)
      op.name.should eq(Pdfbox::ContentStream::OperatorName::BEGIN_INLINE_IMAGE_DATA)
      image_data = op.image_data || raise "Expected image data"
      image_data.size.should eq(image_data_string.bytesize)
      String.new(image_data).should eq(image_data_string)
    end
  end

  describe PDFStreamParser do
    describe "number/reference tokenization parity" do
      it "parses object-reference-like sequences as numbers plus operator" do
        # Java source of truth:
        # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/PDFStreamParser.java
        # parseNextToken() numeric branch always returns COSNumber; it does not parse references.
        tokens = PDFStreamParserSpecHelpers.parse_token_string("12 0 R")
        tokens.size.should eq(3)

        tokens[0].should be_a(Pdfbox::Cos::Integer)
        tokens[0].as(Pdfbox::Cos::Integer).value.should eq(12)
        tokens[1].should be_a(Pdfbox::Cos::Integer)
        tokens[1].as(Pdfbox::Cos::Integer).value.should eq(0)
        tokens[2].should be_a(Pdfbox::ContentStream::Operator)
        tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("R")
      end

      it "keeps numbers before drawing operators as standalone numeric operands" do
        tokens = PDFStreamParserSpecHelpers.parse_token_string("100 200 m")
        tokens.size.should eq(3)
        tokens[0].should be_a(Pdfbox::Cos::Integer)
        tokens[1].should be_a(Pdfbox::Cos::Integer)
        tokens[2].should be_a(Pdfbox::ContentStream::Operator)
        tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("m")
      end
    end

    describe "inline images" do
      it "parses ID with Q operator" do
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI Q", "12345", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI Q ", "12345", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI  Q", "12345", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI  Q ", "12345", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI \x00Q", "12345", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI Q                             ", "12345", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI                               Q ", "12345", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI                               Q", "12345", "Q")
      end

      it "parses ID with EMC operator" do
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI EMC", "12345", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI EMC ", "12345", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI  EMC", "12345", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI  EMC ", "12345", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI EMC                           ", "12345", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI                               EMC ", "12345", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12345EI                               EMC", "12345", "EMC")
      end

      it "parses ID without following operator" do
        PDFStreamParserSpecHelpers.test_inline_image_1op("ID\n12345EI", "12345")
        PDFStreamParserSpecHelpers.test_inline_image_1op("ID\n12345EI                               ", "12345")
      end

      it "handles EI within image data" do
        PDFStreamParserSpecHelpers.test_inline_image_1op("ID\n12EI5EI", "12EI5")
        PDFStreamParserSpecHelpers.test_inline_image_1op("ID\n12EI5EI ", "12EI5")
        PDFStreamParserSpecHelpers.test_inline_image_1op("ID\n12EI5EIQEI", "12EI5EIQ")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EIQEI Q", "12EI5EIQ", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI Q", "12EI5", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI Q ", "12EI5", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI EMC", "12EI5", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI EMC ", "12EI5", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI                                Q", "12EI5", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI                                Q ", "12EI5", "Q")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI                                EMC", "12EI5", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI                                EMC ", "12EI5", "EMC")
      end

      # MAX_BIN_CHAR_TEST_LENGTH is currently 10, test boundaries
      it "handles boundary whitespace lengths" do
        # 10 spaces
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI       EMC ", "12EI5", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI       Q   ", "12EI5", "Q")
        # 11 spaces
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI        EMC ", "12EI5", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI        Q   ", "12EI5", "Q")
        # 12 spaces
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI         EMC ", "12EI5", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI         Q   ", "12EI5", "Q")
        # 13 spaces
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI          EMC ", "12EI5", "EMC")
        PDFStreamParserSpecHelpers.test_inline_image_2ops("ID\n12EI5EI          Q   ", "12EI5", "Q")
      end

      # PDFBOX-6038: test that nested BI is detected.
      it "raises on nested BI operator" do
        expect_raises(::IO::Error, "Nested 'BI' operator not allowed at offset 11, first: 2") do
          PDFStreamParserSpecHelpers.parse_token_string("BI/IB/IB BI/ BI")
        end
      end
    end
  end
end
