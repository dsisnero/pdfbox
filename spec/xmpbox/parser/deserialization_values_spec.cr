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

        thumbs = basic.not_nil!.thumbnails_property
        thumbs.should_not be_nil
        thumbs.not_nil!.size.should eq(2)
        t0 = thumbs.not_nil![0]
        t0.height.should eq(162)
        t0.width.should eq(216)
        t0.format.should eq("JPEG")
        t0.image.should eq("/9j/4AAQSkZJRgABAgEASABIAAD")
        t1 = thumbs.not_nil![1]
        t1.height.should eq(162)
        t1.width.should eq(216)
        t1.format.should eq("JPEG")
        t1.image.should eq("/9j/4AAQSkZJRgABAgEASABIAAD")

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

      # Port of DeserializationTest.checkTransform — serialize then re-parse must
      # preserve the schema count (data integrity; the SHA-256 digests are not
      # reproduced since byte-exact output parity is out of scope).
      {
        "structured_recursive.xml" => 1,
        "empty_list.xml"           => 1,
        "AltBagSeqTest.xml"        => 6,
      }.each do |rel, expected_schemas|
        it "round-trips #{rel} preserving #{expected_schemas} schemas" do
          path = File.join(fixture_dir, "org", "apache", "xmpbox", "parser", rel)
          parser = DomXmpParser.new(strict_parsing: false)
          xmp = parser.parse(File.open(path))
          xmp.all_schemas.size.should eq(expected_schemas)
          output = Xmpbox::Xml::XmpSerializer.new.serialize(xmp)
          rxmp = parser.parse(output)
          rxmp.all_schemas.size.should eq(expected_schemas)
        end
      end

      it "round-trips attr_as_props.xml preserving schema count" do
        path = File.join(fixture_dir, "validxmp", "attr_as_props.xml")
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(File.open(path))
        output = Xmpbox::Xml::XmpSerializer.new.serialize(xmp)
        rxmp = parser.parse(output)
        rxmp.all_schemas.size.should eq(xmp.all_schemas.size)
      end

      it "round-trips only_space_fields.xmp preserving schema count and spaces" do
        path = File.join(fixture_dir, "validxmp", "only_space_fields.xmp")
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(File.open(path))
        output = Xmpbox::Xml::XmpSerializer.new.serialize(xmp)
        rxmp = parser.parse(output)
        rxmp.all_schemas.size.should eq(xmp.all_schemas.size)
        rxmp.adobe_pdf_schema.not_nil!.producer.should eq(" ")
      end

      it "PDFBOX-6029 round-trips an empty date property" do
        s = "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" +
            "<x:xmpmeta x:xmptk=\"Adobe XMP Core 4.2.1-c041 52.342996, 2008/05/07-20:48:00\" xmlns:x=\"adobe:ns:meta/\">\n" +
            "  <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "   <rdf:Description rdf:about=\"\" xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\">\n" +
            "    <xmp:CreateDate></xmp:CreateDate>\n" +
            "   </rdf:Description>\n" +
            "  </rdf:RDF>\n" +
            "</x:xmpmeta>\n" +
            "<?xpacket end=\"w\"?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)
        output = Xmpbox::Xml::XmpSerializer.new.serialize(xmp)
        rxmp = parser.parse(output)
        rxmp.all_schemas.size.should eq(1)
      end

      it "testMetadataParsing round-trips constructed metadata" do
        meta = Xmpbox::XMPMetadata.create_xmp_metadata
        dc = meta.create_and_add_dublin_core_schema
        dc.coverage = "coverage"
        dc.add_contributor("contributor1")
        dc.add_contributor("contributor2")
        dc.set_title("x-default", "Description")
        pdf = meta.create_and_add_adobe_pdf_schema
        pdf.producer = "Producer"
        pdf.pdf_version = "1.4"

        output = Xmpbox::Xml::XmpSerializer.new.serialize(meta)
        rxmp = DomXmpParser.new.parse(output)
        rxmp.all_schemas.size.should eq(2)
      end
    end
  end
end
