require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/COSFilterInputStream.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::DigitalSignature
  describe COSFilterInputStream do
    it "returns only the bytes inside one (begin, length) interval" do
      stream = COSFilterInputStream.new(::IO::Memory.new("Hello, World!"), [7, 5])
      String.new(stream.to_byte_array).should eq("World")
    end

    it "concatenates multiple intervals in order" do
      stream = COSFilterInputStream.new(::IO::Memory.new("Hello, World!"), [0, 5, 7, 5])
      String.new(stream.to_byte_array).should eq("HelloWorld")
    end

    it "reads from a byte array source" do
      stream = COSFilterInputStream.new("0123456789".to_slice, [2, 3, 8, 2])
      String.new(stream.to_byte_array).should eq("23489")
    end

    it "raises when a range starts past the end of the source" do
      stream = COSFilterInputStream.new("abc".to_slice, [10, 5])
      expect_raises(::IO::Error) { stream.to_byte_array }
    end
  end
end
