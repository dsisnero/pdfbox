require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/ASCII85Filter.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/ASCII85OutputStream.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/ASCII85InputStream.java
# The Java filter delegates to the ASCII85 stream classes: default line length
# 72, terminator '~', followed by '>' and a newline. Upstream has no dedicated
# test; this is a characterization spec.
describe Pdfbox::Filter::ASCII85Filter do
  it "wraps lines at 72 characters and terminates with ~> followed by a newline" do
    input = Bytes.new(72) { |i| (i + 1).to_u8 }
    encoded = String.new(Pdfbox::Filter::ASCII85Filter.new.encode(input))

    encoded.ends_with?("~>\n").should be_true
    encoded.split('\n').first.size.should eq(72)
  end

  it "compresses an all-zero group to 'z'" do
    encoded = String.new(Pdfbox::Filter::ASCII85Filter.new.encode(Bytes[0, 0, 0, 0]))
    encoded.should eq("z~>\n")
  end

  it "round-trips arbitrary data" do
    filter = Pdfbox::Filter::ASCII85Filter.new
    input = "hello world, ascii85!".to_slice
    filter.decode(filter.encode(input)).should eq(input)
  end

  it "round-trips data with embedded zero groups" do
    filter = Pdfbox::Filter::ASCII85Filter.new
    input = Bytes[0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 255, 254, 253]
    filter.decode(filter.encode(input)).should eq(input)
  end
end
