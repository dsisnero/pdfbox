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
  end

  describe "#save and .load" do
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
    it "returns default version 1.4" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.version.should eq("1.4")
    end

    it "allows setting version" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.version = "1.5"
      doc.version.should eq("1.5")
    end
  end

  describe ".load with invalid PDF" do
    it "raises error for invalid PDF" do
      invalid_pdf = "<script language='JavaScript'>"
      expect_raises(Pdfbox::Pdfparser::SyntaxError) do
        Pdfbox::Pdmodel::Document.load(IO::Memory.new(invalid_pdf))
      end
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
      parser.source.seek(xref_offset.not_nil!)
      xref = parser.parse_xref

      # Get catalog object (object 1)
      catalog_entry = xref[1]
      catalog_entry.should_not be_nil
      catalog_entry.not_nil!.type.should eq(:in_use)

      # Parse catalog object
      catalog_obj = parser.parse_indirect_object_at_offset(catalog_entry.not_nil!.offset)
      catalog_obj.should be_a(Pdfbox::Cos::Dictionary)

      catalog_dict = catalog_obj.as(Pdfbox::Cos::Dictionary)
      catalog_dict[Pdfbox::Cos::Name.new("Type")].should be_a(Pdfbox::Cos::Name)
      catalog_dict[Pdfbox::Cos::Name.new("Type")].as(Pdfbox::Cos::Name).value.should eq("Catalog")

      catalog_dict[Pdfbox::Cos::Name.new("Pages")].should be_a(Pdfbox::Cos::Reference)
      pages_ref = catalog_dict["Pages"].as(Pdfbox::Cos::Reference)
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

      parser.source.seek(xref_offset.not_nil!)
      xref = parser.parse_xref

      # Get pages object (object 2)
      pages_entry = xref[2]
      pages_entry.should_not be_nil
      pages_entry.not_nil!.type.should eq(:in_use)

      # Parse pages object
      pages_obj = parser.parse_indirect_object_at_offset(pages_entry.not_nil!.offset)
      pages_obj.should be_a(Pdfbox::Cos::Dictionary)

      pages_dict = pages_obj.as(Pdfbox::Cos::Dictionary)
      pages_dict["Type"].should be_a(Pdfbox::Cos::Name)
      pages_dict["Type"].as(Pdfbox::Cos::Name).value.should eq("Pages")

      pages_dict["Count"].should be_a(Pdfbox::Cos::Integer)
      pages_dict["Count"].as(Pdfbox::Cos::Integer).value.should eq(1)

      pages_dict["Kids"].should be_a(Pdfbox::Cos::Array)
      kids = pages_dict["Kids"].as(Pdfbox::Cos::Array)
      kids.items.size.should eq(1)
      kids.items[0].should be_a(Pdfbox::Cos::Reference)
      kids.items[0].as(Pdfbox::Cos::Reference).obj_number.should eq(3)
    end
  end
end
