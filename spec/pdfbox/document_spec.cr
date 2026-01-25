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
end
