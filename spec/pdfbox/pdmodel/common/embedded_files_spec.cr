require "../../../spec_helper"

describe "Embedded files" do
  it "test null embedded file" do
    # Test from TestEmbeddedFiles.testNullEmbeddedFile
    pdf_path = File.expand_path("../../../resources/pdfbox/pdmodel/common/null_PDComplexFileSpecification.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil

    catalog = doc.document_catalog
    catalog.should_not be_nil

    catalog = catalog || raise "expected catalog"
    names = catalog.names
    names.should_not be_nil

    names = names || raise "expected names"
    embedded_files = names.embedded_files
    embedded_files.should_not be_nil

    embedded_files = embedded_files || raise "expected embedded files"
    files_map = embedded_files.names
    files_map.should_not be_nil
    files_map = files_map || raise "expected files map"
    files_map.size.should eq 2

    # Get non-existent file spec
    spec = files_map["non-existent-file.docx"]
    spec.should_not be_nil
    spec = spec || raise "expected non-existent-file spec entry"
    spec.embedded_file.should be_nil

    # Get existing attachment
    spec = files_map["My first attachment"]
    spec.should_not be_nil
    spec = spec || raise "expected attachment spec"
    embedded_file = spec.embedded_file
    embedded_file.should_not be_nil
    embedded_file = embedded_file || raise "expected embedded file"
    length = embedded_file.length
    length.should_not be_nil
    length = length || raise "expected embedded file length"
    length.should eq 17660

    doc.close if doc.responds_to?(:close)
  end

  it "test OS-specific attachments" do
    # Test from TestEmbeddedFiles.testOSSpecificAttachments
    pdf_path = File.expand_path("../../../resources/pdfbox/pdmodel/common/testPDF_multiFormatEmbFiles.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil

    catalog = doc.document_catalog
    catalog.should_not be_nil

    catalog = catalog || raise "expected catalog"
    names = catalog.names
    names.should_not be_nil

    names = names || raise "expected names"
    embedded_files = names.embedded_files
    embedded_files.should_not be_nil

    # Try to get spec from local names first
    spec = nil
    embedded_files = embedded_files || raise "expected embedded files"
    local_names = embedded_files.names
    if local_names
      spec = local_names["My first attachment"]
    end

    # If not found, check kids as in Java test
    unless spec
      kids = embedded_files.kids
      if kids
        kids.each do |kid|
          tmp_names = kid.names
          next unless tmp_names

          spec = tmp_names["My first attachment"]
          break if spec
        end
      end
    end

    spec.should_not be_nil
    spec = spec || raise "expected OS-specific attachment spec"

    # Check platform-specific embedded files
    non_os_file = spec.embedded_file
    non_os_file.should_not be_nil
    non_os_file = non_os_file || raise "expected non-OS embedded file"
    non_os_file_length = non_os_file.length
    non_os_file_length.should_not be_nil
    non_os_file_length = non_os_file_length || raise "expected non-OS file length"
    non_os_file_length.should be > 0

    mac_file = spec.embedded_file_mac
    mac_file.should_not be_nil
    mac_file = mac_file || raise "expected mac file"
    mac_file_length = mac_file.length
    mac_file_length.should_not be_nil
    mac_file_length = mac_file_length || raise "expected mac file length"
    mac_file_length.should be > 0

    dos_file = spec.embedded_file_dos
    dos_file.should_not be_nil
    dos_file = dos_file || raise "expected dos file"
    dos_file_length = dos_file.length
    dos_file_length.should_not be_nil
    dos_file_length = dos_file_length || raise "expected dos file length"
    dos_file_length.should be > 0

    unix_file = spec.embedded_file_unix
    unix_file.should_not be_nil
    unix_file = unix_file || raise "expected unix file"
    unix_file_length = unix_file.length
    unix_file_length.should_not be_nil
    unix_file_length = unix_file_length || raise "expected unix file length"
    unix_file_length.should be > 0

    doc.close if doc.responds_to?(:close)
  end
end
