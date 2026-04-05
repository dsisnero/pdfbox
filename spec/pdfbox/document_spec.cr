require "../spec_helper"

describe Pdfbox::Pdmodel::Document do
  describe ".create" do
    it "creates a new empty document" do
      doc = Pdfbox::Pdmodel::Document.create
      doc.should be_a(Pdfbox::Pdmodel::Document)
    end
  end

  describe "#add_page" do
    it "adds a page to the document" do
      doc = Pdfbox::Pdmodel::Document.new
      page = Pdfbox::Pdmodel::Page.new
      doc.add_page(page).should eq(page)
    end

    it "creates and adds a new page" do
      doc = Pdfbox::Pdmodel::Document.new
      page = doc.add_page
      page.should be_a(Pdfbox::Pdmodel::Page)
    end
  end

  describe "#page_count" do
    it "returns 0 for empty document" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.page_count.should eq(0)
    end

    it "exposes Java-shaped document accessors" do
      doc = Pdfbox::Pdmodel::Document.new
      page = doc.add_page

      doc.get_number_of_pages.should eq(1)
      doc.get_page(0).should eq(page)
      doc.get_pages.should eq([page])
      doc.get_document_catalog.should eq(doc.document_catalog)
      doc.get_document.should_not be_nil
    end
  end

  describe "Java-shaped state accessors" do
    it "gets and sets document id and security-removal flags" do
      doc = Pdfbox::Pdmodel::Document.new
      id = Bytes[0x01_u8, 0x02_u8, 0x03_u8]

      doc.set_document_id(id)
      doc.get_document_id.should eq(id)

      doc.set_all_security_to_be_removed(true)
      doc.is_all_security_to_be_removed.should be_true
    end

    it "gets and sets document information through the trailer" do
      trailer = Pdfbox::Cos::Dictionary.new
      doc = Pdfbox::Pdmodel::Document.new(nil, "1.4", trailer)
      info = Pdfbox::Pdmodel::DocumentInformation.new
      info.title = "Spec Title"

      doc.set_document_information(info)

      loaded = doc.get_document_information
      loaded.should_not be_nil
      loaded.not_nil!.title.should eq("Spec Title")

      doc.set_document_information(nil)
      doc.get_document_information.should be_nil
    end
  end

  describe "#save and .load" do
    it "TestPDDocument#testSaveLoadStream" do
      baos = IO::Memory.new

      doc = Pdfbox::Pdmodel::Document.new
      begin
        doc.add_page(Pdfbox::Pdmodel::Page.new)
        doc.save(baos, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
      ensure
        doc.close
      end

      pdf = baos.to_slice
      pdf.size.should be > 200
      String.new(pdf[0, 8]).should eq("%PDF-1.4")
      String.new(pdf[pdf.size - 6, 6]).should eq("%%EOF\n")

      load_doc = Pdfbox::Pdmodel::Document.load(IO::Memory.new(pdf))
      begin
        load_doc.number_of_pages.should eq(1)
      ensure
        load_doc.close
      end
    end

    it "TestPDDocument#testSaveLoadFile" do
      target_file = ""
      target_file = (SpecPaths::PROJECT_ROOT / "temp" / "pddocument-saveloadfile.pdf").to_s

      doc = Pdfbox::Pdmodel::Document.new
      begin
        doc.add_page(Pdfbox::Pdmodel::Page.new)
        doc.save(target_file, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
      ensure
        doc.close
      end

      File.size(target_file).should be > 200
      pdf = File.read(target_file).to_slice
      pdf.size.should be > 200
      String.new(pdf[0, 8]).should eq("%PDF-1.4")
      String.new(pdf[pdf.size - 6, 6]).should eq("%%EOF\n")

      load_doc = Pdfbox::Pdmodel::Document.load(target_file)
      begin
        load_doc.number_of_pages.should eq(1)
      ensure
        load_doc.close
      end
    ensure
      path = target_file.not_nil!
      File.delete(path) if File.exists?(path)
    end

    it "saves and loads a document with one page" do
      # Create PDF with one blank page
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)

      # Save to memory
      io = IO::Memory.new
      doc.save(io)

      # Verify content
      pdf = io.to_s
      pdf.size.should be > 200
      pdf.should start_with("%PDF-")
      pdf.should end_with("%%EOF\n")

      # Reload
      load_doc = Pdfbox::Pdmodel::Document.load(IO::Memory.new(pdf))
      load_doc.page_count.should eq(1)
    end

    it "saves and loads from file" do
      filename = "test_save_load.pdf"
      begin
        # Create PDF with one blank page
        doc = Pdfbox::Pdmodel::Document.new
        doc.add_page(Pdfbox::Pdmodel::Page.new)
        doc.save(filename)

        # Verify file exists and has content
        File.exists?(filename).should be_true
        pdf = File.read(filename)
        pdf.size.should be > 200
        pdf.should start_with("%PDF-")
        pdf.should end_with("%%EOF\n")

        # Reload
        load_doc = Pdfbox::Pdmodel::Document.load(filename)
        load_doc.page_count.should eq(1)
      ensure
        File.delete(filename) if File.exists?(filename)
      end
    end
  end

  describe "#version" do
    it "TestPDDocument#testVersions" do
      doc = Pdfbox::Pdmodel::Document.new
      begin
        doc.version.should be_close(1.4_f32, 0.0_f32)
        doc.header_version.should eq("1.4")
        doc.document_catalog.not_nil!.version.should eq("1.4")

        doc.header_version = "1.3"
        doc.document_catalog.not_nil!.version = nil

        doc.version.should be_close(1.3_f32, 0.0_f32)
        doc.header_version.should eq("1.3")
        doc.document_catalog.not_nil!.version.should be_nil
      ensure
        doc.close
      end

      doc = Pdfbox::Pdmodel::Document.new
      begin
        doc.set_version(1.3_f32)

        doc.version.should be_close(1.4_f32, 0.0_f32)
        doc.header_version.should eq("1.4")
        doc.document_catalog.not_nil!.version.should eq("1.4")

        doc.set_version(1.5_f32)

        doc.version.should be_close(1.5_f32, 0.0_f32)
        doc.header_version.should eq("1.4")
        doc.document_catalog.not_nil!.version.should eq("1.5")
      ensure
        doc.close
      end

      baos = IO::Memory.new
      doc = Pdfbox::Pdmodel::Document.new
      begin
        doc.add_page(Pdfbox::Pdmodel::Page.new)
        doc.save(baos)
      ensure
        doc.close
      end

      loaded = Pdfbox::Pdmodel::Document.load(IO::Memory.new(baos.to_slice))
      begin
        loaded.document_catalog.not_nil!.version.should eq("1.6")
        loaded.header_version.should eq("1.6")
        loaded.version.should be_close(1.6_f32, 0.0_f32)
      ensure
        loaded.close
      end

      String.new(baos.to_slice[0, 8]).should eq("%PDF-1.6")
    end
  end

  describe ".load with invalid PDF" do
    it "raises error for invalid PDF" do
      invalid_pdf = "<script language='JavaScript'>"
      expect_raises(Pdfbox::Pdfparser::SyntaxError) do
        Pdfbox::Pdmodel::Document.load(IO::Memory.new(invalid_pdf))
      end
    end

    it "TestPDDocument#testDeleteBadFile" do
      path = (SpecPaths::PROJECT_ROOT / "temp" / "testDeleteBadFile.pdf").to_s
      File.write(path, "<script language='JavaScript'>")

      expect_raises(Pdfbox::Pdfparser::SyntaxError) do
        Pdfbox::Pdmodel::Document.load(path)
      end

      File.delete(path)
      File.exists?(path).should be_false
    end

    it "TestPDDocument#testDeleteGoodFile" do
      path = (SpecPaths::PROJECT_ROOT / "temp" / "testDeleteGoodFile.pdf").to_s

      doc = Pdfbox::Pdmodel::Document.new
      begin
        doc.add_page(Pdfbox::Pdmodel::Page.new)
        doc.save(path)
      ensure
        doc.close
      end

      loaded = Pdfbox::Pdmodel::Document.load(path)
      loaded.close

      File.delete(path)
      File.exists?(path).should be_false
    end
  end

  describe "#close" do
    it "closes document and releases resources" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.close
      # Should not raise error
    end
  end

  describe "xref table integration" do
    it "generates PDF with xref table" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)

      io = IO::Memory.new
      doc.save(io)

      pdf = io.to_s
      pdf.should contain("xref\n")
      pdf.should contain("trailer\n")
      pdf.should end_with("%%EOF\n")
    end

    it "saves and loads document with xref table" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)

      io = IO::Memory.new
      doc.save(io)

      load_doc = Pdfbox::Pdmodel::Document.load(IO::Memory.new(io.to_s))
      load_doc.page_count.should eq(1)
    end

    it "handles multiple pages with xref table" do
      doc = Pdfbox::Pdmodel::Document.new
      3.times { doc.add_page(Pdfbox::Pdmodel::Page.new) }

      io = IO::Memory.new
      doc.save(io)

      pdf = io.to_s
      pdf.should contain("xref\n")

      load_doc = Pdfbox::Pdmodel::Document.load(IO::Memory.new(pdf))
      load_doc.page_count.should eq(3)
    end
  end

  describe "catalog and pages object parsing" do
    it "parses catalog object from generated PDF" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)

      io = IO::Memory.new
      doc.save(io)

      # Parse the PDF to get xref
      source = Pdfbox::IO::MemoryRandomAccessRead.new(io.to_s.to_slice)
      parser = Pdfbox::Pdfparser::Parser.new(source)

      # Find xref offset
      xref_offset = parser.locate_xref_offset
      xref_offset.should_not be_nil

      # Parse xref table
      parser.seek(xref_offset.as(Int64))
      xref = parser.parse_xref

      # Get catalog object (object 1)
      catalog_entry = xref[1]
      catalog_entry.should_not be_nil
      catalog_entry.as(Pdfbox::Pdfparser::XRefEntry).type.should eq(:in_use)

      # Parse catalog object
      catalog_obj = parser.parse_indirect_object_at_offset(catalog_entry.as(Pdfbox::Pdfparser::XRefEntry).offset)
      catalog_obj.should be_a(Pdfbox::Cos::Dictionary)

      catalog_dict = catalog_obj.as(Pdfbox::Cos::Dictionary)
      catalog_dict[Pdfbox::Cos::Name.new("Type")].should be_a(Pdfbox::Cos::Name)
      catalog_dict[Pdfbox::Cos::Name.new("Type")].as(Pdfbox::Cos::Name).value.should eq("Catalog")

      catalog_dict[Pdfbox::Cos::Name.new("Pages")].should be_a(Pdfbox::Cos::Object)
      pages_ref = catalog_dict[Pdfbox::Cos::Name.new("Pages")].as(Pdfbox::Cos::Object)
      pages_ref.obj_number.should eq(2)
      pages_ref.gen_number.should eq(0)
    end

    it "parses pages object from generated PDF" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)

      io = IO::Memory.new
      doc.save(io)

      source = Pdfbox::IO::MemoryRandomAccessRead.new(io.to_s.to_slice)
      parser = Pdfbox::Pdfparser::Parser.new(source)

      xref_offset = parser.locate_xref_offset
      xref_offset.should_not be_nil

      parser.seek(xref_offset.as(Int64))
      xref = parser.parse_xref

      # Get pages object (object 2)
      pages_entry = xref[2]
      pages_entry.should_not be_nil
      pages_entry.as(Pdfbox::Pdfparser::XRefEntry).type.should eq(:in_use)

      # Parse pages object
      pages_obj = parser.parse_indirect_object_at_offset(pages_entry.as(Pdfbox::Pdfparser::XRefEntry).offset)
      pages_obj.should be_a(Pdfbox::Cos::Dictionary)

      pages_dict = pages_obj.as(Pdfbox::Cos::Dictionary)
      pages_dict[Pdfbox::Cos::Name.new("Type")].should be_a(Pdfbox::Cos::Name)
      pages_dict[Pdfbox::Cos::Name.new("Type")].as(Pdfbox::Cos::Name).value.should eq("Pages")

      pages_dict[Pdfbox::Cos::Name.new("Count")].should be_a(Pdfbox::Cos::Integer)
      pages_dict[Pdfbox::Cos::Name.new("Count")].as(Pdfbox::Cos::Integer).value.should eq(1)

      pages_dict[Pdfbox::Cos::Name.new("Kids")].should be_a(Pdfbox::Cos::Array)
      kids = pages_dict[Pdfbox::Cos::Name.new("Kids")].as(Pdfbox::Cos::Array)
      kids.items.size.should eq(1)
      kids.items[0].should be_a(Pdfbox::Cos::Object)
      kids.items[0].as(Pdfbox::Cos::Object).obj_number.should eq(3)
    end
  end
end
