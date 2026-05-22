require "../../../spec_helper"

describe "PDMetadata XMPBox integration" do
  it "creates PDMetadata with default XMP skeleton" do
    doc = Pdfbox::Pdmodel::PDDocument.new
    meta = Pdfbox::Pdmodel::Common::PDMetadata.create_with_xmp(doc)

    meta.should_not be_nil
    cos = meta.cos_object
    cos[Pdfbox::Cos::Name::TYPE].should eq(Pdfbox::Cos::Name.new("Metadata"))
    cos[Pdfbox::Cos::Name::SUBTYPE].should eq(Pdfbox::Cos::Name.new("XML"))
  end

  it "exports and imports XMP metadata" do
    doc = Pdfbox::Pdmodel::PDDocument.new
    meta = Pdfbox::Pdmodel::Common::PDMetadata.new(doc)

    xmp_bytes = "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?><x:xmpmeta xmlns:x=\"adobe:ns:meta/\"><rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"></rdf:RDF></x:xmpmeta><?xpacket end=\"w\"?>".to_slice
    meta.import_xmp_metadata(xmp_bytes)

    exported = meta.export_xmp_metadata
    exported.should_not be_nil
    exported_data = exported.gets_to_end
    exported_data.should contain("adobe:ns:meta/")
  end

  it "parses XMP metadata from PDMetadata" do
    doc = Pdfbox::Pdmodel::PDDocument.new
    meta = Pdfbox::Pdmodel::Common::PDMetadata.new(doc)

    xmp_bytes = "<?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n<x:xmpmeta xmlns:x=\"adobe:ns:meta/\">\n  <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n    <rdf:Description rdf:about=\"\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n      <dc:title>A Title</dc:title>\n    </rdf:Description>\n  </rdf:RDF>\n</x:xmpmeta>\n<?xpacket end=\"w\"?>".to_slice
    meta.import_xmp_metadata(xmp_bytes)

    xmp = meta.xmp_metadata
    xmp.should_not be_nil
    dc = xmp.not_nil!.dublin_core_schema
    dc.should_not be_nil
  end

  it "serializes XMP metadata to PDMetadata" do
    doc = Pdfbox::Pdmodel::PDDocument.new
    meta = Pdfbox::Pdmodel::Common::PDMetadata.new(doc)

    xmp = Xmpbox::XMPMetadata.create_xmp_metadata
    dc = xmp.create_and_add_dublin_core_schema
    dc.set_text_property_value("title", "Test Title")

    meta.xmp_metadata = xmp

    exported = meta.export_xmp_metadata
    exported_data = exported.gets_to_end
    exported_data.should contain("Test Title")
  end
end
