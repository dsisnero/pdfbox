require "../../spec_helper"
require "../../../src/xmpbox"

describe Xmpbox::Xml::DomXmpParser do
  fixture_dir = File.join(__DIR__, "..", "..", "fixtures", "xmpbox")

  describe "parses XMP with defined schemas" do
    valid_files = [
      "/validxmp/override_ns.rdf",
      "/validxmp/ghost2.xmp",
      "/validxmp/history2.rdf",
      "/validxmp/Notepad++_A1b.xmp",
      "/validxmp/metadata.rdf",
      "/validxmp/PDFBOX-6099.xmp",
    ]

    valid_files.each do |rel_path|
      it "parses #{File.basename(rel_path)}" do
        path = File.join(fixture_dir, rel_path)
        parser = Xmpbox::Xml::DomXmpParser.new
        parser.strict_parsing = false
        xmp = parser.parse(File.open(path))
        xmp.all_schemas.should_not be_empty
      end
    end
  end

  describe "parses XMP with undefined schemas" do
    undefined_files = [
      "/undefinedxmp/prism.xmp",
    ]

    undefined_files.each do |rel_path|
      it "parses #{File.basename(rel_path)} leniently" do
        path = File.join(fixture_dir, rel_path)
        parser = Xmpbox::Xml::DomXmpParser.new
        parser.strict_parsing = false
        xmp = parser.parse(File.open(path))
        xmp.all_schemas.should_not be_empty
      end
    end
  end
end
