require "../../spec_helper"

module Pdfbox::Pdmodel
  module PageAnnotationsFilteringSpecHelpers
    def self.build_mock_page_with_annotations : Page
      annots_array = Cos::Array.new
      annots_array.add(Interactive::Annotation::PDAnnotationRubberStamp.new.cos_object)
      annots_array.add(Interactive::Annotation::PDAnnotationSquare.new.cos_object)
      annots_array.add(Interactive::Annotation::PDAnnotationLink.new.cos_object)

      mocked_page = Cos::Dictionary.new
      mocked_page[Cos::Name.new("Annots")] = annots_array
      Page.new(mocked_page)
    end
  end

  describe Page do
    describe "annotation filtering" do
      it "TestPDPageAnnotationsFiltering#validateNoFiltering" do
        page = PageAnnotationsFilteringSpecHelpers.build_mock_page_with_annotations
        annotations = page.annotations
        annotations.size.should eq 3
        annotations.get(0).should be_a(Interactive::Annotation::PDAnnotationRubberStamp)
        annotations.get(1).should be_a(Interactive::Annotation::PDAnnotationSquare)
        annotations.get(2).should be_a(Interactive::Annotation::PDAnnotationLink)
      end

      it "TestPDPageAnnotationsFiltering#validateAllFiltered" do
        page = PageAnnotationsFilteringSpecHelpers.build_mock_page_with_annotations
        annotations = page.get_annotations do |ann|
          false
        end
        annotations.size.should eq 0
      end

      it "TestPDPageAnnotationsFiltering#validateSelectedFew" do
        page = PageAnnotationsFilteringSpecHelpers.build_mock_page_with_annotations
        annotations = page.get_annotations do |ann|
          ann.is_a?(Interactive::Annotation::PDAnnotationLink) ||
            ann.is_a?(Interactive::Annotation::PDAnnotationSquare)
        end
        annotations.size.should eq 2
        annotations.get(0).should be_a(Interactive::Annotation::PDAnnotationSquare)
        annotations.get(1).should be_a(Interactive::Annotation::PDAnnotationLink)
      end
    end
  end
end
