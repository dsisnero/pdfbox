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

      it "PDFBOX-3882_2 parses ResourceEventType and LayerType from attributes" do
        s = "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\"\n" +
            "           x:xmptk=\"Adobe XMP Core 5.0-c060 61.134777, 2010/02/12-17:32:00        \">\n" +
            "\t<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "\t\t<rdf:Description rdf:about=\"\"\n" +
            "\t\t                 xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\"\n" +
            "\t\t                 xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n" +
            "\t\t                 xmlns:xmpMM=\"http://ns.adobe.com/xap/1.0/mm/\"\n" +
            "\t\t                 xmlns:stEvt=\"http://ns.adobe.com/xap/1.0/sType/ResourceEvent#\"\n" +
            "\t\t                 xmlns:stRef=\"http://ns.adobe.com/xap/1.0/sType/ResourceRef#\"\n" +
            "\t\t                 xmlns:photoshop=\"http://ns.adobe.com/photoshop/1.0/\"\n" +
            "\t\t                 xmp:CreatorTool=\"Adobe Photoshop CS5 Macintosh\"\n" +
            "\t\t                 xmp:CreateDate=\"2012-04-30T12:52:07-04:00\"\n" +
            "\t\t                 xmp:MetadataDate=\"2012-05-03T13:36:11-04:00\"\n" +
            "\t\t                 xmp:ModifyDate=\"2012-05-03T13:36:11-04:00\"\n" +
            "\t\t                 dc:format=\"image/jpeg\"\n" +
            "\t\t                 xmpMM:InstanceID=\"xmp.iid:49E997338D4911E1AB62EBF9B374B234\"\n" +
            "\t\t                 xmpMM:DocumentID=\"xmp.did:49E997348D4911E1AB62EBF9B374B234\"\n" +
            "\t\t                 xmpMM:OriginalDocumentID=\"xmp.did:01801174072068118A6D9A879C818256\"\n" +
            "\t\t                 photoshop:History=\"2012-05-03T09:34:50-04:00&#x9;File i1222b.jpg opened&#xA;\">\n" +
            "\t\t\t<xmpMM:History>\n" +
            "\t\t\t\t<rdf:Seq>\n" +
            "\t\t\t\t\t<rdf:li stEvt:action=\"created\"\n" +
            "\t\t\t\t\t        stEvt:instanceID=\"xmp.iid:01801174072068118A6D9A879C818256\"\n" +
            "\t\t\t\t\t        stEvt:when=\"2012-04-30T12:52:07-04:00\"\n" +
            "\t\t\t\t\t        stEvt:softwareAgent=\"Adobe Photoshop CS5 Macintosh\"/>\n" +
            "\t\t\t\t\t<rdf:li stEvt:action=\"saved\"\n" +
            "\t\t\t\t\t        stEvt:instanceID=\"xmp.iid:02801174072068118A6D9A879C818256\"\n" +
            "\t\t\t\t\t        stEvt:when=\"2012-04-30T12:54:04-04:00\"\n" +
            "\t\t\t\t\t        stEvt:softwareAgent=\"Adobe Photoshop CS5 Macintosh\"\n" +
            "\t\t\t\t\t        stEvt:changed=\"/\"/>\n" +
            "\t\t\t\t\t<rdf:li stEvt:action=\"saved\"\n" +
            "\t\t\t\t\t        stEvt:instanceID=\"xmp.iid:03801174072068118A6D9A879C818256\"\n" +
            "\t\t\t\t\t        stEvt:when=\"2012-04-30T12:54:48-04:00\"\n" +
            "\t\t\t\t\t        stEvt:softwareAgent=\"Adobe Photoshop CS5 Macintosh\"\n" +
            "\t\t\t\t\t        stEvt:changed=\"/\"/>\n" +
            "\t\t\t\t</rdf:Seq>\n" +
            "\t\t\t</xmpMM:History>\n" +
            "\t\t\t<xmpMM:DerivedFrom stRef:instanceID=\"xmp.iid:21F0677BA22168118A6D9A879C818256\"\n" +
            "\t\t\t                   stRef:documentID=\"xmp.did:01801174072068118A6D9A879C818256\"\n" +
            "\t\t\t                   stRef:originalDocumentID=\"xmp.did:01801174072068118A6D9A879C818256\"/>\n" +
            "\t\t\t<photoshop:DocumentAncestors>\n" +
            "\t\t\t\t<rdf:Bag>\n" +
            "\t\t\t\t\t<rdf:li>adobe:docid:photoshop:11d3ec5a-c131-11d8-9274-ec65c7d7e0c6</rdf:li>\n" +
            "\t\t\t\t\t<rdf:li>adobe:docid:photoshop:aadc7027-309c-11d8-9596-9cf45d2f630b</rdf:li>\n" +
            "\t\t\t\t\t<rdf:li>adobe:docid:photoshop:c7961c59-6e0f-11d8-87b7-d67539df12d8</rdf:li>\n" +
            "\t\t\t\t</rdf:Bag>\n" +
            "\t\t\t</photoshop:DocumentAncestors>\n" +
            "\t\t\t<photoshop:DateCreated>2012-04-30T12:54:48Z</photoshop:DateCreated>\n" +
            "\t\t\t<photoshop:TextLayers>\n" +
            "\t\t\t\t<rdf:Seq>\n" +
            "\t\t\t\t       <rdf:li photoshop:LayerName=\"Name1\" photoshop:LayerText=\"Text1\"/>\n" +
            "\t\t\t\t       <rdf:li photoshop:LayerName=\"Name2\" photoshop:LayerText=\"Text2\"/>\n" +
            "\t\t\t\t</rdf:Seq>\n" +
            "\t\t\t</photoshop:TextLayers>\n" +
            "\t\t</rdf:Description>\n" +
            "\t</rdf:RDF>\n" +
            "</x:xmpmeta>\n" +
            "<?xpacket end=\"w\"?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)

        xmpmm = xmp.xmp_media_management_schema
        xmpmm.should_not be_nil
        xmpmm.not_nil!.instance_id.should eq("xmp.iid:49E997338D4911E1AB62EBF9B374B234")
        xmpmm.not_nil!.document_id.should eq("xmp.did:49E997348D4911E1AB62EBF9B374B234")
        xmpmm.not_nil!.original_document_id.should eq("xmp.did:01801174072068118A6D9A879C818256")

        history = xmpmm.not_nil!.abstract_property("History").as(Type::ArrayProperty)
        history.all_properties.size.should eq(3)
        evt0 = history.all_properties[0].as(Type::ResourceEventType)
        evt0.action.should eq("created")
        evt0.instance_id.should eq("xmp.iid:01801174072068118A6D9A879C818256")
        evt0.software_agent.should eq("Adobe Photoshop CS5 Macintosh")
        evt0.when.not_nil!.year.should eq(2012)
        evt0.when.not_nil!.minute.should eq(52)
        evt1 = history.all_properties[1].as(Type::ResourceEventType)
        evt1.when.not_nil!.minute.should eq(54)
        evt1.when.not_nil!.second.should eq(4)
        evt2 = history.all_properties[2].as(Type::ResourceEventType)
        evt2.when.not_nil!.minute.should eq(54)
        evt2.when.not_nil!.second.should eq(48)

        photoshop = xmp.photoshop_schema
        photoshop.should_not be_nil
        text_layers = photoshop.not_nil!.abstract_property("TextLayers").as(Type::ArrayProperty)
        text_layers.all_properties.size.should eq(2)
        layer0 = text_layers.all_properties[0].as(Type::LayerType)
        layer0.layer_name.should eq("Name1")
        layer0.layer_text.should eq("Text1")
        layer1 = text_layers.all_properties[1].as(Type::LayerType)
        layer1.layer_name.should eq("Name2")
        layer1.layer_text.should eq("Text2")

        ancestors = photoshop.not_nil!.abstract_property("DocumentAncestors").as(Type::ArrayProperty)
        ancestors.all_properties.size.should eq(3)
        ancestors.all_properties[0].as(Type::TextType).string_value.should eq("adobe:docid:photoshop:11d3ec5a-c131-11d8-9274-ec65c7d7e0c6")
      end

      it "PDFBOX-5292 parses an inline extension schema with a Text property" do
        s = "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\" x:xmptk=\"Adobe XMP Core 5.6-c015 84.159810, 2016/09/10-02:41:30        \">\n" +
            "    <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "        <rdf:Description rdf:about=\"\"\n" +
            "                         xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\"\n" +
            "                         xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n" +
            "                         xmlns:pdf=\"http://ns.adobe.com/pdf/1.3/\"\n" +
            "                         xmlns:pdfaid=\"http://www.aiim.org/pdfa/ns/id/\"\n" +
            "                         xmlns:pdfaExtension=\"http://www.aiim.org/pdfa/ns/extension/\"\n" +
            "                         xmlns:pdfaSchema=\"http://www.aiim.org/pdfa/ns/schema#\"\n" +
            "                         xmlns:pdfaProperty=\"http://www.aiim.org/pdfa/ns/property#\"\n" +
            "                         xmlns:example=\"http://ns.example.org/default/1.0/\">\n" +
            "            <xmp:CreateDate>2021-05-21T11:42:49+01:00</xmp:CreateDate>\n" +
            "            <xmp:ModifyDate>2021-05-21T11:47:16+02:00</xmp:ModifyDate>\n" +
            "            <xmp:MetadataDate>2021-05-21T11:47:16+02:00</xmp:MetadataDate>\n" +
            "            <dc:format>application/pdf</dc:format>\n" +
            "            <dc:title>\n" +
            "                <rdf:Alt>\n" +
            "                    <rdf:li xml:lang=\"x-default\">Inline XMP Extension PoC</rdf:li>\n" +
            "                </rdf:Alt>\n" +
            "            </dc:title>\n" +
            "            <dc:creator>\n" +
            "                <rdf:Seq>\n" +
            "                    <rdf:li>DSO</rdf:li>\n" +
            "                </rdf:Seq>\n" +
            "            </dc:creator>\n" +
            "            <pdf:Keywords/>\n" +
            "            <pdfaid:part>2</pdfaid:part>\n" +
            "            <pdfaid:conformance>A</pdfaid:conformance>\n" +
            "            <example:Data>Example</example:Data>\n" +
            "            <pdfaExtension:schemas>\n" +
            "                <rdf:Bag>\n" +
            "                    <rdf:li rdf:parseType=\"Resource\">\n" +
            "                        <pdfaSchema:schema>Simple Schema</pdfaSchema:schema>\n" +
            "                        <pdfaSchema:namespaceURI>http://ns.example.org/default/1.0/</pdfaSchema:namespaceURI>\n" +
            "                        <pdfaSchema:prefix>example</pdfaSchema:prefix>\n" +
            "                        <pdfaSchema:property>\n" +
            "                            <rdf:Seq>\n" +
            "                                <rdf:li rdf:parseType=\"Resource\">\n" +
            "                                    <pdfaProperty:name>Data</pdfaProperty:name>\n" +
            "                                    <pdfaProperty:valueType>Text</pdfaProperty:valueType>\n" +
            "                                    <pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "                                    <pdfaProperty:description>Example Data</pdfaProperty:description>\n" +
            "                                </rdf:li>\n" +
            "                            </rdf:Seq>\n" +
            "                        </pdfaSchema:property>\n" +
            "                    </rdf:li>\n" +
            "                </rdf:Bag>\n" +
            "            </pdfaExtension:schemas>\n" +
            "        </rdf:Description>\n" +
            "    </rdf:RDF>\n" +
            "</x:xmpmeta>\n" +
            "\n" +
            "<?xpacket end=\"w\"?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)

        pdfaid = xmp.pdfa_identification_schema
        pdfaid.should_not be_nil
        pdfaid.not_nil!.part.should eq(2)

        example = xmp.schema("http://ns.example.org/default/1.0/")
        example.should_not be_nil
        example.not_nil!.unqualified_text_property_value("Data").should eq("Example")
      end

      it "parses a ResourceEventType defined by namespace inside rdf:li" do
        s = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n" +
            "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?><x:xmpmeta xmlns:x=\"adobe:ns:meta/\">\n" +
            "    <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "        <rdf:Description xmlns:xmpMM=\"http://ns.adobe.com/xap/1.0/mm/\" rdf:about=\"\">\n" +
            "            <xmpMM:History>\n" +
            "                <rdf:Seq>\n" +
            "                    <rdf:li xmlns:stEvt=\"http://ns.adobe.com/xap/1.0/sType/ResourceEvent#\" rdf:parseType=\"Resource\">\n" +
            "                        <stEvt:action>created</stEvt:action>\n" +
            "                        <stEvt:parameters>original PDF file</stEvt:parameters>\n" +
            "                    </rdf:li>\n" +
            "                </rdf:Seq>\n" +
            "            </xmpMM:History>\n" +
            "        </rdf:Description>\n" +
            "    </rdf:RDF>\n" +
            "</x:xmpmeta><?xpacket end=\"w\"?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)
        mm = xmp.xmp_media_management_schema
        mm.should_not be_nil
        history = mm.not_nil!.abstract_property("History").as(Type::ArrayProperty)
        evt = history.all_properties[0].as(Type::ResourceEventType)
        evt.action.should eq("created")
        evt.parameters.should eq("original PDF file")
      end

      it "strict rejects an incomplete pdfaExtension, lenient tolerates it" do
        s = "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\"\n" +
            "           x:xmptk=\"Adobe XMP Core 4.2.1-c043 52.372728, 2009/01/18-15:08:04\">\n" +
            "\t<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "\t\t<rdf:Description rdf:about=\"\"\n" +
            "\t\t                 xmlns:xmpMM=\"http://ns.adobe.com/xap/1.0/mm/\">\n" +
            "\t\t\t<xmpMM:DocumentID>uuid:0b306144-6a43-dcbd-6b3e-c6b6b1df873d</xmpMM:DocumentID>\n" +
            "\t\t\t<xmpMM:InstanceID>uuid:0b306144-6a43-dcbd-6b3e-c6b6b1df873d</xmpMM:InstanceID>\n" +
            "\t\t</rdf:Description>\n" +
            "\t\t<rdf:Description rdf:about=\"\"\n" +
            "\t\t                 xmlns:pdfaExtension=\"http://www.aiim.org/pdfa/ns/extension/\"\n" +
            "\t\t                 xmlns:pdfaSchema=\"http://www.aiim.org/pdfa/ns/schema#\"\n" +
            "\t\t                 xmlns:pdfaProperty=\"http://www.aiim.org/pdfa/ns/property#\">\n" +
            "\t\t\t<pdfaExtension:schemas>\n" +
            "\t\t\t\t<rdf:Bag>\n" +
            "\t\t\t\t\t<rdf:li rdf:parseType=\"Resource\">\n" +
            "\t\t\t\t\t\t<pdfaSchema:namespaceURI>http://ns.adobe.com/pdf/1.3/</pdfaSchema:namespaceURI>\n" +
            "\t\t\t\t\t\t<pdfaSchema:prefix>pdf</pdfaSchema:prefix>\n" +
            "\t\t\t\t\t\t<pdfaSchema:schema>Adobe PDF Schema</pdfaSchema:schema>\n" +
            "\t\t\t\t\t</rdf:li>\n" +
            "\t\t\t\t\t<rdf:li rdf:parseType=\"Resource\">\n" +
            "\t\t\t\t\t\t<pdfaSchema:namespaceURI>http://ns.adobe.com/xap/1.0/mm/</pdfaSchema:namespaceURI>\n" +
            "\t\t\t\t\t\t<pdfaSchema:prefix>xmpMM</pdfaSchema:prefix>\n" +
            "\t\t\t\t\t\t<pdfaSchema:schema>XMP Media Management Schema</pdfaSchema:schema>\n" +
            "\t\t\t\t\t\t<pdfaSchema:property>\n" +
            "\t\t\t\t\t\t\t<rdf:Seq>\n" +
            "\t\t\t\t\t\t\t\t<rdf:li rdf:parseType=\"Resource\">\n" +
            "\t\t\t\t\t\t\t\t\t<pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "\t\t\t\t\t\t\t\t\t<pdfaProperty:description>UUID based identifier for specific incarnation of a document</pdfaProperty:description>\n" +
            "\t\t\t\t\t\t\t\t\t<pdfaProperty:name>InstanceID</pdfaProperty:name>\n" +
            "\t\t\t\t\t\t\t\t\t<pdfaProperty:valueType>URI</pdfaProperty:valueType>\n" +
            "\t\t\t\t\t\t\t\t</rdf:li>\n" +
            "\t\t\t\t\t\t\t</rdf:Seq>\n" +
            "\t\t\t\t\t\t</pdfaSchema:property>\n" +
            "\t\t\t\t\t</rdf:li>\n" +
            "\t\t\t\t</rdf:Bag>\n" +
            "\t\t\t</pdfaExtension:schemas>\n" +
            "\t\t</rdf:Description>\n" +
            "\t</rdf:RDF>\n" +
            "</x:xmpmeta>\n" +
            "<?xpacket end=\"w\"?>"
        strict_parser = DomXmpParser.new
        ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
          strict_parser.parse(s)
        end
        ex.to_s.should eq("Missing pdfaSchema:property in type definition")

        lenient_parser = DomXmpParser.new(strict_parsing: false)
        xmp = lenient_parser.parse(s)
        mm = xmp.xmp_media_management_schema
        mm.should_not be_nil
        mm.not_nil!.instance_id.should eq("uuid:0b306144-6a43-dcbd-6b3e-c6b6b1df873d")
        mm.not_nil!.document_id.should eq("uuid:0b306144-6a43-dcbd-6b3e-c6b6b1df873d")
      end

      it "parses CFAPatternType with a Values sequence" do
        s = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n" +
            "<?xpacket begin='\uFEFF' id='W5M0MpCehiHzreSzNTczkc9d'?>\n" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\"\n" +
            "           x:xmptk=\"Adobe XMP Core 4.0-c006 1.236519, Wed Jun 14 2006 08:31:24\">\n" +
            "\t<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" +
            "\t\t<rdf:Description xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n" +
            "\t\t                 xmlns:exif=\"http://ns.adobe.com/exif/1.0/\">\n" +
            "\t\t\t<exif:CFAPattern>\n" +
            "\t\t\t\t<rdf:Description>\n" +
            "\t\t\t\t\t<exif:Values>\n" +
            "\t\t\t\t\t\t<rdf:Seq>\n" +
            "\t\t\t\t\t\t\t<rdf:li>1</rdf:li>\n" +
            "\t\t\t\t\t\t\t<rdf:li>2</rdf:li>\n" +
            "\t\t\t\t\t\t\t<rdf:li>0</rdf:li>\n" +
            "\t\t\t\t\t\t\t<rdf:li>1</rdf:li>\n" +
            "\t\t\t\t\t\t</rdf:Seq>\n" +
            "\t\t\t\t\t</exif:Values>\n" +
            "\t\t\t\t</rdf:Description>\n" +
            "\t\t\t</exif:CFAPattern>\n" +
            "\t\t</rdf:Description>\n" +
            "\t</rdf:RDF>\n" +
            "</x:xmpmeta><?xpacket end='w'?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)
        exif = xmp.schema("http://ns.adobe.com/exif/1.0/")
        exif.should_not be_nil
        cfa = exif.not_nil!.abstract_property("CFAPattern")
        cfa.should be_a(Type::CFAPatternType)
        values = cfa.as(Type::AbstractStructuredType).property("Values")
        values.should_not be_nil
        values.should be_a(Type::ArrayProperty)
        values.as(Type::ArrayProperty).elements_as_string.should eq(["1", "2", "0", "1"])
      end

      it "PDFBOX-6136 parses an extension schema with xmlns= default namespace" do
        s = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n" +
            "<?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d' bytes='6865'?><rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:iX=\"http://ns.adobe.com/iX/1.0/\">\n" +
            "    <rdf:Description xmlns=\"http://www.aiim.org/pdfa/ns/extension/\" xmlns:pdfaExtension=\"http://www.aiim.org/pdfa/ns/extension/\" xmlns:pdfaProperty=\"http://www.aiim.org/pdfa/ns/property#\" xmlns:pdfaSchema=\"http://www.aiim.org/pdfa/ns/schema#\" about=\"\">\n" +
            "        <pdfaExtension:schemas>\n" +
            "            <rdf:Bag>\n" +
            "                <rdf:li rdf:parseType=\"Resource\">\n" +
            "                    <pdfaSchema:namespaceURI>http://ns.adobe.com/pdfx/1.3/</pdfaSchema:namespaceURI>\n" +
            "                    <pdfaSchema:prefix>pdfx</pdfaSchema:prefix>\n" +
            "                    <pdfaSchema:schema>Adobe Document Info PDF eXtension Schema</pdfaSchema:schema>\n" +
            "                    <pdfaSchema:property>\n" +
            "                        <rdf:Seq>\n" +
            "                            <rdf:li rdf:parseType=\"Resource\">\n" +
            "                                <pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "                                <pdfaProperty:description>ID of PDF/X standard</pdfaProperty:description>\n" +
            "                                <pdfaProperty:name>GTS_PDFXVersion</pdfaProperty:name>\n" +
            "                                <pdfaProperty:valueType>Text</pdfaProperty:valueType>\n" +
            "                            </rdf:li>\n" +
            "                        </rdf:Seq>\n" +
            "                    </pdfaSchema:property>\n" +
            "                </rdf:li>\n" +
            "                <rdf:li rdf:parseType=\"Resource\">\n" +
            "                    <pdfaSchema:namespaceURI>http://ns.adobe.com/xap/1.0/mm/</pdfaSchema:namespaceURI>\n" +
            "                    <pdfaSchema:prefix>xmpMM</pdfaSchema:prefix>\n" +
            "                    <pdfaSchema:schema>XMP Media Management Schema</pdfaSchema:schema>\n" +
            "                    <pdfaSchema:property>\n" +
            "                        <rdf:Seq>\n" +
            "                            <rdf:li rdf:parseType=\"Resource\">\n" +
            "                                <pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "                                <pdfaProperty:description>UUID based identifier for specific incarnation of a document</pdfaProperty:description>\n" +
            "                                <pdfaProperty:name>InstanceID</pdfaProperty:name>\n" +
            "                                <pdfaProperty:valueType>URI</pdfaProperty:valueType>\n" +
            "                            </rdf:li>\n" +
            "                        </rdf:Seq>\n" +
            "                    </pdfaSchema:property>\n" +
            "                </rdf:li>\n" +
            "                <rdf:li rdf:parseType=\"Resource\">\n" +
            "                    <pdfaSchema:namespaceURI>http://www.aiim.org/pdfa/ns/id/</pdfaSchema:namespaceURI>\n" +
            "                    <pdfaSchema:prefix>pdfaid</pdfaSchema:prefix>\n" +
            "                    <pdfaSchema:schema>PDF/A ID Schema</pdfaSchema:schema>\n" +
            "                    <pdfaSchema:property>\n" +
            "                        <rdf:Seq>\n" +
            "                            <rdf:li rdf:parseType=\"Resource\">\n" +
            "                                <pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "                                <pdfaProperty:description>Part of PDF/A standard</pdfaProperty:description>\n" +
            "                                <pdfaProperty:name>part</pdfaProperty:name>\n" +
            "                                <pdfaProperty:valueType>Integer</pdfaProperty:valueType>\n" +
            "                            </rdf:li>\n" +
            "                            <rdf:li rdf:parseType=\"Resource\">\n" +
            "                                <pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "                                <pdfaProperty:description>Amendment of PDF/A standard</pdfaProperty:description>\n" +
            "                                <pdfaProperty:name>amd</pdfaProperty:name>\n" +
            "                                <pdfaProperty:valueType>Text</pdfaProperty:valueType>\n" +
            "                            </rdf:li>\n" +
            "                            <rdf:li rdf:parseType=\"Resource\">\n" +
            "                                <pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "                                <pdfaProperty:description>Conformance level of PDF/A standard</pdfaProperty:description>\n" +
            "                                <pdfaProperty:name>conformance</pdfaProperty:name>\n" +
            "                                <pdfaProperty:valueType>Text</pdfaProperty:valueType>\n" +
            "                            </rdf:li>\n" +
            "                        </rdf:Seq>\n" +
            "                    </pdfaSchema:property>\n" +
            "                </rdf:li>\n" +
            "            </rdf:Bag>\n" +
            "        </pdfaExtension:schemas>\n" +
            "    </rdf:Description>\n" +
            "    <rdf:Description xmlns=\"http://www.aiim.org/pdfa/ns/id/\" xmlns:pdfaid=\"http://www.aiim.org/pdfa/ns/id/\" about=\"\">\n" +
            "        <pdfaid:part>1</pdfaid:part>\n" +
            "        <pdfaid:conformance>B</pdfaid:conformance>\n" +
            "    </rdf:Description>\n" +
            "</rdf:RDF><?xpacket end='r'?>"
        parser = DomXmpParser.new(strict_parsing: false)
        xmp = parser.parse(s)
        pdfaid = xmp.pdfa_identification_schema
        pdfaid.should_not be_nil
        pdfaid.not_nil!.conformance.should eq("B")
        pdfaid.not_nil!.part.should eq(1)
      end

      it "PDFBOX-6138 parses extension schemas with namespaces in the root" do
        s = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n" +
            "<?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d'?>" +
            "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\" xmlns:pdfaExtension=\"http://www.aiim.org/pdfa/ns/extension/\" " +
            "xmlns:pdfaProperty=\"http://www.aiim.org/pdfa/ns/property#\" xmlns:pdfaSchema=\"http://www.aiim.org/pdfa/ns/schema#\" " +
            "xmlns:pdfuaid=\"http://www.aiim.org/pdfua/ns/id/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" " +
            "x:xmptk=\"Adobe XMP Core 5.6-c015 91.163280, 2018/06/22-11:31:03        \">\n" +
            "    <rdf:RDF>\n" +
            "        <rdf:Description rdf:about=\"\">\n" +
            "            <pdfaExtension:schemas>\n" +
            "                <rdf:Bag>\n" +
            "                    <rdf:li rdf:parseType=\"Resource\">\n" +
            "                        <pdfaSchema:schema>PDF/UA Universal Accessibility Schema</pdfaSchema:schema>\n" +
            "                        <pdfaSchema:namespaceURI>http://www.aiim.org/pdfua/ns/id/</pdfaSchema:namespaceURI>\n" +
            "                        <pdfaSchema:prefix>pdfuaid</pdfaSchema:prefix>\n" +
            "                        <pdfaSchema:property>\n" +
            "                            <rdf:Seq>\n" +
            "                                <rdf:li rdf:parseType=\"Resource\">\n" +
            "                                    <pdfaProperty:name>part</pdfaProperty:name>\n" +
            "                                    <pdfaProperty:valueType>Integer</pdfaProperty:valueType>\n" +
            "                                    <pdfaProperty:category>internal</pdfaProperty:category>\n" +
            "                                    <pdfaProperty:description>Indicates, which part of ISO 14289 standard is followed</pdfaProperty:description>\n" +
            "                                </rdf:li>\n" +
            "                            </rdf:Seq>\n" +
            "                        </pdfaSchema:property>\n" +
            "                    </rdf:li>\n" +
            "                </rdf:Bag>\n" +
            "            </pdfaExtension:schemas>\n" +
            "            <pdfuaid:part>1</pdfuaid:part>\n" +
            "        </rdf:Description>\n" +
            "    </rdf:RDF>\n" +
            "</x:xmpmeta><?xpacket end='w'?>"
        parser = DomXmpParser.new
        xmp = parser.parse(s)
        ua = xmp.schema("http://www.aiim.org/pdfua/ns/id/")
        ua.should_not be_nil
        ua.not_nil!.integer_property_value("part").should eq(1)
      end
    end
  end
end
