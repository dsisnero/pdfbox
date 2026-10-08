require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSStream.java#toTextString
#
# toTextString decodes the stream data (through its filters) as a PDF text
# string (UTF-16BE/PDFDocEncoding), like COSString.getString(). Used by
# PDVariableText#getRichTextValue.
describe "COSStream#to_text_string" do
  it "decodes UTF-16BE text (with BOM) from the stream" do
    bytes = Bytes[0xFE_u8, 0xFF_u8, 0x00_u8, 0x48_u8, 0x00_u8, 0x69_u8] # "Hi"
    stream = Pdfbox::Cos::Stream.new(data: bytes)
    stream.to_text_string.should eq("Hi")
  end

  it "decodes PDFDocEncoding text from the stream" do
    stream = Pdfbox::Cos::Stream.new(data: "Plain".to_slice)
    stream.to_text_string.should eq("Plain")
  end

  it "decodes a FlateDecode stream before interpreting it as text" do
    io = ::IO::Memory.new
    writer = Compress::Zlib::Writer.new(io)
    writer.write("Compressed".to_slice)
    writer.close

    stream = Pdfbox::Cos::Stream.new(data: io.to_slice)
    stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("FlateDecode")
    stream.to_text_string.should eq("Compressed")
  end

  it "returns an empty string when the stream cannot be decoded" do
    # Corrupt FlateDecode data (Java catches the IOException and returns "").
    stream = Pdfbox::Cos::Stream.new(data: Bytes[0x00_u8, 0x01_u8, 0x02_u8, 0x03_u8])
    stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("FlateDecode")
    stream.to_text_string.should eq("")
  end
end
