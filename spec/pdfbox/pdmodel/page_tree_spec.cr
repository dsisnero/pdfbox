require "../../spec_helper"

module Pdfbox::Pdmodel
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
  end
end
