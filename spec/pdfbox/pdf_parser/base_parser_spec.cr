require "../../spec_helper"

describe Pdfbox::Pdfparser::BaseParser do
  it "handles PDFBOX-6041 without unexpected exception (TestBaseParser#testBaseParserStackOverflow)" do
    fixture = File.expand_path("../../resources/pdfbox/pdparser/PDFBOX-6041-example.pdf", __DIR__)
    bytes = File.open(fixture) do |io|
      data = Bytes.new(io.size.to_i32)
      io.read_fully(data)
      data
    end

    begin
      document = Pdfbox::Loader.load_pdf(bytes)
      document.close if document.responds_to?(:close)
    rescue ex : IO::Error
      ex.message.should eq("Missing root object specification in trailer.")
    end
  end
end
