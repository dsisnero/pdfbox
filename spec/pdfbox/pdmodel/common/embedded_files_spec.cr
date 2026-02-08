require "../../../spec_helper"

describe "Embedded files" do
  it "test null embedded file" do
    # Test from TestEmbeddedFiles.testNullEmbeddedFile
    pdf_path = File.expand_path("../../../resources/pdfbox/pdmodel/common/null_PDComplexFileSpecification.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil

    catalog = doc.document_catalog
    catalog.should_not be_nil

    names = catalog.not_nil!.names
    names.should_not be_nil

    embedded_files = names.not_nil!.embedded_files
    embedded_files.should_not be_nil

    files_map = embedded_files.not_nil!.names
    files_map.should_not be_nil
    files_map.not_nil!.size.should eq 2

    # Get non-existent file spec
    spec = files_map.not_nil!["non-existent-file.docx"]
    spec.should_not be_nil
    spec.not_nil!.embedded_file.should be_nil

    # Get existing attachment
    spec = files_map.not_nil!["My first attachment"]
    spec.should_not be_nil
    embedded_file = spec.not_nil!.embedded_file
    embedded_file.should_not be_nil
    length = embedded_file.not_nil!.length
    length.should_not be_nil
    length.not_nil!.should eq 17660

    doc.close if doc.responds_to?(:close)
  end

  it "test OS-specific attachments" do
    # Test from TestEmbeddedFiles.testOSSpecificAttachments
    pdf_path = File.expand_path("../../../resources/pdfbox/pdmodel/common/testPDF_multiFormatEmbFiles.pdf", __DIR__)
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil

    catalog = doc.document_catalog
    catalog.should_not be_nil

    names = catalog.not_nil!.names
    names.should_not be_nil

    embedded_files = names.not_nil!.embedded_files
    embedded_files.should_not be_nil

    # Try to get spec from local names first
    spec = nil
    local_names = embedded_files.not_nil!.names
    if local_names
      spec = local_names["My first attachment"]
    end

    # If not found, check kids as in Java test
    unless spec
      kids = embedded_files.not_nil!.kids
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

    # Check platform-specific embedded files
    non_os_file = spec.not_nil!.embedded_file
    non_os_file.should_not be_nil
    non_os_file_length = non_os_file.not_nil!.length
    non_os_file_length.should_not be_nil
    non_os_file_length.not_nil!.should be > 0

    mac_file = spec.not_nil!.embedded_file_mac
    mac_file.should_not be_nil
    mac_file_length = mac_file.not_nil!.length
    mac_file_length.should_not be_nil
    mac_file_length.not_nil!.should be > 0

    dos_file = spec.not_nil!.embedded_file_dos
    dos_file.should_not be_nil
    dos_file_length = dos_file.not_nil!.length
    dos_file_length.should_not be_nil
    dos_file_length.not_nil!.should be > 0

    unix_file = spec.not_nil!.embedded_file_unix
    unix_file.should_not be_nil
    unix_file_length = unix_file.not_nil!.length
    unix_file_length.should_not be_nil
    unix_file_length.not_nil!.should be > 0

    doc.close if doc.responds_to?(:close)
  end
end
