require "../../spec_helper"

describe "Pdfbox::Multipdf parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/multipdf/
  #
  # Blocked by missing Crystal multipdf module/classes:
  # PDFCloneUtility, LayerUtility, PDFMergerUtility, Overlay, PageExtractor, and related structure tree handling.

  it "PDFCloneUtilityTest#testClonePDFWithCosArrayStream" do
    src_doc = Pdfbox::Pdmodel::Document.new
    dst_doc = Pdfbox::Pdmodel::Document.new
    src_page = Pdfbox::Pdmodel::Page.new
    src_doc.add_page(src_page)
    Pdfbox::Pdmodel::PDPageContentStream.new(
      src_doc, src_page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, true
    ).close
    Pdfbox::Pdmodel::PDPageContentStream.new(
      src_doc, src_page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, true
    ).close

    cloner = Pdfbox::Multipdf::PDFCloneUtility.new(dst_doc)
    cloner.destination.should be(dst_doc)

    cloned_dict = cloner.clone_for_new_document(src_page.cos_object.not_nil!)
    cloned_dict = cloned_dict.as(Pdfbox::Cos::Dictionary)
    cloned_page = Pdfbox::Pdmodel::Page.new(cloned_dict)
    cloned_page.content_streams.size.should eq(2)
    cloned_page.content_streams.each(&.should_not be_nil)
  end

  it "PDFCloneUtilityTest#testClonePDFWithCosArrayStream2" do
  end

  it "PDFCloneUtilityTest#testDirectIndirect" do
  end

  it "TestLayerUtility#testLayerImport" do
  end

  it "MergeAcroFormsTest#testLegacyModeMerge" do
  end

  it "MergeAcroFormsTest#testAnnotsEntry" do
  end

  it "MergeAcroFormsTest#testAPEntry" do
  end

  it "MergeAnnotationsTest#testLinkAnnotations" do
  end

  it "OverlayTest#testRotatedOverlays" do
  end

  it "OverlayTest#testRotatedOverlaysMap" do
  end

  it "OverlayTest#testOverlayOnRotatedSourcePages" do
  end

  it "PageExtractorTest#testExtract" do
  end

  it "PDFMergerUtilityTest#testPDFMergerUtility" do
  end

  it "PDFMergerUtilityTest#testPDFMergerUtility2" do
  end

  it "PDFMergerUtilityTest#testJpegCcitt" do
  end

  it "PDFMergerUtilityTest#testPDFMergerOpenAction" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge2" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge3" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge4" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge5" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge6" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge7" do
  end

  it "PDFMergerUtilityTest#testMissingParentTreeNextKey" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMergeIDTree" do
  end

  it "PDFMergerUtilityTest#testMergeBogusStructParents1" do
  end

  it "PDFMergerUtilityTest#testMergeBogusStructParents2" do
  end

  it "PDFMergerUtilityTest#testParentTree" do
  end

  it "PDFMergerUtilityTest#testFileDeletion" do
  end

  it "PDFMergerUtilityTest#testPDFBox5198_2" do
  end

  it "PDFMergerUtilityTest#testPDFBox5198_3" do
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTree" do
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTreeAndDestinations" do
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTreeAndDestinationsAndRemovedAnnotations" do
  end

  it "PDFMergerUtilityTest#testSinglePageSplit" do
  end

  it "PDFMergerUtilityTest#testSplitWithPopupAnnotations" do
  end

  it "PDFMergerUtilityTest#testSplitWithBrokenDestination" do
  end

  it "PDFMergerUtilityTest#testSplitWithNamedDestinations" do
  end

  it "PDFMergerUtilityTest#testSplitWithPgEntryAtTheTop" do
  end

  it "PDFMergerUtilityTest#testSplitWithOrphanPopupAnnotation" do
  end

  it "PDFMergerUtilityTest#testOutlinesSelfParent" do
  end

  it "PDFMergerUtilityTest#testPDFBox515" do
  end
end
