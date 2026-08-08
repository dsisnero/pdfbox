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

      it "testIsartorStyleWithThumbs parses thumbnails and extension schemas" do
        path = File.join(fixture_dir, "org", "apache", "xmpbox", "parser", "ThumbisartorStyle.xml")
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(File.open(path))

        mm = xmp.xmp_media_management_schema
        mm.should_not be_nil
        mm.not_nil!.document_id.should eq("uuid:09C78666-2F91-3A9C-92AF-3691A6D594F7")

        basic = xmp.xmp_basic_schema
        basic.should_not be_nil
        basic.not_nil!.create_date.should_not be_nil
        basic.not_nil!.modify_date.should_not be_nil
        basic.not_nil!.metadata_date.should_not be_nil

        thumbs = basic.not_nil!.abstract_property("Thumbnails")
        thumbs.should be_a(Xmpbox::Type::ArrayProperty)
        thumbs.as(Xmpbox::Type::ArrayProperty).all_properties.size.should eq(2)
        t0 = thumbs.as(Xmpbox::Type::ArrayProperty).all_properties[0].as(Xmpbox::Type::ThumbnailType)
        t0.height.should eq(162)
        t0.width.should eq(216)
        t0.format.should eq("JPEG")
        t0.image.should eq("/9j/4AAQSkZJRgABAgEASABIAAD")

        acme = xmp.schema("http://www.acme.com/ns/email/1/")
        acme.should_not be_nil
        delivery = acme.not_nil!.abstract_property("Delivery-Date")
        delivery.should_not be_nil
        delivery.as(Xmpbox::Type::AbstractSimpleProperty).string_value.should eq("2007-11-09T09:55:36+01:00")

        from = acme.not_nil!.abstract_property("From")
        from.should be_a(Xmpbox::Type::DefinedStructuredType)
        dst = from.as(Xmpbox::Type::DefinedStructuredType)
        dst.property("name").as(Xmpbox::Type::AbstractSimpleProperty).string_value.should eq("John Doe")
        dst.property("mailto").as(Xmpbox::Type::AbstractSimpleProperty).string_value.should eq("john@acme.com")
      end
    end
  end
end
