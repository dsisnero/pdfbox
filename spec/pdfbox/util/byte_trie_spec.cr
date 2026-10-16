require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/util/filetypedetector/ByteTrie.java
# Upstream has no dedicated ByteTrie test; this is a characterization spec of a
# prefix tree ("trie") that stores values for byte sequences.
describe Pdfbox::Util::ByteTrie do
  it "returns the most specific value stored for a byte sequence" do
    trie = Pdfbox::Util::ByteTrie(String).new
    trie.add_path("short", Bytes[0x01])
    trie.add_path("long", Bytes[0x01, 0x02])

    trie.find(Bytes[0x01, 0x02, 0x03]).should eq("long")
    trie.find(Bytes[0x01, 0x09]).should eq("short")
  end

  it "adds a value across multiple byte parts" do
    trie = Pdfbox::Util::ByteTrie(String).new
    trie.add_path("tiff", "II".to_slice, Bytes[0x2A, 0x00])

    trie.find(Bytes[0x49, 0x49, 0x2A, 0x00]).should eq("tiff")
    trie.find(Bytes[0x49, 0x49]).should be_nil
  end

  it "returns nil when no path matches and no default is set" do
    trie = Pdfbox::Util::ByteTrie(String).new
    trie.add_path("gif", "GIF".to_slice)

    trie.find(Bytes[0x00]).should be_nil
  end

  it "uses the default value when no path matches" do
    trie = Pdfbox::Util::ByteTrie(String).new
    trie.set_default_value("unknown")
    trie.add_path("gif", "GIF".to_slice)

    trie.find("GIF".to_slice).should eq("gif")
    trie.find(Bytes[0x00]).should eq("unknown")
  end

  it "tracks the maximum depth" do
    trie = Pdfbox::Util::ByteTrie(String).new
    trie.max_depth.should eq(0)

    trie.add_path("a", Bytes[0x01, 0x02])
    trie.max_depth.should eq(2)

    trie.add_path("b", Bytes[0x03], Bytes[0x04, 0x05])
    trie.max_depth.should eq(3)
  end

  it "raises when a value is already set for a node" do
    trie = Pdfbox::Util::ByteTrie(String).new
    trie.add_path("a", Bytes[0x01])

    expect_raises(Pdfbox::Util::IllegalStateError, "Value already set for this trie node") do
      trie.add_path("b", Bytes[0x01])
    end
  end

  it "raises when the default value is already set" do
    trie = Pdfbox::Util::ByteTrie(String).new
    trie.set_default_value("unknown")

    expect_raises(Pdfbox::Util::IllegalStateError, "Value already set for this trie node") do
      trie.set_default_value("other")
    end
  end

  it "resolves file types through the FileTypeDetector trie" do
    Pdfbox::Util::FileTypeDetector.detect_file_type(Bytes[0xFF, 0xD8, 0x00]).should eq(Pdfbox::Util::FileType::Jpeg)
    Pdfbox::Util::FileTypeDetector.detect_file_type("II".to_slice + Bytes[0x2A, 0x00]).should eq(Pdfbox::Util::FileType::Tiff)
    Pdfbox::Util::FileTypeDetector.detect_file_type(Bytes[0x00, 0x00]).should eq(Pdfbox::Util::FileType::Unknown)
  end
end
