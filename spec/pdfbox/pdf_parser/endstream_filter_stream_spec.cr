require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdfparser/EndstreamFilterStreamTest.java
describe Pdfbox::Pdfparser::EndstreamFilterStream do
  it "matches EndstreamFilterStreamTest#testEndstreamFilterStream" do
    # 1
    feos = Pdfbox::Pdfparser::EndstreamFilterStream.new
    tab1 = Bytes[1, 2, 3, 4]
    tab2 = Bytes[5, 6, 7, '\r'.ord.to_u8, '\n'.ord.to_u8]
    tab3 = Bytes[8, 9, '\r'.ord.to_u8, '\n'.ord.to_u8]
    feos.filter(tab1, 0, tab1.size)
    feos.filter(tab2, 0, tab2.size)
    feos.filter(tab3, 0, tab3.size)
    feos.calculate_length.should eq(11)

    # 2
    feos = Pdfbox::Pdfparser::EndstreamFilterStream.new
    tab4 = Bytes[1, 2, 3, 4]
    tab5 = Bytes[5, 6, 7, '\r'.ord.to_u8]
    tab6 = Bytes[8, 9, '\n'.ord.to_u8]
    feos.filter(tab4, 0, tab4.size)
    feos.filter(tab5, 0, tab5.size)
    feos.filter(tab6, 0, tab6.size)
    feos.calculate_length.should eq(10)

    # 3
    feos = Pdfbox::Pdfparser::EndstreamFilterStream.new
    tab7 = Bytes[1, 2, 3, 4, '\r'.ord.to_u8]
    tab8 = Bytes['\n'.ord.to_u8, 5, 6, 7, '\n'.ord.to_u8]
    tab9 = Bytes[8, 9, '\r'.ord.to_u8]
    feos.filter(tab7, 0, tab7.size)
    feos.filter(tab8, 0, tab8.size)
    feos.filter(tab9, 0, tab9.size)
    feos.calculate_length.should eq(13)

    # 4
    feos = Pdfbox::Pdfparser::EndstreamFilterStream.new
    tab10 = Bytes[1, 2, 3, 4, '\r'.ord.to_u8]
    tab11 = Bytes['\n'.ord.to_u8, 5, 6, 7, '\r'.ord.to_u8]
    tab12 = Bytes[8, 9, '\r'.ord.to_u8]
    tab13 = Bytes['\n'.ord.to_u8]
    feos.filter(tab10, 0, tab10.size)
    feos.filter(tab11, 0, tab11.size)
    feos.filter(tab12, 0, tab12.size)
    feos.filter(tab13, 0, tab13.size)
    feos.calculate_length.should eq(12)

    # 5
    feos = Pdfbox::Pdfparser::EndstreamFilterStream.new
    tab14 = Bytes[1, 2, 3, 4, '\r'.ord.to_u8]
    tab15 = Bytes['\n'.ord.to_u8, 5, 6, 7, '\r'.ord.to_u8]
    tab16 = Bytes[8, 9, '\n'.ord.to_u8]
    tab17 = Bytes['\r'.ord.to_u8]
    feos.filter(tab14, 0, tab14.size)
    feos.filter(tab15, 0, tab15.size)
    feos.filter(tab16, 0, tab16.size)
    feos.filter(tab17, 0, tab17.size)
    feos.calculate_length.should eq(14)
  end

  it "matches EndstreamFilterStreamTest#testPDFBox2079EmbeddedFile" do
    # The embedded zip must be exactly 17660 bytes (no spurious trailing newline).
    path = SpecPaths.resolve("spec/resources/pdfbox/pdparser/embedded_zip.pdf")
    doc = Pdfbox::Loader.load_pdf(path)
    begin
      catalog = doc.document_catalog.not_nil!
      names = catalog.names.not_nil!
      node = names.embedded_files.not_nil!
      map = node.names.not_nil!
      map.size.should eq(1)

      spec = map["My first attachment"]
      embedded_file = spec.embedded_file.not_nil!
      input = embedded_file.create_input_stream.not_nil!
      bytes = input.getb_to_end
      bytes.size.should eq(17660)
    ensure
      doc.close
    end
  end
end
