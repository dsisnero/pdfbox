require "../../spec_helper"
require "../../../src/xmpbox"

describe Xmpbox::Xml::DomXmpParser do
  fixture_dir = File.join(__DIR__, "..", "..", "fixtures", "xmpbox")

  # Port of DeserializationTest.java error-type assertions.
  describe "invalid XMP error types" do
    it "XpacketBadStart when no xpacket start" do
      path = File.join(fixture_dir, "invalidxmp", "noxpacket.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::XpacketBadStart)
    end

    it "XpacketBadEnd when no xpacket end" do
      path = File.join(fixture_dir, "invalidxmp", "noxpacketend.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::XpacketBadEnd)
    end

    it "Format when no RDF element" do
      path = File.join(fixture_dir, "invalidxmp", "noroot.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::Format)
    end

    it "Format when two RDF elements" do
      path = File.join(fixture_dir, "invalidxmp", "tworoot.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::Format)
    end

    it "Format when invalid RDF element prefix" do
      path = File.join(fixture_dir, "invalidxmp", "invalidroot2.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::Format)
    end

    it "Format when RDF root is text" do
      path = File.join(fixture_dir, "invalidxmp", "invalidroot.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::Format)
    end

    it "NoSchema for undefined schema" do
      path = File.join(fixture_dir, "invalidxmp", "undefinedschema.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::NoSchema)
    end

    it "NoType for undefined property in defined schema" do
      path = File.join(fixture_dir, "invalidxmp", "undefinedpropertyindefinedschema.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::NoType)
    end

    it "NoValueType for undefined structured type in defined schema" do
      path = File.join(fixture_dir, "invalidxmp", "undefinedstructuredindefinedschema.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(File.open(path))
      end
      ex.error_type.should eq(Xmpbox::Xml::XmpParsingException::ErrorType::NoValueType)
    end
  end
end
