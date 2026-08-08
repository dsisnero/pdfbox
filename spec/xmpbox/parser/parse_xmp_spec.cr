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
    # Port of TestXMPWithUndefinedSchemas.java — lenient parsing of prism.xmp
    # registers the prism namespace and its aggregationType property.
    it "parses prism.xmp leniently with namespace and property" do
      path = File.join(fixture_dir, "/undefinedxmp/prism.xmp")
      parser = Xmpbox::Xml::DomXmpParser.new
      parser.strict_parsing = false
      xmp = parser.parse(File.open(path))

      xmp.all_schemas.should_not be_empty

      namespace = "http://prismstandard.org/namespaces/basic/2.0/"
      property_name = "aggregationType"
      property_value = "journal"

      schema = xmp.schema(namespace)
      schema.should_not be_nil
      prop = schema.not_nil!.abstract_property(property_name)
      prop.should_not be_nil
      prop.not_nil!.property_name.should eq(property_name)
      schema.not_nil!.unqualified_text_property_value(property_name).should eq(property_value)
    end
  end
end
