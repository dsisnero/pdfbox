require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/multipdf/PDFMergerUtility.java
#     DocumentMergeMode, get/setDocumentMergeMode, get/setDestinationDocumentInformation,
#     isIgnoreAcroFormErrors/setIgnoreAcroFormErrors, addSources. Upstream has no
#     dedicated unit test; this is a characterization spec.
module Pdfbox::Multipdf
  describe PDFMergerUtility do
    it "defaults to the optimize-resources document merge mode" do
      merger = PDFMergerUtility.new
      merger.document_merge_mode.should eq(PDFMergerUtility::DocumentMergeMode::OPTIMIZE_RESOURCES_MODE)

      merger.document_merge_mode = PDFMergerUtility::DocumentMergeMode::PDFBOX_LEGACY_MODE
      merger.document_merge_mode.should eq(PDFMergerUtility::DocumentMergeMode::PDFBOX_LEGACY_MODE)
    end

    it "defaults ignore_acro_form_errors to false and round-trips it" do
      merger = PDFMergerUtility.new
      merger.ignore_acro_form_errors?.should be_false

      merger.ignore_acro_form_errors = true
      merger.ignore_acro_form_errors?.should be_true
    end

    it "accepts multiple source documents via add_sources" do
      merger = PDFMergerUtility.new
      merger.add_sources([Pdfbox::Pdmodel::Document.new, Pdfbox::Pdmodel::Document.new])
      merger.should_not be_nil
    end

    it "applies the destination document information on merge" do
      output = ::IO::Memory.new
      merger = PDFMergerUtility.new
      merger.destination_stream = output
      merger.add_source(Pdfbox::Pdmodel::Document.new)

      info = Pdfbox::Pdmodel::DocumentInformation.new
      info.title = "Merged Title"
      merger.destination_document_information = info

      merger.merge_documents

      reloaded = Pdfbox::Loader.load_pdf(output.to_slice)
      begin
        reloaded.document_information.not_nil!.title.should eq("Merged Title")
      ensure
        reloaded.close
      end
    end
  end
end
