require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/multipdf/Overlay.java
#     overlayDocuments(Map<Integer, PDDocument>) and the per-page
#     set*OverlayPDF(PDDocument) setters. Upstream has no dedicated unit test for
#     the document-based paths (the overlay tests use files); this is a
#     characterization spec.
module Pdfbox::Multipdf
  describe Overlay do
    it "accepts per-page overlay PDF documents" do
      overlay_doc = Pdfbox::Pdmodel::Document.new
      overlay_doc.add_page(Pdfbox::Pdmodel::Page.new)

      overlay = Overlay.new
      overlay.default_overlay_pdf = overlay_doc
      overlay.first_page_overlay_pdf = overlay_doc
      overlay.last_page_overlay_pdf = overlay_doc
      overlay.odd_page_overlay_pdf = overlay_doc
      overlay.even_page_overlay_pdf = overlay_doc
      overlay.all_pages_overlay_pdf = overlay_doc

      overlay.should_not be_nil
    end

    it "overlay_documents returns the input document" do
      input = Pdfbox::Pdmodel::Document.new
      input.add_page(Pdfbox::Pdmodel::Page.new)

      overlay = Overlay.new
      overlay.input_pdf = input

      result = overlay.overlay_documents({} of Int32 => Pdfbox::Pdmodel::Document)
      result.should be(input)
      result.number_of_pages.should eq(1)
    end
  end
end
