require "../spec_helper"
require "../../src/xmpbox"

describe Xmpbox::XMPMetadata do
  it "creates with default xpacket values" do
    meta = Xmpbox::XMPMetadata.create_xmp_metadata
    meta.xpacket_begin.should eq("\uFEFF")
    meta.xpacket_id.should eq("W5M0MpCehiHzreSzNTczkc9d")
    meta.xpacket_encoding.should eq("UTF-8")
    meta.xpacket_end.should eq("w")
  end

  it "creates with custom xpacket values" do
    meta = Xmpbox::XMPMetadata.create_xmp_metadata("TESTBEG", "TESTID", "TESTBYTES", "TESTENCOD")
    meta.xpacket_begin.should eq("TESTBEG")
    meta.xpacket_id.should eq("TESTID")
    meta.xpacket_bytes.should eq("TESTBYTES")
    meta.xpacket_encoding.should eq("TESTENCOD")
  end

  it "adds and retrieves schemas" do
    meta = Xmpbox::XMPMetadata.create_xmp_metadata
    tmp_ns = "http://www.test.org/schem/"

    tmp = Xmpbox::Schema::XMPSchema.new(meta, tmp_ns, "test")
    tmp.add_qualified_bag_value("BagContainer", "Value1")
    tmp.add_qualified_bag_value("BagContainer", "Value2")
    tmp.add_qualified_bag_value("BagContainer", "Value3")

    tmp.add_unqualified_sequence_value("SeqContainer", "Value1")
    tmp.add_unqualified_sequence_value("SeqContainer", "Value2")
    tmp.add_unqualified_sequence_value("SeqContainer", "Value3")

    tmp2 = Xmpbox::Schema::XMPSchema.new(meta, "http://www.space.org/schem/", "space", "space")
    tmp2.add_unqualified_sequence_value("SeqSpContainer", "ValueSpace1")
    tmp2.add_unqualified_sequence_value("SeqSpContainer", "ValueSpace2")
    tmp2.add_unqualified_sequence_value("SeqSpContainer", "ValueSpace3")

    meta.add_schema(tmp)
    meta.add_schema(tmp2)

    meta.schema(tmp_ns).should eq(tmp)
    meta.schema("THIS URI NOT EXISTS !").should be_nil

    schemas = meta.all_schemas
    schemas.includes?(tmp).should be_true
    schemas.includes?(tmp2).should be_true
  end

  it "parses inline XMP and accesses schema properties" do
    xmpmeta = <<-XML
    <?xpacket id="W5M0MpCehiHzreSzNTczkc9d"?>
    <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Adobe XMP Core">
       <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about=""
                xmlns:xap="http://ns.adobe.com/xap/1.0/">
             <xap:CreatorTool>Acrobat PDFMaker</xap:CreatorTool>
             <xap:CreateDate>2008-11-12T15:29:40+01:00</xap:CreateDate>
             <xap:MetadataDate>2008-11-12T15:29:43+01:00</xap:MetadataDate>
          </rdf:Description>
          <rdf:Description rdf:about=""
                xmlns:dc="http://purl.org/dc/elements/1.1/">
             <dc:format>application/pdf</dc:format>
             <dc:creator>
                <rdf:Seq>
                   <rdf:li>R002325</rdf:li>
                </rdf:Seq>
             </dc:creator>
             <dc:subject>
                <rdf:Bag>
                   <rdf:li>one</rdf:li>
                   <rdf:li>two</rdf:li>
                   <rdf:li>three</rdf:li>
                   <rdf:li>four</rdf:li>
                </rdf:Bag>
             </dc:subject>
          </rdf:Description>
       </rdf:RDF>
    </x:xmpmeta>
    <?xpacket end="w"?>
    XML

    parser = Xmpbox::Xml::DomXmpParser.new
    parser.strict_parsing = false
    xmp = parser.parse(xmpmeta)

    # Check xap schema
    xap = xmp.xmp_basic_schema
    xap.should_not be_nil
    xap.not_nil!.unqualified_text_property_value("CreatorTool").should eq("Acrobat PDFMaker")

    # Check dc schema
    dc = xmp.dublin_core_schema
    dc.should_not be_nil
    dc.not_nil!.unqualified_text_property_value("format").should eq("application/pdf")

    # Check dc:subject bag
    subjects = dc.not_nil!.unqualified_bag_value_list("subject")
    subjects.should_not be_nil
    subjects.not_nil!.size.should eq(4)
    subjects.not_nil!.includes?("one").should be_true
    subjects.not_nil!.includes?("four").should be_true
  end

  it "clears schemas" do
    meta = Xmpbox::XMPMetadata.create_xmp_metadata
    tmp = Xmpbox::Schema::XMPSchema.new(meta, "http://test.org/", "test")
    meta.add_schema(tmp)
    meta.all_schemas.size.should eq(1)
    meta.clear_schemas
    meta.all_schemas.size.should eq(0)
  end

  it "removes schema by namespace" do
    meta = Xmpbox::XMPMetadata.create_xmp_metadata
    tmp = Xmpbox::Schema::XMPSchema.new(meta, "http://test.org/", "test")
    meta.add_schema(tmp)
    meta.remove_schema("http://test.org/")
    meta.all_schemas.size.should eq(0)
  end
end
