require "../spec_helper"
require "../../src/xmpbox"

describe Xmpbox::Xml::DomXmpParser do
  fixture_dir = File.join(__DIR__, "..", "fixtures", "xmpbox")

  describe "#parse" do
    it "parses a simple XMP metadata file" do
      fixture_path = File.join(fixture_dir, "validxmp", "only_space_fields.xmp")
      File.exists?(fixture_path).should be_true

      xml_content = File.read(fixture_path)
      parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      metadata = parser.parse(xml_content)

      metadata.should_not be_nil

      # Should have Dublin Core schema
      dc = metadata.dublin_core_schema
      dc.should be_nil # This file doesn't have DC

      # Should have XMP Basic schema
      xmp_basic = metadata.xmp_basic_schema
      xmp_basic.should_not be_nil
      xmp_basic.not_nil!.unqualified_text_property_value("CreatorTool").should eq "Canon "

      # Should have Adobe PDF schema
      pdf = metadata.adobe_pdf_schema
      pdf.should_not be_nil
      pdf.not_nil!.unqualified_text_property_value("Producer").should eq ""

      # Should have PDFA Identification schema
      pdfaid = metadata.pdfa_identification_schema
      pdfaid.should_not be_nil
      pdfaid.not_nil!.unqualified_text_property_value("part").should eq "1"
      pdfaid.not_nil!.unqualified_text_property_value("conformance").should eq "B"
    end

    it "parses a more complex XMP file with sequences and structured types" do
      fixture_path = File.join(fixture_dir, "org", "apache", "xmpbox", "parser", "isartorStyleXMPOK.xml")
      File.exists?(fixture_path).should be_true

      xml_content = File.read(fixture_path)
      parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      metadata = parser.parse(xml_content)

      metadata.should_not be_nil

      xmp_basic = metadata.xmp_basic_schema
      xmp_basic.should_not be_nil
      xmp_basic.not_nil!.unqualified_text_property_value("ModifyDate").should_not be_nil

      xmpmm = metadata.xmp_media_management_schema
      xmpmm.should_not be_nil
      xmpmm.not_nil!.unqualified_text_property_value("DocumentID").should_not be_nil
    end

    it "parses metadata.rdf with Dublin Core and rights schemas" do
      fixture_path = File.join(fixture_dir, "validxmp", "metadata.rdf")
      File.exists?(fixture_path).should be_true

      xml_content = File.read(fixture_path)
      parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      metadata = parser.parse(xml_content)

      metadata.should_not be_nil

      dc = metadata.dublin_core_schema
      dc.should_not be_nil
      dc.not_nil!.unqualified_text_property_value("format").should eq "application/pdf"
    end
  end
end
