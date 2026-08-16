require "../../../spec_helper"
require "../../../../src/pdfbox"

private COMMON_DIR = "spec/resources/pdfbox/pdmodel/common"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/TestEmbeddedFiles.java

private def byte_array_contains(target : String, bytes : Bytes) : Bool
  String.new(bytes).downcase.includes?(target)
end

describe Pdfbox::Pdmodel::Document do
  it "TestEmbeddedFiles#testNullEmbeddedFile" do
    file = SpecPaths.resolve("#{COMMON_DIR}/null_PDComplexFileSpecification.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      catalog = document.document_catalog.not_nil!
      names = catalog.names
      embedded_files = names.try(&.embedded_files)
      names_map = embedded_files.not_nil!.names.not_nil!
      names_map.size.should eq(2)

      spec = names_map["non-existent-file.docx"]?
      spec.should_not be_nil
      spec.not_nil!.embedded_file.should be_nil

      spec = names_map["My first attachment"]?
      spec.should_not be_nil
      spec.not_nil!.embedded_file.not_nil!.length.should eq(17660)

      spec = names_map["non-existent-file.docx"]?
      spec.should_not be_nil
      spec.not_nil!.file.should be_nil
      spec.not_nil!.embedded_file.should be_nil
    ensure
      document.close
    end
  end

  it "TestEmbeddedFiles#testOSSpecificAttachments" do
    file = SpecPaths.resolve("#{COMMON_DIR}/testPDF_multiFormatEmbFiles.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      catalog = document.document_catalog.not_nil!
      names = catalog.names
      tree_node = names.try(&.embedded_files)
      kids = tree_node.not_nil!.kids
      kids.should_not be_nil

      non_os_file = nil
      mac_file = nil
      dos_file = nil
      unix_file = nil

      kids.not_nil!.each do |kid|
        tmp_names = kid.names.not_nil!
        spec = tmp_names["My first attachment"]?
        if spec
          non_os_file = spec.not_nil!.embedded_file
          mac_file = spec.not_nil!.embedded_file_mac
          dos_file = spec.not_nil!.embedded_file_dos
          unix_file = spec.not_nil!.embedded_file_unix
        end
      end

      byte_array_contains("non os specific", non_os_file.not_nil!.to_byte_array).should be_true
      byte_array_contains("mac embedded", mac_file.not_nil!.to_byte_array).should be_true
      byte_array_contains("dos embedded", dos_file.not_nil!.to_byte_array).should be_true
      byte_array_contains("unix embedded", unix_file.not_nil!.to_byte_array).should be_true
    ensure
      document.close
    end
  end
end
