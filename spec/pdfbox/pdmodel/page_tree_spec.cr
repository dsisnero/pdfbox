require "../../spec_helper"

module Pdfbox::Pdmodel
  module PageTreeSpecHelpers
    def self.load_page_tree(path : String) : {Document, PDPageTree}
      doc = Pdfbox::Loader.load_pdf(path)
      catalog = doc.document_catalog.not_nil!
      pages_root = catalog.cos_object[Cos::Name.new("Pages")]
      if pages_root.is_a?(Cos::Object)
        pages_root = pages_root.object
      end
      {doc, PDPageTree.new(pages_root.as(Cos::Dictionary), doc)}
    end
  end

  describe PDPageTree do
    it "creates empty page tree" do
      tree = PDPageTree.new
      tree.count.should eq 0
    end

    it "creates page tree from dictionary" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("Type")] = Cos::Name.new("Pages")
      dict[Cos::Name.new("Kids")] = Cos::Array.new
      dict[Cos::Name.new("Count")] = Cos::Integer.new(0)

      tree = PDPageTree.new(dict)
      tree.count.should eq 0
    end

    it "adds pages to tree" do
      tree = PDPageTree.new
      page1 = Page.new
      page2 = Page.new

      tree.add(page1)
      tree.count.should eq 1

      tree.add(page2)
      tree.count.should eq 2
    end

    it "iterates over pages" do
      tree = PDPageTree.new
      page1 = Page.new
      page2 = Page.new
      page3 = Page.new

      tree.add(page1)
      tree.add(page2)
      tree.add(page3)

      pages = [] of Page
      tree.each do |page|
        pages << page
      end

      pages.size.should eq 3
    end

    it "handles malformed PDF with Page type instead of Pages" do
      # Simulate a malformed PDF where the root is a Page dict instead of Pages
      page_dict = Cos::Dictionary.new
      page_dict[Cos::Name.new("Type")] = Cos::Name.new("Page")
      page_dict[Cos::Name.new("MediaBox")] = Cos::Array.new([
        Cos::Float.new(0.0),
        Cos::Float.new(0.0),
        Cos::Float.new(612.0),
        Cos::Float.new(792.0),
      ])

      tree = PDPageTree.new(page_dict)
      tree.count.should eq 1
    end

    it "TestPDPageTree#positiveSingleLevel" do
      doc, tree = PageTreeSpecHelpers.load_page_tree(
        SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/with_outline.pdf")
      )
      begin
        doc.number_of_pages.times do |i|
          tree.index_of(doc.get_page(i)).should eq(i)
        end
      ensure
        doc.close
      end
    end

    it "TestPDPageTree#positiveMultipleLevel" do
      doc, tree = PageTreeSpecHelpers.load_page_tree(
        SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/page_tree_multiple_levels.pdf")
      )
      begin
        doc.number_of_pages.times do |i|
          tree.index_of(doc.get_page(i)).should eq(i)
        end
      ensure
        doc.close
      end
    end

    it "TestPDPageTree#negative" do
      doc, tree = PageTreeSpecHelpers.load_page_tree(
        SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/with_outline.pdf")
      )
      begin
        tree.index_of(Page.new).should eq(-1)
      ensure
        doc.close
      end
    end

    it "TestPDPageTree#testInsertBeforeBlankPage" do
      tree = PDPageTree.new
      page_one = Page.new
      page_two = Page.new
      page_three = Page.new

      tree.add(page_one)
      tree.add(page_two)
      tree.insert_before(page_three, page_two)

      tree.index_of(page_one).should eq(0)
      tree.index_of(page_two).should eq(2)
      tree.index_of(page_three).should eq(1)
    end

    it "TestPDPageTree#testInsertAfterBlankPage" do
      tree = PDPageTree.new
      page_one = Page.new
      page_two = Page.new
      page_three = Page.new

      tree.add(page_one)
      tree.add(page_two)
      tree.insert_after(page_three, page_two)

      tree.index_of(page_one).should eq(0)
      tree.index_of(page_two).should eq(1)
      tree.index_of(page_three).should eq(2)
    end

    it "TestPDPageTree#indexOfPageFromOutlineDestination" do
      doc, tree = PageTreeSpecHelpers.load_page_tree(
        SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/with_outline.pdf")
      )
      begin
        outline = doc.document_catalog.not_nil!.document_outline.not_nil!
        current = outline.first_child
        found = false
        while current
          if current.title.to_s.includes?("Second")
            destination_page = current.find_destination_page(doc)
            destination_page.should_not be_nil
            tree.index_of(destination_page.not_nil!).should eq(2)
            found = true
          end
          current = current.next_sibling
        end
        found.should be_true
      ensure
        doc.close
      end
    end
  end
end
