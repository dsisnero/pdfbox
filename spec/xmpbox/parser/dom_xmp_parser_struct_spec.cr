require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Xml
    # Port of DomXmpParserTest.java structured-type and extension-schema tests.
    describe DomXmpParser do
      fixture_dir = File.join(__DIR__, "..", "..", "fixtures", "xmpbox")

      it "testPageTextSchema parses dimensions, resource ref, and page text" do
        s = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n" +
            "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\">\n" +
            "\t<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "           <rdf:Description xmlns:stRef=\"http://ns.adobe.com/xap/1.0/sType/ResourceRef#\"\n" +
            "\t\t                 xmlns:xmpMM=\"http://ns.adobe.com/xap/1.0/mm/\"\n" +
            "\t\t                 rdf:about=\"\">\n" +
            "\t\t\t<xmpMM:InstanceID>uuid:b429d411-e628-45ca-b932-d2c77fbe6cd3</xmpMM:InstanceID>\n" +
            "\t\t\t<xmpMM:DocumentID>adobe:docid:indd:db084a4d-dbb2-11dc-ac34-beb3cc4028ec</xmpMM:DocumentID>\n" +
            "\t\t\t<xmpMM:RenditionClass>proof:pdf</xmpMM:RenditionClass>\n" +
            "\t\t\t<xmpMM:DerivedFrom rdf:parseType=\"Resource\">\n" +
            "\t\t\t\t<stRef:documentID>adobe:docid:indd:fa7c6589-9f4a-11dc-9641-af983df728d7</stRef:documentID>\n" +
            "\t\t\t</xmpMM:DerivedFrom>\n" +
            "\t\t</rdf:Description>\n" +
            "\t\t<rdf:Description xmlns:xmpTPg=\"http://ns.adobe.com/xap/1.0/t/pg/\"\n" +
            "\t\t                 rdf:about=\"\">\n" +
            "\t\t\t<xmpTPg:MaxPageSize>\n" +
            "\t\t\t\t<rdf:Description xmlns:stDim=\"http://ns.adobe.com/xap/1.0/sType/Dimensions#\">\n" +
            "\t\t\t\t\t<stDim:w>4</stDim:w>\n" +
            "\t\t\t\t\t<stDim:h>3</stDim:h>\n" +
            "\t\t\t\t\t<stDim:unit>inch</stDim:unit>\n" +
            "\t\t\t\t</rdf:Description>\n" +
            "\t\t\t</xmpTPg:MaxPageSize>\n" +
            "\t\t\t<xmpTPg:NPages>7</xmpTPg:NPages>\n" +
            "\t\t</rdf:Description>\n" +
            "\t</rdf:RDF>\n" +
            "</x:xmpmeta><?xpacket end=\"r\"?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)

        page_text = xmp.xmp_page_text_schema
        page_text.should_not be_nil
        dim = page_text.not_nil!.abstract_property("MaxPageSize")
        dim.should be_a(Type::DimensionsType)
        dim.as(Type::DimensionsType).w.should eq(4.0)
        dim.as(Type::DimensionsType).h.should eq(3.0)
        dim.as(Type::DimensionsType).unit.should eq("inch")

        n_pages = page_text.not_nil!.abstract_property("NPages")
        n_pages.should_not be_nil
        n_pages.as(Type::IntegerType).value.should eq(7)

        xmpmm = xmp.xmp_media_management_schema
        xmpmm.should_not be_nil
        xmpmm.not_nil!.instance_id.should eq("uuid:b429d411-e628-45ca-b932-d2c77fbe6cd3")
        xmpmm.not_nil!.rendition_class.should eq("proof:pdf")
        xmpmm.not_nil!.document_id.should eq("adobe:docid:indd:db084a4d-dbb2-11dc-ac34-beb3cc4028ec")

        derived = xmpmm.not_nil!.abstract_property("DerivedFrom")
        derived.should_not be_nil
        derived.should be_a(Type::ResourceRefType)
        derived.as(Type::ResourceRefType).document_id.should eq("adobe:docid:indd:fa7c6589-9f4a-11dc-9641-af983df728d7")
      end

      it "testPageTextSchema2 parses dimensions with attribute w/h and element unit" do
        s = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n" +
            "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\">\n" +
            "\t<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "           <rdf:Description xmlns:xmpTPg=\"http://ns.adobe.com/xap/1.0/t/pg/\"\n" +
            "                            xmlns:stDim=\"http://ns.adobe.com/xap/1.0/sType/Dimensions#\"\n" +
            "\t\t                 rdf:about=\"\">\n" +
            "\t\t\t<xmpTPg:MaxPageSize>\n" +
            "\t\t\t\t<rdf:Description stDim:w=\"4\" stDim:h=\"3\">\n" +
            "\t\t\t\t\t<stDim:unit>inch</stDim:unit>\n" +
            "\t\t\t\t</rdf:Description>\n" +
            "\t\t\t</xmpTPg:MaxPageSize>\n" +
            "\t\t\t<xmpTPg:NPages>7</xmpTPg:NPages>\n" +
            "\t\t</rdf:Description>\n" +
            "\t</rdf:RDF>\n" +
            "</x:xmpmeta><?xpacket end=\"r\"?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)

        page_text = xmp.xmp_page_text_schema
        page_text.should_not be_nil
        dim = page_text.not_nil!.abstract_property("MaxPageSize")
        dim.should be_a(Type::DimensionsType)
        dim.as(Type::DimensionsType).w.should eq(4.0)
        dim.as(Type::DimensionsType).h.should eq(3.0)
        dim.as(Type::DimensionsType).unit.should eq("inch")
      end

      it "testPageTextSchema3 parses dimensions as attributes only" do
        s = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n" +
            "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\">\n" +
            "\t<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "           <rdf:Description xmlns:xmpTPg=\"http://ns.adobe.com/xap/1.0/t/pg/\"\n" +
            "                            xmlns:stDim=\"http://ns.adobe.com/xap/1.0/sType/Dimensions#\"\n" +
            "\t\t                 rdf:about=\"\">\n" +
            "\t\t\t<xmpTPg:MaxPageSize>\n" +
            "\t\t\t\t<rdf:Description stDim:w=\"4\" stDim:h=\"3\" stDim:unit=\"inch\"/>\n" +
            "\t\t\t</xmpTPg:MaxPageSize>\n" +
            "\t\t\t<xmpTPg:NPages>7</xmpTPg:NPages>\n" +
            "\t\t</rdf:Description>\n" +
            "\t</rdf:RDF>\n" +
            "</x:xmpmeta><?xpacket end=\"r\"?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)

        page_text = xmp.xmp_page_text_schema
        page_text.should_not be_nil
        dim = page_text.not_nil!.abstract_property("MaxPageSize")
        dim.should be_a(Type::DimensionsType)
        dim.as(Type::DimensionsType).w.should eq(4.0)
        dim.as(Type::DimensionsType).h.should eq(3.0)
        dim.as(Type::DimensionsType).unit.should eq("inch")
      end

      it "PDFBOX-3882 parses an inline extension schema and its defined types" do
        path = File.join(fixture_dir, "org", "apache", "xmpbox", "xml", "PDFBOX-3882-dematbox.xml")
        parser = DomXmpParser.new
        xmp = parser.parse(File.open(path))

        pdfa_ext = xmp.pdfa_extension_schema
        pdfa_ext.should_not be_nil
        schemas = pdfa_ext.not_nil!.schemas_property
        schemas.should_not be_nil
        all = schemas.not_nil!.all_properties
        all.size.should eq(1)
        pdfa_schema = all[0].as(Type::PDFASchemaType)
        pdfa_schema.namespace_uri_value.should eq("http://www.sagemcom.com/documents/xmlns/dematbox")
        pdfa_schema.prefix_value.should eq("dematbox")

        ext = xmp.schema("http://www.sagemcom.com/documents/xmlns/dematbox")
        ext.should_not be_nil
        ext.not_nil!.namespace.should eq("http://www.sagemcom.com/documents/xmlns/dematbox")
        ext.not_nil!.prefix.should eq("dematbox")

        page_info = ext.not_nil!.abstract_property("PageInfo")
        page_info.should_not be_nil
        page_info.should be_a(Type::ArrayProperty)
        dst = page_info.as(Type::ArrayProperty).all_properties[0]
        dst.should be_a(Type::DefinedStructuredType)
        dst.as(Type::DefinedStructuredType).property("number").as(Type::IntegerType).value.should eq(1)
        dst.as(Type::DefinedStructuredType).property("origNumber").as(Type::IntegerType).value.should eq(1)
      end
    end
  end
end
