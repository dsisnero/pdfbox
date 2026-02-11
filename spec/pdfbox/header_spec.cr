require "../spec_helper"

describe Pdfbox::Pdfparser::Parser do
  describe "#parse_header" do
    it "parses PDF version header" do
      source = Pdfbox::IO::RandomAccessReadBuffer.new("%PDF-1.4\n".to_slice)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      version = parser.parse_header
      version.should eq("1.4")
    end

    it "parses PDF header with binary comment" do
      source = Pdfbox::IO::RandomAccessReadBuffer.new("%PDF-1.7\n%\xE2\xE3\xCF\xD3\n".to_slice)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      version = parser.parse_header
      version.should eq("1.7")
    end

    it "raises error on invalid header" do
      source = Pdfbox::IO::RandomAccessReadBuffer.new("invalid".to_slice)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      expect_raises(Pdfbox::Pdfparser::SyntaxError) do
        parser.parse_header
      end
    end
  end
end

describe Pdfbox::Pdfwriter::Writer do
  describe "#write_header" do
    it "writes PDF version header" do
      io = IO::Memory.new
      writer = Pdfbox::Pdfwriter::Writer.new(io, Pdfbox::Pdmodel::Document.new)
      writer.write_header("1.4")
      io.to_s.should eq("%PDF-1.4\n%\xE2\xE3\xCF\xD3\n")
    end
  end
end
