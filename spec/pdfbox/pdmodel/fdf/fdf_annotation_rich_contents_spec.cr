require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotation.java
#     getStringOrStream (protected) and getRichContents (/RC).
#
# getStringOrStream decodes a /RC that may be a COSString or a COSStream (via
# COSStream.toTextString), dereferencing indirect objects.
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotation rich contents (getStringOrStream)" do
    it "returns the value of a /RC string" do
      annot = FDFAnnotationFreeText.new
      annot.rich_contents = "Plain"
      annot.rich_contents.should eq("Plain")
    end

    it "decodes a /RC stream as text (Java getStringOrStream)" do
      annot = FDFAnnotationFreeText.new
      bytes = Bytes[0xFE_u8, 0xFF_u8, 0x00_u8, 0x48_u8, 0x00_u8, 0x69_u8] # UTF-16BE "Hi"
      annot.cos_object[Cos::Name.new("RC")] = Cos::Stream.new(data: bytes)
      annot.rich_contents.should eq("Hi")
    end

    it "dereferences an indirect /RC stream" do
      annot = FDFAnnotationFreeText.new
      stream = Cos::Stream.new(data: "Plain".to_slice)
      annot.cos_object[Cos::Name.new("RC")] = Cos::Object.new(stream)
      annot.rich_contents.should eq("Plain")
    end

    it "returns an empty string when /RC is absent (Java getStringOrStream)" do
      FDFAnnotationFreeText.new.rich_contents.should eq("")
    end
  end
end
