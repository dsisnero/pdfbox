require "../../../spec_helper"

module Pdfbox::Pdmodel::Common
  module COSArrayListTestSpecHelpers
    # Builds the COSArrayListTest#setUp fixture: highlight, link, circle, link.
    # Returns [actual list, backing COSArray, to-be-compared list, to-be-compared array].
    def self.build_annotation_fixture : Tuple(Array(Interactive::Annotation::PDAnnotation), Cos::Array, Array(Interactive::Annotation::PDAnnotation), Array(Cos::Base))
      txt_mark = Interactive::Annotation::PDAnnotationHighlight.new
      txt_link = Interactive::Annotation::PDAnnotationLink.new
      a_circle = Interactive::Annotation::PDAnnotationCircle.new

      annotations_list = [txt_mark, txt_link, a_circle, txt_link] of Interactive::Annotation::PDAnnotation
      annotations_list.size.should eq(4)

      tbc_annotations_list = [txt_mark, txt_link, a_circle, txt_link] of Interactive::Annotation::PDAnnotation
      tbc_annotations_list.size.should eq(4)

      annotations_array = Cos::Array.new
      annotations_array.add(txt_mark.cos_object)
      annotations_array.add(txt_link.cos_object)
      annotations_array.add(a_circle.cos_object)
      annotations_array.add(txt_link.cos_object)
      annotations_array.size.should eq(4)

      tbc_annotations_array = [] of Cos::Base
      tbc_annotations_array << txt_mark.cos_object
      tbc_annotations_array << txt_link.cos_object
      tbc_annotations_array << a_circle.cos_object
      tbc_annotations_array << txt_link.cos_object
      tbc_annotations_array.size.should eq(4)

      {annotations_list, annotations_array, tbc_annotations_list, tbc_annotations_array}
    end

    # Build a filtered list: actual has 2 entries but backing array has 4
    # (the link annotations are filtered out). Java PDPage.getAnnotations(filter)
    # produces such a list, and mutation must be refused.
    def self.filtered_annotation_list : COSArrayList(Interactive::Annotation::PDAnnotation)
      highlight = Interactive::Annotation::PDAnnotationHighlight.new
      link = Interactive::Annotation::PDAnnotationLink.new
      circle = Interactive::Annotation::PDAnnotationCircle.new

      actual_list = [highlight, circle] of Interactive::Annotation::PDAnnotation
      cos_array = Cos::Array.new
      cos_array.add(highlight.cos_object)
      cos_array.add(link.cos_object)
      cos_array.add(circle.cos_object)
      cos_array.add(link.cos_object)

      COSArrayList(Interactive::Annotation::PDAnnotation).new(actual_list, cos_array)
    end

    def self.temp_pdf_path(name : String) : String
      dir = (SpecPaths::PROJECT_ROOT / "temp" / "cosarraylist-spec").to_s
      Dir.mkdir_p(dir)
      File.join(dir, name)
    end

    def self.build_annotated_pdf(path : String) : Nil
      pdf = Pdfbox::Pdmodel::Document.create
      page = Pdfbox::Pdmodel::Page.new
      pdf.add_page(page)

      page_annots = [] of Interactive::Annotation::PDAnnotation
      txt_mark = Interactive::Annotation::PDAnnotationHighlight.new
      txt_link = Interactive::Annotation::PDAnnotationLink.new

      page_annots << txt_mark
      page_annots << txt_mark
      page_annots << txt_mark
      page_annots << txt_link
      page_annots.size.should eq(4) # There shall be 4 annotations generated

      page.annotations = page_annots
      pdf.save(path)
      pdf.close
    end
  end

  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/COSArrayListTest.java
  #
  # Ports the COSArrayList list-view semantics over direct and indirect COS
  # entries: get/add/remove/removeAll/retainAll stay in sync with the backing
  # COSArray, filtered lists refuse mutation, and annotations set on a page
  # round-trip through save/load with the same list behavior.
  describe COSArrayList do
    describe "COSArrayListTest#getFromList" do
      it "returns PDModel elements in sync with the underlying COSArray" do
        annotations_list, annotations_array, tbc_list, tbc_array = COSArrayListTestSpecHelpers.build_annotation_fixture

        cos_array_list = COSArrayList(Interactive::Annotation::PDAnnotation).new(annotations_list, annotations_array)

        cos_array_list.size.should eq(4)
        cos_array_list.size.times do |i|
          annot = cos_array_list.get(i)
          # PDAnnotations cosObject at i shall be equal to index i of COSArray
          annotations_array.get(i).should eq(annot.cos_object)
          # PDAnnotations at i shall be at index i of List
          tbc_list[i].should eq(annot)
          # PDAnnotations cosObject at i shall be at position i of Array
          tbc_array[i].should eq(annot.cos_object)
        end
      end
    end

    describe "COSArrayListTest#removeFromListByIndex" do
      it "removes by index and keeps List and COSArray in sync" do
        annotations_list, annotations_array, tbc_list, tbc_array = COSArrayListTestSpecHelpers.build_annotation_fixture

        cos_array_list = COSArrayList(Interactive::Annotation::PDAnnotation).new(annotations_list, annotations_array)

        position_to_remove = 2
        to_be_removed = cos_array_list.get(position_to_remove)

        # Remove operation shall return the removed object
        cos_array_list.remove(position_to_remove).should eq(to_be_removed)
        # List size shall be 3
        cos_array_list.size.should eq(3)
        # COSArray size shall be 3
        annotations_array.size.should eq(3)

        # PDAnnotation shall no longer exist in List
        cos_array_list.index_of(tbc_list[position_to_remove]).should be_nil
        # COSObject shall no longer exist in COSArray
        annotations_array.index_of(tbc_array[position_to_remove].as(Cos::Base)).should eq(-1)
      end
    end

    describe "COSArrayListTest#removeUniqueFromListByObject" do
      it "removes a unique object by object and keeps List and COSArray in sync" do
        annotations_list, annotations_array, tbc_list, tbc_array = COSArrayListTestSpecHelpers.build_annotation_fixture

        cos_array_list = COSArrayList(Interactive::Annotation::PDAnnotation).new(annotations_list, annotations_array)

        position_to_remove = 2
        to_be_removed = annotations_list[position_to_remove]

        # Remove operation shall return true
        cos_array_list.remove(to_be_removed).should be_true
        # List size shall be 3
        cos_array_list.size.should eq(3)
        # COSArray size shall be 3
        annotations_array.size.should eq(3)

        # List object at 3 is at position 2 in COSArrayList now
        cos_array_list.get(2).should eq(tbc_list[3])
        # COSObject of List object at 3 is at position 2 in COSArray now
        annotations_array.get(2).should eq(tbc_list[3].cos_object)
        # Array object at 3 is at position 2 in underlying COSArray now
        annotations_array.get(2).should eq(tbc_array[3])

        # PDAnnotation shall no longer exist in List
        cos_array_list.index_of(tbc_list[position_to_remove]).should be_nil
        # COSObject shall no longer exist in COSArray
        annotations_array.index_of(tbc_array[position_to_remove].as(Cos::Base)).should eq(-1)

        # Remove shall not remove any object
        cos_array_list.remove(to_be_removed).should be_false
      end
    end

    describe "COSArrayListTest#removeAllUniqueFromListByObject" do
      it "removes all matching objects via removeAll" do
        annotations_list, annotations_array, _tbc_list, _tbc_array = COSArrayListTestSpecHelpers.build_annotation_fixture

        cos_array_list = COSArrayList(Interactive::Annotation::PDAnnotation).new(annotations_list, annotations_array)

        position_to_remove = 2
        to_be_removed = annotations_list[position_to_remove]
        to_be_removed_instances = [to_be_removed]

        # Remove operation shall return true
        cos_array_list.remove_all(to_be_removed_instances).should be_true
        # List size shall be 3
        cos_array_list.size.should eq(3)
        # COSArray size shall be 3
        annotations_array.size.should eq(3)

        # Remove shall not remove any object
        cos_array_list.remove_all(to_be_removed_instances).should be_false
      end
    end

    describe "COSArrayListTest#removeMultipleFromListByObject" do
      it "removes each occurrence one at a time" do
        annotations_list, annotations_array, tbc_list, _tbc_array = COSArrayListTestSpecHelpers.build_annotation_fixture

        cos_array_list = COSArrayList(Interactive::Annotation::PDAnnotation).new(annotations_list, annotations_array)

        position_to_remove = 1
        to_be_removed = tbc_list[position_to_remove]

        # Remove operation shall return true
        cos_array_list.remove(to_be_removed).should be_true
        cos_array_list.size.should eq(3)
        annotations_array.size.should eq(3)

        # Remove operation shall return true (second occurrence)
        cos_array_list.remove(to_be_removed).should be_true
        cos_array_list.size.should eq(2)
        annotations_array.size.should eq(2)
      end
    end

    describe "COSArrayListTest#removeAllMultipleFromListByObject" do
      it "removes all occurrences via removeAll" do
        annotations_list, annotations_array, tbc_list, _tbc_array = COSArrayListTestSpecHelpers.build_annotation_fixture

        cos_array_list = COSArrayList(Interactive::Annotation::PDAnnotation).new(annotations_list, annotations_array)

        position_to_remove = 1
        to_be_removed = annotations_list[position_to_remove]
        to_be_removed_instances = [to_be_removed]

        # Remove operation shall return true
        cos_array_list.remove_all(to_be_removed_instances).should be_true
        cos_array_list.size.should eq(2)
        annotations_array.size.should eq(2)

        # Remove shall not remove any object
        cos_array_list.remove_all(to_be_removed_instances).should be_false
      end
    end

    describe "filtered list mutation guards" do
      it "COSArrayListTest#removeFromFilteredListByIndex raises UnsupportedOperationError" do
        cos_array_list = COSArrayListTestSpecHelpers.filtered_annotation_list
        expect_raises(Cos::UnsupportedOperationError, "removing entries from a filtered List is not permitted") do
          cos_array_list.remove(1)
        end
      end

      it "COSArrayListTest#removeFromFilteredListByObject raises UnsupportedOperationError" do
        cos_array_list = COSArrayListTestSpecHelpers.filtered_annotation_list
        expect_raises(Cos::UnsupportedOperationError, "removing entries from a filtered List is not permitted") do
          cos_array_list.remove(cos_array_list.get(1))
        end
      end
    end

    describe "save/load round-trip" do
      it "COSArrayListTest#removeSingleDirectObject" do
        temp_file = COSArrayListTestSpecHelpers.temp_pdf_path("removeSingleDirectObjectTest.pdf")
        begin
          pdf = Pdfbox::Pdmodel::Document.create
          page = Pdfbox::Pdmodel::Page.new
          pdf.add_page(page)

          page_annots = [] of Interactive::Annotation::PDAnnotation
          txt_mark = Interactive::Annotation::PDAnnotationHighlight.new
          txt_link = Interactive::Annotation::PDAnnotationLink.new

          # enforce the COSDictionaries to be written directly into the COSArray
          txt_mark.cos_object.direct = true
          txt_link.cos_object.direct = true

          page_annots << txt_mark
          page_annots << txt_mark
          page_annots << txt_mark
          page_annots << txt_link
          page_annots.size.should eq(4) # There shall be 4 annotations generated

          page.annotations = page_annots
          pdf.save(temp_file)
          pdf.close

          loaded_pdf = Pdfbox::Loader.load_pdf(temp_file)
          begin
            loaded_page = loaded_pdf.page(0).as(Pdfbox::Pdmodel::Page)

            annotations = loaded_page.annotations
            annotations.size.should eq(4)         # There shall be 4 annotations retrieved
            annotations.to_list.size.should eq(4) # The size of the internal COSArray shall be 4

            to_be_removed = annotations.get(0)
            annotations.remove(to_be_removed)

            annotations.size.should eq(3)         # There shall be 3 annotations left
            annotations.to_list.size.should eq(3) # The size of the internal COSArray shall be 3
          ensure
            loaded_pdf.close
          end
        ensure
          File.delete?(temp_file)
        end
      end

      it "COSArrayListTest#removeSingleIndirectObject" do
        temp_file = COSArrayListTestSpecHelpers.temp_pdf_path("removeSingleIndirectObjectTest.pdf")
        begin
          COSArrayListTestSpecHelpers.build_annotated_pdf(temp_file)

          loaded_pdf = Pdfbox::Loader.load_pdf(temp_file)
          begin
            loaded_page = loaded_pdf.page(0).as(Pdfbox::Pdmodel::Page)

            annotations = loaded_page.annotations
            annotations.size.should eq(4)         # There shall be 4 annotations retrieved
            annotations.to_list.size.should eq(4) # The size of the internal COSArray shall be 4

            to_be_removed = annotations.get(0)
            annotations.remove(to_be_removed)

            annotations.size.should eq(3)         # There shall be 3 annotations left
            annotations.to_list.size.should eq(3) # The size of the internal COSArray shall be 3
          ensure
            loaded_pdf.close
          end
        ensure
          File.delete?(temp_file)
        end
      end

      it "COSArrayListTest#retainIndirectObject" do
        temp_file = COSArrayListTestSpecHelpers.temp_pdf_path("removeIndirectObjectTest.pdf")
        begin
          COSArrayListTestSpecHelpers.build_annotated_pdf(temp_file)

          loaded_pdf = Pdfbox::Loader.load_pdf(temp_file)
          begin
            loaded_page = loaded_pdf.page(0).as(Pdfbox::Pdmodel::Page)

            annotations = loaded_page.annotations
            annotations.size.should eq(4)         # There shall be 4 annotations retrieved
            annotations.to_list.size.should eq(4) # The size of the internal COSArray shall be 4

            to_be_retained = [annotations.get(0)]
            annotations.retain_all(to_be_retained)

            annotations.size.should eq(3)         # There shall be 3 annotations left
            annotations.to_list.size.should eq(3) # The size of the internal COSArray shall be 3
          ensure
            loaded_pdf.close
          end
        ensure
          File.delete?(temp_file)
        end
      end
    end
  end
end
