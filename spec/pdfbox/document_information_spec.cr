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

  # Java PDDocument#getDocumentInformation never returns null: it lazily creates
  # /Info in the trailer when it is missing and caches the wrapper
  # (`documentInformation`), so an in-memory document can carry metadata too.
  it "creates the information dictionary of an in-memory document" do
    document = Pdfbox::Pdmodel::Document.create
    begin
      information = document.document_information
      information.should_not be_nil
      document.document_information.should be(information)

      information.title = "In-memory Title"
      information.author = "In-memory Author"

      output = IO::Memory.new
      document.save(output, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
      reloaded = Pdfbox::Loader.load_pdf(output.to_slice)
      begin
        reloaded.document_information.title.should eq("In-memory Title")
        reloaded.document_information.author.should eq("In-memory Author")
      ensure
        reloaded.close
      end
    ensure
      document.close
    end
  end

  it "adds /Info to the trailer of a document that has none" do
    output = IO::Memory.new
    document = Pdfbox::Pdmodel::Document.create
    page = Pdfbox::Pdmodel::Page.new
    page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(100.0, 100.0)
    document.add_page(page)
    document.save(output, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
    document.close

    loaded = Pdfbox::Loader.load_pdf(output.to_slice)
    begin
      loaded.trailer.not_nil![Pdfbox::Cos::Name.new("Info")].should be_nil
      information = loaded.document_information
      information.title.should be_nil
      loaded.trailer.not_nil![Pdfbox::Cos::Name.new("Info")].should_not be_nil
    ensure
      loaded.close
    end
  end

  it "caches the wrapper around the existing information dictionary" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")
    document = Pdfbox::Loader.load_pdf(pdf_path)
    begin
      first = document.document_information
      second = document.document_information
      first.should be(second)
      first.title.should eq(second.title)
    ensure
      document.close
    end
  end
end
