require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Xml
    # Port of DeserializationTest.java data-value assertions (excluding the
    # SHA-256 digest checks which require byte-exact serialization).
    describe DomXmpParser do
      fixture_dir = File.join(__DIR__, "..", "..", "fixtures", "xmpbox")

      it "testGetTitle reads the dc:title from emptyli.xml" do
        path = File.join(fixture_dir, "validxmp", "emptyli.xml")
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(File.open(path))
        dc = xmp.dublin_core_schema
        dc.should_not be_nil
        dc.not_nil!.title.should eq("title value")
      end

      it "testRdfAboutFound gives every schema an about attribute" do
        path = File.join(fixture_dir, "validxmp", "emptyli.xml")
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(File.open(path))
        xmp.all_schemas.each do |schema|
          schema.about_attribute.should_not be_nil
        end
      end

      it "testWithAttributesAsProperties parses attribute-defined properties" do
        path = File.join(fixture_dir, "validxmp", "attr_as_props.xml")
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(File.open(path))

        pdf = xmp.adobe_pdf_schema
        pdf.should_not be_nil
        pdf.not_nil!.producer.should eq("GPL Ghostscript 8.64")

        dc = xmp.dublin_core_schema
        dc.should_not be_nil
        dc.not_nil!.format.should eq("application/pdf")

        basic = xmp.xmp_basic_schema
        basic.should_not be_nil
        basic.not_nil!.create_date.should_not be_nil

        pdfaid = xmp.pdfa_identification_schema
        pdfaid.should_not be_nil
        pdfaid.not_nil!.conformance.should eq("B")
        pdfaid.not_nil!.part.should eq(1)

        mm = xmp.xmp_media_management_schema
        mm.should_not be_nil
        mm.not_nil!.document_id.should eq("e7127190-445c-11ea-0000-b3bc74086807")
      end

      it "testSpaceTextValues preserves leading/trailing spaces" do
        path = File.join(fixture_dir, "validxmp", "only_space_fields.xmp")
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(File.open(path))

        pdf = xmp.adobe_pdf_schema
        pdf.should_not be_nil
        pdf.not_nil!.producer.should eq(" ")

        basic = xmp.xmp_basic_schema
        basic.should_not be_nil
        basic.not_nil!.creator_tool.should eq("Canon ")
      end
    end
  end
end
