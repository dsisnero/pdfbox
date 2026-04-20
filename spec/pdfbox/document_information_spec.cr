require "../spec_helper"

describe Pdfbox::Pdmodel::DocumentInformation do
  it "TestPDDocumentInformation#testMetadataExtraction" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")

    doc = Pdfbox::Loader.load_pdf(pdf_path)
    begin
      info = doc.document_information
      info.should_not be_nil

      document_information = info.as(Pdfbox::Pdmodel::DocumentInformation)
      document_information.author.should eq("Brian Carrier")
      document_information.creation_date.should_not be_nil
      document_information.creator.should eq("Acrobat PDFMaker 8.1 for Word")
      document_information.keywords.should be_nil
      document_information.modification_date.should_not be_nil
      document_information.producer.should eq("Acrobat Distiller 8.1.0 (Windows)")
      document_information.subject.should be_nil
      document_information.trapped.should be_nil

      expected_metadata_keys = [
        "CreationDate",
        "Author",
        "Creator",
        "Producer",
        "ModDate",
        "Company",
        "SourceModified",
        "Title",
      ]
      document_information.metadata_keys.size.should eq(expected_metadata_keys.size)
      expected_metadata_keys.each do |key|
        document_information.metadata_keys.should contain(key)
      end

      document_information.custom_metadata_value("Company").should eq("Basis Technology Corp.")
      document_information.custom_metadata_value("SourceModified").should eq("D:20080819181502")
    ensure
      doc.close
    end
  end

  it "TestPDDocumentInformation#testPDFBox3068" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/PDFBOX-3068.pdf")

    doc = Pdfbox::Loader.load_pdf(pdf_path)
    begin
      document_information = doc.document_information
      document_information.should_not be_nil
      document_information.as(Pdfbox::Pdmodel::DocumentInformation).title.should eq("Title")
    ensure
      doc.close
    end
  end
end
