require "./pdmodel"

module Pdfbox::Multipdf
  # Minimal PageExtractor parity helper, mirroring the Java API surface used by COSWriterTest.
  class PageExtractor
    @source_document : Pdfbox::Pdmodel::Document
    @start_page : Int32
    @end_page : Int32

    def initialize(@source_document : Pdfbox::Pdmodel::Document, start_page : Int = 1, end_page : Int? = nil)
      @start_page = start_page.to_i32
      @end_page = (end_page || @source_document.number_of_pages).to_i32
    end

    def start_page : Int32
      @start_page
    end

    def start_page=(value : Int) : Int32
      @start_page = value.to_i32
    end

    def end_page : Int32
      @end_page
    end

    def end_page=(value : Int) : Int32
      @end_page = value.to_i32
    end

    def extract : Pdfbox::Pdmodel::Document
      return Pdfbox::Pdmodel::Document.create if (@end_page - @start_page + 1) <= 0

      first_page = Math.max(@start_page, 1)
      last_page = Math.min(@end_page, @source_document.number_of_pages)
      return Pdfbox::Pdmodel::Document.create if first_page > last_page

      extracted = Pdfbox::Pdmodel::Document.create
      (first_page..last_page).each do |page_number|
        page = @source_document.page(page_number - 1)
        next unless page
        page_dict = page.cos_object
        if page_dict
          cloned_page_dict = Pdfbox::Cos::Dictionary.new
          page_dict.entries.each do |key, value|
            cloned_page_dict[key] = value
          end
          extracted.add_page(Pdfbox::Pdmodel::Page.new(cloned_page_dict))
        else
          extracted.add_page(Pdfbox::Pdmodel::Page.new)
        end
      end
      extracted
    end
  end
end
