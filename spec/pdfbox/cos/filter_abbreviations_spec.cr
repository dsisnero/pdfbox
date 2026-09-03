require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/FilterFactory.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSName.java
#
# Java FilterFactory registers each filter under both its full name and its
# PDF abbreviation (PDF 32000-1 table 6): AHx/ASCIIHexDecode, A85/ASCII85Decode,
# CCF/CCITTFaxDecode, DCT/DCTDecode, Fl/FlateDecode, LZW/LZWDecode,
# RL/RunLengthDecode. Cos::Stream decoding must accept the abbreviation forms.

module Pdfbox::Cos
  describe Stream do
    it "decodes a FlateDecode stream referenced by its Fl abbreviation" do
      raw = "hello pdfbox".to_slice
      encoded = Pdfbox::Filter::FlateFilter.new.encode(raw)
      stream = Stream.new(entries: {} of Name => Base, data: encoded)
      stream[Name.new("Filter")] = Name.new("Fl")
      stream.create_input_stream.gets_to_end.to_slice.should eq(raw)
    end

    it "decodes an ASCII85Decode stream referenced by its A85 abbreviation" do
      raw = "source.pdf ascii85 content".to_slice
      encoded = Pdfbox::Filter::ASCII85Filter.new.encode(raw)
      stream = Stream.new(entries: {} of Name => Base, data: encoded)
      stream[Name.new("Filter")] = Name.new("A85")
      stream.create_input_stream.gets_to_end.to_slice.should eq(raw)
    end

    it "decodes a RunLengthDecode stream referenced by its RL abbreviation" do
      raw = Bytes[1, 2, 3, 4, 5, 128, 140, 180, 255]
      encoded = Pdfbox::Filter::RunLengthDecodeFilter.new.encode(raw)
      stream = Stream.new(entries: {} of Name => Base, data: encoded)
      stream[Name.new("Filter")] = Name.new("RL")
      stream.create_input_stream.gets_to_end.to_slice.should eq(raw)
    end

    it "decodes an LZWDecode stream referenced by its LZW abbreviation" do
      raw = "lzw roundtrip data 1234567890".to_slice
      encoded = Pdfbox::Filter::LZWFilter.new.encode(raw)
      stream = Stream.new(entries: {} of Name => Base, data: encoded)
      stream[Name.new("Filter")] = Name.new("LZW")
      stream.create_input_stream.gets_to_end.to_slice.should eq(raw)
    end

    it "renders source.pdf (A85 filter abbreviation) without exception" do
      file = "vendor/pdfbox/pdfbox/src/test/resources/input/rendering/source.pdf"
      document = Pdfbox::Loader.load_pdf(file)
      begin
        renderer = Pdfbox::Rendering::PDFRenderer.new(document)
        image = renderer.render_image(0)
        image.should_not be_nil
        image.rect.width.should be > 0
      ensure
        document.close
      end
    end
  end
end
